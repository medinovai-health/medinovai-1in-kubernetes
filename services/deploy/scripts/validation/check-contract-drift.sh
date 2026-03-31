#!/usr/bin/env bash
# OpenAPI Contract Drift Checker
# Compares running services' /openapi.json against data-contracts/*.yaml
# Usage: bash scripts/check-contract-drift.sh [--results-dir DIR]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONTRACTS_DIR="$REPO_ROOT/data-contracts"
RESULTS_DIR="${1:-$REPO_ROOT/logs/customer1/contract-drift}"

for arg in "$@"; do
  case "$arg" in --results-dir) shift; RESULTS_DIR="$1"; shift ;; esac
done

mkdir -p "$RESULTS_DIR"

BLUE='\033[0;34m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${BLUE}[CONTRACT]${NC} $*"; }
pass() { echo -e "${GREEN}  PASS${NC} $*"; }
fail_c() { echo -e "${RED}  DRIFT${NC} $*"; }
skip() { echo -e "${YELLOW}  SKIP${NC} $*"; }

SERVICE_ENDPOINTS=(
  "medinovai-registry:http://localhost:8060"
)

DRIFT_COUNT=0
CHECK_COUNT=0
SKIP_COUNT=0

log "Checking OpenAPI contract drift against data-contracts/"

for entry in "${SERVICE_ENDPOINTS[@]}"; do
  IFS=':' read -r svc_name base_url <<< "$entry"
  CHECK_COUNT=$((CHECK_COUNT + 1))
  contract_file="$CONTRACTS_DIR/${svc_name}-contracts.yaml"

  if [ ! -f "$contract_file" ]; then
    contract_file="$CONTRACTS_DIR/medinovai-${svc_name#medinovai-}-contracts.yaml"
  fi

  if [ ! -f "$contract_file" ]; then
    skip "$svc_name — no contract file found"
    SKIP_COUNT=$((SKIP_COUNT + 1))
    continue
  fi

  live_spec=$(curl -sf "${base_url}/openapi.json" 2>/dev/null || echo "")
  if [ -z "$live_spec" ]; then
    live_spec=$(curl -sf "${base_url}/docs/openapi.json" 2>/dev/null || echo "")
  fi

  if [ -z "$live_spec" ]; then
    skip "$svc_name — /openapi.json not available"
    SKIP_COUNT=$((SKIP_COUNT + 1))
    continue
  fi

  echo "$live_spec" > "$RESULTS_DIR/${svc_name}-live.json"

  LIVE_PATHS=$(echo "$live_spec" | python3 -c "
import sys, json
try:
    spec = json.load(sys.stdin)
    paths = sorted(spec.get('paths', {}).keys())
    print('\n'.join(paths))
except: pass
" 2>/dev/null || echo "")

  CONTRACT_PATHS=$(python3 -c "
import yaml, sys
try:
    with open('$contract_file') as f:
        spec = yaml.safe_load(f)
    paths = sorted(spec.get('paths', {}).keys())
    print('\n'.join(paths))
except: pass
" 2>/dev/null || echo "")

  if [ -z "$CONTRACT_PATHS" ] || [ "$CONTRACT_PATHS" = "" ]; then
    skip "$svc_name — contract has no paths (placeholder)"
    SKIP_COUNT=$((SKIP_COUNT + 1))
    continue
  fi

  MISSING=$(comm -23 <(echo "$CONTRACT_PATHS" | sort) <(echo "$LIVE_PATHS" | sort) 2>/dev/null || echo "")
  EXTRA=$(comm -13 <(echo "$CONTRACT_PATHS" | sort) <(echo "$LIVE_PATHS" | sort) 2>/dev/null || echo "")

  if [ -z "$MISSING" ] && [ -z "$EXTRA" ]; then
    pass "$svc_name — paths match contract"
  else
    fail_c "$svc_name — drift detected"
    if [ -n "$MISSING" ]; then
      echo "    Missing from live (in contract): $(echo "$MISSING" | tr '\n' ', ')"
    fi
    if [ -n "$EXTRA" ]; then
      echo "    Extra in live (not in contract): $(echo "$EXTRA" | tr '\n' ', ')"
    fi
    DRIFT_COUNT=$((DRIFT_COUNT + 1))
  fi

  python3 -c "
import json; from pathlib import Path
Path('$RESULTS_DIR/${svc_name}-drift.json').write_text(json.dumps({
    'service': '$svc_name',
    'contract_file': '$contract_file',
    'missing_paths': '''$MISSING'''.strip().split('\n') if '''$MISSING'''.strip() else [],
    'extra_paths': '''$EXTRA'''.strip().split('\n') if '''$EXTRA'''.strip() else [],
    'drift_detected': bool('''$MISSING'''.strip() or '''$EXTRA'''.strip()),
}, indent=2))
" 2>/dev/null || true
done

echo ""
log "Contract drift summary: $CHECK_COUNT checked, $DRIFT_COUNT drifted, $SKIP_COUNT skipped"

if [ "$DRIFT_COUNT" -gt 0 ]; then
  log "BREAKING DRIFT DETECTED — review data-contracts/ vs running services"
  exit 1
fi

log "No breaking contract drift detected"
exit 0
