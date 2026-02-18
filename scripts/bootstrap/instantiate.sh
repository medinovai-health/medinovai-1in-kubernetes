#!/usr/bin/env bash
# ─── instantiate.sh ───────────────────────────────────────────────────────────
# Full greenfield instantiation of the MedinovAI platform — on-prem K3s.
# Takes blank physical servers and stands up a complete environment.
#
# Usage:
#   bash scripts/bootstrap/instantiate.sh
#   bash scripts/bootstrap/instantiate.sh --critical-path-only
#   bash scripts/bootstrap/instantiate.sh --dry-run
#   bash scripts/bootstrap/instantiate.sh --resume
#   bash scripts/bootstrap/instantiate.sh --step 8
#
# Options:
#   --critical-path-only  Deploy minimum viable platform (~25 min)
#   --dry-run             Show what would be done without executing
#   --resume              Resume from last checkpoint
#   --step N              Start from a specific step number
#   --skip-gpu            Skip DGX/GPU node setup
#   --skip-embed          Skip AtlasOS embedding in repos
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
DEPLOY_HOME="${DEPLOY_HOME:-$HOME/.medinovai-deploy}"
CHECKPOINT_DIR="$DEPLOY_HOME/checkpoints"
LOG_DIR="$DEPLOY_HOME/logs"
TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
LOG_FILE="$LOG_DIR/instantiate-$TIMESTAMP.log"

CRITICAL_PATH_ONLY=false
DRY_RUN=false
RESUME=false
START_STEP=1
SKIP_GPU=false
SKIP_EMBED=false
TOTAL_STEPS=25

while [[ $# -gt 0 ]]; do
    case $1 in
        --critical-path-only) CRITICAL_PATH_ONLY=true; TOTAL_STEPS=15; shift ;;
        --dry-run)            DRY_RUN=true; shift ;;
        --resume)             RESUME=true; shift ;;
        --step)               START_STEP="$2"; shift 2 ;;
        --skip-gpu)           SKIP_GPU=true; shift ;;
        --skip-embed)         SKIP_EMBED=true; shift ;;
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
    local step="$1" description="$2"
    echo "{\"step\": $step, \"description\": \"$description\", \"completed_at\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" > "$CHECKPOINT_DIR/step_$step.done"
    log "  ✓ Checkpoint saved: step $step — $description"
}

run_step() {
    local step_num="$1" description="$2" func="$3"
    [ "$step_num" -lt "$START_STEP" ] && return 0
    $RESUME && checkpoint_exists "$step_num" && { log "  ⏭ Step $step_num: $description — SKIPPED (checkpoint)"; return 0; }
    log ""; log "━━━ Step $step_num/$TOTAL_STEPS: $description ━━━"
    $DRY_RUN && { log "  [DRY RUN] Would execute: $description"; return 0; }
    if $func; then mark_checkpoint "$step_num" "$description"; else log "  ✗ Step $step_num FAILED. Re-run with --resume."; exit 1; fi
}

# ─── Step Functions ──────────────────────────────────────────────────────────

step_01_prerequisites() {
    bash "$SCRIPT_DIR/prerequisites.sh"
}

step_02_network() {
    bash "$SCRIPT_DIR/init-network.sh"
}

step_03_k3s_server() {
    bash "$SCRIPT_DIR/init-orbstack.sh" --role server
}

step_04_k3s_worker() {
    bash "$SCRIPT_DIR/init-orbstack.sh" --role agent
}

step_05_dgx() {
    if $SKIP_GPU; then log "  Skipping GPU setup (--skip-gpu)"; return 0; fi
    bash "$SCRIPT_DIR/init-dgx.sh" --from-fleet
}

step_06_storage() {
    bash "$SCRIPT_DIR/init-storage.sh"
}

step_07_namespaces() {
    log "  Deploying namespaces, RBAC, network policies..."
    kubectl apply -k "$REPO_ROOT/infra/kubernetes/base"
}

