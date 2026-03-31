#!/usr/bin/env bash
set -euo pipefail

# Master orchestrator: Roll out MedinovAI standards to all repos by tier.
# Usage: ./rollout-all.sh [--tier <N>] [--push] [--dry-run]
#
# Options:
#   --tier <N>   Only roll out to tier N (0-4). Default: all tiers.
#   --push       Push branches to origin after commit.
#   --dry-run    Show what would happen without making changes.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BRAIN_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CLONE_DIR="$HOME/medinovai-all-repos"
CATALOG="$BRAIN_DIR/registry/platform-catalog.yaml"

TIER_FILTER=""
PUSH_FLAG=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --tier) TIER_FILTER="$2"; shift 2 ;;
    --push) PUSH_FLAG=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

echo "=============================================="
echo "MedinovAI Organization-Wide Standards Rollout"
echo "=============================================="
echo "Brain repo: $BRAIN_DIR"
echo "Clone dir:  $CLONE_DIR"
echo "Tier filter: ${TIER_FILTER:-all}"
echo "Push: $PUSH_FLAG"
echo "Dry run: $DRY_RUN"
echo ""

REPORT_FILE="$BRAIN_DIR/standards-rollout-package/ROLLOUT_LOG_$(date +%Y%m%d_%H%M%S).txt"
SUMMARY_SUCCESS=0
SUMMARY_SKIP=0
SUMMARY_FAIL=0

log() {
  echo "$1" | tee -a "$REPORT_FILE"
}

python3 -c "
import yaml, json

with open('$CATALOG') as f:
    catalog = yaml.safe_load(f)

repos = catalog.get('repos', {})
result = []
for repo_id, meta in repos.items():
    status = meta.get('status', 'active')
    if status in ('archived', 'deprecated'):
        continue
    tier = meta.get('tier', 99)
    tier_filter = '$TIER_FILTER'
    if tier_filter and str(tier) != tier_filter:
        continue
    result.append({
        'id': repo_id,
        'old_name': meta.get('old_name', repo_id),
        'tier': tier,
        'category': meta.get('category', 'unknown'),
        'lang': meta.get('lang', 'unknown')
    })

result.sort(key=lambda x: (x['tier'], x['old_name']))

with open('/tmp/rollout_targets.json', 'w') as f:
    json.dump(result, f, indent=2)

print(f'Targets: {len(result)} repos')
"

TARGETS=$(python3 -c "
import json
with open('/tmp/rollout_targets.json') as f:
    targets = json.load(f)
for t in targets:
    print(f\"{t['old_name']}|{t['id']}|{t['tier']}|{t['category']}|{t['lang']}\")
")

TOTAL=$(echo "$TARGETS" | wc -l | tr -d ' ')
CURRENT=0

log "Starting rollout: $TOTAL repos"
log "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
log ""

while IFS='|' read -r OLD_NAME REPO_ID TIER CATEGORY LANG_VAL; do
  CURRENT=$((CURRENT + 1))
  REPO_DIR="$CLONE_DIR/$OLD_NAME"

  log "[$CURRENT/$TOTAL] $OLD_NAME (tier=$TIER)"

  if [ ! -d "$REPO_DIR" ]; then
    log "  SKIP — not cloned locally"
    SUMMARY_SKIP=$((SUMMARY_SKIP + 1))
    continue
  fi

  if [ "$DRY_RUN" = "true" ]; then
    log "  DRY-RUN — would apply standards"
    SUMMARY_SUCCESS=$((SUMMARY_SUCCESS + 1))
    continue
  fi

  if bash "$SCRIPT_DIR/rollout-to-repo.sh" "$REPO_DIR" "$REPO_ID" "$OLD_NAME" "$TIER" "$CATEGORY" "$LANG_VAL" >> "$REPORT_FILE" 2>&1; then
    SUMMARY_SUCCESS=$((SUMMARY_SUCCESS + 1))
    if [ "$PUSH_FLAG" = "true" ]; then
      cd "$REPO_DIR"
      git push -u origin "standards/org-rollout-2026-03" --quiet 2>/dev/null && log "  PUSHED" || log "  PUSH FAILED"
    fi
  else
    SUMMARY_FAIL=$((SUMMARY_FAIL + 1))
    log "  FAILED — see log for details"
  fi
done <<< "$TARGETS"

log ""
log "=============================================="
log "ROLLOUT SUMMARY"
log "=============================================="
log "Total repos:    $TOTAL"
log "Success:        $SUMMARY_SUCCESS"
log "Skipped:        $SUMMARY_SKIP"
log "Failed:         $SUMMARY_FAIL"
log "Log file:       $REPORT_FILE"
log "=============================================="
