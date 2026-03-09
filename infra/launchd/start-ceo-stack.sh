#!/bin/bash
# Boot-time AtlasOS runtime activation via medinovai-Deploy.

set -uo pipefail

DEPLOY_ROOT="/Users/mayanktrivedi/Github/medinovai-health/medinovai-Deploy"
ENV_MANAGER="$DEPLOY_ROOT/scripts/env-manager.sh"
SYNC_SCRIPT="$DEPLOY_ROOT/scripts/sync-atlas-runtime.sh"
LOG_TAG="[medinovai-ceo]"
MAX_WAIT=120

log() { echo "$(date '+%Y-%m-%dT%H:%M:%S') $LOG_TAG $*"; }

wait_for_docker() {
  local elapsed=0
  while true; do
    if [ -S "/Users/mayanktrivedi/.docker/run/docker.sock" ]; then
      export DOCKER_HOST="unix:///Users/mayanktrivedi/.docker/run/docker.sock"
      break
    fi
    if [ -S "/var/run/docker.sock" ]; then
      break
    fi
    sleep 5
    elapsed=$((elapsed + 5))
    if [ "$elapsed" -ge "$MAX_WAIT" ]; then
      log "ERROR: Docker not ready after ${MAX_WAIT}s."
      exit 1
    fi
  done
}

wait_for_docker
log "Docker ready. Activating authoritative prod environment."
"$ENV_MANAGER" activate prod --all || exit 1
"$ENV_MANAGER" verify prod || log "WARNING: runtime verification reported drift"

log "AtlasOS prod environment active. Refreshing runtime every 5 minutes."
while true; do
  sleep 300
  "$ENV_MANAGER" start prod --all >/dev/null 2>&1 || log "WARNING: env-manager start refresh failed"
  "$SYNC_SCRIPT" prod >/dev/null 2>&1 || log "WARNING: runtime sync refresh failed"
done
