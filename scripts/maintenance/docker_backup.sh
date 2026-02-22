#!/usr/bin/env bash
# ─── docker_backup.sh ─────────────────────────────────────────────────────────
# Full backup of the MedinovAI Docker Compose production stack on Mac Studio.
# Backs up: PostgreSQL, MySQL, Docker volumes (ChromaDB, audit, decisions, etc.)
#
# Usage:
#   bash scripts/maintenance/docker_backup.sh              # Full backup
#   bash scripts/maintenance/docker_backup.sh --verify     # Verify latest backups
#   bash scripts/maintenance/docker_backup.sh --restore    # Interactive restore
#   bash scripts/maintenance/docker_backup.sh --offsite    # Sync to offsite target
#
# Scheduled via: nightly-health.yml (GitHub Actions self-hosted) or cron
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

VERIFY=false
RESTORE=false
OFFSITE=false
BACKUP_ROOT="${MEDINOVAI_BACKUP_DIR:-$HOME/.medinovai-backups}"
TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
DATE_DIR="$BACKUP_ROOT/$TIMESTAMP"
OFFSITE_TARGET="${MEDINOVAI_OFFSITE_TARGET:-}"   # e.g. user@nas:/medinovai-backups or s3://bucket/backups
RETENTION_DAYS="${MEDINOVAI_BACKUP_RETENTION:-7}"
LOG_FILE="$BACKUP_ROOT/backup.log"

PASS=0
FAIL=0
WARNINGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --verify)   VERIFY=true;   shift ;;
        --restore)  RESTORE=true;  shift ;;
        --offsite)  OFFSITE=true;  shift ;;
        --dir)      DATE_DIR="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# ─── Helpers ──────────────────────────────────────────────────────────────────

log() { echo "[$(date -u +%H:%M:%SZ)] $*" | tee -a "$LOG_FILE"; }
ok()  { log "  ✓ $*"; PASS=$((PASS + 1)); }
err() { log "  ✗ $*"; FAIL=$((FAIL + 1)); }
warn(){ log "  ⚠ $*"; WARNINGS+=("$*"); }

sha256_file() { shasum -a 256 "$1" | awk '{print $1}'; }

write_meta() {
    local file="$1" type="$2" source="$3"
    python3 - <<PYEOF
import json, os
meta = {
    "file": "$file",
    "type": "$type",
    "source": "$source",
    "timestamp": "$TIMESTAMP",
    "size_bytes": os.path.getsize("$file"),
    "sha256": "$(sha256_file "$file")",
}
with open("${file}.meta.json", "w") as f:
    json.dump(meta, f, indent=2)
print(json.dumps(meta))
PYEOF
}

container_running() { docker ps --filter "name=^$1$" --format "{{.Names}}" 2>/dev/null | grep -q "^$1$"; }

# ─── VERIFY MODE ──────────────────────────────────────────────────────────────

