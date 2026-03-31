#!/usr/bin/env bash
# ─── backup.sh ────────────────────────────────────────────────────────────────
# Backup databases and Docker volumes for MedinovAI Docker deployment.
# Per medinovai-backup-strategy: backups go to ~/medinovai-backups/<project>/
#
# Usage:
#   bash scripts/backup.sh
#   bash scripts/backup.sh --project medinovai-Deploy
#
# Requires: Docker stack running (postgres container for DB dump)
# Output: ~/medinovai-backups/medinovai-Deploy/{db,volumes,config}/
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECT="${PROJECT:-medinovai-Deploy}"
BACKUP_BASE="$HOME/medinovai-backups/$PROJECT"
COMPOSE_FILE="$REPO_ROOT/infra/docker/docker-compose.dev.yml"
LOG_FILE="$BACKUP_BASE/BACKUP_LOG.md"

while [[ $# -gt 0 ]]; do
    case $1 in
        --project)  PROJECT="$2"; BACKUP_BASE="$HOME/medinovai-backups/$PROJECT"; shift 2 ;;
        *)          echo "Unknown option: $1"; exit 1 ;;
    esac
done

mkdir -p "$BACKUP_BASE"/{db,volumes,config}
TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  MedinovAI Backup — $PROJECT"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "  Backup base: $BACKUP_BASE"
echo "  Timestamp:   $TIMESTAMP"
echo ""

# ─── 1. PostgreSQL dump ───────────────────────────────────────────────────────
echo "▸ Dumping PostgreSQL..."
POSTGRES_CONTAINER="medinovai-postgres"
if docker ps --format '{{.Names}}' | grep -q "^${POSTGRES_CONTAINER}$"; then
    DUMP_FILE="$BACKUP_BASE/db/medinovai_${TIMESTAMP}.sql"
    docker exec "$POSTGRES_CONTAINER" pg_dump -U medinovai medinovai 2>/dev/null > "$DUMP_FILE" || true
    if [ -s "$DUMP_FILE" ]; then
        echo "  ✓ PostgreSQL dump: $DUMP_FILE"
    else
        echo "  ⚠ Dump empty or failed (DB may be empty)"
        rm -f "$DUMP_FILE"
    fi
else
    echo "  ⚠ Postgres container not running — skipping DB dump"
fi

# ─── 2. Copy docker-compose and config ────────────────────────────────────────
echo ""
echo "▸ Saving config..."
cp "$COMPOSE_FILE" "$BACKUP_BASE/config/docker-compose.dev_${TIMESTAMP}.yml"
cp "$COMPOSE_FILE" "$BACKUP_BASE/config/docker-compose.dev_latest.yml"
echo "  ✓ Config saved to $BACKUP_BASE/config/"

# ─── 3. Export Docker volumes (optional, slower) ─────────────────────────────────
echo ""
echo "▸ Exporting volumes..."
# Volume names may be prefixed by compose project (e.g. medinovai-dev_postgres-data)
for base in postgres-data redis-data prometheus-data grafana-data localstack-data; do
    vol=$(docker volume ls -q | grep -E "${base}$" | head -1)
    [ -z "$vol" ] && continue
    if docker volume inspect "$vol" &>/dev/null; then
        TAR_FILE="$BACKUP_BASE/volumes/${base}_${TIMESTAMP}.tar.gz"
        docker run --rm \
            -v "$vol:/data:ro" \
            -v "$BACKUP_BASE/volumes:/backup" \
            alpine tar czf "/backup/$(basename "$TAR_FILE")" -C /data . 2>/dev/null || true
        if [ -f "$TAR_FILE" ]; then
            echo "  ✓ $base -> $(basename "$TAR_FILE")"
        fi
    fi
done

# ─── 4. Append to BACKUP_LOG.md ─────────────────────────────────────────────────
echo "" >> "$LOG_FILE" 2>/dev/null || touch "$LOG_FILE"
{
    echo "## $TIMESTAMP"
    echo "- DB dump: $([ -f "$BACKUP_BASE/db/medinovai_${TIMESTAMP}.sql" ] && echo 'yes' || echo 'skipped')"
    echo "- Config: docker-compose.dev_latest.yml"
    echo ""
} >> "$LOG_FILE"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✓ Backup complete"
echo "║  Location: $BACKUP_BASE"
echo "╚══════════════════════════════════════════════════════════════╝"
