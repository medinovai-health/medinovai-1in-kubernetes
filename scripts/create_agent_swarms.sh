#!/bin/bash

# MedinovAI Agent Swarms Creation Script
# This script creates and coordinates agent swarms for parallel implementation

set -euo pipefail

# Configuration
ORG="myonsite-healthcare"
REPO_PATTERN="medinovai"
SWARM_SIZE=10  # Number of parallel agents
PHASE="bootstrap"
LOG_DIR="swarm_logs"
SWARM_CONFIG_DIR="swarm_configs"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_swarm() {
    echo -e "${PURPLE}🤖 $1${NC}"
}

log_coordinator() {
    echo -e "${CYAN}🎯 $1${NC}"
}

# Create swarm configuration
create_swarm_config() {
    local swarm_id="$1"
    local repo_list="$2"
    local phase="$3"
    
    log_swarm "Creating configuration for Swarm $swarm_id"
    
    cat > "$SWARM_CONFIG_DIR/swarm_${swarm_id}_config.json" << EOF
{
  "swarm_id": "$swarm_id",
  "phase": "$phase",
  "organization": "$ORG",
  "repositories": $repo_list,
  "max_parallel": 5,
  "timeout": 1800,
  "retry_count": 3,
  "log_file": "$LOG_DIR/swarm_${swarm_id}.log",
  "status_file": "$LOG_DIR/swarm_${swarm_id}_status.json",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
    
    log_success "Swarm $swarm_id configuration created"
}

# Create individual agent script
create_agent_script() {
    local swarm_id="$1"
    local agent_id="$2"
    
    log_swarm "Creating agent script for Swarm $swarm_id, Agent $agent_id"
    
    cat > "$SWARM_CONFIG_DIR/agent_${swarm_id}_${agent_id}.sh" << 'EOF'
#!/bin/bash

# MedinovAI Agent Script
# This script executes BMAD implementation for assigned repositories

set -euo pipefail

# Agent configuration
AGENT_ID="$1"
SWARM_ID="$2"
CONFIG_FILE="$3"
LOG_FILE="$4"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Logging functions
log_agent() {
    echo -e "${PURPLE}🤖 Agent $AGENT_ID: $1${NC}"
    echo "$(date): Agent $AGENT_ID: $1" >> "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}✅ Agent $AGENT_ID: $1${NC}"
    echo "$(date): Agent $AGENT_ID SUCCESS: $1" >> "$LOG_FILE"
}

log_error() {
    echo -e "${RED}❌ Agent $AGENT_ID: $1${NC}"
    echo "$(date): Agent $AGENT_ID ERROR: $1" >> "$LOG_FILE"
}

# Load configuration
load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
    
    ORG=$(jq -r '.organization' "$CONFIG_FILE")
    PHASE=$(jq -r '.phase' "$CONFIG_FILE")
    REPOS=$(jq -r '.repositories[]' "$CONFIG_FILE")
    MAX_PARALLEL=$(jq -r '.max_parallel' "$CONFIG_FILE")
    TIMEOUT=$(jq -r '.timeout' "$CONFIG_FILE")
    RETRY_COUNT=$(jq -r '.retry_count' "$CONFIG_FILE")
    
    log_agent "Loaded configuration: Phase=$PHASE, MaxParallel=$MAX_PARALLEL, Timeout=${TIMEOUT}s"
}

# Process repository
process_repository() {
    local repo_name="$1"
    local attempt=1
    
    log_agent "Processing repository: $repo_name"
    
    while [[ $attempt -le $RETRY_COUNT ]]; do
        log_agent "Attempt $attempt/$RETRY_COUNT for $repo_name"
        
        if process_repo_implementation "$repo_name"; then
            log_success "Successfully processed $repo_name"
            return 0
        else
            log_error "Failed to process $repo_name (attempt $attempt)"
            ((attempt++))
            if [[ $attempt -le $RETRY_COUNT ]]; then
                log_agent "Retrying $repo_name in 30 seconds..."
                sleep 30
            fi
        fi
    done
    
    log_error "Failed to process $repo_name after $RETRY_COUNT attempts"
    return 1
}

# Implement repository changes
process_repo_implementation() {
    local repo_name="$1"
    local temp_dir="/tmp/medinovai-agent-${AGENT_ID}-${repo_name}"
    
    # Cleanup previous attempts
    rm -rf "$temp_dir"
    
    # Clone repository
    if ! git clone "https://github.com/$ORG/$repo_name.git" "$temp_dir" 2>/dev/null; then
        log_error "Failed to clone $repo_name"
        return 1
    fi
    
    cd "$temp_dir"
    
    # Create branch
    local branch_name="chore/medinovai-standards-${PHASE}-agent-${AGENT_ID}"
    if ! git checkout -b "$branch_name" 2>/dev/null; then
        log_agent "Branch $branch_name already exists for $repo_name, skipping"
        cd - >/dev/null
        rm -rf "$temp_dir"
        return 0
    fi
    
    # Apply phase-specific changes
    case "$PHASE" in
        "bootstrap")
            apply_bootstrap_changes "$repo_name"
            ;;
        "migrate")
            apply_migration_changes "$repo_name"
            ;;
        "audit")
            apply_audit_changes "$repo_name"
            ;;
        "deepen")
            apply_deepen_changes "$repo_name"
            ;;
        *)
            log_error "Unknown phase: $PHASE"
            cd - >/dev/null
            rm -rf "$temp_dir"
            return 1
            ;;
    esac
    
    # Commit changes
    git add .
    if ! git diff --cached --quiet; then
        git commit -m "chore: $PHASE medinovai infrastructure standards (agent $AGENT_ID)"
        
        # Push branch and create PR
        if git push -u origin "$branch_name" 2>/dev/null; then
            local pr_title="$PHASE: Adopt MedinovAI Infrastructure Standards (Agent $AGENT_ID)"
            local pr_body="This PR implements the $PHASE phase of the BMAD methodology:

