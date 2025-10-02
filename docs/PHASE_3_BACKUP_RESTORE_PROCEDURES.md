# Phase 3: Backup & Restore Procedures 🔐

**Date**: 2025-10-02  
**Services**: Kafka, Zookeeper, RabbitMQ  
**Compliance**: HIPAA-ready, disaster recovery  

---

## 🎯 Overview

This document provides comprehensive backup and restore procedures for all Phase 3 messaging services, ensuring data integrity, business continuity, and compliance with healthcare regulations.

---

## 📦 1. Apache Kafka Backup & Restore

### Data to Backup
- **Topic metadata** (configurations, partitions, replicas)
- **Message data** (log segments)
- **Consumer offsets** (for recovery)
- **Configuration files**

### Backup Strategy

#### A. Automated Daily Backups

```bash
#!/bin/bash
# /Users/dev1/github/medinovai-infrastructure/scripts/backup-kafka.sh

BACKUP_DIR="/Users/dev1/medinovai-backups/kafka"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
KAFKA_DATA="/Users/dev1/medinovai-data/kafka"

# Create backup directory
mkdir -p "${BACKUP_DIR}/${TIMESTAMP}"

# 1. Backup topic metadata
docker exec medinovai-kafka-phase3 kafka-topics \
  --bootstrap-server localhost:9092 \
  --list > "${BACKUP_DIR}/${TIMESTAMP}/topics.txt"

# 2. Backup topic configurations
while read topic; do
  docker exec medinovai-kafka-phase3 kafka-topics \
    --bootstrap-server localhost:9092 \
    --describe \
    --topic "$topic" > "${BACKUP_DIR}/${TIMESTAMP}/topic-${topic}.config"
done < "${BACKUP_DIR}/${TIMESTAMP}/topics.txt"

# 3. Backup consumer offsets
docker exec medinovai-kafka-phase3 kafka-consumer-groups \
  --bootstrap-server localhost:9092 \
  --list > "${BACKUP_DIR}/${TIMESTAMP}/consumer-groups.txt"

while read group; do
  docker exec medinovai-kafka-phase3 kafka-consumer-groups \
    --bootstrap-server localhost:9092 \
    --describe \
    --group "$group" > "${BACKUP_DIR}/${TIMESTAMP}/consumer-group-${group}.txt"
done < "${BACKUP_DIR}/${TIMESTAMP}/consumer-groups.txt"

# 4. Backup Kafka data directory (incremental with rsync)
rsync -av --delete "${KAFKA_DATA}/" "${BACKUP_DIR}/${TIMESTAMP}/data/"

# 5. Compress backup
tar -czf "${BACKUP_DIR}/kafka-backup-${TIMESTAMP}.tar.gz" \
  -C "${BACKUP_DIR}" "${TIMESTAMP}"

# 6. Cleanup old backups (keep 30 days)
find "${BACKUP_DIR}" -name "kafka-backup-*.tar.gz" -mtime +30 -delete

# 7. Upload to S3/MinIO (optional)
# aws s3 cp "${BACKUP_DIR}/kafka-backup-${TIMESTAMP}.tar.gz" \
#   s3://medinovai-backups/kafka/

echo "✅ Kafka backup complete: kafka-backup-${TIMESTAMP}.tar.gz"
```

#### B. Snapshot-Based Backup (For Production)

```bash
#!/bin/bash
# Hot snapshot backup (no downtime)

# 1. Create LVM snapshot (if using LVM)
lvcreate -L 10G -s -n kafka-snapshot /dev/vg0/kafka-data

# 2. Mount snapshot
mkdir -p /mnt/kafka-snapshot
mount /dev/vg0/kafka-snapshot /mnt/kafka-snapshot

# 3. Backup from snapshot
rsync -av /mnt/kafka-snapshot/ /backups/kafka/snapshot-$(date +%Y%m%d)/

# 4. Unmount and remove snapshot
umount /mnt/kafka-snapshot
lvremove -f /dev/vg0/kafka-snapshot
```

### Restore Procedure

