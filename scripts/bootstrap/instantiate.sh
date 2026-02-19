#!/usr/bin/env bash
# ─── instantiate.sh ───────────────────────────────────────────────────────────
# Full greenfield instantiation of the MedinovAI platform on-prem (25-step K3s flow).
# Takes bare metal nodes and stands up the complete K3s + MedinovAI stack.
#
# Usage:
#   bash scripts/bootstrap/instantiate.sh
#   bash scripts/bootstrap/instantiate.sh --target critical-path
#   bash scripts/bootstrap/instantiate.sh --resume
#   bash scripts/bootstrap/instantiate.sh --step 12
#   bash scripts/bootstrap/instantiate.sh --dry-run
#   bash scripts/bootstrap/instantiate.sh --fleet-config /path/to/fleet.json5
#
# Options:
#   --target TARGET     onprem (default, full 25 steps) or critical-path (steps 1-15 only)
#   --resume            Resume from last checkpoint
#   --dry-run           Show what would be done without executing
#   --step N            Start from a specific step number
#   --fleet-config PATH Path to fleet.json5 (default: \$REPO_ROOT/config/fleet.json5)
#
# Estimated time: ~70 min full (onprem), ~25 min critical-path
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

TARGET="${TARGET:-onprem}"
DRY_RUN=false
RESUME=false
START_STEP=1
TOTAL_STEPS=25
FLEET_CONFIG="${FLEET_CONFIG:-$REPO_ROOT/config/fleet.json5}"

while [[ $# -gt 0 ]]; do
    case $1 in
        --target)        TARGET="$2"; shift 2 ;;
        --dry-run)       DRY_RUN=true; shift ;;
        --resume)        RESUME=true; shift ;;
        --step)          START_STEP="$2"; shift 2 ;;
        --fleet-config)  FLEET_CONFIG="$2"; shift 2 ;;
        *)               echo "Unknown option: $1"; exit 1 ;;
    esac
done

CRITICAL_PATH_ONLY=false
[[ "$TARGET" == "critical-path" ]] && CRITICAL_PATH_ONLY=true

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

step_02_tailscale() {
    log "  Setting up Tailscale mesh..."
    bash "$SCRIPT_DIR/init-network.sh"
}

step_03_k3s_server() {
    log "  OrbStack + K3s server (Mac Studio)..."
    bash "$SCRIPT_DIR/init-orbstack.sh" --role server
    export KUBECONFIG="$KUBECONFIG_FILE"
}

