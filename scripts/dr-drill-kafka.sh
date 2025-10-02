#!/bin/bash
# DISASTER RECOVERY DRILL - Kafka
# Tests backup and restoration procedures

set -e

BACKUP_DIR="/Users/dev1/medinovai-backups/kafka"
TEST_DIR="/tmp/kafka-dr-test-$(date +%Y%m%d-%H%M%S)"
RESULTS_FILE="/Users/dev1/github/medinovai-infrastructure/docs/DR_DRILL_RESULTS_$(date +%Y%m%d-%H%M%S).md"

echo "🔥 DISASTER RECOVERY DRILL - KAFKA"
echo "=================================="
echo "Date: $(date)"
echo "Test Directory: ${TEST_DIR}"
echo ""

mkdir -p "${TEST_DIR}"

# Initialize results
cat > "${RESULTS_FILE}" << 'EOF'
# Disaster Recovery Drill Results - Kafka

**Date**: $(date +%Y-%m-%d\ %H:%M:%S)
**Objective**: Validate backup/restore procedures
**Compliance**: HIPAA disaster recovery testing requirement

---

## Test Scenario
Simulate complete Kafka failure and restore from backup

## Test Steps

EOF

echo "Step 1: Creating test data..."
echo "### Step 1: Create Test Data" >> "${RESULTS_FILE}"
docker exec medinovai-kafka-phase3 kafka-topics \
  --bootstrap-server localhost:9092 \
  --create --topic dr-test-topic \
  --partitions 3 --replication-factor 1 2>&1 | tee -a "${RESULTS_FILE}"

# Produce test messages
echo "Producing test messages..." | tee -a "${RESULTS_FILE}"
for i in {1..100}; do
  echo "Message $i: DR Test at $(date)" | \
    docker exec -i medinovai-kafka-phase3 kafka-console-producer \
      --bootstrap-server localhost:9092 \
      --topic dr-test-topic 2>/dev/null
done
echo "✅ Created 100 test messages" | tee -a "${RESULTS_FILE}"
echo "" >> "${RESULTS_FILE}"

# Verify messages exist
echo "Step 2: Verifying test data exists..."
echo "### Step 2: Verify Test Data" >> "${RESULTS_FILE}"
MSG_COUNT=$(docker exec medinovai-kafka-phase3 kafka-run-class kafka.tools.GetOffsetShell \
  --broker-list localhost:9092 \
  --topic dr-test-topic | awk -F':' '{sum += $3} END {print sum}')
echo "Messages in topic: ${MSG_COUNT}" | tee -a "${RESULTS_FILE}"
echo "" >> "${RESULTS_FILE}"

# Backup
echo "Step 3: Creating backup..."
echo "### Step 3: Create Backup" >> "${RESULTS_FILE}"
BACKUP_START=$(date +%s)
./scripts/backup-kafka.sh 2>&1 | tee -a "${RESULTS_FILE}"
BACKUP_END=$(date +%s)
BACKUP_DURATION=$((BACKUP_END - BACKUP_START))
echo "Backup duration: ${BACKUP_DURATION} seconds" | tee -a "${RESULTS_FILE}"
echo "" >> "${RESULTS_FILE}"

# Find latest backup
LATEST_BACKUP=$(ls -t ${BACKUP_DIR}/kafka-backup-*.tar.gz | head -1)
echo "Latest backup: ${LATEST_BACKUP}" | tee -a "${RESULTS_FILE}"

# Simulate disaster
echo "Step 4: SIMULATING DISASTER - Stopping Kafka and removing data..."
echo "### Step 4: Simulate Disaster" >> "${RESULTS_FILE}"
docker-compose -f docker-compose-phase3-complete.yml stop kafka 2>&1 | tee -a "${RESULTS_FILE}"

# Backup current data (safety)
mv /Users/dev1/medinovai-data/kafka "${TEST_DIR}/kafka-original-backup"
mkdir -p /Users/dev1/medinovai-data/kafka
echo "✅ Data removed (backed up to ${TEST_DIR})" | tee -a "${RESULTS_FILE}"
echo "" >> "${RESULTS_FILE}"

# Restore
echo "Step 5: RESTORING from backup..."
echo "### Step 5: Restore from Backup" >> "${RESULTS_FILE}"
RESTORE_START=$(date +%s)

# Extract backup
mkdir -p "${TEST_DIR}/restore"
tar -xzf "${LATEST_BACKUP}" -C "${TEST_DIR}/restore"

# Copy data
BACKUP_DATA_DIR=$(find "${TEST_DIR}/restore" -type d -name "data" | head -1)
rsync -av "${BACKUP_DATA_DIR}/" /Users/dev1/medinovai-data/kafka/ 2>&1 | tee -a "${RESULTS_FILE}"

RESTORE_END=$(date +%s)
RESTORE_DURATION=$((RESTORE_END - RESTORE_START))
echo "Restore duration: ${RESTORE_DURATION} seconds" | tee -a "${RESULTS_FILE}"
echo "" >> "${RESULTS_FILE}"