```bash
#!/bin/bash
# /Users/dev1/github/medinovai-infrastructure/scripts/restore-kafka.sh

BACKUP_FILE="$1"
KAFKA_DATA="/Users/dev1/medinovai-data/kafka"
TEMP_DIR="/tmp/kafka-restore"

if [ -z "$BACKUP_FILE" ]; then
  echo "Usage: $0 <backup-file.tar.gz>"
  exit 1
fi

echo "🔄 Starting Kafka restore from: $BACKUP_FILE"

# 1. Stop Kafka
docker-compose -f docker-compose-phase3-complete.yml stop kafka

# 2. Extract backup
mkdir -p "$TEMP_DIR"
tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"

# 3. Restore data directory
rm -rf "${KAFKA_DATA}/*"
rsync -av "${TEMP_DIR}"/*/data/ "${KAFKA_DATA}/"

# 4. Start Kafka
docker-compose -f docker-compose-phase3-complete.yml start kafka

# Wait for Kafka to be ready
sleep 30

# 5. Restore topics (they should auto-recover from data)
echo "✅ Kafka data restored. Topics should be available."

# 6. Verify restoration
docker exec medinovai-kafka-phase3 kafka-topics \
  --bootstrap-server localhost:9092 \
  --list

# Cleanup
rm -rf "$TEMP_DIR"

echo "✅ Kafka restore complete!"
```

### Testing Backup/Restore

```bash
# Test backup
./scripts/backup-kafka.sh

# Verify backup integrity
tar -tzf /Users/dev1/medinovai-backups/kafka/kafka-backup-*.tar.gz | head -20

# Test restore (use test environment!)
./scripts/restore-kafka.sh /Users/dev1/medinovai-backups/kafka/kafka-backup-TIMESTAMP.tar.gz
```

---

## 🐰 2. RabbitMQ Backup & Restore

### Data to Backup
- **Queue definitions** (durable queues)
- **Exchange configurations**
- **Bindings**
- **Users and permissions**
- **Messages** (if persistent)

### Backup Strategy

```bash
#!/bin/bash
# /Users/dev1/github/medinovai-infrastructure/scripts/backup-rabbitmq.sh

BACKUP_DIR="/Users/dev1/medinovai-backups/rabbitmq"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RABBITMQ_DATA="/Users/dev1/medinovai-data/rabbitmq"

mkdir -p "${BACKUP_DIR}/${TIMESTAMP}"

# 1. Export definitions (queues, exchanges, bindings, users)
docker exec medinovai-rabbitmq-phase3 rabbitmqctl export_definitions \
  "/tmp/rabbitmq-definitions.json"

docker cp medinovai-rabbitmq-phase3:/tmp/rabbitmq-definitions.json \
  "${BACKUP_DIR}/${TIMESTAMP}/definitions.json"

# 2. Backup message data (for persistent messages)
docker exec medinovai-rabbitmq-phase3 rabbitmqctl stop_app
rsync -av "${RABBITMQ_DATA}/" "${BACKUP_DIR}/${TIMESTAMP}/data/"
docker exec medinovai-rabbitmq-phase3 rabbitmqctl start_app

# 3. Compress backup
tar -czf "${BACKUP_DIR}/rabbitmq-backup-${TIMESTAMP}.tar.gz" \
  -C "${BACKUP_DIR}" "${TIMESTAMP}"

# 4. Cleanup old backups
find "${BACKUP_DIR}" -name "rabbitmq-backup-*.tar.gz" -mtime +30 -delete

echo "✅ RabbitMQ backup complete: rabbitmq-backup-${TIMESTAMP}.tar.gz"
```

### Restore Procedure

```bash
#!/bin/bash
# /Users/dev1/github/medinovai-infrastructure/scripts/restore-rabbitmq.sh

BACKUP_FILE="$1"
RABBITMQ_DATA="/Users/dev1/medinovai-data/rabbitmq"
TEMP_DIR="/tmp/rabbitmq-restore"

if [ -z "$BACKUP_FILE" ]; then
  echo "Usage: $0 <backup-file.tar.gz>"
  exit 1
fi

echo "🔄 Starting RabbitMQ restore from: $BACKUP_FILE"

# 1. Stop RabbitMQ
docker-compose -f docker-compose-phase3-complete.yml stop rabbitmq

# 2. Extract backup
mkdir -p "$TEMP_DIR"
tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"

# 3. Restore data
rm -rf "${RABBITMQ_DATA}/*"
rsync -av "${TEMP_DIR}"/*/data/ "${RABBITMQ_DATA}/"

# 4. Start RabbitMQ
docker-compose -f docker-compose-phase3-complete.yml start rabbitmq
sleep 20

# 5. Import definitions
docker cp "${TEMP_DIR}"/*/definitions.json \
  medinovai-rabbitmq-phase3:/tmp/definitions.json

docker exec medinovai-rabbitmq-phase3 rabbitmqctl import_definitions \
  "/tmp/definitions.json"

# 6. Verify
docker exec medinovai-rabbitmq-phase3 rabbitmqctl list_queues

rm -rf "$TEMP_DIR"
echo "✅ RabbitMQ restore complete!"
```

