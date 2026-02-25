#!/bin/bash
# ─── backup-atlasos-config.sh ────────────────────────────────────────────────
# Backs up all AtlasOS/AtlasOS config and credentials before any upgrade.
# Safe to run any time; idempotent. Creates timestamped + "latest" symlink.
#
# What is backed up:
#   ~/.atlas/atlasos.json          - CEO agent config, WhatsApp/Telegram/channel bindings,
#                                    model config, agent definitions (Arjun + team)
#   ~/.atlas/atlasos.json         - AtlasOS gateway config
#   ~/.atlas/credentials/          - WhatsApp pairing, Telegram pairing, Mattermost tokens
#   ~/.atlas/devices/              - Paired device state
#   ~/Library/LaunchAgents/ai.*    - All AtlasOS/AtlasOS LaunchAgent plists
#   ~/Library/LaunchAgents/com.atlasos.* - Voice bridge and other plists
#   infra/docker/docker-compose.ceo.yml  - CEO Docker stack config
#
# Usage:
#   ./infra/scripts/backup-atlasos-config.sh
#   ./infra/scripts/backup-atlasos-config.sh --restore latest
#   ./infra/scripts/backup-atlasos-config.sh --restore 20260225_120000
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

BACKUP_ROOT="$HOME/.atlas-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"
LATEST_LINK="$BACKUP_ROOT/latest"
ATLAS_DIR="$HOME/.atlas"
DEPLOY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

log() { echo "$(date '+%H:%M:%S') [backup] $*"; }
err() { echo "$(date '+%H:%M:%S') [ERROR] $*" >&2; }

# ── RESTORE MODE ──────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--restore" ]]; then
  TARGET="${2:-latest}"
  if [[ "$TARGET" == "latest" ]]; then
    RESTORE_FROM="$BACKUP_ROOT/latest"
  else
    RESTORE_FROM="$BACKUP_ROOT/$TARGET"
  fi
  if [[ ! -d "$RESTORE_FROM" ]]; then
    err "Backup not found: $RESTORE_FROM"
    echo "Available backups:"
    ls "$BACKUP_ROOT" 2>/dev/null | grep -v latest | sort -r | head -10
    exit 1
  fi

  log "Restoring from: $RESTORE_FROM"

  # Safety: backup current state before restore
  SAFETY_BACKUP="$BACKUP_ROOT/pre-restore-${TIMESTAMP}"
  mkdir -p "$SAFETY_BACKUP"
  [[ -f "$ATLAS_DIR/atlasos.json" ]] && cp "$ATLAS_DIR/atlasos.json" "$SAFETY_BACKUP/"
  [[ -f "$ATLAS_DIR/atlasos.json" ]] && cp "$ATLAS_DIR/atlasos.json" "$SAFETY_BACKUP/"
  log "Safety backup of current state: $SAFETY_BACKUP"

  # Stop gateway before restore
  launchctl unload "$HOME/Library/LaunchAgents/ai.atlasos.gateway.plist" 2>/dev/null || true

  # Restore files
  [[ -f "$RESTORE_FROM/atlasos.json" ]] && cp "$RESTORE_FROM/atlasos.json" "$ATLAS_DIR/atlasos.json" && log "Restored: atlasos.json"
  [[ -f "$RESTORE_FROM/atlasos.json" ]] && cp "$RESTORE_FROM/atlasos.json" "$ATLAS_DIR/atlasos.json" && log "Restored: atlasos.json"
  [[ -d "$RESTORE_FROM/credentials" ]] && rsync -a "$RESTORE_FROM/credentials/" "$ATLAS_DIR/credentials/" && log "Restored: credentials/"
  [[ -d "$RESTORE_FROM/devices" ]] && rsync -a "$RESTORE_FROM/devices/" "$ATLAS_DIR/devices/" && log "Restored: devices/"
  [[ -d "$RESTORE_FROM/LaunchAgents" ]] && rsync -a "$RESTORE_FROM/LaunchAgents/" "$HOME/Library/LaunchAgents/" && log "Restored: LaunchAgents"

  # Restart gateway
  sleep 2
  launchctl load "$HOME/Library/LaunchAgents/ai.atlasos.gateway.plist" && log "Gateway restarted"
  log "Restore complete."
  exit 0
