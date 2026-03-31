#!/usr/bin/env bash
# ─── CEO Stack Vault Credential Seeder ────────────────────────────────────────
# Usage:
#   ./infra/scripts/seed-vault-credentials.sh [SYSTEM]
#
# Systems: vtiger | quickbooks | google | lis | mattermost | twilio | 3cx | all
#
# Example:
#   ./infra/scripts/seed-vault-credentials.sh vtiger
#   ./infra/scripts/seed-vault-credentials.sh all
#
# After seeding, recreate the relevant MCP container:
#   docker compose -f infra/docker/docker-compose.ceo.yml up -d --force-recreate mcp-vtiger
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

VAULT_ADDR="${VAULT_ADDR:-http://localhost:41100}"
VAULT_TOKEN="${VAULT_TOKEN:-medinovai-dev-token}"
SYSTEM="${1:-all}"

vault_put() {
    local path="$1"
    local -n data_ref="$2"
    local payload='{"data":{'
    local first=1
    for key in "${!data_ref[@]}"; do
        val="${data_ref[$key]}"
        [[ $first -eq 0 ]] && payload+=","
        payload+="\"$key\":\"$(echo "$val" | sed 's/"/\\"/g')\""
        first=0
    done
    payload+="}}"
    result=$(python3 -c "
import urllib.request, json, sys
req = urllib.request.Request('${VAULT_ADDR}/v1/medinovai-secrets/data/${path}',
    data=sys.stdin.buffer.read(), method='POST')
req.add_header('X-Vault-Token', '${VAULT_TOKEN}')
req.add_header('Content-Type', 'application/json')
try:
    with urllib.request.urlopen(req) as r:
        d = json.loads(r.read())
        print('OK version:', d['data']['version'])
except Exception as e:
    print('ERR:', e)
" <<< "$payload")
    echo "  $path: $result"
}

prompt_and_seed_vtiger() {
    echo ""
    echo "=== VTiger CRM ==="
    echo "Find your access key at: VTiger Admin > My Preferences > Access Credentials"
    read -r -p "  VTiger URL [https://crm.myonsitehealthcare.com]: " vtiger_url
    vtiger_url="${vtiger_url:-https://crm.myonsitehealthcare.com}"
    read -r -p "  VTiger username [Mayank]: " vtiger_username
    vtiger_username="${vtiger_username:-Mayank}"
    read -r -s -p "  VTiger access key: " vtiger_key
    echo ""
    declare -A vtiger_data=(
        ["url"]="$vtiger_url"
        ["username"]="$vtiger_username"
        ["access_key"]="$vtiger_key"
    )
    vault_put "atlasos/vtiger" vtiger_data
}

prompt_and_seed_quickbooks() {
    echo ""
    echo "=== QuickBooks Online ==="
    echo "Get OAuth tokens from: https://developer.intuit.com/app/developer/playground"
    read -r -p "  Client ID: " qb_client_id
    read -r -s -p "  Client Secret: " qb_secret
    echo ""
    read -r -s -p "  Refresh Token: " qb_refresh
    echo ""
    read -r -p "  Realm ID (Company ID): " qb_realm
    read -r -p "  Sandbox mode? [y/N]: " qb_sandbox
    qb_sandbox_val="false"
    [[ "${qb_sandbox,,}" == "y" ]] && qb_sandbox_val="true"
    declare -A qb_data=(
        ["client_id"]="$qb_client_id"
        ["client_secret"]="$qb_secret"
        ["refresh_token"]="$qb_refresh"
        ["realm_id"]="$qb_realm"
        ["sandbox"]="$qb_sandbox_val"
    )
    vault_put "atlasos/quickbooks" qb_data
}

prompt_and_seed_google() {
    echo ""
    echo "=== Google Workspace ==="
    echo "Create a service account at: console.cloud.google.com > IAM & Admin > Service Accounts"
    echo "Enable Calendar, Drive, Gmail APIs. Download service account JSON key."
    echo "Paste the entire JSON content (single line), then press Enter:"
    read -r -s sa_json
    echo ""
    read -r -p "  Calendar ID [primary]: " cal_id
    cal_id="${cal_id:-primary}"
    read -r -p "  Delegate user email (for domain-wide delegation): " delegate_user
    declare -A gws_data=(
        ["service_account_json"]="$sa_json"
        ["calendar_id"]="$cal_id"
        ["delegate_user"]="$delegate_user"
    )
    vault_put "atlasos/google-workspace" gws_data
}

prompt_and_seed_lis() {
    echo ""
    echo "=== LIS (Laboratory Information System) ==="
    read -r -p "  LIS API base URL (e.g. https://lis.mylab.com/api): " lis_url
    read -r -s -p "  LIS API key: " lis_key
    echo ""
    declare -A lis_data=(
        ["api_url"]="$lis_url"
        ["api_key"]="$lis_key"
    )
    vault_put "atlasos/lis" lis_data
}

prompt_and_seed_mattermost() {
    echo ""
    echo "=== Mattermost ==="
    read -r -p "  Mattermost URL (e.g. https://chat.medinovai.com): " mm_url
    read -r -s -p "  Bot token (System Console > Integrations > Bot Accounts): " mm_token
    echo ""
    read -r -p "  Team ID (optional, auto-detected if blank): " mm_team
    declare -A mm_data=(
        ["api_url"]="$mm_url"
        ["bot_token"]="$mm_token"
        ["team_id"]="$mm_team"
    )
    vault_put "atlasos/mattermost" mm_data
}

prompt_and_seed_twilio() {
    echo ""
    echo "=== Twilio ==="
    echo "Find credentials at: console.twilio.com"
    read -r -p "  Account SID (starts with AC...): " tw_sid
    read -r -s -p "  Auth Token: " tw_token
    echo ""
    read -r -p "  Phone number (E.164 format, e.g. +12488815445): " tw_phone
    declare -A tw_data=(
        ["account_sid"]="$tw_sid"
        ["auth_token"]="$tw_token"
        ["phone_number"]="$tw_phone"
    )
    vault_put "atlasos/twilio" tw_data
}

prompt_and_seed_3cx() {
    echo ""
    echo "=== 3CX PBX ==="
    echo "Find API credentials at: 3CX Admin Console > Integrations > API"
    read -r -p "  3CX base URL (e.g. https://pbx.medinovai.com): " cx_url
    read -r -p "  Client ID (DN/extension): " cx_client
    read -r -s -p "  API key: " cx_key
    echo ""
    declare -A cx_data=(
        ["base_url"]="$cx_url"
        ["client_id"]="$cx_client"
        ["api_key"]="$cx_key"
    )
    vault_put "atlasos/threecx" cx_data
}

echo "CEO Stack Vault Credential Seeder"
echo "Vault: $VAULT_ADDR"
echo ""

case "$SYSTEM" in
    vtiger)     prompt_and_seed_vtiger ;;
    quickbooks) prompt_and_seed_quickbooks ;;
    google)     prompt_and_seed_google ;;
    lis)        prompt_and_seed_lis ;;
    mattermost) prompt_and_seed_mattermost ;;
    twilio)     prompt_and_seed_twilio ;;
    3cx)        prompt_and_seed_3cx ;;
    all)
        prompt_and_seed_vtiger
        prompt_and_seed_quickbooks
        prompt_and_seed_google
        prompt_and_seed_lis
        prompt_and_seed_mattermost
        prompt_and_seed_twilio
        prompt_and_seed_3cx
        ;;
    *)
        echo "Unknown system: $SYSTEM"
        echo "Usage: $0 [vtiger|quickbooks|google|lis|mattermost|twilio|3cx|all]"
        exit 1
        ;;
esac

echo ""
echo "Done. To apply: recreate the MCP container(s) — e.g.:"
echo "  make ceo-stack-restart"
echo "  OR: docker compose -f infra/docker/docker-compose.ceo.yml up -d --force-recreate mcp-vtiger"
