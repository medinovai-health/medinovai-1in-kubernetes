#!/bin/bash
# ─── AtlasOS Engine — Self-Healing Gateway Runner ─────────────────────────────
# AtlasOS Charter: DO things, never block, never need a human except for approvals.
# 3-tier model routing: AIFactory nodes → Cloud (Anthropic) → Embedded (never-fail)
# Self-corrects config problems before starting. Never stops responding.
# ─────────────────────────────────────────────────────────────────────────────
ATLASOS_DIR='/Users/mayanktrivedi/Github/medinovai-health/AtlasOS'
DEPLOY_ROOT='/Users/mayanktrivedi/Github/medinovai-health/medinovai-Deploy'
SYNC_SCRIPT="${DEPLOY_ROOT}/scripts/sync-atlas-runtime.sh"
ENGINE="${ATLASOS_DIR}/packages/engine/medinovai-engine.mjs"
NODE='/opt/homebrew/bin/node'
STATE_DIR="${ATLASOS_STATE_DIR:-${HOME}/.atlas}"
LOG_TAG='[atlas-engine]'

log() { echo "$(date '+%Y-%m-%dT%H:%M:%S') $LOG_TAG $*"; }

# ── 1. Source credentials ─────────────────────────────────────────────────────
set -a
for env_file in \
    "${ATLASOS_DIR}/.env" \
    "${STATE_DIR}/.env" \
    "${HOME}/.env"
do
    [ -f "$env_file" ] && source "$env_file" && log "Sourced $env_file"
done
# macOS Keychain fallback
if [ -z "$ANTHROPIC_API_KEY" ]; then
    ANTHROPIC_API_KEY=$(security find-generic-password -w -s 'ANTHROPIC_API_KEY' 2>/dev/null || true)
    [ -n "$ANTHROPIC_API_KEY" ] && log "ANTHROPIC_API_KEY loaded from Keychain"
fi
set +a

# Read primary model from runtime config (ground truth)
_PRIMARY_MODEL=$("$NODE" -e "try{const c=JSON.parse(require('fs').readFileSync('${STATE_DIR}/atlasos.json','utf8'));const m=c.agents?.defaults?.model;console.log(typeof m==='string'?m:m?.primary||'unknown')}catch(e){console.log('unknown')}" 2>/dev/null || echo 'unknown')
log "Model routing: Primary (${_PRIMARY_MODEL}) → local fallbacks → cloud escalation only"

# ── 1b. Ensure Ollama is running (local-first model provider) ────────────────
if ! curl -sf http://127.0.0.1:11434/ > /dev/null 2>&1; then
    log "Ollama not running — starting..."
    /usr/local/bin/ollama serve &
    sleep 3
    curl -sf http://127.0.0.1:11434/ > /dev/null 2>&1 && log "Ollama started" || log "WARNING: Ollama failed to start"
else
    log "Ollama already running"
fi

# ── 1c. Ensure Docker Desktop is running (for containers and CEO stack) ──────
if ! /usr/local/bin/docker info > /dev/null 2>&1; then
    log "Docker not running — starting Docker Desktop..."
    open -a 'Docker' 2>/dev/null || true
    for _i in $(seq 1 30); do
        /usr/local/bin/docker info > /dev/null 2>&1 && break
        sleep 2
    done
    /usr/local/bin/docker info > /dev/null 2>&1 && log "Docker started" || log "WARNING: Docker failed to start (non-blocking)"
else
    log "Docker already running"
fi