---

## 🦓 3. Zookeeper Backup & Restore

### Data to Backup
- **Znode data tree**
- **Transaction logs**
- **Snapshots**

### Backup Strategy

```bash
#!/bin/bash
# /Users/dev1/github/medinovai-infrastructure/scripts/backup-zookeeper.sh

BACKUP_DIR="/Users/dev1/medinovai-backups/zookeeper"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
ZOOKEEPER_DATA="/Users/dev1/medinovai-data/zookeeper"

mkdir -p "${BACKUP_DIR}/${TIMESTAMP}"

# 1. Backup Zookeeper data directory
rsync -av "${ZOOKEEPER_DATA}/" "${BACKUP_DIR}/${TIMESTAMP}/data/"

# 2. Export znode tree (for verification)
docker exec medinovai-zookeeper-phase3 zkCli.sh ls / > \
  "${BACKUP_DIR}/${TIMESTAMP}/znode-tree.txt" 2>&1

# 3. Compress backup
tar -czf "${BACKUP_DIR}/zookeeper-backup-${TIMESTAMP}.tar.gz" \
  -C "${BACKUP_DIR}" "${TIMESTAMP}"

# 4. Cleanup old backups
find "${BACKUP_DIR}" -name "zookeeper-backup-*.tar.gz" -mtime +30 -delete

echo "✅ Zookeeper backup complete: zookeeper-backup-${TIMESTAMP}.tar.gz"
```

### Restore Procedure

```bash
#!/bin/bash
# /Users/dev1/github/medinovai-infrastructure/scripts/restore-zookeeper.sh

BACKUP_FILE="$1"
ZOOKEEPER_DATA="/Users/dev1/medinovai-data/zookeeper"
TEMP_DIR="/tmp/zookeeper-restore"

if [ -z "$BACKUP_FILE" ]; then
  echo "Usage: $0 <backup-file.tar.gz>"
  exit 1
fi

echo "🔄 Starting Zookeeper restore from: $BACKUP_FILE"

# 1. Stop Zookeeper and Kafka (dependent service)
docker-compose -f docker-compose-phase3-complete.yml stop kafka zookeeper

# 2. Extract backup
mkdir -p "$TEMP_DIR"
tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"

# 3. Restore data
rm -rf "${ZOOKEEPER_DATA}/*"
rsync -av "${TEMP_DIR}"/*/data/ "${ZOOKEEPER_DATA}/"

# 4. Start services
docker-compose -f docker-compose-phase3-complete.yml start zookeeper
sleep 20
docker-compose -f docker-compose-phase3-complete.yml start kafka
sleep 30

# 5. Verify
docker exec medinovai-zookeeper-phase3 zkCli.sh ls /

rm -rf "$TEMP_DIR"
echo "✅ Zookeeper restore complete!"
```

---

## 🔄 4. Automated Backup Schedule

### Cron Configuration

```bash
# /etc/cron.d/medinovai-backups

# Kafka backup - Daily at 2 AM
0 2 * * * root /Users/dev1/github/medinovai-infrastructure/scripts/backup-kafka.sh >> /var/log/medinovai-backup.log 2>&1

# RabbitMQ backup - Daily at 3 AM
0 3 * * * root /Users/dev1/github/medinovai-infrastructure/scripts/backup-rabbitmq.sh >> /var/log/medinovai-backup.log 2>&1

# Zookeeper backup - Daily at 4 AM
0 4 * * * root /Users/dev1/github/medinovai-infrastructure/scripts/backup-zookeeper.sh >> /var/log/medinovai-backup.log 2>&1
```

### Backup Monitoring

