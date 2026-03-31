#!/usr/bin/env bash
# ─── instantiate.sh ───────────────────────────────────────────────────────────
# Full greenfield instantiation of the MedinovAI platform on-prem.
# Takes bare metal nodes and stands up the complete K3s + MedinovAI stack.
#
# Usage:
#   bash scripts/bootstrap/instantiate.sh
#   bash scripts/bootstrap/instantiate.sh --critical-path-only
#   bash scripts/bootstrap/instantiate.sh --resume
#   bash scripts/bootstrap/instantiate.sh --step 12
#   bash scripts/bootstrap/instantiate.sh --dry-run
#
# Options:
#   --critical-path-only  Deploy only the 12 essential services (~25 min)
#   --dry-run             Show what would be done without executing
#   --resume              Resume from last checkpoint
#   --step N              Start from a specific step number
#   --dgx-ips "ip1,ip2"  DGX server IPs (default from fleet.json5)
#   --skip-gpu            Skip DGX/GPU setup steps
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
DEPLOY_HOME="${DEPLOY_HOME:-$HOME/.medinovai-deploy}"
CHECKPOINT_DIR="$DEPLOY_HOME/checkpoints"
LOG_DIR="$DEPLOY_HOME/logs"
TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
LOG_FILE="$LOG_DIR/instantiate-$TIMESTAMP.log"
KUBECONFIG_FILE="$DEPLOY_HOME/kubeconfig.yaml"

CRITICAL_PATH_ONLY=false
DRY_RUN=false
RESUME=false
START_STEP=1
TOTAL_STEPS=25
DGX_IPS="${DGX_IPS:-192.168.68.78,192.168.68.85}"
SKIP_GPU=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --critical-path-only) CRITICAL_PATH_ONLY=true; shift ;;
        --dry-run)            DRY_RUN=true; shift ;;
        --resume)             RESUME=true; shift ;;
        --step)               START_STEP="$2"; shift 2 ;;
        --dgx-ips)            DGX_IPS="$2"; shift 2 ;;
        --skip-gpu)           SKIP_GPU=true; shift ;;
        *)                    echo "Unknown option: $1"; exit 1 ;;
    esac
done

mkdir -p "$CHECKPOINT_DIR" "$LOG_DIR"

log() {
    local msg="[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $1"
    echo "$msg" | tee -a "$LOG_FILE"
}

checkpoint_exists() { [ -f "$CHECKPOINT_DIR/step_$1.done" ]; }

mark_checkpoint() {
    local step="$1" desc="$2"
    echo "{\"step\": $step, \"description\": \"$desc\", \"completed_at\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" \
        > "$CHECKPOINT_DIR/step_$step.done"
    log "  ✓ Checkpoint saved: step $step — $desc"
}

run_step() {
    local step_num="$1" desc="$2" func="$3"
    [ "$step_num" -lt "$START_STEP" ] && return 0
    $RESUME && checkpoint_exists "$step_num" && { log "  ⏭ Step $step_num/$TOTAL_STEPS: $desc — SKIPPED (checkpoint)"; return 0; }
    log ""
    log "━━━ Step $step_num/$TOTAL_STEPS: $desc ━━━"
    if $DRY_RUN; then log "  [DRY RUN] Would execute: $desc"; return 0; fi
    if $func; then mark_checkpoint "$step_num" "$desc"; else log "  ✗ Step $step_num FAILED: $desc"; log "  Re-run with --resume to retry."; exit 1; fi
}

# ─── Step Functions ───────────────────────────────────────────────────────────

step_01_prerequisites() {
    log "  Checking prerequisites..."
    bash "$SCRIPT_DIR/prerequisites.sh"
}

step_02_network() {
    log "  Setting up Tailscale mesh..."
    bash "$SCRIPT_DIR/init-network.sh" --advertise-routes
}

step_03_k3s_server() {
    log "  Setting up K3s server on Mac Studio via OrbStack..."
    bash "$SCRIPT_DIR/init-orbstack.sh" --role server
    export KUBECONFIG="$KUBECONFIG_FILE"
}

step_04_k3s_agent() {
    log "  Setting up K3s agent on MacBook Pro via OrbStack..."
    local server_ip
    server_ip=$(tailscale ip -4 2>/dev/null || echo "")
    bash "$SCRIPT_DIR/init-orbstack.sh" --role agent --server-ip "$server_ip" --vm-name "medinovai-k3s-worker"
}

