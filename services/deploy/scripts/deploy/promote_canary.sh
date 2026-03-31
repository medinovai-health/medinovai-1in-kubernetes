#!/usr/bin/env bash
# ─── promote_canary.sh ────────────────────────────────────────────────────────
# Promote a canary deployment to full rollout.
#
# Usage:
#   bash scripts/deploy/promote_canary.sh --service api-gateway --environment production
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SERVICE=""
ENVIRONMENT="production"

while [[ $# -gt 0 ]]; do
    case $1 in
        --service)      SERVICE="$2"; shift 2 ;;
        --environment)  ENVIRONMENT="$2"; shift 2 ;;
        *)              echo "Unknown option: $1"; exit 1 ;;
    esac
done

if [ -z "$SERVICE" ]; then
    echo "Error: --service is required"
    exit 1
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Promote Canary: $SERVICE → 100% in $ENVIRONMENT"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

NAMESPACE="${NAMESPACE:-medinovai-services}"

echo "▸ Checking canary health metrics..."

CANARY_EXISTS=$(kubectl get deployment "${SERVICE}-canary" -n "$NAMESPACE" -o name 2>/dev/null || echo "")
if [ -z "$CANARY_EXISTS" ]; then
    echo "  ✗ No canary deployment found for $SERVICE in $NAMESPACE"
    exit 1
fi

RESTARTS=$(kubectl get pods -l "app=$SERVICE,track=canary" -n "$NAMESPACE" \
    -o jsonpath='{.items[*].status.containerStatuses[0].restartCount}' 2>/dev/null || echo "0")
READY=$(kubectl get pods -l "app=$SERVICE,track=canary" -n "$NAMESPACE" \
    -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "")

echo "  Canary restart count: $RESTARTS"
echo "  Canary ready status: $READY"

if [[ "$RESTARTS" -gt 0 ]] 2>/dev/null; then
    echo "  ✗ Canary has restarts — promotion aborted"
    echo "  Run: bash scripts/deploy/rollback_service.sh --service $SERVICE --environment $ENVIRONMENT"
    exit 1
fi

if [[ "$READY" != *"True"* ]]; then
    echo "  ✗ Canary is not ready — promotion aborted"
    exit 1
fi
echo "  ✓ Canary health checks passed"

echo ""
echo "▸ Promoting canary to full rollout..."

STABLE_REPLICAS=$(kubectl get deployment "$SERVICE" -n "$NAMESPACE" \
    -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")
echo "  Scaling canary to $STABLE_REPLICAS replicas (matching stable)..."
kubectl scale deployment "${SERVICE}-canary" -n "$NAMESPACE" --replicas="$STABLE_REPLICAS"

echo "  Waiting for canary scale-up..."
kubectl rollout status "deployment/${SERVICE}-canary" -n "$NAMESPACE" --timeout=300s

echo "  Removing stable deployment..."
kubectl delete deployment "$SERVICE" -n "$NAMESPACE" 2>/dev/null || true

# Recreate the primary deployment from canary spec (without canary labels)
echo "  Recreating primary deployment from canary..."
kubectl get deployment "${SERVICE}-canary" -n "$NAMESPACE" -o json | \
    python3 -c "
import json, sys
d = json.load(sys.stdin)
d['metadata']['name'] = '${SERVICE}'
d['metadata'].pop('resourceVersion', None)
d['metadata'].pop('uid', None)
d['metadata'].pop('creationTimestamp', None)
d['metadata'].get('labels', {}).pop('track', None)
d['spec']['selector']['matchLabels'].pop('track', None)
d['spec']['template']['metadata'].get('labels', {}).pop('track', None)
json.dump(d, sys.stdout)
" | kubectl apply -f - -n "$NAMESPACE"

echo "  Removing canary deployment..."
kubectl delete deployment "${SERVICE}-canary" -n "$NAMESPACE" 2>/dev/null || true

echo ""
echo "▸ Post-promotion health check..."
kubectl rollout status "deployment/$SERVICE" -n "$NAMESPACE" --timeout=120s && \
    echo "  ✓ All replicas healthy" || \
    echo "  ⚠ Rollout status check returned non-zero"

READY_COUNT=$(kubectl get deployment "$SERVICE" -n "$NAMESPACE" \
    -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
DESIRED_COUNT=$(kubectl get deployment "$SERVICE" -n "$NAMESPACE" \
    -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "?")
echo "  Ready replicas: $READY_COUNT / $DESIRED_COUNT"

echo ""
echo "✓ Canary promotion of $SERVICE in $ENVIRONMENT complete."
