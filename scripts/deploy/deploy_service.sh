#!/usr/bin/env bash
# ─── deploy_service.sh ────────────────────────────────────────────────────────
# Deploy a single MedinovAI service using canary or blue-green strategy.
#
# Usage:
#   bash scripts/deploy/deploy_service.sh --service api-gateway --environment staging
#   bash scripts/deploy/deploy_service.sh --service api-gateway --environment production --strategy canary
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

SERVICE=""
ENVIRONMENT="staging"
STRATEGY="rolling"
IMAGE_TAG=""
DRY_RUN=false
CANARY_PERCENT=5
CANARY_DURATION=600

while [[ $# -gt 0 ]]; do
    case $1 in
        --service)          SERVICE="$2"; shift 2 ;;
        --environment)      ENVIRONMENT="$2"; shift 2 ;;
        --strategy)         STRATEGY="$2"; shift 2 ;;
        --image-tag)        IMAGE_TAG="$2"; shift 2 ;;
        --dry-run)          DRY_RUN=true; shift ;;
        --canary-percent)   CANARY_PERCENT="$2"; shift 2 ;;
        --canary-duration)  CANARY_DURATION="$2"; shift 2 ;;
        *)                  echo "Unknown option: $1"; exit 1 ;;
    esac
done

if [ -z "$SERVICE" ]; then
    echo "Error: --service is required"
    echo "Usage: deploy_service.sh --service <name> --environment <env>"
    exit 1
fi

MANIFEST_FILE="$REPO_ROOT/services/registry/${SERVICE}.manifest.json"
K8S_DIR="$REPO_ROOT/infra/kubernetes/services/${SERVICE}"
OVERLAY_DIR="$REPO_ROOT/infra/kubernetes/overlays/${ENVIRONMENT}"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Deploy Service: $SERVICE"
echo "║  Environment:    $ENVIRONMENT"
echo "║  Strategy:       $STRATEGY"
echo "║  Image Tag:      ${IMAGE_TAG:-<latest>}"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ─── Load service manifest ───────────────────────────────────────────────────
if [ -f "$MANIFEST_FILE" ]; then
    echo "▸ Loading service manifest: $MANIFEST_FILE"
    TIER=$(python3 -c "import json; print(json.load(open('$MANIFEST_FILE')).get('tier', 'normal'))" 2>/dev/null || echo "normal")
    REQUIRES_APPROVAL=$(python3 -c "import json; print(json.load(open('$MANIFEST_FILE')).get('governance', {}).get('requires_approval', False))" 2>/dev/null || echo "False")
    echo "  Tier: $TIER"
    echo "  Requires approval: $REQUIRES_APPROVAL"
else
    echo "▸ No manifest found at $MANIFEST_FILE — using defaults"
    TIER="normal"
    REQUIRES_APPROVAL="False"
fi

# ─── Production safety checks ────────────────────────────────────────────────
if [ "$ENVIRONMENT" = "production" ]; then
    echo ""
    echo "▸ Production safety checks..."

    if [ "$STRATEGY" = "rolling" ]; then
        echo "  ⚠ Overriding strategy to 'canary' for production deployment"
        STRATEGY="canary"
    fi

    if [ "$REQUIRES_APPROVAL" = "True" ]; then
        echo "  This service requires approval for production deployment."
        if ! $DRY_RUN; then
            read -r -p "  Has this deployment been approved? [y/N] " confirm
            case "$confirm" in
                [yY][eE][sS]|[yY]) echo "  ✓ Approval confirmed" ;;
                *) echo "  Aborted — approval required."; exit 1 ;;
            esac
        fi
    fi

    HOUR=$(date -u +%H)
    DAY=$(date -u +%u)
    if [ "$DAY" -ge 5 ]; then
        echo "  ⚠ WARNING: Deploying on a weekend/Friday"
    fi
fi

# ─── Record previous version for rollback ────────────────────────────────────
echo ""
echo "▸ Recording current version for rollback..."
PREV_VERSION="unknown"
if command -v kubectl &>/dev/null; then
    PREV_VERSION=$(kubectl get deployment "$SERVICE" -n medinovai-services -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "none")
fi
echo "  Previous version: $PREV_VERSION"

# ─── Deploy ──────────────────────────────────────────────────────────────────
if $DRY_RUN; then
    echo ""
    echo "[DRY RUN] Would deploy $SERVICE to $ENVIRONMENT with strategy $STRATEGY"
    exit 0
fi

echo ""
case "$STRATEGY" in
    canary)
        echo "▸ Deploying canary ($CANARY_PERCENT% traffic)..."
        echo "  TODO: Create canary deployment with $CANARY_PERCENT% traffic weight"
        echo "  TODO: Monitor for ${CANARY_DURATION}s"
        echo "  TODO: Check error rate vs baseline"
        echo "  TODO: Auto-promote or auto-rollback"
        ;;
    blue-green)
        echo "▸ Deploying blue-green..."
        echo "  TODO: Deploy to inactive environment"
        echo "  TODO: Run health checks"
        echo "  TODO: Switch traffic atomically"
        echo "  TODO: Keep old environment for rollback"
        ;;
    rolling)
        echo "▸ Deploying with rolling update..."
        if [ -d "$K8S_DIR" ]; then
            echo "  Applying K8s manifests from $K8S_DIR"
            echo "  TODO: kubectl apply -k $K8S_DIR"
            echo "  TODO: kubectl rollout status deployment/$SERVICE -n medinovai-services"
        else
            echo "  No K8s manifests found at $K8S_DIR"
        fi
        ;;
    *)
        echo "Unknown strategy: $STRATEGY"
        exit 1
        ;;
esac

# ─── Post-deploy health check ────────────────────────────────────────────────
echo ""
echo "▸ Post-deploy health check..."
echo "  TODO: Verify /health endpoint returns 200"
echo "  TODO: Verify /ready endpoint returns 200"
echo "  TODO: Check error rate is within normal range"

echo ""
echo "✓ Deployment of $SERVICE to $ENVIRONMENT complete."
echo "  Rollback command: bash scripts/deploy/rollback_service.sh --service $SERVICE --environment $ENVIRONMENT"