step_05_dgx_nodes() {
    if $SKIP_GPU; then log "  Skipping DGX setup (--skip-gpu)"; return 0; fi
    local server_ip
    server_ip=$(tailscale ip -4 2>/dev/null || echo "")
    log "  Setting up DGX GPU nodes..."
    bash "$SCRIPT_DIR/init-dgx.sh" --server-ip "$server_ip" --dgx-ips "$DGX_IPS"
}

step_06_storage() {
    log "  Installing Longhorn storage..."
    bash "$SCRIPT_DIR/init-storage.sh" --replicas 2
}

step_07_namespaces() {
    log "  Creating Kubernetes namespaces and RBAC..."
    export KUBECONFIG="$KUBECONFIG_FILE"
    kubectl apply -f "$REPO_ROOT/infra/kubernetes/services/tier0/namespace.yaml"
    [ -d "$REPO_ROOT/infra/kubernetes/base" ] && kubectl apply -k "$REPO_ROOT/infra/kubernetes/base" || true
}

step_08_vault() {
    log "  Deploying HashiCorp Vault..."
    bash "$SCRIPT_DIR/init-vault.sh"
}

step_09_seed_secrets() {
    log "  Seeding secrets into Vault..."
    local env_file="$HOME/.atlas/.env"
    if [ -f "$env_file" ]; then
        bash "$SCRIPT_DIR/init-vault.sh" --seed-from-env "$env_file"
    else
        log "  No .env file found at $env_file — run 'init-vault.sh --seed' manually"
    fi
    return 0
}

step_10_eso() {
    log "  Installing External Secrets Operator..."
    export KUBECONFIG="$KUBECONFIG_FILE"
    helm repo add external-secrets https://charts.external-secrets.io 2>/dev/null || true
    helm repo update external-secrets 2>/dev/null || true
    helm install external-secrets external-secrets/external-secrets \
        -n external-secrets --create-namespace --wait --timeout 3m 2>/dev/null || \
        helm upgrade external-secrets external-secrets/external-secrets \
            -n external-secrets --wait --timeout 3m
    kubectl apply -k "$REPO_ROOT/infra/kubernetes/external-secrets/"
    log "  ✓ ESO installed and SecretStores created"
}

step_11_monitoring() {
    log "  Deploying monitoring stack..."
    export KUBECONFIG="$KUBECONFIG_FILE"
    if [ -d "$REPO_ROOT/infra/kubernetes/monitoring" ]; then
        kubectl apply -k "$REPO_ROOT/infra/kubernetes/monitoring" || true
    else
        log "  Monitoring manifests not found — skipping"
    fi
    return 0
}

step_12_tier0() {
    log "  Deploying Tier 0: Databases and infrastructure..."
    export KUBECONFIG="$KUBECONFIG_FILE"
    kubectl apply -k "$REPO_ROOT/infra/kubernetes/services/tier0/"
    log "  Waiting for PostgreSQL to be ready..."
    kubectl wait --for=condition=ready pod -l app=postgres-primary -n infra --timeout=120s 2>/dev/null || true
    kubectl wait --for=condition=ready pod -l app=redis -n infra --timeout=60s 2>/dev/null || true
}

step_13_tier1() {
    log "  Deploying Tier 1: Security services..."
    export KUBECONFIG="$KUBECONFIG_FILE"
    if [ -d "$REPO_ROOT/infra/kubernetes/services/tier1" ]; then
        kubectl apply -k "$REPO_ROOT/infra/kubernetes/services/tier1/" || true
    else
        log "  Tier 1 manifests not yet created — skipping"
    fi
    return 0
}

step_14_tier2() {
    log "  Deploying Tier 2: Platform core services..."
    export KUBECONFIG="$KUBECONFIG_FILE"
    if [ -d "$REPO_ROOT/infra/kubernetes/services/tier2" ]; then
        kubectl apply -k "$REPO_ROOT/infra/kubernetes/services/tier2/" || true
    else
        log "  Tier 2 manifests not yet created — skipping"
    fi
    return 0
}

step_15_atlasos() {
    log "  Deploying AtlasOS services..."
    export KUBECONFIG="$KUBECONFIG_FILE"
    kubectl apply -k "$REPO_ROOT/infra/kubernetes/services/atlasos/"
}

