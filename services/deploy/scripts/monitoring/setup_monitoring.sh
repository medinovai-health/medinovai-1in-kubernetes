#!/usr/bin/env bash
# ─── setup_monitoring.sh ──────────────────────────────────────────────────────
# Deploy the monitoring stack (Prometheus, Grafana, Alertmanager, Loki).
#
# Usage:
#   bash scripts/monitoring/setup_monitoring.sh --environment staging
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
ENVIRONMENT="staging"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --environment)  ENVIRONMENT="$2"; shift 2 ;;
        --dry-run)      DRY_RUN=true; shift ;;
        *)              echo "Unknown option: $1"; exit 1 ;;
    esac
done

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Deploy Monitoring Stack — $ENVIRONMENT"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

MONITORING_DIR="$REPO_ROOT/infra/kubernetes/monitoring"

if $DRY_RUN; then
    echo "[DRY RUN] Would deploy:"
fi

apply_manifest() {
    local name="$1"
    local file="$2"
    local resource_type="${3:-deployment}"
    local resource_name="${4:-$name}"

    echo ""
    echo "▸ Deploying $name..."

    if [ ! -f "$file" ]; then
        echo "  ⚠ Manifest not found: $file — skipping"
        return 0
    fi

    if $DRY_RUN; then
        echo "  [DRY RUN] kubectl apply -f $file"
        return 0
    fi

    kubectl apply -f "$file" 2>&1 | while read -r line; do echo "  $line"; done

    echo "  Waiting for $resource_type/$resource_name..."
    kubectl rollout status "$resource_type/$resource_name" \
        -n medinovai-monitoring --timeout=120s 2>/dev/null || \
        echo "  ⚠ Rollout status check timed out for $resource_name"
}

echo "▸ Step 1: Create monitoring namespace..."
if $DRY_RUN; then
    echo "  [DRY RUN] kubectl create namespace medinovai-monitoring"
else
    kubectl create namespace medinovai-monitoring --dry-run=client -o yaml | kubectl apply -f -
    echo "  ✓ Namespace ready"
fi

apply_manifest "Prometheus" "$MONITORING_DIR/prometheus.yaml" "statefulset" "prometheus"
apply_manifest "Grafana" "$MONITORING_DIR/grafana.yaml" "deployment" "grafana"
apply_manifest "Alertmanager" "$MONITORING_DIR/alertmanager.yaml" "deployment" "alertmanager"
apply_manifest "Loki" "$MONITORING_DIR/loki.yaml" "statefulset" "loki"

if [ -f "$MONITORING_DIR/alert-rules.yaml" ]; then
    echo ""
    echo "▸ Applying alert rules..."
    if $DRY_RUN; then
        echo "  [DRY RUN] kubectl apply -f $MONITORING_DIR/alert-rules.yaml"
    else
        kubectl apply -f "$MONITORING_DIR/alert-rules.yaml" 2>&1 | while read -r line; do echo "  $line"; done
    fi
fi

echo ""
echo "✓ Monitoring stack deployment complete."
echo "  Access Grafana: kubectl port-forward svc/grafana -n medinovai-monitoring 3000:3000"
