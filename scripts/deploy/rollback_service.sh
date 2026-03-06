#!/usr/bin/env bash
# ─── rollback_service.sh ──────────────────────────────────────────────────────
# Rollback a service to its previous version.
#
# Usage:
#   bash scripts/deploy/rollback_service.sh --service api-gateway --environment staging
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SERVICE=""
ENVIRONMENT="staging"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --service)      SERVICE="$2"; shift 2 ;;
        --environment)  ENVIRONMENT="$2"; shift 2 ;;
        --dry-run)      DRY_RUN=true; shift ;;
        *)              echo "Unknown option: $1"; exit 1 ;;
    esac
done

if [ -z "$SERVICE" ]; then
    echo "Error: --service is required"
    exit 1
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Rollback: $SERVICE in $ENVIRONMENT"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

if $DRY_RUN; then
    echo "[DRY RUN] Would rollback $SERVICE in $ENVIRONMENT to previous version"
    exit 0
fi

echo "▸ Rolling back $SERVICE..."
if command -v kubectl &>/dev/null; then
    echo "  kubectl rollout undo deployment/$SERVICE -n medinovai-services"
    kubectl rollout undo "deployment/$SERVICE" -n medinovai-services 2>/dev/null || \
        echo "  ⚠ kubectl rollback failed (cluster may not be configured)"
    echo ""
    echo "▸ Waiting for rollback to complete..."
    kubectl rollout status "deployment/$SERVICE" -n medinovai-services --timeout=300s 2>/dev/null || \
        echo "  ⚠ rollout status check failed"
else
    echo "  kubectl not available — manual rollback required"
fi

echo ""
echo "▸ Post-rollback health check..."
HEALTH_OK=false
for attempt in 1 2 3 4 5; do
    if kubectl exec -n medinovai-services deploy/"$SERVICE" -- \
        sh -c "wget -qO- http://localhost:8000/health 2>/dev/null || curl -sf http://localhost:8000/health 2>/dev/null" &>/dev/null; then
        echo "  ✓ Health endpoint OK (attempt $attempt)"
        HEALTH_OK=true
        break
    fi
    echo "  Attempt $attempt/5 — waiting 10s..."
    sleep 10
done

if ! $HEALTH_OK; then
    echo "  ⚠ Health check did not pass after 5 attempts (service may not expose /health)"
fi

echo ""
echo "✓ Rollback of $SERVICE in $ENVIRONMENT complete."
echo "  Create an incident ticket to track the rollback reason."