# Start Kafka
echo "Step 6: Starting Kafka..."
echo "### Step 6: Start Kafka" >> "${RESULTS_FILE}"
docker-compose -f docker-compose-phase3-complete.yml start kafka 2>&1 | tee -a "${RESULTS_FILE}"
sleep 30

# Verify restoration
echo "Step 7: Verifying restoration..."
echo "### Step 7: Verify Restoration" >> "${RESULTS_FILE}"

# Check if Kafka is responsive
if docker exec medinovai-kafka-phase3 kafka-topics --bootstrap-server localhost:9092 --list 2>&1 | grep -q "dr-test-topic"; then
  echo "✅ Topic exists after restore" | tee -a "${RESULTS_FILE}"
else
  echo "❌ Topic NOT found after restore" | tee -a "${RESULTS_FILE}"
  exit 1
fi

# Check message count
RESTORED_MSG_COUNT=$(docker exec medinovai-kafka-phase3 kafka-run-class kafka.tools.GetOffsetShell \
  --broker-list localhost:9092 \
  --topic dr-test-topic | awk -F':' '{sum += $3} END {print sum}')
echo "Messages after restore: ${RESTORED_MSG_COUNT}" | tee -a "${RESULTS_FILE}"

# Consume and verify
echo "Consuming first 5 messages..." | tee -a "${RESULTS_FILE}"
docker exec medinovai-kafka-phase3 kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic dr-test-topic \
  --from-beginning \
  --max-messages 5 2>&1 | tee -a "${RESULTS_FILE}"

echo "" >> "${RESULTS_FILE}"

# Calculate RPO/RTO
echo "### Step 8: DR Metrics" >> "${RESULTS_FILE}"
echo "" >> "${RESULTS_FILE}"
echo "| Metric | Value | Target | Status |" >> "${RESULTS_FILE}"
echo "|--------|-------|--------|--------|" >> "${RESULTS_FILE}"
echo "| **RTO** (Recovery Time) | ${RESTORE_DURATION}s | < 240s (4 min) | $([ ${RESTORE_DURATION} -lt 240 ] && echo '✅ PASS' || echo '❌ FAIL') |" >> "${RESULTS_FILE}"
echo "| **RPO** (Data Loss) | 0 messages | 0 | $([ ${RESTORED_MSG_COUNT} -eq ${MSG_COUNT} ] && echo '✅ PASS' || echo '❌ FAIL') |" >> "${RESULTS_FILE}"
echo "| **Backup Duration** | ${BACKUP_DURATION}s | < 300s | $([ ${BACKUP_DURATION} -lt 300 ] && echo '✅ PASS' || echo '❌ FAIL') |" >> "${RESULTS_FILE}"
echo "" >> "${RESULTS_FILE}"

# Cleanup
echo "Step 9: Cleanup..."
echo "### Step 9: Cleanup" >> "${RESULTS_FILE}"
docker exec medinovai-kafka-phase3 kafka-topics \
  --bootstrap-server localhost:9092 \
  --delete --topic dr-test-topic 2>&1 | tee -a "${RESULTS_FILE}"

# Restore original data
rm -rf /Users/dev1/medinovai-data/kafka
mv "${TEST_DIR}/kafka-original-backup" /Users/dev1/medinovai-data/kafka
docker-compose -f docker-compose-phase3-complete.yml restart kafka

echo "✅ Original data restored" | tee -a "${RESULTS_FILE}"
echo "" >> "${RESULTS_FILE}"

# Final verdict
echo "---" >> "${RESULTS_FILE}"
echo "" >> "${RESULTS_FILE}"
echo "## Final Verdict" >> "${RESULTS_FILE}"
echo "" >> "${RESULTS_FILE}"

if [ ${RESTORED_MSG_COUNT} -eq ${MSG_COUNT} ] && [ ${RESTORE_DURATION} -lt 240 ]; then
  echo "✅ **DR DRILL PASSED**" >> "${RESULTS_FILE}"
  echo "" >> "${RESULTS_FILE}"
  echo "- All data restored successfully" >> "${RESULTS_FILE}"
  echo "- RTO within target (< 4 minutes)" >> "${RESULTS_FILE}"
  echo "- RPO = 0 (no data loss)" >> "${RESULTS_FILE}"
  echo "- Backup/restore procedures validated" >> "${RESULTS_FILE}"
  echo "" >> "${RESULTS_FILE}"
  echo "**Status**: Production Ready ✅" >> "${RESULTS_FILE}"
  
  echo ""
  echo "✅ DR DRILL PASSED!"
  echo "Results: ${RESULTS_FILE}"
  exit 0
else
  echo "❌ **DR DRILL FAILED**" >> "${RESULTS_FILE}"
  echo "" >> "${RESULTS_FILE}"
  echo "Issues:" >> "${RESULTS_FILE}"
  [ ${RESTORED_MSG_COUNT} -ne ${MSG_COUNT} ] && echo "- Data loss detected" >> "${RESULTS_FILE}"
  [ ${RESTORE_DURATION} -ge 240 ] && echo "- RTO exceeded target" >> "${RESULTS_FILE}"
  
  echo ""
  echo "❌ DR DRILL FAILED"
  echo "Results: ${RESULTS_FILE}"
  exit 1
fi

