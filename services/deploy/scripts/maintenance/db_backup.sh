#!/usr/bin/env bash
# ─── db_backup.sh ─────────────────────────────────────────────────────────────
# Database backup and verification for on-prem K3s PostgreSQL and AWS RDS.
#
# Usage:
#   bash scripts/maintenance/db_backup.sh                              # Backup primary on-prem
#   bash scripts/maintenance/db_backup.sh --database clinical          # Backup clinical DB
#   bash scripts/maintenance/db_backup.sh --verify                     # Verify latest backup
#   bash scripts/maintenance/db_backup.sh --backend aws --environment production
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

BACKEND="onprem"
ENVIRONMENT="production"
DATABASE="primary"
VERIFY=false
DEPLOY_HOME="${DEPLOY_HOME:-$HOME/.medinovai-deploy}"
BACKUP_DIR="$DEPLOY_HOME/backups/postgres"

while [[ $# -gt 0 ]]; do
    case $1 in
        --environment)  ENVIRONMENT="$2"; shift 2 ;;
        --database)     DATABASE="$2"; shift 2 ;;
        --verify)       VERIFY=true; shift ;;
        --backend)      BACKEND="$2"; shift 2 ;;
        *)              echo "Unknown option: $1"; exit 1 ;;
    esac
done

mkdir -p "$BACKUP_DIR"
TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Database Backup — $BACKEND / $DATABASE                     "
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

onprem_backup() {
    local pod_name namespace db_name

    case "$DATABASE" in
        primary)
            pod_name="postgres-primary-0"
            namespace="infra"
            db_name="medinovai"
            ;;
        clinical)
            pod_name="postgres-clinical-0"
            namespace="infra"
            db_name="clinical"
            ;;
        *)
            echo "Unknown database: $DATABASE (use: primary, clinical)"
            exit 1
            ;;
    esac

    echo "▸ Backing up $db_name from $pod_name in $namespace..."

    local dump_file="$BACKUP_DIR/${DATABASE}-${TIMESTAMP}.sql.gz"

    kubectl exec "$pod_name" -n "$namespace" -- \
        pg_dump -U medinovai -d "$db_name" --no-owner --no-privileges -Fc 2>/dev/null \
        | gzip > "$dump_file"

    local file_size
    file_size=$(du -h "$dump_file" | cut -f1)

    if [ -s "$dump_file" ]; then
        echo "  ✓ Backup created: $dump_file ($file_size)"

        # Keep metadata for verification
        python3 -c "
import json, hashlib, datetime, os
dump_path = '$dump_file'
with open(dump_path, 'rb') as f:
    sha256 = hashlib.sha256(f.read()).hexdigest()
meta = {
    'database': '$DATABASE',
    'namespace': '$namespace',
    'pod': '$pod_name',
    'db_name': '$db_name',
    'file': dump_path,
    'size_bytes': os.path.getsize(dump_path),
    'sha256': sha256,
    'created_at': datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ'),
}
meta_path = dump_path.replace('.sql.gz', '.meta.json')
with open(meta_path, 'w') as f:
    json.dump(meta, f, indent=2)
print(f'  ✓ Metadata: {meta_path}')
print(f'  ✓ SHA256: {sha256[:16]}...')
"
    else
        echo "  ✗ Backup file is empty — pg_dump may have failed"
        rm -f "$dump_file"
        exit 1
    fi

    # Prune old backups (keep last 7)
    local count
    count=$(ls -1 "$BACKUP_DIR/${DATABASE}"-*.sql.gz 2>/dev/null | wc -l | xargs)
    if [ "$count" -gt 7 ]; then
        local to_delete=$((count - 7))
        ls -1t "$BACKUP_DIR/${DATABASE}"-*.sql.gz | tail -"$to_delete" | while read -r old; do
            rm -f "$old" "${old%.sql.gz}.meta.json"
            echo "  Pruned old backup: $(basename "$old")"
        done
    fi
}

