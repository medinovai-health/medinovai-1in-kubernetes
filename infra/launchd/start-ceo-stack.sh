#!/bin/bash
# ─── start-ceo-stack.sh ──────────────────────────────────────────────────────
# Called by launchd at boot to start the AtlasOS CEO Stack.
# Waits for Docker Desktop to be ready before launching compose.
# Runs as root (LaunchDaemon), so it can start before any login.
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail   # no -e: we handle errors per-phase

DEPLOY_ROOT="/Users/mayanktrivedi/Github/medinovai-health/medinovai-Deploy"
CEO_COMPOSE="$DEPLOY_ROOT/infra/docker/docker-compose.ceo.yml"
LOG_TAG="[medinovai-ceo]"
DOCKER_SOCKET="/var/run/docker.sock"
MAX_WAIT=120  # seconds to wait for Docker

log() { echo "$(date '+%Y-%m-%dT%H:%M:%S') $LOG_TAG $*"; }

# ── 1. Wait for Docker Desktop socket ────────────────────────────────────────
log "Waiting for Docker socket at $DOCKER_SOCKET (max ${MAX_WAIT}s)..."
elapsed=0
while [ ! -S "$DOCKER_SOCKET" ]; do
  # Also check Docker Desktop's user socket
  if [ -S "/Users/mayanktrivedi/.docker/run/docker.sock" ]; then
    export DOCKER_HOST="unix:///Users/mayanktrivedi/.docker/run/docker.sock"
    log "Using Docker Desktop user socket"
    break
  fi
  sleep 5
  elapsed=$((elapsed + 5))
  if [ $elapsed -ge $MAX_WAIT ]; then
    log "ERROR: Docker not ready after ${MAX_WAIT}s. Exiting (launchd will retry)."
    exit 1
  fi
done

# ── 2. Verify docker CLI works ────────────────────────────────────────────────
DOCKER_BIN=$(command -v docker 2>/dev/null || echo "/usr/local/bin/docker")
if ! "$DOCKER_BIN" info >/dev/null 2>&1; then
  log "ERROR: docker info failed. Exiting (launchd will retry)."
  exit 1
fi
log "Docker is ready."

# ── 3. Load credentials from AtlasOS .env ─────────────────────────────────────
ATLASOS_PATH="${ATLASOS_PATH:-/Users/mayanktrivedi/Github/medinovai-health/AtlasOS}"
ATLASOS_ENV_FILE="${ATLASOS_ENV_FILE:-$ATLASOS_PATH/.env}"

if [ -f "$ATLASOS_ENV_FILE" ]; then
  log "Loading credentials from $ATLASOS_ENV_FILE"
  # Export all non-comment, non-empty lines as env vars
  set -a
  # shellcheck disable=SC1090
  source "$ATLASOS_ENV_FILE"
  set +a
else
  log "WARNING: $ATLASOS_ENV_FILE not found — WhatsApp and AI credentials may be missing"
fi

# ── 4. Start CEO stack ────────────────────────────────────────────────────────
log "Starting CEO stack... (ATLASOS_PATH=$ATLASOS_PATH)"

export ATLASOS_PATH
export AIFACTORY_ENDPOINT="${AIFACTORY_ENDPOINT:-http://host.docker.internal:8300}"
export OLLAMA_HOST="${OLLAMA_HOST:-http://host.docker.internal:11434}"

# Note: no -p flag → project name defaults to "docker" (directory name)
"$DOCKER_BIN" compose -f "$CEO_COMPOSE" \
  up -d --no-recreate 2>&1 || \
  log "WARNING: compose up exited non-zero (some containers may already be running — this is OK)"

# Verify atlas-gateway (critical - WhatsApp handler on port 18789)
sleep 15
if "$DOCKER_BIN" ps --filter "name=ceo-atlas-gateway" --format "{{.Status}}" | grep -q "Up"; then
  log "ceo-atlas-gateway is running. WhatsApp webhook live on port 18789 (Tailscale Funnel active)."
else
  log "WARNING: ceo-atlas-gateway did not start. Attempting targeted start..."
  "$DOCKER_BIN" compose -f "$CEO_COMPOSE" \
    up -d atlas-gateway 2>&1 || true
fi

# ── 5. Keep running (launchd KeepAlive monitors this process) ─────────────────
log "CEO stack is running. Monitoring every 60s..."
while true; do
  sleep 60
  # Health pulse - restart any stopped containers without rebuilding
  "$DOCKER_BIN" compose -f "$CEO_COMPOSE" \
    up -d --no-recreate 2>/dev/null || true
done
