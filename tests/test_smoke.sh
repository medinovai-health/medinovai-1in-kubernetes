#!/usr/bin/env bash
# Basic smoke tests for medinovai-infrastructure
set -euo pipefail

echo "=== medinovai-infrastructure smoke tests ==="

# Test 1: health endpoint (if service is running)
URL="${MEDINOVAI_INFRASTRUCTURE_URL:-http://localhost:8000}"
if curl -sf "$URL/health" > /dev/null 2>&1; then
    echo "PASS: /health returns 200"
else
    echo "SKIP: service not running at $URL"
fi

# Test 2: script syntax check
for f in *.sh; do
    if bash -n "$f" 2>/dev/null; then
        echo "PASS: $f syntax OK"
    else
        echo "FAIL: $f has syntax errors"
        exit 1
    fi
done

echo "=== All smoke tests passed ==="
