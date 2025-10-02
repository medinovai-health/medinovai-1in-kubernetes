#!/bin/bash
# MongoDB Automated Backup Script
# Part of MedinovAI Infrastructure v2.0

set -e

BACKUP_DIR="/tmp/backups/mongodb"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="mongodb_backup_${TIMESTAMP}"
RETENTION_DAYS=30

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo "[$(date)] Starting MongoDB backup..."

# Perform backup
docker exec medinovai-mongodb mongodump \
  --username=medinovai \
  --password=${MONGO_PASSWORD:-medinovai_mongo_2025_secure} \
  --authenticationDatabase=admin \
  --out=/tmp/${BACKUP_NAME}

# Copy backup from container
docker cp medinovai-mongodb:/tmp/${BACKUP_NAME} "${BACKUP_DIR}/${BACKUP_NAME}"

# Compress backup
tar -czf "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" -C "$BACKUP_DIR" "$BACKUP_NAME"
rm -rf "${BACKUP_DIR}/${BACKUP_NAME}"

echo "[$(date)] Backup completed: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"

# Upload to MinIO
if command -v mc &> /dev/null; then
  echo "[$(date)] Uploading to MinIO..."
  mc cp "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" minio/medinovai-backups/mongodb/
fi

# Cleanup old backups
find "$BACKUP_DIR" -name "mongodb_backup_*.tar.gz" -mtime +${RETENTION_DAYS} -delete

echo "[$(date)] MongoDB backup complete!"

