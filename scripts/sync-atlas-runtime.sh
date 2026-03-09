#!/usr/bin/env bash
# Sync AtlasOS runtime state into ~/.atlas from repo sources.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEPLOY_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ATLASOS_ROOT="${ATLASOS_ROOT:-$DEPLOY_ROOT/../AtlasOS}"
ATLAS_HOME="${ATLAS_HOME:-$HOME/.atlas}"
ENV_NAME="${1:-prod}"
BOOTSTRAP_FILES=("AGENTS.md" "SOUL.md" "IDENTITY.md" "TOOLS.md" "HEARTBEAT.md" "MISTAKES.md" "BOOTSTRAP.md" "USER.md")

log() {
  printf '%s [atlas-runtime-sync] %s\n' "$(date '+%Y-%m-%dT%H:%M:%S')" "$*"
}

sync_workspace() {
  local src_dir="$1"
  local name="$2"
  local dst_dir="$ATLAS_HOME/workspace-$name"
  mkdir -p "$dst_dir"

  for file in "${BOOTSTRAP_FILES[@]}"; do
    if [[ -f "$src_dir/$file" ]]; then
      install -m 0644 "$src_dir/$file" "$dst_dir/$file"
    fi
  done
}

main() {
  mkdir -p "$ATLAS_HOME"
  log "Syncing workspace bootstrap files from $ATLASOS_ROOT/workspaces"

  while IFS= read -r workspace; do
    [[ -d "$workspace" ]] || continue
    local_name="$(basename "$workspace")"
    sync_workspace "$workspace" "$local_name"
  done < <(printf '%s\n' "$ATLASOS_ROOT"/workspaces/*)

  if [[ -f "$ATLASOS_ROOT/BUILD_INFO.json" ]]; then
    install -m 0644 "$ATLASOS_ROOT/BUILD_INFO.json" "$ATLAS_HOME/BUILD_INFO.json"
    install -m 0644 "$ATLASOS_ROOT/BUILD_INFO.json" "$ATLAS_HOME/workspace-ceo/BUILD_INFO.json"
  fi

  log "Reconciling live atlasos.json to local-first policy"
  python3 "$ATLASOS_ROOT/scripts/reconcile_runtime_config.py"

  log "Writing runtime source metadata"
  python3 - <<'PYEOF'
import json
import os
from datetime import datetime, timezone
from pathlib import Path

atlas_home = Path(os.environ.get("ATLAS_HOME", Path.home() / ".atlas")).expanduser()
atlasos_root = Path(os.environ.get("ATLASOS_ROOT", "")).resolve()
deploy_root = Path(os.environ.get("DEPLOY_ROOT", "")).resolve()
env_name = os.environ.get("ENV_NAME", "prod")
payload = {
    "generated_at": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "authoritative_deploy_repo": str(deploy_root),
    "atlasos_repo": str(atlasos_root),
    "environment": env_name,
}
path = atlas_home / "state" / "runtime" / "runtime_source.json"
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(payload, indent=2) + "\n")
PYEOF

  log "Writing runtime status artifacts"
  python3 "$ATLASOS_ROOT/scripts/write_runtime_status.py"

  log "Atlas runtime sync complete"
}

export ATLASOS_ROOT
export DEPLOY_ROOT
export ATLAS_HOME
export ENV_NAME

main "$@"
