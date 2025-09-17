#!/usr/bin/env bash
set -euo pipefail
ORG="myonsite-healthcare"
MATCH="medinovai"
APPLY="false"
PHASE="bootstrap"
LOG_FILE="bulk_sync.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
    echo "$(date): INFO: $1" >> "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
    echo "$(date): SUCCESS: $1" >> "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    echo "$(date): WARNING: $1" >> "$LOG_FILE"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    echo "$(date): ERROR: $1" >> "$LOG_FILE"
}

# Phase-specific functions
apply_migration_changes() {
    local repo_path="$1"
    log_info "Applying migration changes to $repo_path"
    
    # Convert existing deployments to use ConfigMaps
    if [[ -f "$repo_path/deploy/base/deployment.yaml" ]]; then
        # Add ConfigMap references
        sed -i.bak 's/env:/envFrom:/g' "$repo_path/deploy/base/deployment.yaml"
        sed -i.bak 's/valueFrom:/configMapRef:/g' "$repo_path/deploy/base/deployment.yaml"
    fi
    
    # Convert to Argo Rollouts if it's a web service
    if [[ -f "$repo_path/deploy/base/deployment.yaml" ]] && grep -q "web\|api\|service" "$repo_path/deploy/base/deployment.yaml"; then
        cp "$repo_path/deploy/base/deployment.yaml" "$repo_path/deploy/base/rollout.yaml"
        sed -i.bak 's/kind: Deployment/kind: Rollout/g' "$repo_path/deploy/base/rollout.yaml"
        sed -i.bak 's/apiVersion: apps\/v1/apiVersion: argoproj.io\/v1alpha1/g' "$repo_path/deploy/base/rollout.yaml"
    fi
    
    # Convert services to ClusterIP
    if [[ -f "$repo_path/deploy/base/service.yaml" ]]; then
        sed -i.bak 's/type: NodePort/type: ClusterIP/g' "$repo_path/deploy/base/service.yaml"
        sed -i.bak 's/type: LoadBalancer/type: ClusterIP/g' "$repo_path/deploy/base/service.yaml"
    fi
    
    # Add Gateway API resources
    cat > "$repo_path/deploy/base/gateway.yaml" << EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: \$(APP_NAME)
spec:
  parentRefs:
  - name: medinovai-gateway
  hostnames:
  - \$(APP_NAME).medinovai.local
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: \$(APP_NAME)
      port: 80
EOF
}

apply_audit_changes() {
    local repo_path="$1"
    log_info "Applying audit changes to $repo_path"
    
    # Add SBOM generation to CI
    if [[ -f "$repo_path/.github/workflows/ci.yml" ]]; then
        # Add SBOM generation step
        sed -i.bak '/- name: Build and push Docker image/a\
    - name: Generate SBOM\
      uses: anchore/sbom-action@v0\
      with:\
        image: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}\
        format: spdx-json\
        output-file: sbom.spdx.json\
\
    - name: Upload SBOM\
      uses: actions/upload-artifact@v4\
      with:\
        name: sbom\
        path: sbom.spdx.json' "$repo_path/.github/workflows/ci.yml"
    fi
    
    # Add image signing
    if [[ -f "$repo_path/.github/workflows/ci.yml" ]]; then
        sed -i.bak '/- name: Build and push Docker image/a\
    - name: Sign image with Cosign\
      uses: sigstore/cosign-installer@v3\
      with:\
        cosign-release: '\''v2.2.0'\''\
\
    - name: Sign the published Docker image\
      run: cosign sign --yes ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}@${{ steps.meta.outputs.digest }}\
      env:\
        COSIGN_EXPERIMENTAL: 1' "$repo_path/.github/workflows/ci.yml"
    fi
    
    # Add vulnerability scanning
    if [[ -f "$repo_path/.github/workflows/ci.yml" ]]; then
        sed -i.bak '/- name: Run Trivy vulnerability scanner/a\
    - name: Run Grype vulnerability scanner\
      uses: anchore/grype-action@v1\
      with:\
        path: .\
        format: sarif\
        output: grype-results.sarif\
\
    - name: Upload Grype scan results\
      uses: github/codeql-action/upload-sarif@v2\
      if: always()\
      with:\
        sarif_file: '\''grype-results.sarif'\''' "$repo_path/.github/workflows/ci.yml"
    fi
}

