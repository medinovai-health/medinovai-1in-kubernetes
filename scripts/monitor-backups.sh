#!/bin/bash
# Backup Monitoring & Alerting Script
# Monitors backup health and alerts on failures

set -e

BACKUP_DIRS=(
  "/Users/dev1/medinovai-backups/kafka"
  "/Users/dev1/medinovai-backups/rabbitmq"
  "/Users/dev1/medinovai-backups/zookeeper"
)

MAX_AGE_HOURS=26
ALERT_LOG="/Users/dev1/github/medinovai-infrastructure/logs/backup-alerts.log"
STATUS_FILE="/Users/dev1/github/medinovai-infrastructure/logs/backup-status.json"

mkdir -p "$(dirname ${ALERT_LOG})"
mkdir -p "$(dirname ${STATUS_FILE})"

echo "🔍 Backup Monitoring Check - $(date)"
echo "====================================="

ALERTS=()
STATUS_DATA="{"

# Check each backup directory
for backup_dir in "${BACKUP_DIRS[@]}"; do
  service=$(basename "$backup_dir")
  echo "Checking ${service}..."
  
  if [ ! -d "$backup_dir" ]; then
    ALERTS+=("❌ ${service}: Backup directory missing!")
    STATUS_DATA+="\"${service}\":{\"status\":\"ERROR\",\"message\":\"Directory missing\"},"
    continue
  fi
  
  # Find most recent backup
  latest_backup=$(find "$backup_dir" -name "${service}-backup-*.tar.gz" -type f 2>/dev/null | sort -r | head -1)
  
  if [ -z "$latest_backup" ]; then
    ALERTS+=("❌ ${service}: No backups found!")
    STATUS_DATA+="\"${service}\":{\"status\":\"ERROR\",\"message\":\"No backups found\"},"
    continue
  fi
  
  # Check backup age
  backup_time=$(stat -f %m "$latest_backup" 2>/dev/null || stat -c %Y "$latest_backup" 2>/dev/null)
  current_time=$(date +%s)
  age_hours=$(( (current_time - backup_time) / 3600 ))
  
  # Check backup size
  backup_size=$(du -sh "$latest_backup" | awk '{print $1}')
  
  if [ $age_hours -gt $MAX_AGE_HOURS ]; then
    ALERTS+=("⚠️  ${service}: Last backup is ${age_hours} hours old (threshold: ${MAX_AGE_HOURS}h)")
    STATUS_DATA+="\"${service}\":{\"status\":\"WARNING\",\"age_hours\":${age_hours},\"size\":\"${backup_size}\",\"file\":\"$(basename $latest_backup)\"},"
  else
    echo "  ✅ ${service}: Last backup ${age_hours}h ago, size ${backup_size}"
    STATUS_DATA+="\"${service}\":{\"status\":\"OK\",\"age_hours\":${age_hours},\"size\":\"${backup_size}\",\"file\":\"$(basename $latest_backup)\"},"
  fi
done

# Close JSON
STATUS_DATA="${STATUS_DATA%,}}"
echo "$STATUS_DATA" > "$STATUS_FILE"

# Report alerts
if [ ${#ALERTS[@]} -gt 0 ]; then
  echo ""
  echo "🚨 BACKUP ALERTS:"
  for alert in "${ALERTS[@]}"; do
    echo "$alert"
    echo "$(date): $alert" >> "$ALERT_LOG"
  done
  
  # Send notification (configure your alerting here)
  # Examples:
  # - Slack webhook
  # - Email via sendmail
  # - PagerDuty
  # - AWS SNS
  
  # Example: Slack webhook (uncomment and configure)
  # SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
  # curl -X POST -H 'Content-type: application/json' \
  #   --data "{\"text\":\"🚨 Backup Alert:\n$(printf '%s\n' "${ALERTS[@]}")\"}" \
  #   "$SLACK_WEBHOOK"
  
  exit 1
else
  echo ""
  echo "✅ All backups current and healthy"
  echo "$(date): All backups OK" >> "$ALERT_LOG"
  exit 0
fi