- ✅ Automated implementation by Agent $AGENT_ID
- ✅ Phase: $PHASE
- ✅ Repository: $repo_name
- ✅ Agent ID: $AGENT_ID
- ✅ Timestamp: $(date)

**Phase:** $PHASE
**Methodology:** BMAD (Bootstrap-Migrate-Audit-Deepen)
**Agent:** $AGENT_ID
**Reference:** [MedinovAI Unified Infrastructure & Policy Architecture](https://github.com/myonsite-healthcare/medinovai-infrastructure)"
            
            if gh pr create --title "$pr_title" --body "$pr_body" 2>/dev/null; then
                log_success "Created PR for $repo_name"
            else
                log_error "Failed to create PR for $repo_name"
                cd - >/dev/null
                rm -rf "$temp_dir"
                return 1
            fi
        else
            log_error "Failed to push branch for $repo_name"
            cd - >/dev/null
            rm -rf "$temp_dir"
            return 1
        fi
    else
        log_agent "No changes for $repo_name"
    fi
    
    cd - >/dev/null
    rm -rf "$temp_dir"
    return 0
}

# Apply bootstrap changes
apply_bootstrap_changes() {
    local repo_name="$1"
    log_agent "Applying bootstrap changes to $repo_name"
    
    # Copy standard templates
    if [[ -d "../medinovai-infrastructure-standards/templates/medinovai-app" ]]; then
        cp -r ../medinovai-infrastructure-standards/templates/medinovai-app/* .
    fi
    
    # Create .github directory if it doesn't exist
    mkdir -p .github/workflows
    
    # Add standard CI workflow
    cat > .github/workflows/ci.yml << 'EOF'
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Run pre-commit
      uses: pre-commit/action@v3.0.0
      
  security:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'fs'
        scan-ref: '.'
        format: 'sarif'
        output: 'trivy-results.sarif'
EOF
    
    # Add pre-commit configuration
    cat > .pre-commit-config.yaml << 'EOF'
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-json
EOF
    
    # Add Renovate configuration
    cat > renovate.json << 'EOF'
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended"],
  "prHourlyLimit": 2
}
EOF
}

# Apply migration changes
apply_migration_changes() {
    local repo_name="$1"
    log_agent "Applying migration changes to $repo_name"
    
    # Convert existing deployments to use ConfigMaps
    if [[ -f "deploy/base/deployment.yaml" ]]; then
        sed -i.bak 's/env:/envFrom:/g' deploy/base/deployment.yaml
        sed -i.bak 's/valueFrom:/configMapRef:/g' deploy/base/deployment.yaml
    fi
    
    # Convert services to ClusterIP
    if [[ -f "deploy/base/service.yaml" ]]; then
        sed -i.bak 's/type: NodePort/type: ClusterIP/g' deploy/base/service.yaml
        sed -i.bak 's/type: LoadBalancer/type: ClusterIP/g' deploy/base/service.yaml
    fi
}

# Apply audit changes
apply_audit_changes() {
    local repo_name="$1"
    log_agent "Applying audit changes to $repo_name"
    
    # Add SBOM generation to CI
    if [[ -f ".github/workflows/ci.yml" ]]; then
        sed -i.bak '/- name: Run Trivy vulnerability scanner/a\
    - name: Generate SBOM\
      uses: anchore/sbom-action@v0\
      with:\
        image: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}\
        format: spdx-json\
        output-file: sbom.spdx.json' .github/workflows/ci.yml
    fi
}

# Apply deepen changes
apply_deepen_changes() {
    local repo_name="$1"
    log_agent "Applying deepen changes to $repo_name"
    
    # Add observability configurations
    mkdir -p deploy/base
    cat > deploy/base/servicemonitor.yaml << 'EOF'
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: $(APP_NAME)
spec:
  selector:
    matchLabels:
      app: $(APP_NAME)
  endpoints:
  - port: metrics
    path: /metrics
    interval: 30s
EOF
}

# Main agent execution
main() {
    log_agent "Starting Agent $AGENT_ID for Swarm $SWARM_ID"
    
    # Load configuration
    load_config
    
    # Process repositories
    local success_count=0
    local failed_count=0
    
    for repo in $REPOS; do
        if process_repository "$repo"; then
            ((success_count++))
        else
            ((failed_count++))
        fi
    done
    
    # Update status
    cat > "$LOG_DIR/swarm_${SWARM_ID}_agent_${AGENT_ID}_status.json" << EOF
{
  "agent_id": "$AGENT_ID",
  "swarm_id": "$SWARM_ID",
  "phase": "$PHASE",
  "success_count": $success_count,
  "failed_count": $failed_count,
  "total_repos": $((success_count + failed_count)),
  "completed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "completed"
}
EOF
    
    log_success "Agent $AGENT_ID completed: $success_count successful, $failed_count failed"
}

# Run main function
main "$@"
EOF
    
    chmod +x "$SWARM_CONFIG_DIR/agent_${swarm_id}_${agent_id}.sh"
    log_success "Agent script created for Swarm $swarm_id, Agent $agent_id"
}

# Create swarm coordinator
create_swarm_coordinator() {
    local swarm_id="$1"
    
    log_coordinator "Creating coordinator for Swarm $swarm_id"
    
    cat > "$SWARM_CONFIG_DIR/coordinator_${swarm_id}.sh" << 'EOF'
#!/bin/bash

# MedinovAI Swarm Coordinator
# This script coordinates and monitors agent execution

set -euo pipefail

SWARM_ID="$1"
CONFIG_FILE="$2"
LOG_DIR="$3"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging functions
log_coordinator() {
    echo -e "${CYAN}🎯 Coordinator $SWARM_ID: $1${NC}"
    echo "$(date): Coordinator $SWARM_ID: $1" >> "$LOG_DIR/coordinator_${SWARM_ID}.log"
}

log_success() {
    echo -e "${GREEN}✅ Coordinator $SWARM_ID: $1${NC}"
    echo "$(date): Coordinator $SWARM_ID SUCCESS: $1" >> "$LOG_DIR/coordinator_${SWARM_ID}.log"
}

log_error() {
    echo -e "${RED}❌ Coordinator $SWARM_ID: $1${NC}"
    echo "$(date): Coordinator $SWARM_ID ERROR: $1" >> "$LOG_DIR/coordinator_${SWARM_ID}.log"
}

# Load configuration
load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
    
    PHASE=$(jq -r '.phase' "$CONFIG_FILE")
    MAX_PARALLEL=$(jq -r '.max_parallel' "$CONFIG_FILE")
    TIMEOUT=$(jq -r '.timeout' "$CONFIG_FILE")
    
    log_coordinator "Loaded configuration: Phase=$PHASE, MaxParallel=$MAX_PARALLEL, Timeout=${TIMEOUT}s"
}

# Monitor agents
monitor_agents() {
    local agent_pids=()
    local agent_count=0
    
    log_coordinator "Starting agent monitoring"
    
    # Start agents
    for agent_id in $(seq 1 $MAX_PARALLEL); do
        local agent_script="$SWARM_CONFIG_DIR/agent_${SWARM_ID}_${agent_id}.sh"
        if [[ -f "$agent_script" ]]; then
            log_coordinator "Starting Agent $agent_id"
            "$agent_script" "$agent_id" "$SWARM_ID" "$CONFIG_FILE" "$LOG_DIR/swarm_${SWARM_ID}_agent_${agent_id}.log" &
            agent_pids+=($!)
            ((agent_count++))
        fi
    done
    
    log_coordinator "Started $agent_count agents"
    
    # Monitor agent completion
    local completed_agents=0
    while [[ $completed_agents -lt $agent_count ]]; do
        for i in "${!agent_pids[@]}"; do
            if ! kill -0 "${agent_pids[$i]}" 2>/dev/null; then
                wait "${agent_pids[$i]}"
                local exit_code=$?
                if [[ $exit_code -eq 0 ]]; then
                    log_success "Agent $((i+1)) completed successfully"
                else
                    log_error "Agent $((i+1)) failed with exit code $exit_code"
                fi
                unset agent_pids[$i]
                ((completed_agents++))
            fi
        done
        sleep 5
    done
    
    log_success "All agents completed for Swarm $SWARM_ID"
}

# Generate swarm report
generate_swarm_report() {
    log_coordinator "Generating swarm report"
    
    local total_success=0
    local total_failed=0
    local total_repos=0
    
    for agent_id in $(seq 1 $MAX_PARALLEL); do
        local status_file="$LOG_DIR/swarm_${SWARM_ID}_agent_${agent_id}_status.json"
        if [[ -f "$status_file" ]]; then
            local success=$(jq -r '.success_count' "$status_file")
            local failed=$(jq -r '.failed_count' "$status_file")
            local repos=$(jq -r '.total_repos' "$status_file")
            
            total_success=$((total_success + success))
            total_failed=$((total_failed + failed))
            total_repos=$((total_repos + repos))
        fi
    done
    
    cat > "$LOG_DIR/swarm_${SWARM_ID}_report.json" << EOF
{
  "swarm_id": "$SWARM_ID",
  "phase": "$PHASE",
  "total_repositories": $total_repos,
  "successful_repositories": $total_success,
  "failed_repositories": $total_failed,
  "success_rate": $(echo "scale=2; $total_success * 100 / $total_repos" | bc -l),
  "completed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "completed"
}
EOF
    
    log_success "Swarm $SWARM_ID report generated: $total_success/$total_repos successful"
}

# Main coordinator execution
main() {
    log_coordinator "Starting Coordinator for Swarm $SWARM_ID"
    
    # Load configuration
    load_config
    
    # Monitor agents
    monitor_agents
    
    # Generate report
    generate_swarm_report
    
    log_success "Coordinator $SWARM_ID completed"
}

# Run main function
main "$@"
EOF
    
    chmod +x "$SWARM_CONFIG_DIR/coordinator_${swarm_id}.sh"
    log_success "Coordinator created for Swarm $swarm_id"
}

# Main execution
main() {
    echo "🤖 MedinovAI Agent Swarms Creation"
    echo "=================================="
    echo "Organization: $ORG"
    echo "Repository Pattern: $REPO_PATTERN"
    echo "Swarm Size: $SWARM_SIZE"
    echo "Phase: $PHASE"
    echo "Date: $(date)"
    echo ""
    
    # Create directories
    mkdir -p "$LOG_DIR" "$SWARM_CONFIG_DIR"
    
    log_info "Creating agent swarms for parallel execution..."
    
    # Get repository list
    log_info "Discovering repositories..."
    local repos_json
    repos_json=$(gh api -X GET orgs/${ORG}/repos --paginate -f per_page=100 --jq '.[] | select(.private==true and .archived==false and (.name | test(env.REPO_PATTERN; "i"))) | .name' | jq -R -s -c 'split("\n")[:-1]')
    
    if [[ -z "$repos_json" || "$repos_json" == "[]" ]]; then
        log_error "No repositories found matching pattern: $REPO_PATTERN"
        exit 1
    fi
    
    local repo_count
    repo_count=$(echo "$repos_json" | jq 'length')
    log_success "Found $repo_count repositories"
    
    # Calculate repositories per swarm
    local repos_per_swarm=$((repo_count / SWARM_SIZE))
    if [[ $repos_per_swarm -eq 0 ]]; then
        repos_per_swarm=1
    fi
    
    log_info "Creating $SWARM_SIZE swarms with ~$repos_per_swarm repositories each"
    
    # Create swarms
    for swarm_id in $(seq 1 $SWARM_SIZE); do
        local start_idx=$(((swarm_id - 1) * repos_per_swarm))
        local end_idx=$((start_idx + repos_per_swarm))
        
        if [[ $swarm_id -eq $SWARM_SIZE ]]; then
            # Last swarm gets remaining repositories
            end_idx=$repo_count
        fi
        
        local swarm_repos
        swarm_repos=$(echo "$repos_json" | jq ".[$start_idx:$end_idx]")
        
        if [[ "$swarm_repos" != "[]" ]]; then
            log_swarm "Creating Swarm $swarm_id with $(echo "$swarm_repos" | jq 'length') repositories"
            
            # Create swarm configuration
            create_swarm_config "$swarm_id" "$swarm_repos" "$PHASE"
            
            # Create agent scripts
            for agent_id in $(seq 1 5); do
                create_agent_script "$swarm_id" "$agent_id"
            done
            
            # Create coordinator
            create_swarm_coordinator "$swarm_id"
            
            log_success "Swarm $swarm_id created successfully"
        fi
    done
    
    echo ""
    log_success "🎉 Agent swarms created successfully!"
    echo ""
    echo "📊 Swarm Summary:"
    echo "  🤖 Total Swarms: $SWARM_SIZE"
    echo "  📁 Configuration Directory: $SWARM_CONFIG_DIR"
    echo "  📝 Log Directory: $LOG_DIR"
    echo "  🎯 Phase: $PHASE"
    echo ""
    echo "🚀 Next Steps:"
    echo "  1. Review swarm configurations"
    echo "  2. Execute swarms: ./scripts/execute_agent_swarms.sh"
    echo "  3. Monitor progress: ./scripts/monitor_swarms.sh"
}

# Run main function
main "$@"