if $VERIFY; then
    log "═══════════════════════════════════════════════════════"
    log " MedinovAI Docker Backup — Verification"
    log "═══════════════════════════════════════════════════════"

    latest_dir=$(ls -1dt "$BACKUP_ROOT"/2* 2>/dev/null | head -1 || echo "")
    if [ -z "$latest_dir" ]; then
        err "No backup directories found in $BACKUP_ROOT"
        exit 1
    fi

    log "Latest backup: $latest_dir"

    age_hours=$(python3 -c "
import datetime, os
mtime = os.path.getmtime('$latest_dir')
age = (datetime.datetime.now().timestamp() - mtime) / 3600
print(f'{age:.1f}')
")
    log "Age: ${age_hours}h"

    if python3 -c "exit(0 if float('$age_hours') <= 25 else 1)" 2>/dev/null; then
        ok "Backup is within 25 hours"
    else
        warn "Backup is older than 25 hours (${age_hours}h)"
    fi

    for meta_file in "$latest_dir"/*.meta.json; do
        [ -f "$meta_file" ] || continue
        python3 - <<PYEOF
import json, hashlib, os, sys
meta = json.loads(open("$meta_file").read())
fpath = meta["file"]
if not os.path.exists(fpath):
    print(f"  ✗ MISSING: {os.path.basename(fpath)}")
    sys.exit(1)
with open(fpath, "rb") as f:
    current = hashlib.sha256(f.read()).hexdigest()
stored = meta.get("sha256", "")
if current == stored:
    size_mb = meta["size_bytes"] / 1_048_576
    print(f"  ✓ {os.path.basename(fpath)} ({size_mb:.1f} MB) — integrity OK")
else:
    print(f"  ✗ {os.path.basename(fpath)} — SHA256 MISMATCH (backup corrupted!)")
    sys.exit(1)
PYEOF
        if [ $? -eq 0 ]; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); fi
    done

    echo ""
    log "Result: ${PASS} passed, ${FAIL} failed"
    [ "$FAIL" -eq 0 ] && exit 0 || exit 1
fi

# ─── RESTORE MODE ─────────────────────────────────────────────────────────────

if $RESTORE; then
    log "═══════════════════════════════════════════════════════"
    log " MedinovAI Docker Backup — Restore"
    log "═══════════════════════════════════════════════════════"

    echo ""
    echo "Available backups:"
    ls -1dt "$BACKUP_ROOT"/2* 2>/dev/null | head -10 | while read -r d; do
        echo "  $(basename "$d")  ($(du -sh "$d" 2>/dev/null | cut -f1))"
    done
    echo ""
    read -p "Enter backup timestamp to restore (e.g. 20260222T120000Z): " RESTORE_TS
    RESTORE_DIR="$BACKUP_ROOT/$RESTORE_TS"

    if [ ! -d "$RESTORE_DIR" ]; then
        echo "Backup not found: $RESTORE_DIR"; exit 1
    fi

    echo ""
    echo "⚠️  WARNING: This will overwrite current data in running containers."
    read -p "Type 'RESTORE' to confirm: " CONFIRM
    [ "$CONFIRM" = "RESTORE" ] || { echo "Aborted."; exit 0; }

    # Restore PostgreSQL (CEO stack)
    pg_dump="$RESTORE_DIR/ceo-postgres.sql.gz"
    if [ -f "$pg_dump" ] && container_running "ceo-postgres"; then
        log "Restoring ceo-postgres..."
        gunzip -c "$pg_dump" | docker exec -i ceo-postgres psql -U medinovai -d atlas
        ok "ceo-postgres restored"
    fi

    # Restore MySQL (atlas-db)
    mysql_dump="$RESTORE_DIR/atlas-db.sql.gz"
    if [ -f "$mysql_dump" ] && container_running "atlas-db"; then
        log "Restoring atlas-db (MySQL)..."
        gunzip -c "$mysql_dump" | docker exec -i atlas-db mysql -uatlas -patlas_password_123 atlas
        ok "atlas-db restored"
    fi

    # Restore volumes from tarballs
    for tarball in "$RESTORE_DIR"/*.vol.tar.gz; do
        [ -f "$tarball" ] || continue
        vol_name=$(basename "$tarball" .vol.tar.gz)
        log "Restoring volume: $vol_name..."
        docker run --rm \
            -v "${vol_name}:/target" \
            -v "$RESTORE_DIR:/backup:ro" \
            alpine sh -c "cd /target && tar xzf /backup/${vol_name}.vol.tar.gz --strip-components=1" 2>/dev/null \
            && ok "$vol_name volume restored" \
            || warn "$vol_name volume restore failed (may not exist)"
    done

    log "Restore complete. Restart affected containers to pick up changes."
    exit 0
fi

# ─── FULL BACKUP MODE ─────────────────────────────────────────────────────────

mkdir -p "$DATE_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

log "═══════════════════════════════════════════════════════"
log " MedinovAI Docker Backup — Full Backup"
log " Timestamp: $TIMESTAMP"
log " Output:    $DATE_DIR"
log "═══════════════════════════════════════════════════════"
echo ""

# ── 1. PostgreSQL (CEO stack: ceo-postgres) ──────────────────────────────────
log "── PostgreSQL (ceo-postgres) ──"
if container_running "ceo-postgres"; then
    PG_FILE="$DATE_DIR/ceo-postgres.sql.gz"
    docker exec ceo-postgres pg_dumpall -U medinovai 2>/dev/null | gzip > "$PG_FILE"
    if [ -s "$PG_FILE" ]; then
        write_meta "$PG_FILE" "postgresql" "ceo-postgres" > /dev/null
        ok "ceo-postgres backup: $(du -h "$PG_FILE" | cut -f1)"
    else
        rm -f "$PG_FILE"
        err "ceo-postgres pg_dumpall failed — container may be unhealthy"
    fi
else
    warn "ceo-postgres is not running — skipped"
fi

# ── 2. MySQL (atlas-db) ──────────────────────────────────────────────────────
log "── MySQL (atlas-db) ──"
if container_running "atlas-db"; then
    MYSQL_FILE="$DATE_DIR/atlas-db.sql.gz"
    docker exec atlas-db mysqldump -uatlas -patlas_password_123 --all-databases --single-transaction 2>/dev/null \
        | gzip > "$MYSQL_FILE"
    if [ -s "$MYSQL_FILE" ]; then
        write_meta "$MYSQL_FILE" "mysql" "atlas-db" > /dev/null
        ok "atlas-db backup: $(du -h "$MYSQL_FILE" | cut -f1)"
    else
        rm -f "$MYSQL_FILE"
        err "atlas-db mysqldump failed — container may be unhealthy"
    fi
else
    warn "atlas-db is not running — skipped"
fi

# ── 3. MongoDB (medinovai-stack-mongodb) ─────────────────────────────────────
log "── MongoDB (medinovai-stack-mongodb) ──"
if container_running "medinovai-stack-mongodb"; then
    MONGO_FILE="$DATE_DIR/medinovai-mongodb.archive.gz"
    docker exec medinovai-stack-mongodb mongodump --archive --gzip 2>/dev/null \
        > "$MONGO_FILE"
    if [ -s "$MONGO_FILE" ]; then
        write_meta "$MONGO_FILE" "mongodb" "medinovai-stack-mongodb" > /dev/null
        ok "medinovai-mongodb backup: $(du -h "$MONGO_FILE" | cut -f1)"
    else
        rm -f "$MONGO_FILE"
        err "medinovai-mongodb mongodump failed"
    fi
else
    warn "medinovai-stack-mongodb is not running — skipped"
fi

# ── 4. Docker Volumes (audit, decisions, briefings, correlations, chromadb) ──
backup_volume() {
    local vol_name="$1"
    log "── Volume: $vol_name ──"
    if docker volume inspect "$vol_name" &>/dev/null; then
        local vol_file="$DATE_DIR/${vol_name}.vol.tar.gz"
        docker run --rm \
            -v "${vol_name}:/source:ro" \
            alpine tar czf - -C /source . 2>/dev/null \
            > "$vol_file"
        if [ -s "$vol_file" ]; then
            write_meta "$vol_file" "docker-volume" "$vol_name" > /dev/null
            ok "$vol_name: $(du -h "$vol_file" | cut -f1)"
        else
            rm -f "$vol_file"
            err "$vol_name volume backup failed (empty)"
        fi
    else
        warn "$vol_name volume does not exist — skipped"
    fi
}

# Critical CEO stack volumes
backup_volume "docker_audit-data"
backup_volume "docker_decision-data"
backup_volume "docker_briefing-data"
backup_volume "docker_correlation-data"
backup_volume "docker_chromadb-data"
backup_volume "docker_vault-data"

# Atlas deployment volumes
backup_volume "atlas-deployment_atlas-db-data"
backup_volume "medinovai-chromadb-data"
backup_volume "medinovai-orchestrator-data"

# ── 5. Write backup manifest ──────────────────────────────────────────────────
MANIFEST="$DATE_DIR/MANIFEST.json"
python3 - <<PYEOF
import json, os, datetime

files = []
for fname in os.listdir("$DATE_DIR"):
    fpath = os.path.join("$DATE_DIR", fname)
    if fname.endswith(".meta.json") or fname == "MANIFEST.json":
        continue
    if os.path.isfile(fpath):
        files.append({
            "file": fname,
            "size_bytes": os.path.getsize(fpath),
            "size_human": f"{os.path.getsize(fpath) / 1_048_576:.1f} MB",
        })

manifest = {
    "timestamp": "$TIMESTAMP",
    "backup_dir": "$DATE_DIR",
    "host": os.uname().nodename,
    "files": sorted(files, key=lambda x: x["file"]),
    "total_files": len(files),
    "total_size_mb": round(sum(f["size_bytes"] for f in files) / 1_048_576, 1),
    "pass": $PASS,
    "fail": $FAIL,
}
with open("$MANIFEST", "w") as f:
    json.dump(manifest, f, indent=2)
print(json.dumps(manifest, indent=2))
PYEOF

# ── 6. Prune old backups ──────────────────────────────────────────────────────
log "── Pruning backups older than ${RETENTION_DAYS} days ──"
find "$BACKUP_ROOT" -maxdepth 1 -type d -name "2*" \
    -mtime "+${RETENTION_DAYS}" \
    -exec rm -rf {} \; 2>/dev/null && log "  Pruned old backups" || true

# ── 7. Offsite sync ───────────────────────────────────────────────────────────
if $OFFSITE || [ -n "$OFFSITE_TARGET" ]; then
    if [ -n "$OFFSITE_TARGET" ]; then
        log "── Offsite sync → $OFFSITE_TARGET ──"
        rsync -az --delete "$BACKUP_ROOT/" "$OFFSITE_TARGET/" \
            && ok "Offsite sync complete" \
            || err "Offsite sync failed (check MEDINOVAI_OFFSITE_TARGET)"
    else
        warn "OFFSITE_TARGET not set — skipping offsite sync (set MEDINOVAI_OFFSITE_TARGET=user@host:/path)"
    fi
fi

# ── 8. Summary ────────────────────────────────────────────────────────────────
echo ""
log "═══════════════════════════════════════════════════════"
log " Backup Summary"
log "═══════════════════════════════════════════════════════"
log " Directory: $DATE_DIR"
log " Total size: $(du -sh "$DATE_DIR" 2>/dev/null | cut -f1)"
log " Result: ${PASS} succeeded, ${FAIL} failed"
if [ ${#WARNINGS[@]} -gt 0 ]; then
    log " Warnings:"
    for w in "${WARNINGS[@]}"; do log "   ⚠ $w"; done
fi

if [ "$FAIL" -gt 0 ]; then
    log " ✗ BACKUP INCOMPLETE — ${FAIL} component(s) failed"
    exit 1
else
    log " ✓ BACKUP COMPLETE"
    exit 0
fi
