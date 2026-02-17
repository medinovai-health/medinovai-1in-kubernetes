#!/usr/bin/env bash
# ─── rotate_secrets.sh ────────────────────────────────────────────────────────
# Rotate secrets that are approaching or past their rotation deadline.
#
# Usage:
#   bash scripts/maintenance/rotate_secrets.sh
#   bash scripts/maintenance/rotate_secrets.sh --dry-run
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

DRY_RUN=false
ROTATION_DAYS=90
CLOUD="aws"

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)          DRY_RUN=true; shift ;;
        --rotation-days)    ROTATION_DAYS="$2"; shift 2 ;;
        --cloud)            CLOUD="$2"; shift 2 ;;
        *)                  echo "Unknown option: $1"; exit 1 ;;
    esac
done

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          Secret Rotation Check                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Rotation policy: every $ROTATION_DAYS days"
echo ""

case "$CLOUD" in
    aws)
        echo "▸ Checking AWS Secrets Manager..."
        SECRETS=$(aws secretsmanager list-secrets --query 'SecretList[?starts_with(Name, `medinovai/`)].{Name:Name,LastRotated:LastRotatedDate,LastChanged:LastChangedDate}' --output json 2>/dev/null || echo "[]")

        if [ "$SECRETS" = "[]" ]; then
            echo "  No MedinovAI secrets found in Secrets Manager."
            exit 0
        fi

        THRESHOLD_DATE=$(date -u -d "-${ROTATION_DAYS} days" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-${ROTATION_DAYS}d +%Y-%m-%dT%H:%M:%SZ)

        echo "$SECRETS" | python3 -c "
import json, sys
from datetime import datetime, timedelta, timezone

secrets = json.load(sys.stdin)
threshold = datetime.now(timezone.utc) - timedelta(days=$ROTATION_DAYS)
needs_rotation = []
ok = []

for s in secrets:
    name = s['Name']
    last_date = s.get('LastRotated') or s.get('LastChanged')
    if last_date:
        last_dt = datetime.fromisoformat(last_date.replace('Z', '+00:00'))
        days_since = (datetime.now(timezone.utc) - last_dt).days
        if last_dt < threshold:
            needs_rotation.append((name, days_since))
        else:
            ok.append((name, days_since))
    else:
        needs_rotation.append((name, -1))

for name, days in ok:
    print(f'  ✓ {name} — rotated {days} days ago')

for name, days in needs_rotation:
    if days == -1:
        print(f'  ✗ {name} — NEVER ROTATED')
    else:
        print(f'  ✗ {name} — {days} days since last rotation (exceeds {$ROTATION_DAYS}d policy)')

if needs_rotation:
    print(f'\nALERT: {len(needs_rotation)} secret(s) need rotation!')
    sys.exit(2)
else:
    print(f'\n✓ All secrets within rotation policy.')
"
        ;;
    *)
        echo "Secret rotation check for $CLOUD not yet implemented."
        ;;
esac