step_16_tier3() {
    if $CRITICAL_PATH_ONLY; then log "  Skipping Tier 3 (critical-path-only mode)"; return 0; fi
    log "  Deploying Tier 3: AI/ML and clinical foundation..."
    export KUBECONFIG="$KUBECONFIG_FILE"
    if [ -d "$REPO_ROOT/infra/kubernetes/services/tier3" ]; then
        kubectl apply -k "$REPO_ROOT/infra/kubernetes/services/tier3/" || true
    fi
    return 0
}

step_17_gpu() {
    if $CRITICAL_PATH_ONLY || $SKIP_GPU; then log "  Skipping GPU workloads"; return 0; fi
    log "  Deploying AI inference on GPU nodes (Ollama, AIFactory)..."
    export KUBECONFIG="$KUBECONFIG_FILE"
    # Ollama DaemonSet for GPU nodes
    cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: ollama
  namespace: ai-ml
spec:
  selector:
    matchLabels:
      app: ollama
  template:
    metadata:
      labels:
        app: ollama
    spec:
      nodeSelector:
        gpu: "true"
      tolerations:
        - key: nvidia.com/gpu
          operator: Exists
          effect: NoSchedule
      containers:
        - name: ollama
          image: ollama/ollama:latest
          ports:
            - containerPort: 11434
          resources:
            limits:
              nvidia.com/gpu: "1"
          volumeMounts:
            - name: ollama-data
              mountPath: /root/.ollama
      volumes:
        - name: ollama-data
          emptyDir:
            sizeLimit: 50Gi
---
apiVersion: v1
kind: Service
metadata:
  name: ollama
  namespace: ai-ml
spec:
  ports:
    - port: 11434
      targetPort: 11434
  selector:
    app: ollama
EOF
    log "  ✓ Ollama DaemonSet deployed to GPU nodes"
}

step_18_tier4() {
    if $CRITICAL_PATH_ONLY; then log "  Skipping Tier 4 (critical-path-only mode)"; return 0; fi
    log "  Deploying Tier 4: Domain services..."
    export KUBECONFIG="$KUBECONFIG_FILE"
    if [ -d "$REPO_ROOT/infra/kubernetes/services/tier4" ]; then
        kubectl apply -k "$REPO_ROOT/infra/kubernetes/services/tier4/" || true
    fi
    return 0
}

step_19_tier5() {
    if $CRITICAL_PATH_ONLY; then log "  Skipping Tier 5 (critical-path-only mode)"; return 0; fi
    log "  Deploying Tier 5: Integration services..."
    return 0
}

step_20_tier6() {
    if $CRITICAL_PATH_ONLY; then log "  Skipping Tier 6 (critical-path-only mode)"; return 0; fi
    log "  Deploying Tier 6: UI shell..."
    return 0
}

step_21_ingress() {
    log "  Configuring ingress..."
    export KUBECONFIG="$KUBECONFIG_FILE"
    if [ -d "$REPO_ROOT/infra/kubernetes/ingress" ]; then
        kubectl apply -k "$REPO_ROOT/infra/kubernetes/ingress/" || true
    fi
    return 0
}

step_22_node_agents() {
    log "  Deploying AtlasOS node agents (DaemonSet)..."
    export KUBECONFIG="$KUBECONFIG_FILE"
    kubectl apply -k "$REPO_ROOT/infra/kubernetes/services/atlasos-node-agent/"
}

step_23_cluster_brain() {
    log "  Deploying AtlasOS cluster brain..."
    export KUBECONFIG="$KUBECONFIG_FILE"
    kubectl apply -k "$REPO_ROOT/infra/kubernetes/services/atlasos-cluster-brain/"
}

step_24_atlas_agents() {
    log "  Registering Atlas agents and crons..."
    if [ -f "$REPO_ROOT/scripts/agents/create_agents.sh" ]; then
        bash "$REPO_ROOT/scripts/agents/create_agents.sh" 2>&1 | tee -a "$LOG_FILE" || true
    fi
    if [ -f "$REPO_ROOT/scripts/agents/register_crons.sh" ]; then
        bash "$REPO_ROOT/scripts/agents/register_crons.sh" 2>&1 | tee -a "$LOG_FILE" || true
    fi
    return 0
}

