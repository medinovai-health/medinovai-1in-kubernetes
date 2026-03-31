#!/usr/bin/env bash
# ─── smoke_test.sh ────────────────────────────────────────────────────────────
# Post-deployment smoke tests for the MedinovAI platform.
#
# Usage:
#   bash scripts/validation/smoke_test.sh --environment staging
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

ENVIRONMENT="staging"
BASE_URL=""
TIMEOUT=10

while [[ $# -gt 0 ]]; do
    case $1 in
        --environment)  ENVIRONMENT="$2"; shift 2 ;;
        --base-url)     BASE_URL="$2"; shift 2 ;;
        --timeout)      TIMEOUT="$2"; shift 2 ;;
        *)              echo "Unknown option: $1"; exit 1 ;;
    esac
done

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Smoke Tests — $ENVIRONMENT"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

PASS=0
FAIL=0

smoke_check() {
    local name="$1"
    local url="$2"
    local expected_status="${3:-200}"

    if [ -z "$url" ]; then
        printf "  ⏭ %-30s — URL not configured\n" "$name"
        return 0
    fi

    local status
    status=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT" "$url" 2>/dev/null || echo "000")

    if [ "$status" = "$expected_status" ]; then
        printf "  ✓ %-30s — HTTP %s\n" "$name" "$status"
        PASS=$((PASS + 1))
    else
        printf "  ✗ %-30s — HTTP %s (expected %s)\n" "$name" "$status" "$expected_status"
        FAIL=$((FAIL + 1))
    fi
}

# ─── Health Endpoints ─────────────────────────────────────────────────────────
echo "▸ Health Endpoints"
if [ -n "$BASE_URL" ]; then
    smoke_check "API Gateway /health"        "$BASE_URL/health"
    smoke_check "API Gateway /ready"         "$BASE_URL/ready"
    smoke_check "Auth Service /health"       "$BASE_URL/api/auth/health"
    smoke_check "Clinical Engine /health"    "$BASE_URL/api/clinical/health"
    smoke_check "Data Pipeline /health"      "$BASE_URL/api/data/health"
    smoke_check "AI Inference /health"       "$BASE_URL/api/ai/health"
else
    echo "  No base URL configured. Using kubectl port-forward or skip."
    echo "  Use --base-url to specify the platform URL."
fi

# ─── Atlas Gateway ────────────────────────────────────────────────────────────
echo ""
echo "▸ Atlas Gateway"
smoke_check "Atlas /health" "http://localhost:18789/health"
smoke_check "Atlas /ready"  "http://localhost:18789/ready"

# ─── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo "────────────────────────────────────────────────────────────────"
echo "Smoke Test Results: $PASS passed, $FAIL failed"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo "SMOKE TESTS: FAILED — $FAIL endpoint(s) unhealthy"
    exit 1
else
    echo "SMOKE TESTS: PASSED"
fi
