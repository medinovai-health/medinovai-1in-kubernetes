#!/bin/bash
# init.sh — MedinovAI Harness 2.1
# Repo: medinovai-infrastructure
# Compliance Tier: 2
set -e
echo "=== MedinovAI init.sh starting ==="
echo "Repo: medinovai-infrastructure"
echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "[1/3] Installing dependencies..."
terraform init -backend=false 2>/dev/null || true
echo "[2/3] Validating harness files..."
for f in CLAUDE.md feature_list.json claude-progress.txt; do
  [ -f "$f" ] || { echo "MISSING: $f"; echo "INIT_FAILED"; exit 1; }
done
echo "[3/3] Smoke test..."
python3 -c "import json; json.load(open('feature_list.json'))" 2>/dev/null \
  || { echo "feature_list.json invalid"; echo "INIT_FAILED"; exit 1; }
echo "INIT_SUCCESS"