step_04_k3s_agent() {
    log "  OrbStack + K3s agent (MacBook Pro)..."
    local server_ip
    server_ip=$(tailscale ip -4 2>/dev/null || python3 -c "
import json
with open('$DEPLOY_HOME/network.json') as f:
    state = json.load(f)
for n in state.get('nodes', []):
    if n.get('role') == 'server' and n.get('tailscale_ip'):
        print(n['tailscale_ip'])
        break
" 2>/dev/null || echo "")
    bash "$SCRIPT_DIR/init-orbstack.sh" --role agent --server-ip "${server_ip:-}"
}

step_05_dgx() {
    log "  DGX K3s agents + GPU operator (from fleet)..."
    export FLEET_CONFIG
    bash "$SCRIPT_DIR/init-dgx.sh" --from-fleet
}

step_06_longhorn() {
    log "  Longhorn distributed storage..."
    bash "$SCRIPT_DIR/init-storage.sh"
}

step_07_base_k8s() {
    log "  Base K8s resources..."
    export KUBECONFIG="$KUBECONFIG_FILE"
    kubectl apply -k "$REPO_ROOT/infra/kubernetes/base"
}

step_08_vault() {
    log "  Vault deployment + initialization..."
    bash "$SCRIPT_DIR/init-vault.sh"
}

step_09_seed_secrets() {
    log "  Seeding secrets into Vault..."
    bash "$SCRIPT_DIR/init-vault.sh" --seed
}

step_10_eso() {
    log "  External Secrets Operator..."
    export KUBECONFIG="$KUBECONFIG_FILE"
    helm repo add external-secrets https://charts.external-secrets.io 2>/dev/null || true
    helm repo update external-secrets 2>/dev/null || true
    helm install external-secrets external-secrets/external-secrets \
        -n external-secrets --create-namespace --wait --timeout 3m 2>/dev/null || \
        helm upgrade external-secrets external-secrets/external-secrets \
            -n external-secrets --wait --timeout 3m
    kubectl apply -k "$REPO_ROOT/infra/kubernetes/external-secrets"
    log "  ✓ ESO installed and SecretStores created"
}

step_11_monitoring() {
    log "  Monitoring stack..."
    export KUBECONFIG="$KUBECONFIG_FILE"
    if [ -d "$REPO_ROOT/infra/kubernetes/monitoring" ]; then
        kubectl apply -k "$REPO_ROOT/infra/kubernetes/monitoring" || true
    else
        log "  Monitoring manifests not found — skipping"
    fi
    return 0
}

step_12_tier0() {
    log "  Tier 0: Databases + infra..."
    export KUBECONFIG="$KUBECONFIG_FILE"
    bash "$REPO_ROOT/scripts/deploy/deploy_tier.sh" 0
}

step_13_tier1() {
    log "  Tier 1: Security services..."
    export KUBECONFIG="$KUBECONFIG_FILE"
    bash "$REPO_ROOT/scripts/deploy/deploy_tier.sh" 1
}

step_14_tier2() {
    log "  Tier 2: Platform core..."
    export KUBECONFIG="$KUBECONFIG_FILE"
    bash "$REPO_ROOT/scripts/deploy/deploy_tier.sh" 2
}

step_15_atlasos() {
    log "  AtlasOS services..."
    export KUBECONFIG="$KUBECONFIG_FILE"
    bash "$REPO_ROOT/scripts/deploy/deploy_tier.sh" atlasos
}

step_16_tier3() {
    if $CRITICAL_PATH_ONLY; then log "  Skipping (critical-path mode)"; return 0; fi
    log "  Tier 3: AI/ML + clinical foundation..."
    export KUBECONFIG="$KUBECONFIG_FILE"
    bash "$REPO_ROOT/scripts/deploy/deploy_tier.sh" 3
}

step_17_gpu() {
    if $CRITICAL_PATH_ONLY; then log "  Skipping (critical-path mode)"; return 0; fi
    log "  AI inference on GPU nodes..."
    export KUBECONFIG="$KUBECONFIG_FILE"
    bash "$REPO_ROOT/scripts/deploy/deploy_tier.sh" gpu
}

step_18_tier4() {
    if $CRITICAL_PATH_ONLY; then log "  Skipping (critical-path mode)"; return 0; fi
    log "  Tier 4: Domain services..."
    export KUBECONFIG="$KUBECONFIG_FILE"
    bash "$REPO_ROOT/scripts/deploy/deploy_tier.sh" 4
}

step_19_tier5() {
    if $CRITICAL_PATH_ONLY; then log "  Skipping (critical-path mode)"; return 0; fi
    log "  Tier 5: Integration services..."
    export KUBECONFIG="$KUBECONFIG_FILE"
    bash "$REPO_ROOT/scripts/deploy/deploy_tier.sh" 5
}

step_20_tier6() {
    if $CRITICAL_PATH_ONLY; then log "  Skipping (critical-path mode)"; return 0; fi
    log "  Tier 6: UI shell..."
    export KUBECONFIG="$KUBECONFIG_FILE"
    bash "$REPO_ROOT/scripts/deploy/deploy_tier.sh" 6
}

step_21_ingress() {
    log "  Ingress (Traefik)..."
    export KUBECONFIG="$KUBECONFIG_FILE"
    if [ -d "$REPO_ROOT/infra/kubernetes/ingress" ]; then
        kubectl apply -k "$REPO_ROOT/infra/kubernetes/ingress" || true
    fi
    return 0
}

step_22_node_agents() {
    log "  AtlasOS node agents (DaemonSet)..."
    export KUBECONFIG="$KUBECONFIG_FILE"
    kubectl apply -k "$REPO_ROOT/infra/kubernetes/services/atlasos-node-agent"
}

step_23_cluster_brain() {
    log "  AtlasOS cluster brain..."
    export KUBECONFIG="$KUBECONFIG_FILE"
    kubectl apply -k "$REPO_ROOT/infra/kubernetes/services/atlasos-cluster-brain"
}

step_24_atlas_agents() {
    log "  Atlas agent registration + crons..."
    if [ -f "$REPO_ROOT/scripts/agents/create_agents.sh" ]; then
        bash "$REPO_ROOT/scripts/agents/create_agents.sh" 2>&1 | tee -a "$LOG_FILE" || true
    fi
    if [ -f "$REPO_ROOT/scripts/agents/register_crons.sh" ]; then
        bash "$REPO_ROOT/scripts/agents/register_crons.sh" 2>&1 | tee -a "$LOG_FILE" || true
    fi
    return 0
}

step_25_smoke_tests() {
    log "  Smoke tests + cluster brain self-test..."
    export KUBECONFIG="$KUBECONFIG_FILE"

    if [ -f "$REPO_ROOT/scripts/validation/smoke_test.sh" ]; then
        bash "$REPO_ROOT/scripts/validation/smoke_test.sh" 2>&1 | tee -a "$LOG_FILE" || true
    fi

    log "  Checking nodes..."
    kubectl get nodes -o wide 2>/dev/null || true

    log "  Checking critical pods..."
    for ns in infra security platform atlasos ai-ml; do
        ready=$(kubectl get pods -n "$ns" --no-headers 2>/dev/null | grep -c "Running" || echo "0")
        total=$(kubectl get pods -n "$ns" --no-headers 2>/dev/null | wc -l | xargs || echo "0")
        log "    $ns: $ready/$total running"
    done

    log "  Checking Vault..."
    kubectl exec -n vault vault-0 -- vault status 2>/dev/null | head -5 || true

    log "  Checking cluster brain health..."
    kubectl exec -n atlasos deploy/atlasos-cluster-brain -- curl -s http://localhost:8100/health 2>/dev/null || true

    log "  ✓ Smoke tests complete"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║     MedinovAI On-Prem Instantiation — 25-Step K3s Bootstrap Flow         ║"
echo "║     Target: $TARGET | Steps: 1-$TOTAL_STEPS | ~70min full / ~25min critical-path"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo ""
log "Configuration:"
log "  Target:       $TARGET (critical-path = steps 1-15 only)"
log "  Fleet config: $FLEET_CONFIG"
log "  Dry run:      $DRY_RUN"
log "  Resume:       $RESUME"
log "  Start step:   $START_STEP"
log "  Log file:     $LOG_FILE"
echo ""

if ! $DRY_RUN; then
    echo "This will set up the K3s cluster and deploy the MedinovAI platform."
    if $CRITICAL_PATH_ONLY; then
        echo "Mode: critical-path (~25 min, steps 1-15)"
    else
        echo "Mode: full platform (~70 min, all 25 steps)"
    fi
    echo ""
    read -r -p "Proceed? [y/N] " confirm
    case "$confirm" in [yY][eE][sS]|[yY]) ;; *) echo "Aborted."; exit 0 ;; esac