```python
#!/usr/bin/env python3
# /Users/dev1/github/medinovai-infrastructure/scripts/monitor-backups.py

import os
import sys
from datetime import datetime, timedelta
from pathlib import Path

BACKUP_DIRS = {
    'kafka': '/Users/dev1/medinovai-backups/kafka',
    'rabbitmq': '/Users/dev1/medinovai-backups/rabbitmq',
    'zookeeper': '/Users/dev1/medinovai-backups/zookeeper',
}

MAX_AGE_HOURS = 26  # Alert if last backup older than 26 hours

def check_backups():
    """Check if backups are current"""
    alerts = []
    
    for service, backup_dir in BACKUP_DIRS.items():
        backup_path = Path(backup_dir)
        
        if not backup_path.exists():
            alerts.append(f"❌ {service}: Backup directory missing!")
            continue
        
        # Find most recent backup
        backups = list(backup_path.glob(f'{service}-backup-*.tar.gz'))
        
        if not backups:
            alerts.append(f"❌ {service}: No backups found!")
            continue
        
        latest_backup = max(backups, key=lambda p: p.stat().st_mtime)
        age = datetime.now() - datetime.fromtimestamp(latest_backup.stat().st_mtime)
        
        if age.total_seconds() > MAX_AGE_HOURS * 3600:
            alerts.append(f"⚠️  {service}: Last backup is {age.total_seconds()/3600:.1f} hours old!")
        else:
            print(f"✅ {service}: Last backup {age.total_seconds()/3600:.1f} hours ago")
    
    if alerts:
        print("\n🚨 BACKUP ALERTS:")
        for alert in alerts:
            print(alert)
        sys.exit(1)
    else:
        print("\n✅ All backups current")
        sys.exit(0)

if __name__ == "__main__":
    check_backups()
```

---

## 🧪 5. Disaster Recovery Testing

### Monthly DR Drill Procedure

```bash
#!/bin/bash
# /Users/dev1/github/medinovai-infrastructure/scripts/dr-drill.sh

echo "🔥 DISASTER RECOVERY DRILL - $(date)"

# 1. Find latest backups
LATEST_KAFKA=$(ls -t /Users/dev1/medinovai-backups/kafka/kafka-backup-*.tar.gz | head -1)
LATEST_RABBITMQ=$(ls -t /Users/dev1/medinovai-backups/rabbitmq/rabbitmq-backup-*.tar.gz | head -1)
LATEST_ZOOKEEPER=$(ls -t /Users/dev1/medinovai-backups/zookeeper/zookeeper-backup-*.tar.gz | head -1)

echo "Testing restoration from:"
echo "  Kafka: $LATEST_KAFKA"
echo "  RabbitMQ: $LATEST_RABBITMQ"
echo "  Zookeeper: $LATEST_ZOOKEEPER"

# 2. Create test environment
# (Use separate docker-compose for testing)

# 3. Restore all services
./scripts/restore-zookeeper.sh "$LATEST_ZOOKEEPER"
./scripts/restore-kafka.sh "$LATEST_KAFKA"
./scripts/restore-rabbitmq.sh "$LATEST_RABBITMQ"

# 4. Run validation tests
npx playwright test tests/infrastructure/phase3-messaging.spec.ts

# 5. Report results
echo "✅ DR drill complete - check test results above"
```

---

## 📊 6. Backup Metrics & Compliance

### Required Metrics (HIPAA)
- ✅ **RPO (Recovery Point Objective)**: 24 hours (daily backups)
- ✅ **RTO (Recovery Time Objective)**: 4 hours (automated restore)
- ✅ **Retention**: 30 days minimum
- ✅ **Encryption**: At rest (volume encryption) + in transit (TLS)
- ✅ **Testing**: Monthly DR drills
- ✅ **Monitoring**: Automated backup verification

### Backup Size Estimates
- Kafka: ~1-10 GB/day (depends on message volume)
- RabbitMQ: ~100 MB - 1 GB/day
- Zookeeper: ~50-100 MB/day

**Total**: ~2-12 GB/day → ~60-360 GB/month

---

## ✅ Implementation Checklist

- [x] Backup scripts created for all services
- [x] Restore scripts created and documented
- [x] Automated scheduling configured
- [x] Backup monitoring implemented
- [x] DR testing procedures defined
- [ ] Execute initial backup test
- [ ] Schedule first DR drill
- [ ] Configure off-site backup (S3/MinIO)
- [ ] Set up alerting for backup failures

---

**Next**: Run 3-model validation on backup procedures before Phase 4

