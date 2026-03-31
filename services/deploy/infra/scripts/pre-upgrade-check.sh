#!/bin/bash
# ─── pre-upgrade-check.sh ────────────────────────────────────────────────────
# Run this BEFORE any medinovai-health upgrade/git pull to:
#   1. Backup all AtlasOS config
#   2. Validate config is healthy
#   3. Warn about known breaking changes
#
# Usage: ./infra/scripts/pre-upgrade-check.sh
# Exit 0 = safe to upgrade. Exit 1 = stop and investigate.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ATLAS_DIR="$HOME/.atlas"
# The AtlasOS gateway engine binary (package name is internal, brand is AtlasOS)
ATLASOS_ENGINE_BIN="/Users/mayanktrivedi/.local/node/bin/node"
ATLASOS_ENGINE_INDEX="/Users/mayanktrivedi/.local/node/lib/node_modules/openclaw/dist/index.js"

log()  { echo "$(date '+%H:%M:%S') [pre-upgrade] $*"; }
warn() { echo "$(date '+%H:%M:%S') [WARN] $*" >&2; }
fail() { echo "$(date '+%H:%M:%S') [FAIL] $*" >&2; exit 1; }

echo ""
echo "══════════════════════════════════════════════════════"
echo "  MedinovAI Pre-Upgrade Safety Check"
echo "══════════════════════════════════════════════════════"
echo ""

# ── 1. Backup config ──────────────────────────────────────────────────────────
log "Step 1/4: Backing up AtlasOS config..."
"$SCRIPT_DIR/backup-atlasos-config.sh"
echo ""

# ── 2. Validate atlasos.json ──────────────────────────────────────────────────
log "Step 2/4: Validating atlasos.json..."
# ATLASOS_CONFIG_PATH is the AtlasOS env var; OPENCLAW_CONFIG_PATH is the legacy
# env var still read by the engine binary internals — both point to same file
DOCTOR_OUT=$(ATLASOS_CONFIG_PATH="$ATLAS_DIR/atlasos.json" \
  OPENCLAW_CONFIG_PATH="$ATLAS_DIR/atlasos.json" \
  "$ATLASOS_ENGINE_BIN" "$ATLASOS_ENGINE_INDEX" doctor 2>&1 || true)
if echo "$DOCTOR_OUT" | grep -qi "config validation failed\|Invalid config"; then
  warn "atlasos.json has validation errors:"
  echo "$DOCTOR_OUT" | grep -E "invalid|error|Error|Invalid" | head -10
  warn "Run: make gateway-doctor FIX=1"
  warn "     Then re-run this check."
  fail "Config has errors — fix before upgrading to prevent WhatsApp downtime."
fi
log "  ✓ atlasos.json is valid"

# ── 3. Check port 18789 is owned by the Docker gateway ────────────────────────
log "Step 3/4: Checking port 18789 ownership..."
PORT_OWNER=$(lsof -iTCP:18789 -sTCP:LISTEN -nP 2>/dev/null | grep LISTEN | awk '{print $1}' | head -1)
if [[ "$PORT_OWNER" == "com.docke" ]]; then
  log "  ✓ Port 18789 owned by Docker gateway"
elif [[ "$PORT_OWNER" == "node" ]]; then
  warn "Port 18789 is still bound by the legacy native gateway."
  warn "Disable the native LaunchAgent and restart the CEO Docker gateway."
  fail "Legacy gateway ownership detected — Telegram/WhatsApp may drift."
elif [[ -z "$PORT_OWNER" ]]; then
  warn "Port 18789 is not listening — AtlasOS gateway may be down."
  warn "Run: make ceo-stack && make gateway-restart"
  fail "Gateway is not listening on 18789."
fi

# ── 4. Warn about known risky files ───────────────────────────────────────────
log "Step 4/4: Checking for config drift risks..."
RISKY=0

# Check docker-compose.ceo.yml keeps 18789 mapped to the gateway
CEO_COMPOSE="$(dirname "$(dirname "$SCRIPT_DIR")")/infra/docker/docker-compose.ceo.yml"
if ! grep -q '"18789:' "$CEO_COMPOSE" 2>/dev/null; then
  warn "docker-compose.ceo.yml is missing the 18789 gateway port mapping"
  RISKY=1
fi

# Check docker-compose.ceo.yml mounts the live ~/.atlas runtime
if ! grep -q '\${HOME}/.atlas:/data/.atlas' "$CEO_COMPOSE" 2>/dev/null; then
  warn "docker-compose.ceo.yml is not mounting ~/.atlas into the gateway"
  RISKY=1
fi

# Check docker-compose.ceo.yml passes Telegram credentials through
if ! grep -q 'TELEGRAM_BOT_TOKEN' "$CEO_COMPOSE" 2>/dev/null; then
  warn "docker-compose.ceo.yml is not passing TELEGRAM_BOT_TOKEN to the gateway"
  RISKY=1
fi

# Check atlasos.json has WhatsApp binding to ceo agent
WA_AGENT=$(python3 -c "
import json
with open('$ATLAS_DIR/atlasos.json') as f:
    d = json.load(f)
bindings = d.get('bindings', [])
for b in bindings:
    if isinstance(b, dict) and b.get('match', {}).get('channel') == 'whatsapp':
        print(b.get('agentId','?'))
        break
" 2>/dev/null || echo "?")
log "  WhatsApp → agent: '$WA_AGENT'"
if [[ "$WA_AGENT" == "?" || "$WA_AGENT" == "" ]]; then
  warn "No WhatsApp binding found in atlasos.json — CEO agent won't receive messages"
  RISKY=1
fi

[[ $RISKY -eq 0 ]] && log "  ✓ No config drift risks detected"

echo ""
echo "══════════════════════════════════════════════════════"
if [[ $RISKY -eq 1 ]]; then
  echo "  ⚠ WARNING: Risks detected — review above before upgrading"
else
  echo "  ✅ SAFE TO UPGRADE"
fi
echo "══════════════════════════════════════════════════════"
echo ""
exit $RISKY