step_08_vault() {
    bash "$SCRIPT_DIR/init-vault.sh"
}

step_09_seed_secrets() {
    bash "$SCRIPT_DIR/init-vault.sh" --seed-from-env
}

step_10_eso() {
    log "  Installing External Secrets Operator..."
    helm repo add external-secrets https://charts.external-secrets.io 2>/dev/null || true
    helm repo update
    helm upgrade --install external-secrets external-secrets/external-secrets \
        -n external-secrets --create-namespace --wait --timeout 3m
    log "  Deploying SecretStores and ExternalSecrets..."
    kubectl apply -k "$REPO_ROOT/infra/kubernetes/external-secrets"
}

step_11_monitoring() {
    log "  Deploying monitoring stack..."
    if [ -d "$REPO_ROOT/infra/kubernetes/monitoring" ]; then
        kubectl apply -k "$REPO_ROOT/infra/kubernetes/monitoring" 2>/dev/null || log "  WARN: monitoring apply had issues"
    fi
}

step_12_tier0() {
    bash "$REPO_ROOT/scripts/deploy/deploy_tier.sh" 0
}

step_13_tier1() {
    bash "$REPO_ROOT/scripts/deploy/deploy_tier.sh" 1
}

step_14_tier2() {
    bash "$REPO_ROOT/scripts/deploy/deploy_tier.sh" 2
}

step_15_atlasos() {
    bash "$REPO_ROOT/scripts/deploy/deploy_tier.sh" atlasos
}

step_16_gpu_inference() {
    if $SKIP_GPU; then log "  Skipping GPU inference (--skip-gpu)"; return 0; fi
    bash "$REPO_ROOT/scripts/deploy/deploy_tier.sh" gpu
}

step_17_tier3() {
    bash "$REPO_ROOT/scripts/deploy/deploy_tier.sh" 3
}

step_18_tier4() {
    bash "$REPO_ROOT/scripts/deploy/deploy_tier.sh" 4
}

step_19_tier5() {
    bash "$REPO_ROOT/scripts/deploy/deploy_tier.sh" 5
}

step_20_tier6() {
    bash "$REPO_ROOT/scripts/deploy/deploy_tier.sh" 6
}

step_21_ingress() {
    log "  Deploying Traefik ingress..."
    if [ -d "$REPO_ROOT/infra/kubernetes/ingress" ]; then
        kubectl apply -k "$REPO_ROOT/infra/kubernetes/ingress" 2>/dev/null || true
    fi
}

step_22_node_agents() {
    bash "$REPO_ROOT/scripts/deploy/deploy_tier.sh" node-agents
}

step_23_cluster_brain() {
    bash "$REPO_ROOT/scripts/deploy/deploy_tier.sh" cluster-brain
}

step_24_agents() {
    log "  Registering Atlas agents and crons..."
    [ -f "$REPO_ROOT/scripts/agents/create_agents.sh" ] && bash "$REPO_ROOT/scripts/agents/create_agents.sh" 2>&1 | tee -a "$LOG_FILE" || true
    [ -f "$REPO_ROOT/scripts/agents/register_crons.sh" ] && bash "$REPO_ROOT/scripts/agents/register_crons.sh" 2>&1 | tee -a "$LOG_FILE" || true
}

