#!/usr/bin/env bash
# ─── health_check_all.sh ─────────────────────────────────────────────────────
# Full-stack health audit for the MedinovAI platform.
#
# Usage:
#   bash scripts/monitoring/health_check_all.sh
#   bash scripts/monitoring/health_check_all.sh --json
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

JSON_MODE=false
[[ "${1:-}" == "--json" ]] && JSON_MODE=true

PASS=0
FAIL=0
WARN=0

check() {
    local category="$1"
    local name="$2"
    local status="$3"
    local detail="$4"

    case "$status" in
        ok)   PASS=$((PASS + 1)); $JSON_MODE || printf "  ✓ [%-14s] %s — %s\n" "$category" "$name" "$detail" ;;
        warn) WARN=$((WARN + 1)); $JSON_MODE || printf "  ⚠ [%-14s] %s — %s\n" "$category" "$name" "$detail" ;;
        fail) FAIL=$((FAIL + 1)); $JSON_MODE || printf "  ✗ [%-14s] %s — %s\n" "$category" "$name" "$detail" ;;
    esac
}

if ! $JSON_MODE; then
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║          MedinovAI Platform — Full Health Audit              ║"
    echo "║          $(date -u +%Y-%m-%dT%H:%M:%SZ)                     ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
fi

# ─── 1. Infrastructure Layer ─────────────────────────────────────────────────
$JSON_MODE || echo "▸ Infrastructure Layer"

if command -v kubectl &>/dev/null; then
    NODE_STATUS=$(kubectl get nodes -o json 2>/dev/null | python3 -c "
import json, sys
try:
    nodes = json.load(sys.stdin)['items']
    ready = sum(1 for n in nodes if any(c['type']=='Ready' and c['status']=='True' for c in n['status']['conditions']))
    total = len(nodes)
    print(f'{ready}/{total}')
except: print('error')
" 2>/dev/null || echo "unavailable")

    if [ "$NODE_STATUS" = "unavailable" ] || [ "$NODE_STATUS" = "error" ]; then
        check "infra" "K8s nodes" "warn" "Could not query cluster"
    else
        READY=$(echo "$NODE_STATUS" | cut -d/ -f1)
        TOTAL=$(echo "$NODE_STATUS" | cut -d/ -f2)
        if [ "$READY" = "$TOTAL" ]; then
            check "infra" "K8s nodes" "ok" "$NODE_STATUS ready"
        else
            check "infra" "K8s nodes" "fail" "$NODE_STATUS ready"
        fi
    fi
else
    check "infra" "K8s nodes" "warn" "kubectl not available"
fi

# ─── 2. Service Layer ────────────────────────────────────────────────────────
$JSON_MODE || echo ""
$JSON_MODE || echo "▸ Service Layer"

SERVICES=("api-gateway" "auth-service" "clinical-engine" "data-pipeline" "ai-inference" "notification-service")

for svc in "${SERVICES[@]}"; do
    if command -v kubectl &>/dev/null; then
        SVC_STATUS=$(kubectl get deployment "$svc" -n medinovai-services -o jsonpath='{.status.readyReplicas}/{.status.replicas}' 2>/dev/null || echo "not-found")
        if [ "$SVC_STATUS" = "not-found" ]; then
            check "service" "$svc" "warn" "Not deployed"
        else
            READY=$(echo "$SVC_STATUS" | cut -d/ -f1)
            DESIRED=$(echo "$SVC_STATUS" | cut -d/ -f2)
            if [ "$READY" = "$DESIRED" ] && [ "$READY" != "" ]; then
                check "service" "$svc" "ok" "$SVC_STATUS replicas ready"
            else
                check "service" "$svc" "fail" "$SVC_STATUS replicas ready"
            fi
        fi
    else
        check "service" "$svc" "warn" "Cannot check — no kubectl"
    fi
done

# ─── 3. Database Layer ───────────────────────────────────────────────────────
$JSON_MODE || echo ""
$JSON_MODE || echo "▸ Database Layer"

if command -v aws &>/dev/null; then
    RDS_STATUS=$(aws rds describe-db-instances \
        --query "DBInstances[?contains(DBInstanceIdentifier,'medinovai')].{ID:DBInstanceIdentifier,Status:DBInstanceStatus}" \
        --output json 2>/dev/null || echo "[]")

    if [ "$RDS_STATUS" != "[]" ]; then
        echo "$RDS_STATUS" | python3 -c "
import json, sys
instances = json.load(sys.stdin)
for inst in instances:
    name = inst['ID']
    status = inst['Status']
    symbol = '✓' if status == 'available' else '✗'
    print(f'  {symbol} [database      ] {name} — {status}')
" 2>/dev/null
    else
        check "database" "RDS instances" "warn" "No instances found or AWS not configured"
    fi
else
    check "database" "RDS" "warn" "AWS CLI not available"
fi

# ─── 4. Monitoring Layer ─────────────────────────────────────────────────────
$JSON_MODE || echo ""
$JSON_MODE || echo "▸ Monitoring Layer"

for component in "prometheus" "grafana" "alertmanager" "loki"; do
    if command -v kubectl &>/dev/null; then
        STATUS=$(kubectl get deployment "$component" -n medinovai-monitoring -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        if [ "$STATUS" != "0" ] && [ -n "$STATUS" ]; then
            check "monitoring" "$component" "ok" "$STATUS replicas ready"
        else
            check "monitoring" "$component" "warn" "Not deployed"
        fi
    else
        check "monitoring" "$component" "warn" "Cannot check — no kubectl"
    fi
done

# ─── 5. Atlas Gateway ────────────────────────────────────────────────────────
$JSON_MODE || echo ""
$JSON_MODE || echo "▸ Atlas Gateway"

if command -v atlas &>/dev/null; then
    ATLAS_STATUS=$(atlas status 2>/dev/null || echo "not running")
    if echo "$ATLAS_STATUS" | grep -qi "running\|healthy\|ok"; then
        check "atlas" "Gateway" "ok" "Running"
    else
        check "atlas" "Gateway" "warn" "Not running or not installed"
    fi
else
    check "atlas" "Gateway" "warn" "Atlas CLI not installed"
fi

# ─── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo "────────────────────────────────────────────────────────────────"
echo "Health Audit Results: $PASS passed, $FAIL failed, $WARN warnings"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo "STATUS: UNHEALTHY — $FAIL critical issues detected"
    exit 1
elif [ "$WARN" -gt 0 ]; then
    echo "STATUS: DEGRADED — $WARN warnings (no critical failures)"
    exit 0
else
    echo "STATUS: HEALTHY — All checks passed"
    exit 0
fi
