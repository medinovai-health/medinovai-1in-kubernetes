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

# ── 3. Check port 18789 is owned by AtlasOS (not Docker) ─────────────────────
log "Step 3/4: Checking port 18789 ownership..."
PORT_OWNER=$(lsof -iTCP:18789 -sTCP:LISTEN -nP 2>/dev/null | grep LISTEN | awk '{print $1}' | head -1)
if [[ "$PORT_OWNER" == "com.docke" ]]; then
  warn "Port 18789 is bound by Docker — this will break WhatsApp."
  warn "Check docker-compose.ceo.yml for '18789:' mapping and remove it."
  fail "Port conflict detected — WhatsApp will be down after upgrade."
elif [[ "$PORT_OWNER" == "node" ]]; then
  log "  ✓ Port 18789 owned by AtlasOS gateway (node process)"
elif [[ -z "$PORT_OWNER" ]]; then
  warn "Port 18789 is not listening — AtlasOS gateway may be down."
  warn "Run: launchctl load ~/Library/LaunchAgents/ai.atlasos.gateway.plist"
  # Non-fatal: gateway might just not be started yet
fi

# ── 4. Warn about known risky files ───────────────────────────────────────────
log "Step 4/4: Checking for config drift risks..."
RISKY=0

# Check docker-compose.ceo.yml doesn't have 18789 mapped
CEO_COMPOSE="$(dirname "$(dirname "$SCRIPT_DIR")")/infra/docker/docker-compose.ceo.yml"
if grep -q '"18789:' "$CEO_COMPOSE" 2>/dev/null; then
  warn "docker-compose.ceo.yml still has 18789 port mapping — REMOVE IT"
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