fi

# ── BACKUP MODE ───────────────────────────────────────────────────────────────
log "Creating backup: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Core config files
if [[ -f "$ATLAS_DIR/atlasos.json" ]]; then
  cp "$ATLAS_DIR/atlasos.json" "$BACKUP_DIR/atlasos.json"
  log "  ✓ atlasos.json ($(wc -c < "$ATLAS_DIR/atlasos.json" | tr -d ' ') bytes)"
fi
if [[ -f "$ATLAS_DIR/atlasos.json" ]]; then
  cp "$ATLAS_DIR/atlasos.json" "$BACKUP_DIR/atlasos.json"
  log "  ✓ atlasos.json"
fi

# Credentials (WhatsApp pairing, Telegram, Mattermost tokens)
if [[ -d "$ATLAS_DIR/credentials" ]]; then
  cp -r "$ATLAS_DIR/credentials" "$BACKUP_DIR/credentials"
  log "  ✓ credentials/ ($(ls "$ATLAS_DIR/credentials" | wc -l | tr -d ' ') files)"
fi

# Device pairing state
if [[ -d "$ATLAS_DIR/devices" ]]; then
  cp -r "$ATLAS_DIR/devices" "$BACKUP_DIR/devices"
  log "  ✓ devices/"
fi

# LaunchAgent plists
mkdir -p "$BACKUP_DIR/LaunchAgents"
for plist in "$HOME/Library/LaunchAgents"/ai.atlasos.*.plist \
             "$HOME/Library/LaunchAgents"/ai.atlasos.*.plist \
             "$HOME/Library/LaunchAgents"/ai.medinovai.*.plist \
             "$HOME/Library/LaunchAgents"/com.atlasos.*.plist \
             "$HOME/Library/LaunchAgents"/com.medinovai.*.plist \
             "$HOME/Library/LaunchAgents"/com.atlasos.*.plist; do
  [[ -f "$plist" ]] && cp "$plist" "$BACKUP_DIR/LaunchAgents/" && log "  ✓ LaunchAgent: $(basename "$plist")"
done

# CEO Docker stack config
if [[ -f "$DEPLOY_ROOT/infra/docker/docker-compose.ceo.yml" ]]; then
  cp "$DEPLOY_ROOT/infra/docker/docker-compose.ceo.yml" "$BACKUP_DIR/docker-compose.ceo.yml"
  log "  ✓ docker-compose.ceo.yml"
fi

# Write manifest
cat > "$BACKUP_DIR/manifest.json" << MANIFEST
{
  "timestamp": "$TIMESTAMP",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "atlas_version": "$(cat "$ATLAS_DIR/BUILD_INFO.json" 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('version','unknown'))" 2>/dev/null || echo 'unknown')",
  "atlasos_config_sha256": "$(shasum -a 256 "$ATLAS_DIR/atlasos.json" 2>/dev/null | awk '{print $1}' || echo 'n/a')",
  "files": $(ls "$BACKUP_DIR" | grep -v manifest.json | python3 -c "import sys,json; print(json.dumps(sys.stdin.read().strip().splitlines()))")
}
MANIFEST
log "  ✓ manifest.json"

# Update "latest" symlink
ln -sfn "$BACKUP_DIR" "$LATEST_LINK"
log "  ✓ latest → $TIMESTAMP"

log ""
log "Backup complete: $BACKUP_DIR"
log "Restore with: $0 --restore $TIMESTAMP"
log "              $0 --restore latest"

# Cleanup: keep only last 20 backups (not "latest" symlink, not "pre-restore-" ones)
BACKUP_COUNT=$(ls -d "$BACKUP_ROOT"/[0-9]* 2>/dev/null | wc -l | tr -d ' ')
if [[ "$BACKUP_COUNT" -gt 20 ]]; then
  EXCESS=$((BACKUP_COUNT - 20))
  ls -d "$BACKUP_ROOT"/[0-9]* | head -"$EXCESS" | while read -r old; do
    rm -rf "$old"
    log "Pruned old backup: $(basename "$old")"
  done
fi
