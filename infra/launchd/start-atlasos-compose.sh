#!/bin/bash
# ─── start-atlasos-compose.sh ────────────────────────────────────────────────
# Starts the AtlasOS permanent compose stack at login/reboot.
# Called by launchd (com.medinovai.atlasos-compose).
# Protected stack — never runs docker compose down. Only brings up.
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail

ATLASOS_PATH="${ATLASOS_PATH:-/Users/mayanktrivedi/Github/medinovai-health/AtlasOS}"
COMPOSE_FILE="$ATLASOS_PATH/docker-compose.local.yml"
DOCKER_SOCKET_SYSTEM="/var/run/docker.sock"
DOCKER_SOCKET_USER="/Users/mayanktrivedi/.docker/run/docker.sock"
MAX_WAIT=120
LOG_TAG="[atlasos-compose]"

log() { echo "$(date '+%Y-%m-%dT%H:%M:%S') $LOG_TAG $*"; }

# ── 1. Wait for Docker socket ─────────────────────────────────────────────────
log "Waiting for Docker (max ${MAX_WAIT}s)..."
elapsed=0
while true; do
  if [ -S "$DOCKER_SOCKET_USER" ]; then
    export DOCKER_HOST="unix://${DOCKER_SOCKET_USER}"
    log "Using Docker Desktop user socket"
    break
  fi
  if [ -S "$DOCKER_SOCKET_SYSTEM" ]; then
    log "Using system Docker socket"
    break
  fi
  sleep 5
  elapsed=$((elapsed + 5))
  if [ "$elapsed" -ge "$MAX_WAIT" ]; then
    log "ERROR: Docker not ready after ${MAX_WAIT}s — launchd will retry."
    exit 1
  fi
done

# ── 2. Verify docker CLI works ────────────────────────────────────────────────
DOCKER_BIN=$(command -v docker 2>/dev/null || echo "/usr/local/bin/docker")
if ! "$DOCKER_BIN" info >/dev/null 2>&1; then
  log "ERROR: docker info failed — launchd will retry."
  exit 1
fi
log "Docker is ready."

# ── 3. Load credentials ───────────────────────────────────────────────────────
ENV_FILE="${ATLASOS_PATH}/.env"
if [ -f "$ENV_FILE" ]; then
  set -a; source "$ENV_FILE"; set +a
  log "Loaded credentials from $ENV_FILE"
fi

# ── 4. Bring up protected stack (--no-recreate preserves running containers) ──
log "Bringing up atlasos compose stack: $COMPOSE_FILE"
# #region agent log
echo "{\"sessionId\":\"2c7c88\",\"hypothesisId\":\"A\",\"location\":\"start-atlasos-compose.sh:55\",\"message\":\"compose_up_initial_start\",\"data\":{\"compose_file\":\"$COMPOSE_FILE\",\"pid\":$$},\"timestamp\":$(date +%s)000}" >> /Users/mayanktrivedi/Github/medinovai-health/AtlasOS/.cursor/debug-2c7c88.log
# #endregion
"$DOCKER_BIN" compose -f "$COMPOSE_FILE" -p atlasos up -d --no-recreate 2>&1 | \
  while IFS= read -r line; do log "$line"; done

STATUS=$?
if [ "$STATUS" -ne 0 ]; then
  log "WARNING: compose up returned $STATUS — some services may not have started."
fi
# #region agent log
echo "{\"sessionId\":\"2c7c88\",\"hypothesisId\":\"A\",\"location\":\"start-atlasos-compose.sh:65\",\"message\":\"compose_up_initial_done\",\"data\":{\"status\":$STATUS},\"timestamp\":$(date +%s)000}" >> /Users/mayanktrivedi/Github/medinovai-health/AtlasOS/.cursor/debug-2c7c88.log
# #endregion

# ── 5. Verify protected services are running ──────────────────────────────────
sleep 5
RUNNING=$("$DOCKER_BIN" ps --filter "label=atlasos.protected=true" --filter "label=com.docker.compose.project=atlasos" --format "{{.Names}}" 2>/dev/null | wc -l | tr -d ' ')
log "AtlasOS compose: $RUNNING protected containers running."

# ── 6. Health watch loop — restart exited containers without compose down ─────
log "Entering health watch loop (checks every 60s)..."
while true; do
  sleep 60

  # Restart any exited atlasos protected containers
  EXITED=$("$DOCKER_BIN" ps -a \
    --filter "label=atlasos.protected=true" \
    --filter "label=com.docker.compose.project=atlasos" \
    --filter "status=exited" \
    --format "{{.Names}}" 2>/dev/null)

  if [ -n "$EXITED" ]; then
    log "WARN: Exited protected containers detected: $(echo "$EXITED" | tr '\n' ',')"
    for c in $EXITED; do
      log "Restarting: $c"
      "$DOCKER_BIN" start "$c" 2>/dev/null && log "Restarted: $c" || log "ERROR: Failed to restart $c"
    done
  fi

  # Re-run compose up --no-recreate to catch any missing containers
  # #region agent log
  RUNNING_COUNT=$("$DOCKER_BIN" ps --filter "label=com.docker.compose.project=atlasos" --format "{{.Names}}" 2>/dev/null | wc -l | tr -d ' ')
  echo "{\"sessionId\":\"2c7c88\",\"hypothesisId\":\"B_C\",\"location\":\"start-atlasos-compose.sh:92\",\"message\":\"health_loop_compose_up_called\",\"data\":{\"running_count\":$RUNNING_COUNT,\"exited\":\"${EXITED:-none}\",\"pid\":$$},\"timestamp\":$(date +%s)000}" >> /Users/mayanktrivedi/Github/medinovai-health/AtlasOS/.cursor/debug-2c7c88.log
  # #endregion
  "$DOCKER_BIN" compose -f "$COMPOSE_FILE" -p atlasos up -d --no-recreate >/dev/null 2>&1
  # #region agent log
  LOOP_STATUS=$?
  echo "{\"sessionId\":\"2c7c88\",\"hypothesisId\":\"B_C\",\"location\":\"start-atlasos-compose.sh:98\",\"message\":\"health_loop_compose_up_done\",\"data\":{\"exit_code\":$LOOP_STATUS},\"timestamp\":$(date +%s)000}" >> /Users/mayanktrivedi/Github/medinovai-health/AtlasOS/.cursor/debug-2c7c88.log
  # #endregion
done
