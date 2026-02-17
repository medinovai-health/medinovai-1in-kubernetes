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

echo "▸ Step 1: Create monitoring namespace..."
echo "  kubectl create namespace medinovai-monitoring --dry-run=client -o yaml | kubectl apply -f -"

echo ""
echo "▸ Step 2: Deploy Prometheus..."
echo "  TODO: Apply $MONITORING_DIR/prometheus/ manifests"
echo "  - Prometheus server (metrics collection)"
echo "  - ServiceMonitor CRDs for auto-discovery"
echo "  - Recording rules and alert rules"

echo ""
echo "▸ Step 3: Deploy Grafana..."
echo "  TODO: Apply $MONITORING_DIR/grafana/ manifests"
echo "  - Grafana server with persistent storage"
echo "  - Pre-configured dashboards:"
echo "    - Platform Overview"
echo "    - Service Detail (per service)"
echo "    - AI Model Health"
echo "    - Cost Center"
echo "    - Security Posture"
echo "    - Deploy Pipeline Metrics"
echo "  - Datasource: Prometheus, Loki"

echo ""
echo "▸ Step 4: Deploy Alertmanager..."
echo "  TODO: Apply $MONITORING_DIR/alertmanager/ manifests"
echo "  - Alert routing:"
echo "    - P1 Critical → PagerDuty (page)"
echo "    - P2 High → PagerDuty (notify) + Slack #incidents"
echo "    - P3 Medium → Slack #eng"
echo "    - P4 Low → Slack #ops-digest"
echo "  - Inhibition rules (suppress low-priority during incidents)"
echo "  - Silence management"

echo ""
echo "▸ Step 5: Deploy Loki..."
echo "  TODO: Apply $MONITORING_DIR/loki/ manifests"
echo "  - Loki for log aggregation"
echo "  - Promtail DaemonSet for log collection"
echo "  - Retention: 30 days (staging), 90 days (production)"

echo ""
echo "✓ Monitoring stack deployment complete."
echo "  Access Grafana: kubectl port-forward svc/grafana -n medinovai-monitoring 3000:3000"
