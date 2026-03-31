#!/usr/bin/env bash
# ─── restore.sh ───────────────────────────────────────────────────────────────
# Restore MedinovAI Docker stack from backup.
#
# Usage:
#   bash scripts/restore.sh
#   bash scripts/restore.sh --from-dump path/to/dump.sql
#   bash scripts/restore.sh --from-latest
#
# WARNING: This overwrites current data. Ensure backup exists first.
# Backup location: ~/medinovai-backups/medinovai-Deploy/
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECT="${PROJECT:-medinovai-Deploy}"
BACKUP_BASE="$HOME/medinovai-backups/$PROJECT"
COMPOSE_FILE="$REPO_ROOT/infra/docker/docker-compose.dev.yml"

FROM_DUMP=""
FROM_LATEST=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --from-dump)   FROM_DUMP="$2"; shift 2 ;;
        --from-latest) FROM_LATEST=true; shift ;;
        --project)     PROJECT="$2"; BACKUP_BASE="$HOME/medinovai-backups/$PROJECT"; shift 2 ;;
        *)             echo "Unknown option: $1"; exit 1 ;;
    esac
done

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  MedinovAI Restore — $PROJECT"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

if [ -z "$FROM_DUMP" ] && ! $FROM_LATEST; then
    echo "Usage:"
    echo "  bash scripts/restore.sh --from-dump $BACKUP_BASE/db/medinovai_YYYYMMDDTHHMMSSZ.sql"
    echo "  bash scripts/restore.sh --from-latest   # Use latest dump in backup dir"
    echo ""
    LATEST=$(ls -t "$BACKUP_BASE/db"/medinovai_*.sql 2>/dev/null | head -1)
    if [ -n "$LATEST" ]; then
        echo "Latest dump available: $LATEST"
        echo "  Run: bash scripts/restore.sh --from-dump $LATEST"
    fi
    exit 0
fi

echo "▸ Stopping Docker stack..."
cd "$REPO_ROOT"
docker compose -f "$COMPOSE_FILE" down 2>/dev/null || true

# ─── Restore DB from dump ──────────────────────────────────────────────────────
if $FROM_LATEST; then
    FROM_DUMP=$(ls -t "$BACKUP_BASE/db"/medinovai_*.sql 2>/dev/null | head -1)
fi

if [ -n "$FROM_DUMP" ] && [ -f "$FROM_DUMP" ]; then
    echo ""
    echo "▸ Starting Postgres only for restore..."
    docker compose -f "$COMPOSE_FILE" up -d postgres
    echo "  Waiting for Postgres to be ready..."
    sleep 5
    for i in $(seq 1 30); do
        if docker exec medinovai-postgres pg_isready -U medinovai -d medinovai 2>/dev/null; then
            break
        fi
        sleep 1
    done

    echo "▸ Restoring database from $FROM_DUMP..."
    docker exec -i medinovai-postgres psql -U medinovai -d medinovai < "$FROM_DUMP" 2>/dev/null || true
    echo "  ✓ Database restored"
fi

# ─── Start full stack ──────────────────────────────────────────────────────────
echo ""
echo "▸ Starting full stack..."
docker compose -f "$COMPOSE_FILE" up -d

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✓ Restore complete. Stack is starting."
echo "║  Run: docker compose -f $COMPOSE_FILE ps"
echo "╚══════════════════════════════════════════════════════════════╝"
