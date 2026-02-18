#!/usr/bin/env bash
# Deploy services by tier for the MedinovAI platform.
# Usage:
#   bash scripts/deploy/deploy_tier.sh 0          # Deploy Tier 0 (databases)
#   bash scripts/deploy/deploy_tier.sh 1          # Deploy Tier 1 (security)
#   bash scripts/deploy/deploy_tier.sh atlasos     # Deploy AtlasOS
#   bash scripts/deploy/deploy_tier.sh gpu         # Deploy GPU services
#   bash scripts/deploy/deploy_tier.sh all         # Deploy all tiers in order
#   bash scripts/deploy/deploy_tier.sh all --critical-path-only

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
K8S_DIR="$REPO_ROOT/infra/kubernetes"

TIER="${1:-}"
CRITICAL_PATH=false
DRY_RUN=false

shift || true
for arg in "$@"; do
    case "$arg" in
        --critical-path-only) CRITICAL_PATH=true ;;
        --dry-run)            DRY_RUN=true ;;
    esac
done

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $1"; }

deploy_kustomize() {
    local dir="$1"
    local name="$2"
    if [ ! -d "$dir" ]; then
        log "  SKIP: $dir does not exist"
        return 0
    fi
    if $DRY_RUN; then
        log "  [DRY RUN] kubectl apply -k $dir"
        return 0
    fi
    log "  Deploying $name..."
    kubectl apply -k "$dir" 2>&1 | while read -r line; do
        log "    $line"
    done
}

wait_for_pods() {
    local namespace="$1"
    local timeout="${2:-120}"
    log "  Waiting for pods in $namespace to be ready (${timeout}s timeout)..."
    kubectl wait --for=condition=Ready pods --all -n "$namespace" --timeout="${timeout}s" 2>/dev/null || \
        log "  WARNING: Some pods in $namespace are not ready yet"
}

deploy_tier_0() {
    log "━━━ Tier 0: Bare Infrastructure ━━━"
    deploy_kustomize "$K8S_DIR/base" "base resources (namespaces, RBAC, network policies)"
    deploy_kustomize "$K8S_DIR/services/tier0" "databases (PostgreSQL, Redis, MinIO)"
    wait_for_pods "medinovai-data" 180
}

deploy_tier_1() {
    log "━━━ Tier 1: Security Foundation ━━━"
    deploy_kustomize "$K8S_DIR/services/tier1" "security services"
    wait_for_pods "medinovai-security" 120
}

deploy_tier_2() {
    log "━━━ Tier 2: Platform Core ━━━"
    deploy_kustomize "$K8S_DIR/services/tier2" "platform core services"
    wait_for_pods "medinovai-services" 120
}

deploy_atlasos() {
    log "━━━ AtlasOS Services ━━━"
    deploy_kustomize "$K8S_DIR/services/atlasos" "AtlasOS services"
    wait_for_pods "medinovai-services" 120
}

deploy_gpu() {
    log "━━━ GPU / AI Inference ━━━"
    deploy_kustomize "$K8S_DIR/services/tier3" "AI/ML services (Ollama, AIFactory)"
    wait_for_pods "medinovai-ai" 180
}

deploy_tier_4() {
    log "━━━ Tier 4: Domain Services ━━━"
    deploy_kustomize "$K8S_DIR/services/tier4" "domain services"
}

deploy_tier_5() {
    log "━━━ Tier 5: Integration Services ━━━"
    deploy_kustomize "$K8S_DIR/services/tier5" "integration services"
}

deploy_tier_6() {
    log "━━━ Tier 6: UI Shell ━━━"
    deploy_kustomize "$K8S_DIR/services/tier6" "UI shell (medinovaios)"
}

deploy_atlasos_infra() {
    log "━━━ AtlasOS Infrastructure Agents ━━━"
    deploy_kustomize "$K8S_DIR/services/atlasos-node-agent" "AtlasOS node agents (DaemonSet)"
    deploy_kustomize "$K8S_DIR/services/atlasos-cluster-brain" "AtlasOS cluster brain"
    deploy_kustomize "$K8S_DIR/services/atlasos-sidecar" "AtlasOS sidecar config"
}

case "$TIER" in
    0)       deploy_tier_0 ;;
    1)       deploy_tier_1 ;;
    2)       deploy_tier_2 ;;
    3|gpu)   deploy_gpu ;;
    4)       deploy_tier_4 ;;
    5)       deploy_tier_5 ;;
    6)       deploy_tier_6 ;;
    atlasos) deploy_atlasos ;;
    agents)  deploy_atlasos_infra ;;
    all)
        if $CRITICAL_PATH; then
            log "Deploying critical path only (12 services)..."
            deploy_tier_0
            deploy_tier_1
            deploy_tier_2
            deploy_atlasos
            log "Critical path deployment complete."
        else
            log "Deploying all tiers..."
            deploy_tier_0
            deploy_tier_1
            deploy_tier_2
            deploy_atlasos
            deploy_gpu
            deploy_tier_4
            deploy_tier_5
            deploy_tier_6
            deploy_atlasos_infra
            log "Full platform deployment complete."
        fi
        ;;
    *)
        echo "Usage: $0 <tier> [--dry-run] [--critical-path-only]"
        echo "  Tiers: 0, 1, 2, 3, 4, 5, 6, atlasos, gpu, agents, all"
        exit 1
        ;;
esac
