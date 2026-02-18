#!/usr/bin/env bash
# ─── install-k8s.sh ────────────────────────────────────────────────────────────
# Clean Kubernetes install of MedinovAI platform.
# Tailscale-aware: detects Tailscale IP, generates per-machine ConfigMap.
# Idempotent — safe to re-run on any machine.
#
# Usage:
#   bash scripts/bootstrap/install-k8s.sh
#   bash scripts/bootstrap/install-k8s.sh --context docker-desktop
#   bash scripts/bootstrap/install-k8s.sh --primary                    # this machine hosts postgres/redis
#   bash scripts/bootstrap/install-k8s.sh --db-host 100.x.x.x         # remote primary
#   bash scripts/bootstrap/install-k8s.sh --dry-run
#
# Multi-machine workflow:
#   Machine A (primary):  bash scripts/bootstrap/install-k8s.sh --primary
#   Machine B:            bash scripts/bootstrap/install-k8s.sh --db-host <machine-A-tailscale-ip>
#   Machine C:            bash scripts/bootstrap/install-k8s.sh --db-host <machine-A-tailscale-ip>
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
COMPOSE_FILE="$REPO_ROOT/infra/docker/docker-compose.dev.yml"
OVERLAY="$REPO_ROOT/infra/kubernetes/overlays/docker-desktop"
ENV_FILE="$REPO_ROOT/.env.tailscale"

CONTEXT="docker-desktop"
DRY_RUN=false
SKIP_INFRA=false
IS_PRIMARY=false
DB_HOST_OVERRIDE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --context)     CONTEXT="$2"; shift 2 ;;
        --dry-run)     DRY_RUN=true; shift ;;
        --skip-infra)  SKIP_INFRA=true; shift ;;
        --primary)     IS_PRIMARY=true; shift ;;
        --db-host)     DB_HOST_OVERRIDE="$2"; shift 2 ;;
        *)             echo "Unknown option: $1"; exit 1 ;;
    esac
done

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  MedinovAI — Kubernetes Clean Install (Tailscale-aware)"
echo "║  Context: $CONTEXT"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ─── 1. Tailscale configuration ──────────────────────────────────────────────
echo "▸ [1/7] Tailscale configuration..."
TS_ARGS=""
$IS_PRIMARY && TS_ARGS="--primary"
[ -n "$DB_HOST_OVERRIDE" ] && TS_ARGS="--db-host $DB_HOST_OVERRIDE"

if [ -f "$ENV_FILE" ] && [ -z "$TS_ARGS" ]; then
    echo "  ✓ Using existing $ENV_FILE"
    source "$ENV_FILE"
else
    if ! $DRY_RUN; then
        bash "$SCRIPT_DIR/tailscale-config.sh" $TS_ARGS
        source "$ENV_FILE"
    else
        echo "  [DRY RUN] Would run: tailscale-config.sh $TS_ARGS"
        TS_IP="100.x.x.x"
        TS_HOSTNAME="this-machine"
        DB_HOST="host.docker.internal"
    fi
fi
echo "  This machine: ${TS_HOSTNAME:-unknown} @ ${TS_IP:-unknown}"
echo "  DB host:      ${DB_HOST:-host.docker.internal}"

# ─── 2. Validate kubectl ─────────────────────────────────────────────────────
echo ""
echo "▸ [2/7] Validating kubectl..."
command -v kubectl &>/dev/null || { echo "  ✗ kubectl not found"; exit 1; }
kubectl config use-context "$CONTEXT" 2>/dev/null || {
    echo "  ✗ Context '$CONTEXT' not found"
    echo "  Available: $(kubectl config get-contexts -o name | tr '\n' ' ')"
    exit 1
}
kubectl cluster-info 2>/dev/null | head -1
echo "  ✓ kubectl connected to $CONTEXT"

# ─── 3. Docker Compose infra ─────────────────────────────────────────────────
if ! $SKIP_INFRA; then
    echo ""
    echo "▸ [3/7] Docker Compose infra..."
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "medinovai-postgres"; then
        echo "  ✓ Already running"
    else
        echo "  Starting infra..."
        if ! $DRY_RUN; then
            docker compose -f "$COMPOSE_FILE" up -d
            echo -n "  Waiting for postgres"
            for i in $(seq 1 30); do
                docker exec medinovai-postgres pg_isready -U medinovai -d medinovai 2>/dev/null && break || { echo -n "."; sleep 2; }
            done
            echo " ✓"
        else
            echo "  [DRY RUN] Would start Docker Compose infra"
        fi
    fi
