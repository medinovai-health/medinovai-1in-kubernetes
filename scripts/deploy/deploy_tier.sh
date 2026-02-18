#!/usr/bin/env bash
# ─── deploy_tier.sh ───────────────────────────────────────────────────────────
# Deploy services by tier from the dependency graph.
#
# Usage:
#   bash scripts/deploy/deploy_tier.sh 0                    # Deploy Tier 0
#   bash scripts/deploy/deploy_tier.sh atlasos              # Deploy AtlasOS services
#   bash scripts/deploy/deploy_tier.sh gpu                  # Deploy GPU workloads
#   bash scripts/deploy/deploy_tier.sh all                  # Deploy all tiers
#   bash scripts/deploy/deploy_tier.sh 4 --parallel-jobs 4  # Parallel deploys
#   bash scripts/deploy/deploy_tier.sh 0 --dry-run          # Show what would deploy
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
DEPLOY_HOME="${DEPLOY_HOME:-$HOME/.medinovai-deploy}"
KUBECONFIG="${KUBECONFIG:-$DEPLOY_HOME/kubeconfig.yaml}"
K8S_DIR="$REPO_ROOT/infra/kubernetes/services"

TIER="${1:-}"
shift || true

DRY_RUN=false
PARALLEL_JOBS=4
WAIT_TIMEOUT=300

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)         DRY_RUN=true; shift ;;
        --parallel-jobs)   PARALLEL_JOBS="$2"; shift 2 ;;
        --wait-timeout)    WAIT_TIMEOUT="$2"; shift 2 ;;
        *)                 echo "Unknown option: $1"; exit 1 ;;
    esac
done

if [ -z "$TIER" ]; then
    echo "Usage: deploy_tier.sh <tier|atlasos|gpu|all> [--dry-run] [--parallel-jobs N]"
    exit 1
fi

export KUBECONFIG
log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $1"; }

deploy_kustomize() {
    local dir="$1"
    local name="$2"

    if [ ! -d "$dir" ]; then
        log "  SKIP $name — directory not found: $dir"
        return 0
    fi

    if $DRY_RUN; then
        log "  [DRY RUN] kubectl apply -k $dir"
        return 0
    fi

    log "  Deploying $name..."
    if kubectl apply -k "$dir" 2>&1; then
        log "  ✓ $name deployed"
    else
        log "  ✗ $name failed"
        return 1
    fi
}

wait_for_ready() {
    local namespace="$1"
    local label="$2"
    local timeout="${3:-$WAIT_TIMEOUT}"

    if $DRY_RUN; then return 0; fi

    log "  Waiting for pods ($label) in $namespace..."
    kubectl wait --for=condition=ready pod -l "$label" -n "$namespace" --timeout="${timeout}s" 2>/dev/null || true
}

case "$TIER" in
    0)
        log "━━━ Deploying Tier 0: Bare Infrastructure ━━━"
        deploy_kustomize "$K8S_DIR/tier0" "tier0-infrastructure"
        wait_for_ready medinovai-system "tier=0" 300
        wait_for_ready medinovai-data "tier=0" 300
        ;;
    1)
        log "━━━ Deploying Tier 1: Security Services (sequential) ━━━"
        # Tier 1 is sequential — services depend on each other
        for svc in secrets-manager-bridge medinovai-security universal-sign-on role-based-permissions; do
            if [ -d "$K8S_DIR/tier1/$svc.yaml" ] || [ -f "$K8S_DIR/tier1/$svc.yaml" ]; then
                if $DRY_RUN; then
                    log "  [DRY RUN] kubectl apply -f $K8S_DIR/tier1/$svc.yaml"
                else
                    kubectl apply -f "$K8S_DIR/tier1/$svc.yaml" 2>/dev/null && log "  ✓ $svc" || log "  ✗ $svc"
                fi
            fi
        done
        ;;
    2)
        log "━━━ Deploying Tier 2: Platform Core (sequential) ━━━"
        for svc_dir in "$K8S_DIR"/tier2/*.yaml; do
            [ -f "$svc_dir" ] || continue
            svc_name=$(basename "$svc_dir" .yaml)
            if $DRY_RUN; then
                log "  [DRY RUN] kubectl apply -f $svc_dir"
            else
                kubectl apply -f "$svc_dir" 2>/dev/null && log "  ✓ $svc_name" || log "  ✗ $svc_name"
            fi
        done
        ;;
    atlasos)
        log "━━━ Deploying AtlasOS Services ━━━"
        deploy_kustomize "$K8S_DIR/atlasos" "atlasos-services"
        wait_for_ready medinovai-services "component=atlasos" 300
        ;;
    gpu)
        log "━━━ Deploying GPU Workloads (AI Inference) ━━━"
        # Install NVIDIA GPU Operator if not present
        if ! kubectl get ns gpu-operator &>/dev/null && ! $DRY_RUN; then
            log "  Installing NVIDIA GPU Operator..."
            helm repo add nvidia https://helm.ngc.nvidia.com/nvidia 2>/dev/null || true
            helm repo update
            helm upgrade --install gpu-operator nvidia/gpu-operator \
                -n gpu-operator --create-namespace \
                --wait --timeout 5m 2>/dev/null || log "  WARN: GPU operator install issue"
        fi
        deploy_kustomize "$K8S_DIR/ai-inference" "ai-inference"
        wait_for_ready medinovai-ai "app=ollama" 300
        ;;
    3|4|5)
        log "━━━ Deploying Tier $TIER: Domain Services (parallel) ━━━"
        if [ -d "$K8S_DIR/tier$TIER" ]; then
            deploy_kustomize "$K8S_DIR/tier$TIER" "tier$TIER-services"
        else
            log "  No manifests found for tier $TIER"
        fi
        ;;
    6)
        log "━━━ Deploying Tier 6: UI Shell ━━━"
        if [ -d "$K8S_DIR/tier6" ]; then
            deploy_kustomize "$K8S_DIR/tier6" "tier6-ui"
        fi
        ;;
    node-agents)
        log "━━━ Deploying AtlasOS Node Agents (DaemonSet) ━━━"
        deploy_kustomize "$K8S_DIR/atlasos-node-agent" "node-agents"
        ;;
    cluster-brain)
        log "━━━ Deploying AtlasOS Cluster Brain ━━━"
        deploy_kustomize "$K8S_DIR/atlasos-cluster-brain" "cluster-brain"
        ;;
    all)
        log "━━━ Deploying ALL Tiers ━━━"
        for t in 0 1 2 atlasos gpu 3 4 5 6 node-agents cluster-brain; do
            bash "$0" "$t" ${DRY_RUN:+--dry-run}
            echo ""
        done
        ;;
    *)
        echo "Unknown tier: $TIER"
        echo "Valid: 0, 1, 2, 3, 4, 5, 6, atlasos, gpu, node-agents, cluster-brain, all"
        exit 1
        ;;
esac

log "Tier $TIER deployment complete."
