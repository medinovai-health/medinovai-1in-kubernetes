#!/usr/bin/env bash
#
# Phase AA: Run AtlasOS Integration Tests
#
# Checks required services, runs pytest with appropriate flags, reports results.
# Use env vars to point at local/Docker/K8s services (see tests/integration/conftest.py).
#
# Usage:
#   ./scripts/run_integration_tests.sh
#   STREAM_BUS_URL=http://localhost:10102 WEBHOOK_RECEIVER_URL=http://localhost:3121 ./scripts/run_integration_tests.sh
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

TESTS_DIR="${TESTS_DIR:-$REPO_ROOT/tests/integration}"
REQUIREMENTS="${TESTS_DIR}/requirements.txt"
VENV_DIR="${VENV_DIR:-$REPO_ROOT/.venv-integration}"

# ─── Colors ───────────────────────────────────────────────────────────────
R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
NC='\033[0m'

log() { echo -e "$*"; }
ok()  { log "${G}[OK]${NC} $*"; }
warn() { log "${Y}[WARN]${NC} $*"; }
err() { log "${R}[ERR]${NC} $*"; }

# ─── Check required services (optional, informational) ──────────────────────
check_service() {
  local url="$1"
  local name="$2"
  if command -v curl &>/dev/null; then
    if curl -sf --max-time 3 "${url}" &>/dev/null; then
      ok "$name: $url"
      return 0
    fi
  fi
  warn "$name not reachable at $url (tests may skip)"
  return 1
}

log ""
log "Phase AA: AtlasOS Integration Tests"
log "===================================="
log ""

# Services to check (env overrides in conftest.py)
STREAM_BUS_URL="${STREAM_BUS_URL:-http://localhost:3000}"
MCP_DEPLOY_URL="${MCP_DEPLOY_URL:-http://localhost:3120}"
WEBHOOK_RECEIVER_URL="${WEBHOOK_RECEIVER_URL:-http://localhost:3121}"
CLUSTER_BRAIN_URL="${CLUSTER_BRAIN_URL:-http://localhost:8100}"

log "Checking services (optional; tests will skip if unavailable):"
check_service "${STREAM_BUS_URL}/health" "Stream bus"       || true
check_service "${STREAM_BUS_URL}/health/ready" "Stream bus (ready)" || true
check_service "${MCP_DEPLOY_URL}/health" "MCP-deploy"      || true
check_service "${WEBHOOK_RECEIVER_URL}/health" "Webhook receiver" || true
check_service "${CLUSTER_BRAIN_URL}/health" "Cluster brain"  || true
log ""

# ─── Ensure test dependencies ──────────────────────────────────────────────
if [[ ! -f "$REQUIREMENTS" ]]; then
  err "Requirements not found: $REQUIREMENTS"
  exit 1
fi

if ! python3 -c "import pytest, httpx, pytest_asyncio" 2>/dev/null; then
  log "Installing test dependencies from $REQUIREMENTS ..."
  pip install -q -r "$REQUIREMENTS" || {
    err "Failed to install dependencies"
    exit 1
  }
  ok "Dependencies installed"
fi

# ─── Run pytest ─────────────────────────────────────────────────────────────
log "Running pytest in $TESTS_DIR ..."
log ""

PYTEST_ARGS=(
  -v
  --tb=short
  -p no:warnings
  -p no:pytest_postgresql
  -p no:visual
)
# Optional: stop on first failure
[[ -n "${FAIL_FAST:-}" ]] && PYTEST_ARGS+=(-x)
# Optional: per-test timeout (requires pytest-timeout)
python3 -c "import pytest_timeout" 2>/dev/null && PYTEST_ARGS+=(--timeout=60)

# Pass through extra args
PYTEST_ARGS+=("$@")

export PYTHONPATH="${REPO_ROOT}:${TESTS_DIR}"
cd "$TESTS_DIR"

# Prefer repo-local or default python
PYTHON="${PYTHON:-python3}"

if $PYTHON -m pytest "${PYTEST_ARGS[@]}" .; then
  log ""
  ok "All integration tests passed"
  exit 0
else
  rc=$?
  log ""
  err "Some tests failed (exit $rc)"
  exit $rc
fi