else
    echo ""
    echo "▸ [3/7] Skipping infra (--skip-infra)"
fi

# ─── 4. Inject Tailscale-aware ConfigMap ─────────────────────────────────────
echo ""
echo "▸ [4/7] Injecting per-machine ConfigMap..."
LOCAL_CM="$OVERLAY/configmap-env-local.yaml"
LOCAL_CM_AI="$OVERLAY/configmap-env-ai-local.yaml"
if [ -f "$LOCAL_CM" ]; then
    echo "  ✓ Local ConfigMap exists (from tailscale-config.sh)"
    # Temporarily use local ConfigMaps in kustomization
    if ! $DRY_RUN; then
        kubectl apply -f "$LOCAL_CM" 2>/dev/null || true
        kubectl apply -f "$LOCAL_CM_AI" 2>/dev/null || true
        echo "  ✓ ConfigMaps applied"
    fi
else
    echo "  Using default ConfigMap (host.docker.internal)"
fi

# ─── 5. Apply K8s manifests ──────────────────────────────────────────────────
echo ""
echo "▸ [5/7] Applying Kubernetes manifests..."
if $DRY_RUN; then
    echo "  [DRY RUN] kubectl apply -k $OVERLAY"
    kubectl kustomize "$OVERLAY" | grep -E "^kind:|image:" | head -20
else
    kubectl apply -k "$OVERLAY" 2>&1
    echo "  ✓ Manifests applied"
    # Re-apply local ConfigMaps (kustomize may overwrite with defaults)
    [ -f "$LOCAL_CM" ] && kubectl apply -f "$LOCAL_CM" 2>/dev/null || true
    [ -f "$LOCAL_CM_AI" ] && kubectl apply -f "$LOCAL_CM_AI" 2>/dev/null || true
    # Restart pods to pick up new ConfigMap values
    kubectl rollout restart deployment -n medinovai-services 2>/dev/null || true
    kubectl rollout restart deployment -n medinovai-ai 2>/dev/null || true
fi

# ─── 6. Wait for pods ────────────────────────────────────────────────────────
echo ""
echo "▸ [6/7] Waiting for pods..."
if ! $DRY_RUN; then
    SERVICES="api-gateway auth-service clinical-engine data-pipeline notification-service"
    for svc in $SERVICES; do
        echo -n "  $svc: "
        kubectl rollout status deployment/"$svc" -n medinovai-services --timeout=90s 2>/dev/null && echo "✓" || echo "⚠"
    done
    echo -n "  ai-inference: "
    kubectl rollout status deployment/ai-inference -n medinovai-ai --timeout=90s 2>/dev/null && echo "✓" || echo "⚠"
fi

# ─── 7. Summary ──────────────────────────────────────────────────────────────
echo ""
echo "▸ [7/7] Status:"
if ! $DRY_RUN; then
    kubectl get pods -n medinovai-services 2>/dev/null || true
    echo ""
    kubectl get pods -n medinovai-ai 2>/dev/null || true
fi

TS_IP_DISPLAY="${TS_IP:-<tailscale-ip>}"
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✓ Install complete"
echo "║"
echo "║  Tailscale IP:  $TS_IP_DISPLAY"
echo "║  DB host:       ${DB_HOST:-host.docker.internal}"
echo "║"
echo "║  Services reachable at:"
echo "║    http://$TS_IP_DISPLAY:30080  ← api-gateway (other machines)"
echo "║    http://$TS_IP_DISPLAY:30081  ← auth-service (other machines)"
echo "║    http://localhost:3000         ← Grafana"
echo "║    http://localhost:9090         ← Prometheus"
echo "║"
echo "║  On OTHER machines:"
echo "║    bash scripts/bootstrap/install-k8s.sh --db-host $TS_IP_DISPLAY"
echo "║"
echo "║  Uninstall: make k8s-uninstall"
echo "╚══════════════════════════════════════════════════════════════╝"