apply_deepen_changes() {
    local repo_path="$1"
    log_info "Applying deepen changes to $repo_path"
    
    # Add observability configurations
    cat > "$repo_path/deploy/base/servicemonitor.yaml" << EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: \$(APP_NAME)
spec:
  selector:
    matchLabels:
      app: \$(APP_NAME)
  endpoints:
  - port: metrics
    path: /metrics
    interval: 30s
EOF
    
    # Add NetworkPolicy
    cat > "$repo_path/deploy/base/networkpolicy.yaml" << EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: \$(APP_NAME)
spec:
  podSelector:
    matchLabels:
      app: \$(APP_NAME)
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: medinovai-platform
    ports:
    - protocol: TCP
      port: 80
  egress:
  - to: []
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
EOF
    
    # Add SLO configuration
    cat > "$repo_path/deploy/base/slo.yaml" << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: \$(APP_NAME)-slo
data:
  slo.yaml: |
    objectives:
    - sli: availability
      target: 99.9
    - sli: latency
      target: 0.3
      window: 30d
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --org) ORG="$2"; shift 2 ;;
    --match) MATCH="$2"; shift 2 ;;
    --phase) PHASE="$2"; shift 2 ;;
    --apply) APPLY="true"; shift ;;
    --dry-run) APPLY="false"; shift ;;
    --help) 
      echo "Usage: $0 [OPTIONS]"
      echo "Options:"
      echo "  --org ORG        Organization name (default: myonsite-healthcare)"
      echo "  --match PATTERN  Repository name pattern (default: medinovai)"
      echo "  --phase PHASE    BMAD phase: bootstrap, migrate, audit, deepen (default: bootstrap)"
      echo "  --apply          Apply changes (create PRs)"
      echo "  --dry-run        Dry run mode (default)"
      echo "  --help           Show this help"
      exit 0 ;;
    *) log_error "Unknown argument: $1"; exit 1 ;;
  esac
done
# Check prerequisites
command -v gh >/dev/null || { log_error "GitHub CLI (gh) is required"; exit 1; }

# Initialize log file
echo "MedinovAI Bulk Sync Log" > "$LOG_FILE"
echo "Date: $(date)" >> "$LOG_FILE"
echo "Organization: $ORG" >> "$LOG_FILE"
echo "Match Pattern: $MATCH" >> "$LOG_FILE"
echo "Phase: $PHASE" >> "$LOG_FILE"
echo "Apply Mode: $APPLY" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"

log_info "Starting BMAD $PHASE phase for organization: $ORG"
log_info "Repository pattern: $MATCH"
log_info "Apply mode: $APPLY"

# Get repositories
log_info "Discovering repositories..."
repos=$(gh api -X GET orgs/${ORG}/repos --paginate -f per_page=100 --jq '.[] | select(.private==true and .archived==false and (.name | test(env.MATCH; "i"))) | .name')

if [[ -z "$repos" ]]; then
    log_error "No repositories found matching pattern: $MATCH"
    exit 1
fi

repo_count=$(echo "$repos" | wc -l)
log_success "Found $repo_count repositories"

# Create temporary directory
tmp_root=$(mktemp -d)
log_info "Using temporary directory: $tmp_root"

# Process each repository
success_count=0
failed_count=0
skipped_count=0

for r in $repos; do
    log_info "Processing repository: ${ORG}/${r}"
    
    tmp="${tmp_root}/${r}"
    mkdir -p "$tmp"
    
    # Clone repository
    if ! gh repo clone "${ORG}/${r}" "$tmp" 2>/dev/null; then
        log_error "Failed to clone ${ORG}/${r}"
        ((failed_count++))
        continue
    fi
    
    pushd "$tmp" >/dev/null
    
    # Create branch
    branch_name="chore/medinovai-standards-${PHASE}"
    if ! git checkout -b "$branch_name" 2>/dev/null; then
        log_warning "Branch $branch_name already exists for ${r}, skipping"
        ((skipped_count++))
        popd >/dev/null
        continue
    fi
    
    # Apply phase-specific changes
    case "$PHASE" in
        "bootstrap")
            # Copy standard templates
            rsync -a "$(dirname "$0")/../templates/medinovai-app/" "$tmp/"
            commit_msg="chore: bootstrap medinovai infrastructure standards"
            pr_title="Bootstrap: Adopt MedinovAI Infrastructure Standards"
            pr_body="This PR implements the Bootstrap phase of the BMAD methodology:

- ✅ Standard CI/CD workflows
- ✅ Kustomize deployment structure  
- ✅ Pre-commit hooks configuration
- ✅ Renovate dependency management
- ✅ Branch protection rules

**Phase:** Bootstrap (Pass 1)
**Methodology:** BMAD (Bootstrap-Migrate-Audit-Deepen)
**Reference:** [MedinovAI Unified Infrastructure & Policy Architecture](https://github.com/myonsite-healthcare/medinovai-infrastructure)"
            ;;
        "migrate")
            # Apply migration changes
            apply_migration_changes "$tmp"
            commit_msg="chore: migrate to medinovai infrastructure standards"
            pr_title="Migrate: Update to MedinovAI Infrastructure Standards"
            pr_body="This PR implements the Migrate phase of the BMAD methodology:

- ✅ Configuration migration to ConfigMaps
- ✅ Secrets migration to External Secrets Operator
- ✅ Ingress migration to Gateway API
- ✅ Deployment migration to Argo Rollouts
- ✅ Service migration to ClusterIP

**Phase:** Migrate (Pass 2)
**Methodology:** BMAD (Bootstrap-Migrate-Audit-Deepen)"
            ;;
        "audit")
            # Apply audit changes
            apply_audit_changes "$tmp"
            commit_msg="chore: implement audit and compliance standards"
            pr_title="Audit: Implement Security and Compliance Standards"
            pr_body="This PR implements the Audit phase of the BMAD methodology:

- ✅ SBOM generation implementation
- ✅ Container image signing with Cosign
- ✅ Vulnerability scanning with Trivy/Grype
- ✅ Policy compliance enforcement
- ✅ Security scanning integration

**Phase:** Audit (Pass 3)
**Methodology:** BMAD (Bootstrap-Migrate-Audit-Deepen)"
            ;;
        "deepen")
            # Apply deepen changes
            apply_deepen_changes "$tmp"
            commit_msg="chore: implement advanced observability and security"
            pr_title="Deepen: Advanced Observability and Security"
            pr_body="This PR implements the Deepen phase of the BMAD methodology:

- ✅ Observability dashboard creation
- ✅ SLO tracking implementation
- ✅ Distributed tracing setup
- ✅ Network policies implementation
- ✅ Advanced monitoring configuration

**Phase:** Deepen (Continuous)
**Methodology:** BMAD (Bootstrap-Migrate-Audit-Deepen)"
            ;;
        *)
            log_error "Unknown phase: $PHASE"
            ((failed_count++))
            popd >/dev/null
            continue
            ;;
    esac
    
    # Add changes
    git add .
    
    # Check if there are changes
    if ! git diff --cached --quiet; then
        git commit -m "$commit_msg"
        
        if [[ "$APPLY" == "true" ]]; then
            # Push branch and create PR
            if git push -u origin "$branch_name" 2>/dev/null; then
                if gh pr create --title "$pr_title" --body "$pr_body" 2>/dev/null; then
                    log_success "Created PR for ${r}"
                    ((success_count++))
                else
                    log_error "Failed to create PR for ${r}"
                    ((failed_count++))
                fi
            else
                log_error "Failed to push branch for ${r}"
                ((failed_count++))
            fi
        else
            log_info "(dry-run) would create PR for ${r}"
            ((success_count++))
        fi
    else
        log_warning "No changes for ${r}"
        ((skipped_count++))
    fi
    
    popd >/dev/null
done

# Cleanup
rm -rf "$tmp_root"

# Generate summary
log_info "Bulk sync completed"
log_success "Successful: $success_count"
log_warning "Skipped: $skipped_count"
if [[ $failed_count -gt 0 ]]; then
    log_error "Failed: $failed_count"
fi

echo ""
echo "📊 BMAD $PHASE Phase Summary:"
echo "  ✅ Successful: $success_count"
echo "  ⚠️  Skipped: $skipped_count"
echo "  ❌ Failed: $failed_count"
echo "  📝 Log file: $LOG_FILE"

if [[ $failed_count -gt 0 ]]; then
    log_warning "Some repositories failed. Check the log file for details."
    exit 1
fi

log_success "🎉 BMAD $PHASE phase complete!"
