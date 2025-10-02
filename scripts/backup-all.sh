#!/bin/bash
# Master Backup Script for All MedinovAI Services
# Part of MedinovAI Infrastructure v2.0

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/medinovai/backups.log"

mkdir -p "$(dirname "$LOG_FILE")"

echo "========================================" | tee -a "$LOG_FILE"
echo "[$(date)] Starting MedinovAI Full Backup" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Backup PostgreSQL
echo "[$(date)] Backing up PostgreSQL..." | tee -a "$LOG_FILE"
bash "${SCRIPT_DIR}/backup-postgres.sh" 2>&1 | tee -a "$LOG_FILE"

# Backup MongoDB
echo "[$(date)] Backing up MongoDB..." | tee -a "$LOG_FILE"
bash "${SCRIPT_DIR}/backup-mongodb.sh" 2>&1 | tee -a "$LOG_FILE"

# Backup TimescaleDB
echo "[$(date)] Backing up TimescaleDB..." | tee -a "$LOG_FILE"
docker exec medinovai-timescaledb pg_dump \
  -U medinovai \
  -d medinovai_timeseries \
  --format=custom \
  > /tmp/backups/timescaledb/timescaledb_backup_$(date +%Y%m%d_%H%M%S).sql

# Backup Redis (RDB snapshot)
echo "[$(date)] Backing up Redis..." | tee -a "$LOG_FILE"
docker exec medinovai-redis redis-cli BGSAVE
sleep 5
docker cp medinovai-redis:/data/dump.rdb /tmp/backups/redis/dump_$(date +%Y%m%d_%H%M%S).rdb

# Backup Vault data
echo "[$(date)] Backing up Vault..." | tee -a "$LOG_FILE"
docker exec medinovai-vault vault operator raft snapshot save /tmp/vault_snapshot_$(date +%Y%m%d_%H%M%S) || true

echo "========================================" | tee -a "$LOG_FILE"
echo "[$(date)] MedinovAI Full Backup Complete!" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