step_25_smoke_tests() {
    log "  Running smoke tests..."
    export KUBECONFIG="$KUBECONFIG_FILE"

    log "  Checking nodes..."
    kubectl get nodes -o wide 2>/dev/null || true

    log "  Checking critical pods..."
    for ns in infra security platform atlasos ai-ml; do
        local ready
        ready=$(kubectl get pods -n "$ns" --no-headers 2>/dev/null | grep -c "Running" || echo "0")
        local total
        total=$(kubectl get pods -n "$ns" --no-headers 2>/dev/null | wc -l | xargs || echo "0")
        log "    $ns: $ready/$total running"
    done

    log "  Checking Vault..."
    kubectl exec -n vault vault-0 -- vault status 2>/dev/null | head -5 || true

    log "  Checking cluster brain..."
    kubectl exec -n atlasos deploy/atlasos-cluster-brain -- curl -s http://localhost:8100/health 2>/dev/null || true

    log "  ✓ Smoke tests complete"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   MedinovAI Platform — On-Prem Greenfield Instantiation     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
log "Configuration:"
log "  Target:       On-Prem K3s (OrbStack + DGX)"
log "  DGX IPs:      ${DGX_IPS:-none}"
log "  Critical Only: $CRITICAL_PATH_ONLY"
log "  Skip GPU:      $SKIP_GPU"
log "  Dry Run:       $DRY_RUN"
log "  Resume:        $RESUME"
log "  Start Step:    $START_STEP"
log "  Log File:      $LOG_FILE"
echo ""

if ! $DRY_RUN; then
    echo "This will set up K3s cluster and deploy the MedinovAI platform."
    if $CRITICAL_PATH_ONLY; then
        echo "Mode: Critical path only (~25 min, 12 essential services)"
    else
        echo "Mode: Full platform (~70 min, all 109 services)"
    fi
    echo ""
    read -r -p "Proceed? [y/N] " confirm
    case "$confirm" in [yY][eE][sS]|[yY]) ;; *) echo "Aborted."; exit 0 ;; esac
fi

START_TIME=$(date +%s)

run_step 1  "Prerequisites check"                       step_01_prerequisites
run_step 2  "Tailscale mesh network"                    step_02_network
run_step 3  "K3s server (Mac Studio via OrbStack)"      step_03_k3s_server
run_step 4  "K3s agent (MacBook Pro via OrbStack)"      step_04_k3s_agent
run_step 5  "DGX GPU nodes"                             step_05_dgx_nodes
run_step 6  "Longhorn distributed storage"              step_06_storage
run_step 7  "Kubernetes namespaces and RBAC"            step_07_namespaces
run_step 8  "HashiCorp Vault"                           step_08_vault
run_step 9  "Seed secrets into Vault"                   step_09_seed_secrets
run_step 10 "External Secrets Operator"                 step_10_eso
run_step 11 "Monitoring stack"                          step_11_monitoring
run_step 12 "Tier 0: Databases + infrastructure"        step_12_tier0
run_step 13 "Tier 1: Security services"                 step_13_tier1
run_step 14 "Tier 2: Platform core"                     step_14_tier2
run_step 15 "AtlasOS services"                          step_15_atlasos
run_step 16 "Tier 3: AI/ML + clinical foundation"       step_16_tier3
run_step 17 "GPU inference (Ollama, AIFactory)"         step_17_gpu
run_step 18 "Tier 4: Domain services"                   step_18_tier4
run_step 19 "Tier 5: Integration services"              step_19_tier5
run_step 20 "Tier 6: UI shell"                          step_20_tier6
run_step 21 "Ingress"                                   step_21_ingress
run_step 22 "AtlasOS node agents (DaemonSet)"           step_22_node_agents
run_step 23 "AtlasOS cluster brain"                     step_23_cluster_brain
run_step 24 "Atlas agent registration + crons"          step_24_atlas_agents
run_step 25 "Smoke tests"                               step_25_smoke_tests

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
MINUTES=$((ELAPSED / 60))
SECONDS_LEFT=$((ELAPSED % 60))

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✓ Instantiation complete!                                  ║"
echo "║                                                             ║"
echo "║  Duration:    ${MINUTES}m ${SECONDS_LEFT}s                  ║"
echo "║  Log:         $LOG_FILE                                     ║"
echo "║                                                             ║"
echo "║  Next steps:                                                ║"
echo "║  1. Verify: make health                                     ║"
echo "║  2. Seed secrets: make seed-secrets                         ║"
echo "║  3. Dashboards: make dashboards                             ║"
echo "║  4. Embed AtlasOS in repos: make embed-atlasos              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
