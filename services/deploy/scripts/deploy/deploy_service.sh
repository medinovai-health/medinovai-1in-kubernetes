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

NAMESPACE="${NAMESPACE:-medinovai-services}"
DEPLOY_OUTCOME="failure"

echo ""
case "$STRATEGY" in
    canary)
        echo "▸ Deploying canary ($CANARY_PERCENT% traffic)..."

        if [ ! -d "$K8S_DIR" ]; then
            echo "  ✗ No K8s manifests found at $K8S_DIR"
            exit 1
        fi

        # Create canary deployment as a copy with track=canary label and 1 replica
        echo "  Creating canary deployment: ${SERVICE}-canary"
        kubectl get deployment "$SERVICE" -n "$NAMESPACE" -o json 2>/dev/null | \
            python3 -c "
import json, sys
d = json.load(sys.stdin)
d['metadata']['name'] = '${SERVICE}-canary'
d['metadata'].pop('resourceVersion', None)
d['metadata'].pop('uid', None)
d['metadata'].pop('creationTimestamp', None)
d['metadata'].setdefault('labels', {})['track'] = 'canary'
d['spec']['replicas'] = 1
d['spec']['selector']['matchLabels']['track'] = 'canary'
d['spec']['template']['metadata'].setdefault('labels', {})['track'] = 'canary'
json.dump(d, sys.stdout)
" | kubectl apply -f - -n "$NAMESPACE"

        echo "  Waiting for canary readiness..."
        if ! kubectl rollout status "deployment/${SERVICE}-canary" -n "$NAMESPACE" --timeout=300s; then
            echo "  ✗ Canary deployment failed to become ready"
            kubectl delete deployment "${SERVICE}-canary" -n "$NAMESPACE" 2>/dev/null || true
            exit 1
        fi

        echo "  Monitoring canary for ${CANARY_DURATION}s..."
        ELAPSED=0
        MONITOR_INTERVAL=30
        while [[ $ELAPSED -lt $CANARY_DURATION ]]; do
            RESTARTS=$(kubectl get pods -l "app=$SERVICE,track=canary" -n "$NAMESPACE" \
                -o jsonpath='{.items[*].status.containerStatuses[0].restartCount}' 2>/dev/null || echo "0")
            READY=$(kubectl get pods -l "app=$SERVICE,track=canary" -n "$NAMESPACE" \
                -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "False")

            if [[ "$RESTARTS" -gt 0 ]] 2>/dev/null; then
                echo "  ✗ Canary pod restarted ($RESTARTS times) — aborting"
                kubectl delete deployment "${SERVICE}-canary" -n "$NAMESPACE" 2>/dev/null || true
                exit 1
            fi
            if [[ "$READY" != *"True"* ]]; then
                echo "  ✗ Canary pod not ready — aborting"
                kubectl delete deployment "${SERVICE}-canary" -n "$NAMESPACE" 2>/dev/null || true
                exit 1
            fi

            sleep "$MONITOR_INTERVAL"
            ELAPSED=$((ELAPSED + MONITOR_INTERVAL))
            echo "  [$ELAPSED/${CANARY_DURATION}s] Canary healthy (restarts: $RESTARTS)"
        done

        echo "  ✓ Canary passed monitoring window"
        echo "  Run: bash scripts/deploy/promote_canary.sh --service $SERVICE --environment $ENVIRONMENT"
        DEPLOY_OUTCOME="success"
        ;;

    blue-green)
        echo "▸ Deploying blue-green..."

        if [ ! -d "$K8S_DIR" ]; then
            echo "  ✗ No K8s manifests found at $K8S_DIR"
            exit 1
        fi

        # Deploy green alongside existing (blue)
        echo "  Deploying green version: ${SERVICE}-green"
        kubectl get deployment "$SERVICE" -n "$NAMESPACE" -o json 2>/dev/null | \
            python3 -c "
