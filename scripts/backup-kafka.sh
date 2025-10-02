#!/bin/bash
# Kafka Backup Script - Optimized with sparse file handling

BACKUP_DIR="/Users/dev1/medinovai-backups/kafka"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
KAFKA_DATA="/Users/dev1/medinovai-data/kafka"

mkdir -p "${BACKUP_DIR}/${TIMESTAMP}"

# 1. Backup topic metadata
docker exec medinovai-kafka-phase3 kafka-topics \
  --bootstrap-server localhost:9092 \
  --list > "${BACKUP_DIR}/${TIMESTAMP}/topics.txt" 2>&1

# 2. Backup consumer groups
docker exec medinovai-kafka-phase3 kafka-consumer-groups \
  --bootstrap-server localhost:9092 \
  --list > "${BACKUP_DIR}/${TIMESTAMP}/consumer-groups.txt" 2>&1

# 3. Backup data directory (SPARSE-AWARE)
rsync -avS --sparse "${KAFKA_DATA}/" "${BACKUP_DIR}/${TIMESTAMP}/data/" 2>&1

# 4. Compress (SPARSE-AWARE)
tar -czSf "${BACKUP_DIR}/kafka-backup-${TIMESTAMP}.tar.gz" \
  -C "${BACKUP_DIR}" "${TIMESTAMP}" 2>&1

# 5. Cleanup temporary directory
rm -rf "${BACKUP_DIR}/${TIMESTAMP}"

# 6. Cleanup old backups (keep 30 days)
find "${BACKUP_DIR}" -name "kafka-backup-*.tar.gz" -mtime +30 -delete

# 7. Report actual sizes
ACTUAL_SIZE=$(du -sh --apparent-size "${KAFKA_DATA}" 2>/dev/null | awk '{print $1}' || du -sh "${KAFKA_DATA}" | awk '{print $1}')
BACKUP_SIZE=$(du -sh "${BACKUP_DIR}/kafka-backup-${TIMESTAMP}.tar.gz" | awk '{print $1}')

echo "✅ Kafka backup complete: kafka-backup-${TIMESTAMP}.tar.gz"
echo "   Actual data: ${ACTUAL_SIZE}"
echo "   Backup size: ${BACKUP_SIZE}"