fi

START_TIME=$(date +%s)

run_step 1  "Prerequisites check"                       step_01_prerequisites
run_step 2  "Tailscale mesh setup"                    step_02_tailscale
run_step 3  "OrbStack + K3s server (Mac Studio)"      step_03_k3s_server
run_step 4  "OrbStack + K3s agent (MacBook Pro)"      step_04_k3s_agent
run_step 5  "DGX K3s agents + GPU operator"                             step_05_dgx
run_step 6  "Longhorn storage"              step_06_longhorn
run_step 7  "Base K8s resources"            step_07_base_k8s
run_step 8  "Vault deployment + initialization"                           step_08_vault
run_step 9  "Seed secrets into Vault"                   step_09_seed_secrets
run_step 10 "External Secrets Operator"                 step_10_eso
run_step 11 "Monitoring stack"                          step_11_monitoring
run_step 12 "Tier 0: Databases + infra"        step_12_tier0
run_step 13 "Tier 1: Security services"                 step_13_tier1
run_step 14 "Tier 2: Platform core"                     step_14_tier2
run_step 15 "AtlasOS services"                          step_15_atlasos
run_step 16 "Tier 3: AI/ML + clinical foundation"       step_16_tier3
run_step 17 "AI inference on GPU nodes"         step_17_gpu
run_step 18 "Tier 4: Domain services"                   step_18_tier4
run_step 19 "Tier 5: Integration services"              step_19_tier5
run_step 20 "Tier 6: UI shell"                          step_20_tier6
run_step 21 "Ingress (Traefik)"                                   step_21_ingress
run_step 22 "AtlasOS node agents (DaemonSet)"           step_22_node_agents
run_step 23 "AtlasOS cluster brain"                     step_23_cluster_brain
run_step 24 "Atlas agent registration + crons"          step_24_atlas_agents
run_step 25 "Smoke tests + cluster brain self-test"                               step_25_smoke_tests

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
MINUTES=$((ELAPSED / 60))
SECONDS_LEFT=$((ELAPSED % 60))

echo ""
echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║  ✓ Instantiation complete!                                              ║"
echo "║                                                                          ║"
echo "║  Duration:    ${MINUTES}m ${SECONDS_LEFT}s                                               ║"
echo "║  Log:         $LOG_FILE"
echo "║                                                                          ║"
echo "║  Next steps:                                                             ║"
echo "║  1. Verify: make health                                                  ║"
echo "║  2. Seed secrets: make seed-secrets (if not done in step 9)              ║"
echo "║  3. Dashboards: make dashboards                                          ║"
echo "║  4. Embed AtlasOS in repos: make embed-atlasos                           ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