import json, sys
d = json.load(sys.stdin)
d['metadata']['name'] = '${SERVICE}-green'
d['metadata'].pop('resourceVersion', None)
d['metadata'].pop('uid', None)
d['metadata'].pop('creationTimestamp', None)
d['metadata'].setdefault('labels', {})['slot'] = 'green'
d['spec']['selector']['matchLabels']['slot'] = 'green'
d['spec']['template']['metadata'].setdefault('labels', {})['slot'] = 'green'
json.dump(d, sys.stdout)
" | kubectl apply -f - -n "$NAMESPACE"

        echo "  Waiting for green deployment readiness..."
        if ! kubectl rollout status "deployment/${SERVICE}-green" -n "$NAMESPACE" --timeout=300s; then
            echo "  ✗ Green deployment failed — cleaning up"
            kubectl delete deployment "${SERVICE}-green" -n "$NAMESPACE" 2>/dev/null || true
            exit 1
        fi

        # Switch Service selector to green
        echo "  Switching Service selector to green..."
        kubectl patch service "$SERVICE" -n "$NAMESPACE" \
            -p '{"spec":{"selector":{"slot":"green"}}}' 2>/dev/null || \
            echo "  ⚠ Service patch skipped (service may not exist)"

        echo "  Removing old (blue) deployment..."
        kubectl delete deployment "$SERVICE" -n "$NAMESPACE" 2>/dev/null || true

        # Rename green to primary
        echo "  Promoting green to primary name..."
        kubectl get deployment "${SERVICE}-green" -n "$NAMESPACE" -o json | \
            python3 -c "
import json, sys
d = json.load(sys.stdin)
d['metadata']['name'] = '${SERVICE}'
d['metadata'].pop('resourceVersion', None)
d['metadata'].pop('uid', None)
d['metadata'].pop('creationTimestamp', None)
json.dump(d, sys.stdout)
" | kubectl apply -f - -n "$NAMESPACE"
        kubectl delete deployment "${SERVICE}-green" -n "$NAMESPACE" 2>/dev/null || true

        DEPLOY_OUTCOME="success"
        ;;

    rolling)
        echo "▸ Deploying with rolling update..."
        if [ -d "$K8S_DIR" ]; then
            echo "  Applying K8s manifests from $K8S_DIR"

            if [ -d "$OVERLAY_DIR" ] && [ -f "$OVERLAY_DIR/kustomization.yaml" ]; then
                kubectl apply -k "$OVERLAY_DIR" 2>&1
            else
                kubectl apply -k "$K8S_DIR" 2>&1
            fi

            echo "  Waiting for rollout to complete..."
            if kubectl rollout status "deployment/$SERVICE" -n "$NAMESPACE" --timeout=300s; then
                DEPLOY_OUTCOME="success"
            else
                echo "  ✗ Rolling update failed — triggering rollback"
                kubectl rollout undo "deployment/$SERVICE" -n "$NAMESPACE" 2>/dev/null || true
                exit 1
            fi
        else
            echo "  ✗ No K8s manifests found at $K8S_DIR"
            exit 1
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
HEALTH_OK=false
for attempt in 1 2 3 4 5; do
    POD_IP=$(kubectl get pods -l "app=$SERVICE" -n "$NAMESPACE" \
        -o jsonpath='{.items[0].status.podIP}' 2>/dev/null || echo "")

    if [ -n "$POD_IP" ]; then
        if kubectl exec -n "$NAMESPACE" deploy/"$SERVICE" -- \
            sh -c "wget -qO- http://localhost:8000/health 2>/dev/null || curl -sf http://localhost:8000/health 2>/dev/null" &>/dev/null; then
            echo "  ✓ /health returned OK (attempt $attempt)"
            HEALTH_OK=true
            break
        fi
    fi
    echo "  Attempt $attempt/5 — waiting 10s..."
    sleep 10
done

if ! $HEALTH_OK; then
    echo "  ⚠ Health check did not pass after 5 attempts (non-fatal — service may not expose /health)"
fi

# ─── Audit log ────────────────────────────────────────────────────────────────
AUDIT_DIR="$REPO_ROOT/outputs"
mkdir -p "$AUDIT_DIR"
AUDIT_FILE="$AUDIT_DIR/deploy-audit.jsonl"
GIT_SHA=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo "unknown")
echo "{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"service\":\"$SERVICE\",\"environment\":\"$ENVIRONMENT\",\"strategy\":\"$STRATEGY\",\"image_tag\":\"${IMAGE_TAG:-latest}\",\"prev_version\":\"$PREV_VERSION\",\"outcome\":\"$DEPLOY_OUTCOME\",\"actor\":\"$(whoami)\",\"git_sha\":\"$GIT_SHA\"}" >> "$AUDIT_FILE"

echo ""
echo "✓ Deployment of $SERVICE to $ENVIRONMENT complete (outcome: $DEPLOY_OUTCOME)."
echo "  Rollback command: bash scripts/deploy/rollback_service.sh --service $SERVICE --environment $ENVIRONMENT"