# ── 2. Heal config (idempotent, valid schema only) ───────────────────────────
heal_config() {
    local config="${STATE_DIR}/atlasos.json"
    [ -f "$config" ] || return

    log "Healing config: enforcing 3-tier model hierarchy (valid schema)..."
    "$NODE" - "$config" "${ANTHROPIC_API_KEY:-}" << 'JSEOF'
const fs = require('fs');
const [,, configPath, anthropicKey] = process.argv;
try {
  const d = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const models = d.models || {};
  const providers = models.providers || {};

  // NEVER block startup over a missing API key — clear ALL ${...} template refs
  for (const [pname, p] of Object.entries(providers)) {
    if (typeof p.apiKey === 'string' && p.apiKey.includes('${')) {
      console.error(`Cleared template ref from providers.${pname}.apiKey`);
      p.apiKey = '';
    }
  }
  // If ANTHROPIC_API_KEY became available, inject it
  const anthropic = providers.anthropic;
  if (anthropic && anthropicKey && !anthropic.apiKey) {
    anthropic.apiKey = anthropicKey;
    console.error('Wrote ANTHROPIC_API_KEY into config');
  }

  // Remove invalid top-level model keys (not in schema)
  for (const k of ['default', 'fallback', 'embedded']) delete models[k];

  // Enforce timeout floor: never allow < 60s (caused CEO outage at 10s)
  const defs0 = d.agents?.defaults || {};
  if (defs0.timeoutSeconds !== undefined && defs0.timeoutSeconds < 60) {
    console.error(`Fixed timeoutSeconds: ${defs0.timeoutSeconds} -> 180 (floor=60)`);
    defs0.timeoutSeconds = 180;
  }

  // Ensure gateway.mode is set (engine refuses to start without it)
  if (d.gateway && !d.gateway.mode) {
    d.gateway.mode = 'local';
    console.error('Set gateway.mode=local (was unset)');
  }

  // Allow loopback or tailnet; only force loopback if nothing valid is set
  const VALID_BINDS = ['loopback', 'tailnet', 'lan', 'auto', 'custom'];
  if (d.gateway) {
    if (!VALID_BINDS.includes(d.gateway.bind)) {
      console.error(`Fixed gateway.bind: ${d.gateway.bind} -> tailnet (invalid value)`);
      d.gateway.bind = 'tailnet';
    }
  }

  // Helper: ensure a model string has a provider prefix
  // Known cloud providers that are valid as-is: anthropic/, openai/, bedrock/
  const CLOUD_PREFIXES = ['anthropic/', 'openai/', 'bedrock/'];
  function ensureProvider(m) {
    if (!m || typeof m !== 'string') return m;
    if (m.includes('/')) return m;
    return `ollama-local/${m}`;
  }

  // Fix agents.defaults.model — missing provider prefix causes model-selection fallback spam
  const defs = d.agents?.defaults || {};
  if (defs.model) {
    if (typeof defs.model === 'string') {
      const fixed = ensureProvider(defs.model);
      if (fixed !== defs.model) { console.error(`Fixed defaults.model: ${defs.model} -> ${fixed}`); defs.model = fixed; }
    } else if (typeof defs.model === 'object') {
      if (defs.model.primary) { const f = ensureProvider(defs.model.primary); if (f !== defs.model.primary) { console.error(`Fixed defaults.model.primary: ${defs.model.primary} -> ${f}`); defs.model.primary = f; } }
      defs.model.fallbacks = (defs.model.fallbacks || []).map(fb => ensureProvider(fb));
    }
  }

  // Fix agent list: missing prefixes, invalid keys
  const agentsList = d.agents?.list || [];
  for (const agent of agentsList) {
    delete agent.modelFallback;
    const current = agent.model;
    if (!current) continue;
    if (typeof current === 'string') {
      const fixed = ensureProvider(current);
      if (fixed !== current) { console.error(`Fixed ${agent.id}.model: ${current} -> ${fixed}`); agent.model = fixed; }
    }
    if (typeof current === 'object') {
      if (current.primary) { const f = ensureProvider(current.primary); if (f !== current.primary) { console.error(`Fixed ${agent.id}.model.primary prefix`); current.primary = f; } }
      if (current.fallbacks) { current.fallbacks = current.fallbacks.map(fb => ensureProvider(fb)); }
    }
  }

  fs.writeFileSync(configPath, JSON.stringify(d, null, 2));
  console.error('Config healed successfully.');
} catch(e) { console.error('Heal skipped:', e.message); }
JSEOF
}

# ── 3. Gateway startup loop (auto-recovers, never permanently stops) ──────────
heal_config

if [ -x "$SYNC_SCRIPT" ]; then
    log "Syncing authoritative runtime before gateway start"
    ATLASOS_ROOT="$ATLASOS_DIR" DEPLOY_ROOT="$DEPLOY_ROOT" ATLAS_HOME="$STATE_DIR" "$SYNC_SCRIPT" prod || \
      log "WARNING: runtime sync failed; continuing with existing state"
fi

MAX_RETRIES=20
attempt=0

while true; do
    attempt=$((attempt + 1))
    log "Starting AtlasOS engine gateway (attempt $attempt)..."

    # Bind and port are set in ~/.atlas/atlasos.json (bind: lan, port: 18789)
    # --force allows restart when session is already active
    "$NODE" "$ENGINE" gateway run \
        --force \
        2>&1

    EXIT_CODE=$?
    log "Gateway exited with code $EXIT_CODE"

    # Clean exit (restart requested) — brief pause, immediate restart
    if [ $EXIT_CODE -eq 0 ]; then
        log "Clean exit — restarting in 5s..."
        sleep 5
        continue
    fi

    # Non-zero exit — self-heal cycle
    log "Non-zero exit — healing config + waiting before retry..."
    heal_config
    if [ -x "$SYNC_SCRIPT" ]; then
        ATLASOS_ROOT="$ATLASOS_DIR" DEPLOY_ROOT="$DEPLOY_ROOT" ATLAS_HOME="$STATE_DIR" "$SYNC_SCRIPT" prod >/dev/null 2>&1 || true
    fi

    # Re-source credentials in case they became available
    [ -f "${ATLASOS_DIR}/.env" ] && { set -a; source "${ATLASOS_DIR}/.env"; set +a; }
    if [ -z "$ANTHROPIC_API_KEY" ]; then
        ANTHROPIC_API_KEY=$(security find-generic-password -w -s 'ANTHROPIC_API_KEY' 2>/dev/null || true)
    fi

    # Exponential backoff (5s → 60s max) then reset
    BACKOFF=$((attempt < 12 ? attempt * 5 : 60))
    log "Waiting ${BACKOFF}s before retry (attempt $attempt / $MAX_RETRIES)..."
    sleep "$BACKOFF"
    [ $attempt -ge $MAX_RETRIES ] && { log "Resetting retry counter after $MAX_RETRIES failures."; attempt=0; }
done
