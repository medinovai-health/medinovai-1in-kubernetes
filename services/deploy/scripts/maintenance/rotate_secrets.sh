#!/usr/bin/env bash
# ─── rotate_secrets.sh ────────────────────────────────────────────────────────
# Rotate secrets approaching or past their rotation deadline.
# Supports on-prem Vault (primary) and AWS Secrets Manager (legacy).
#
# Usage:
#   bash scripts/maintenance/rotate_secrets.sh
#   bash scripts/maintenance/rotate_secrets.sh --dry-run
#   bash scripts/maintenance/rotate_secrets.sh --backend vault
#   bash scripts/maintenance/rotate_secrets.sh --backend aws
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

DRY_RUN=false
ROTATION_DAYS=90
BACKEND="vault"
DEPLOY_HOME="${DEPLOY_HOME:-$HOME/.medinovai-deploy}"
VAULT_DIR="$DEPLOY_HOME/vault"

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)          DRY_RUN=true; shift ;;
        --rotation-days)    ROTATION_DAYS="$2"; shift 2 ;;
        --backend)          BACKEND="$2"; shift 2 ;;
        *)                  echo "Unknown option: $1"; exit 1 ;;
    esac
done

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          Secret Rotation Check                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Backend:         $BACKEND"
echo "Rotation policy: every $ROTATION_DAYS days"
echo "Dry run:         $DRY_RUN"
echo ""

vault_rotation_check() {
    echo "▸ Checking Vault secrets (medinovai-secrets/)..."

    local root_token=""
    if [ -f "$VAULT_DIR/init-keys.json" ]; then
        root_token=$(jq -r '.root_token' "$VAULT_DIR/init-keys.json" 2>/dev/null || echo "")
    fi

    if [ -z "$root_token" ] && [ -z "${VAULT_TOKEN:-}" ]; then
        echo "  ERROR: No Vault token available."
        echo "  Set VAULT_TOKEN or ensure $VAULT_DIR/init-keys.json exists."
        exit 1
    fi

    export VAULT_TOKEN="${VAULT_TOKEN:-$root_token}"

    local needs_port_forward=false
    if [ -z "${VAULT_ADDR:-}" ]; then
        export VAULT_ADDR="http://127.0.0.1:8200"
        kubectl port-forward svc/vault -n vault 8200:8200 &>/dev/null &
        local pf_pid=$!
        needs_port_forward=true
        sleep 3
    fi

    local secret_paths=(
        "atlasos/anthropic"
        "atlasos/openai"
        "atlasos/google-ai"
        "atlasos/mattermost"
        "atlasos/slack"
        "atlasos/hooks"
        "atlasos/threecx"
        "atlasos/whatsapp"
        "atlasos/voice"
        "atlasos/crm"
        "atlasos/ticketing"
        "atlasos/accounting"
        "atlasos/gmail"
        "atlasos/stirling-pdf"
        "atlasos/arena"
        "infra/postgres-primary"
        "infra/postgres-clinical"
        "infra/redis"
        "infra/kafka"
        "security/keycloak"
        "security/jwt"
        "ai-ml/aifactory"
        "ai-ml/ollama"
        "platform/github"
        "platform/notification"
    )

    python3 -c "
import json, subprocess, sys
from datetime import datetime, timedelta, timezone

rotation_days = $ROTATION_DAYS
dry_run = $( $DRY_RUN && echo 'True' || echo 'False' )
threshold = datetime.now(timezone.utc) - timedelta(days=rotation_days)
paths = $(printf '%s\n' "${secret_paths[@]}" | python3 -c "import sys,json; print(json.dumps([l.strip() for l in sys.stdin]))")
needs_rotation = []
ok = []
errors = []

for path in paths:
    full_path = f'medinovai-secrets/{path}'
    result = subprocess.run(
        ['vault', 'kv', 'metadata', 'get', '-format=json', full_path],
        capture_output=True, text=True, timeout=10
    )
    if result.returncode != 0:
        errors.append((path, 'not found or error'))
        continue

    try:
        meta = json.loads(result.stdout)
        updated = meta.get('data', {}).get('updated_time', '')
        if updated:
            updated_dt = datetime.fromisoformat(updated.replace('Z', '+00:00'))
            days_since = (datetime.now(timezone.utc) - updated_dt).days
            if updated_dt < threshold:
                needs_rotation.append((path, days_since))
            else:
                ok.append((path, days_since))
        else:
            needs_rotation.append((path, -1))
    except (json.JSONDecodeError, ValueError):
        errors.append((path, 'parse error'))

for path, days in ok:
    print(f'  ✓ {path} — updated {days} days ago')

for path, days in needs_rotation:
    if days == -1:
        print(f'  ✗ {path} — NEVER UPDATED')
    else:
        print(f'  ✗ {path} — {days} days since last update (exceeds {rotation_days}d policy)')

for path, reason in errors:
    print(f'  ⚠ {path} — {reason}')

print()
if needs_rotation:
    print(f'ALERT: {len(needs_rotation)} secret(s) need rotation!')
    if not dry_run:
        print()
        print('To rotate a secret:')
        print('  vault kv put medinovai-secrets/<path> KEY=new-value')
        print()
        print('Or trigger ESO refresh:')
        print('  kubectl annotate externalsecret <name> -n <ns> force-sync=\$(date +%s) --overwrite')
    sys.exit(2)
else:
    print(f'✓ All {len(ok)} secrets within rotation policy ({rotation_days} days).')
    if errors:
        print(f'  ({len(errors)} paths had errors — check Vault seeding)')
"

    if $needs_port_forward; then
        kill $pf_pid 2>/dev/null || true
    fi
}

aws_rotation_check() {
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
}

case "$BACKEND" in
    vault)  vault_rotation_check ;;
    aws)    aws_rotation_check ;;
    *)      echo "Unknown backend: $BACKEND (use: vault, aws)"; exit 1 ;;
esac
