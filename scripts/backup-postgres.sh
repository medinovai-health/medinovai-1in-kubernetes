#!/bin/bash
# PostgreSQL Automated Backup Script
# Part of MedinovAI Infrastructure v2.0

set -e

BACKUP_DIR="/tmp/backups/postgres"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="postgres_backup_${TIMESTAMP}.sql"
RETENTION_DAYS=30

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo "[$(date)] Starting PostgreSQL backup..."

# Perform backup
docker exec medinovai-postgres pg_dump \
  -U medinovai \
  -d medinovai \
  --verbose \
  --format=custom \
  --file=/tmp/${BACKUP_FILE}

# Copy backup from container
docker cp medinovai-postgres:/tmp/${BACKUP_FILE} "${BACKUP_DIR}/${BACKUP_FILE}"

# Compress backup
gzip "${BACKUP_DIR}/${BACKUP_FILE}"

echo "[$(date)] Backup completed: ${BACKUP_DIR}/${BACKUP_FILE}.gz"

# Upload to MinIO (S3-compatible)
if command -v mc &> /dev/null; then
  echo "[$(date)] Uploading to MinIO..."
  mc cp "${BACKUP_DIR}/${BACKUP_FILE}.gz" minio/medinovai-backups/postgres/
fi

# Cleanup old backups (keep last 30 days)
find "$BACKUP_DIR" -name "postgres_backup_*.sql.gz" -mtime +${RETENTION_DAYS} -delete

echo "[$(date)] PostgreSQL backup complete!"