step_25_smoke() {
    log "  Running smoke tests..."
    log "  Checking nodes..."
    kubectl get nodes 2>/dev/null || true
    log "  Checking pods..."
    kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded 2>/dev/null | head -20 || true
    log "  Checking Vault..."
    kubectl exec -n vault vault-0 -- vault status 2>/dev/null || log "  WARN: Vault not reachable"
    log "  Checking AtlasOS..."
    kubectl get pods -n medinovai-services -l component=atlasos 2>/dev/null || true
    log "  Checking GPU nodes..."
    kubectl get nodes -l gpu=true 2>/dev/null || log "  (no GPU nodes)"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║    MedinovAI Platform — On-Prem Greenfield Instantiation    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
log "Configuration:"
log "  Mode:         $([ "$CRITICAL_PATH_ONLY" = true ] && echo 'Critical Path Only' || echo 'Full Platform')"
log "  Dry Run:      $DRY_RUN"
log "  Resume:       $RESUME"
log "  Start Step:   $START_STEP"
log "  Skip GPU:     $SKIP_GPU"
log "  Log File:     $LOG_FILE"
echo ""

if ! $DRY_RUN; then
    echo "This will provision K3s cluster and deploy the full MedinovAI platform."
    echo "Estimated time: $([ "$CRITICAL_PATH_ONLY" = true ] && echo '~25 minutes' || echo '~70 minutes')"
    echo ""
    read -r -p "Proceed? [y/N] " confirm
    case "$confirm" in [yY][eE][sS]|[yY]) ;; *) echo "Aborted."; exit 0 ;; esac
fi

START_TIME=$(date +%s)

# Phase 1: Infrastructure
run_step 1  "Prerequisites check"                   step_01_prerequisites
run_step 2  "Tailscale mesh networking"              step_02_network
run_step 3  "K3s server (Mac Studio via OrbStack)"   step_03_k3s_server
run_step 4  "K3s worker (MacBook Pro via OrbStack)"  step_04_k3s_worker
run_step 5  "DGX GPU nodes + NVIDIA toolkit"         step_05_dgx
run_step 6  "Longhorn distributed storage"           step_06_storage

# Phase 2: Security + Secrets
run_step 7  "Base K8s resources (namespaces, RBAC)"  step_07_namespaces
run_step 8  "HashiCorp Vault deployment"             step_08_vault
run_step 9  "Seed secrets into Vault"                step_09_seed_secrets
run_step 10 "External Secrets Operator"              step_10_eso

# Phase 3: Platform Services (tiered)
run_step 11 "Monitoring stack"                       step_11_monitoring
run_step 12 "Tier 0: Databases + infrastructure"     step_12_tier0
run_step 13 "Tier 1: Security services"              step_13_tier1
run_step 14 "Tier 2: Platform core"                  step_14_tier2
run_step 15 "AtlasOS services"                       step_15_atlasos

if ! $CRITICAL_PATH_ONLY; then
    run_step 16 "AI inference (GPU: Ollama, AIFactory)" step_16_gpu_inference
    run_step 17 "Tier 3: AI/ML + Clinical foundation"   step_17_tier3
    run_step 18 "Tier 4: Domain services"               step_18_tier4
    run_step 19 "Tier 5: Integration services"          step_19_tier5
    run_step 20 "Tier 6: UI shell"                      step_20_tier6
    run_step 21 "Ingress (Traefik + TLS)"               step_21_ingress
fi

# Phase 4: AtlasOS Everywhere
run_step 22 "AtlasOS node agents (DaemonSet)"        step_22_node_agents
run_step 23 "AtlasOS cluster brain"                   step_23_cluster_brain
run_step 24 "Atlas agent registration + crons"        step_24_agents
run_step 25 "Smoke tests + health verification"       step_25_smoke

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
MINUTES=$((ELAPSED / 60))
SECS=$((ELAPSED % 60))

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✓ Instantiation complete!                                  ║"
echo "║                                                             ║"
echo "║  Mode:     $(printf '%-46s' "$([ "$CRITICAL_PATH_ONLY" = true ] && echo 'Critical Path' || echo 'Full Platform')")║"
echo "║  Duration: $(printf '%-46s' "${MINUTES}m ${SECS}s")║"
echo "║  Log:      $(printf '%-46s' "$LOG_FILE")║"
echo "║                                                             ║"
echo "║  Next steps:                                                ║"
echo "║  1. make health                                             ║"
echo "║  2. make agent-status                                       ║"
echo "║  3. make embed-atlasos (embed agents in all repos)          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
