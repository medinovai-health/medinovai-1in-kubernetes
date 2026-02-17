#!/usr/bin/env bash
# ─── deploy_all.sh ────────────────────────────────────────────────────────────
# Deploy all MedinovAI services in dependency order.
#
# Usage:
#   bash scripts/deploy/deploy_all.sh --environment staging
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
echo "║     Deploy All Services — $ENVIRONMENT"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

DEPLOY_ORDER=(
    "auth-service"
    "notification-service"
    "data-pipeline"
    "clinical-engine"
    "ai-inference"
    "api-gateway"
)

STRATEGY="rolling"
[ "$ENVIRONMENT" = "production" ] && STRATEGY="canary"

TOTAL=${#DEPLOY_ORDER[@]}
PASS=0
FAIL=0

for i in "${!DEPLOY_ORDER[@]}"; do
    service="${DEPLOY_ORDER[$i]}"
    step=$((i + 1))
    echo "━━━ [$step/$TOTAL] Deploying: $service ━━━"

    DRY_FLAG=""
    $DRY_RUN && DRY_FLAG="--dry-run"

    if bash "$SCRIPT_DIR/deploy_service.sh" \
        --service "$service" \
        --environment "$ENVIRONMENT" \
        --strategy "$STRATEGY" \
        $DRY_FLAG; then
        echo "  ✓ $service deployed successfully"
        PASS=$((PASS + 1))
    else
        echo "  ✗ $service deployment FAILED"
        FAIL=$((FAIL + 1))
        echo ""
        echo "Stopping deployment. $PASS/$TOTAL services deployed. $FAIL failed."
        echo "Fix the issue and re-run, or deploy remaining services individually."
        exit 1
    fi
    echo ""
done

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✓ All services deployed: $PASS/$TOTAL                     ║"
echo "║  Environment: $ENVIRONMENT                                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
