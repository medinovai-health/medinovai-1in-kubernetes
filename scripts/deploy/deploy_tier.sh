#!/usr/bin/env bash
# ─── deploy_tier.sh ───────────────────────────────────────────────────────────
# Deploy a specific tier of MedinovAI services to the K3s cluster.
#
# Usage:
#   bash scripts/deploy/deploy_tier.sh 0          # Tier 0: infrastructure
#   bash scripts/deploy/deploy_tier.sh 1          # Tier 1: security
#   bash scripts/deploy/deploy_tier.sh atlasos    # AtlasOS services
#   bash scripts/deploy/deploy_tier.sh gpu        # GPU inference services
#   bash scripts/deploy/deploy_tier.sh all        # All tiers in order
#   bash scripts/deploy/deploy_tier.sh 4 --dry-run
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
DEPLOY_HOME="${DEPLOY_HOME:-$HOME/.medinovai-deploy}"
KUBECONFIG="${KUBECONFIG:-$DEPLOY_HOME/kubeconfig.yaml}"
export KUBECONFIG

TIER="${1:-}"
DRY_RUN=false
WAIT_TIMEOUT="120s"

shift || true
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)        DRY_RUN=true; shift ;;
        --wait-timeout)   WAIT_TIMEOUT="$2"; shift 2 ;;
        *)                shift ;;
    esac
done

if [ -z "$TIER" ]; then
    echo "Usage: deploy_tier.sh <tier>"
    echo "  Tiers: 0, 1, 2, 3, 4, 5, 6, atlasos, gpu, agents, all"
    exit 1
fi

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $1"; }

K8S_SERVICES="$REPO_ROOT/infra/kubernetes/services"

deploy_kustomize() {
    local dir="$1"
    local label="$2"

    if [ ! -d "$dir" ]; then
        log "  SKIP: $dir does not exist yet"
        return 0
    fi

    if $DRY_RUN; then
        log "  [DRY RUN] kubectl apply -k $dir"
        kubectl apply -k "$dir" --dry-run=client 2>/dev/null || true
    else
        log "  Deploying: $label"
        kubectl apply -k "$dir"
    fi
}

health_check_namespace() {
    local ns="$1"
    local ready
    ready=$(kubectl get pods -n "$ns" --no-headers 2>/dev/null | grep -c "Running" || echo "0")
    local total
    total=$(kubectl get pods -n "$ns" --no-headers 2>/dev/null | wc -l | xargs || echo "0")
    log "  Health: $ns — $ready/$total pods running"
}

deploy_tier() {
    local tier="$1"
    log "Deploying tier: $tier"

    case "$tier" in
        0)
            deploy_kustomize "$K8S_SERVICES/tier0" "Tier 0: Databases + Infrastructure"
            kubectl wait --for=condition=ready pod -l app=postgres-primary -n infra --timeout="$WAIT_TIMEOUT" 2>/dev/null || true
            health_check_namespace "infra"
            ;;
        1)
            deploy_kustomize "$K8S_SERVICES/tier1" "Tier 1: Security Services"
            health_check_namespace "security"
            ;;
        2)
            deploy_kustomize "$K8S_SERVICES/tier2" "Tier 2: Platform Core"
            health_check_namespace "platform"
            ;;
        atlasos)
            deploy_kustomize "$K8S_SERVICES/atlasos" "AtlasOS Services"
            health_check_namespace "atlasos"
            ;;
        3)
            deploy_kustomize "$K8S_SERVICES/tier3" "Tier 3: AI/ML + Clinical Foundation"
            health_check_namespace "ai-ml"
            ;;
        gpu)
            deploy_kustomize "$K8S_SERVICES/tier3" "GPU Inference Services"
            health_check_namespace "ai-ml"
            ;;
        4)
            deploy_kustomize "$K8S_SERVICES/tier4" "Tier 4: Domain Services"
            health_check_namespace "clinical"
            health_check_namespace "business"
            ;;
        5)
            deploy_kustomize "$K8S_SERVICES/tier5" "Tier 5: Integration Services"
            health_check_namespace "integrations"
            ;;
        6)
            deploy_kustomize "$K8S_SERVICES/tier6" "Tier 6: UI Shell"
            health_check_namespace "ui"
            ;;
        agents)
            deploy_kustomize "$K8S_SERVICES/atlasos-node-agent" "AtlasOS Node Agents"
            deploy_kustomize "$K8S_SERVICES/atlasos-cluster-brain" "AtlasOS Cluster Brain"
            health_check_namespace "atlasos"
            ;;
        all)
            for t in 0 1 2 atlasos 3 gpu 4 5 6 agents; do
                deploy_tier "$t"
                echo ""
            done
            ;;
        *)
            log "ERROR: Unknown tier '$tier'"
            exit 1
            ;;
    esac

    log "✓ Tier $tier deployment complete"
}

deploy_tier "$TIER"