onprem_verify() {
    echo "▸ Verifying backups for $DATABASE..."

    local latest
    latest=$(ls -1t "$BACKUP_DIR/${DATABASE}"-*.sql.gz 2>/dev/null | head -1 || echo "")

    if [ -z "$latest" ]; then
        echo "  ✗ No backups found for $DATABASE"
        exit 1
    fi

    local meta_file="${latest%.sql.gz}.meta.json"

    echo "  Latest backup: $(basename "$latest")"
    echo "  Size: $(du -h "$latest" | cut -f1)"

    if [ -f "$meta_file" ]; then
        python3 -c "
import json, hashlib, datetime, os
from datetime import timezone

meta = json.loads(open('$meta_file').read())
with open('$latest', 'rb') as f:
    current_sha = hashlib.sha256(f.read()).hexdigest()

integrity = 'PASS' if current_sha == meta.get('sha256', '') else 'FAIL'
created = meta.get('created_at', 'unknown')
age_hours = 0
try:
    dt = datetime.datetime.fromisoformat(created.replace('Z', '+00:00'))
    age_hours = (datetime.datetime.now(timezone.utc) - dt).total_seconds() / 3600
except:
    pass

print(f'  Created:   {created}')
print(f'  Age:       {age_hours:.1f} hours')
print(f'  Integrity: {integrity} (SHA256 match)')
print(f'  Database:  {meta.get(\"db_name\", \"unknown\")}')

if integrity != 'PASS':
    print(f'  ✗ INTEGRITY FAILURE — backup may be corrupted')
    exit(1)
elif age_hours > 24:
    print(f'  ⚠ Backup is older than 24 hours')
    exit(2)
else:
    print(f'  ✓ Backup is healthy')
"
    else
        echo "  ⚠ No metadata file — cannot verify integrity"
    fi

    echo ""
    echo "  All backups for $DATABASE:"
    ls -lh "$BACKUP_DIR/${DATABASE}"-*.sql.gz 2>/dev/null | awk '{print "    " $5 " " $6 " " $7 " " $8 " " $9}'
}

aws_backup() {
    if $VERIFY; then
        echo "  Checking RDS automated backups..."
        aws rds describe-db-instances \
            --query "DBInstances[?contains(DBInstanceIdentifier, 'medinovai') && contains(DBInstanceIdentifier, '$ENVIRONMENT')].{ID:DBInstanceIdentifier,BackupWindow:PreferredBackupWindow,Retention:BackupRetentionPeriod,LatestRestore:LatestRestorableTime}" \
            --output table 2>/dev/null || echo "  Could not query RDS instances"
        echo ""
        echo "  Checking manual snapshots..."
        aws rds describe-db-snapshots \
            --query "DBSnapshots[?contains(DBSnapshotIdentifier, 'medinovai')].{ID:DBSnapshotIdentifier,Status:Status,Created:SnapshotCreateTime,Size:AllocatedStorage}" \
            --output table 2>/dev/null || echo "  Could not query snapshots"
    else
        SNAPSHOT_ID="medinovai-${ENVIRONMENT}-$(date -u +%Y%m%d-%H%M%S)"
        DB_INSTANCE="medinovai-${ENVIRONMENT}-primary"
        echo "  Creating RDS snapshot $SNAPSHOT_ID for $DB_INSTANCE..."
        aws rds create-db-snapshot \
            --db-instance-identifier "$DB_INSTANCE" \
            --db-snapshot-identifier "$SNAPSHOT_ID" \
            --tags "Key=Environment,Value=$ENVIRONMENT" "Key=ManagedBy,Value=medinovai-deploy" \
            2>/dev/null || echo "  ⚠ Snapshot creation failed"
    fi
}

case "$BACKEND" in
    onprem)
        if $VERIFY; then onprem_verify; else onprem_backup; fi
        ;;
    aws)
        aws_backup
        ;;
    *)
        echo "Unknown backend: $BACKEND (use: onprem, aws)"
        exit 1
        ;;
esac

echo ""
echo "✓ Database backup operation complete."
