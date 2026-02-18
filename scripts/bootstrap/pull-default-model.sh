#!/usr/bin/env bash
# ─── pull-default-model.sh ────────────────────────────────────────────────────
# Pull default LLMs into the Docker Compose Ollama instance.
# Idempotent — skips each model if it is already present.
#
# Default models (pulled in order):
#   1. qwen2.5:1.5b      ~1 GB   — fast chat, runs on CPU
#   2. nomic-embed-text  ~274 MB — REQUIRED for RAG / vector search
#   3. gemma3:latest     ~2.3 GB — better reasoning, used by Atlas agents
#
# Usage:
#   bash scripts/bootstrap/pull-default-model.sh             # pull all defaults
#   bash scripts/bootstrap/pull-default-model.sh --model X   # pull one model
#   make ollama-pull-default
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"
SINGLE_MODEL=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --model) SINGLE_MODEL="$2"; shift 2 ;;
    *) shift ;;
  esac
done

G="\033[0;32m"; Y="\033[1;33m"; R="\033[0;31m"; NC="\033[0m"
log()  { echo -e "${G}[ollama]${NC} $*"; }
warn() { echo -e "${Y}[ollama]${NC} $*"; }
err()  { echo -e "${R}[ollama]${NC} $*" >&2; }

# ── Wait for Ollama ────────────────────────────────────────────────────────────
log "Checking Ollama at $OLLAMA_URL..."
RETRIES=0
until curl -sf "$OLLAMA_URL/api/tags" >/dev/null 2>&1; do
  RETRIES=$((RETRIES + 1))
  if [[ $RETRIES -ge 18 ]]; then
    err "Ollama is not responding after 90s. Is Docker Compose running?"
    err "  Start with: make docker-up"
    exit 1
  fi
  warn "  Waiting for Ollama to start... (${RETRIES}/18, 5s intervals)"
  sleep 5
done
log "✓ Ollama is running."

# ── Helper: check and pull a single model ─────────────────────────────────────
pull_model() {
  local model="$1"
  local label="${2:-$model}"

  EXISTING=$(curl -sf "$OLLAMA_URL/api/tags" | python3 -c \
    "import json,sys; models=[m['name'] for m in json.load(sys.stdin).get('models',[])]; print('\n'.join(models))" 2>/dev/null || true)

  if echo "$EXISTING" | grep -qE "^${model}$|^${model}:"; then
    log "✓ '$model' already present — skipping."
    return 0
  fi

  log "Pulling: $label"
  log "  (models are cached in the ollama-data Docker volume)"

  curl -sf -X POST "$OLLAMA_URL/api/pull" \
    -H 'Content-Type: application/json' \
    -d "{\"name\":\"$model\",\"stream\":true}" \
    | python3 -u -c "
import sys, json
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        obj = json.loads(line)
        status = obj.get('status','')
        completed = obj.get('completed', 0)
        total = obj.get('total', 0)
        if total > 0:
            pct = int(completed * 100 / total)
            bar = '#' * (pct // 5) + '-' * (20 - pct // 5)
            print(f'\r  [{bar}] {pct:3d}%  {status[:40]:<40}', end='', flush=True)
        else:
            print(f'  {status}', flush=True)
    except:
        print(line, flush=True)
print()
"
  log "  ✓ '$model' ready."
  echo ""
}

# ── Pull models ───────────────────────────────────────────────────────────────
if [[ -n "$SINGLE_MODEL" ]]; then
  pull_model "$SINGLE_MODEL" "$SINGLE_MODEL"
else
  log "Pulling all default models..."
  echo ""
  pull_model "qwen2.5:1.5b"    "qwen2.5:1.5b  (~1 GB — fast chat, CPU-friendly)"
  pull_model "nomic-embed-text" "nomic-embed-text  (~274 MB — embeddings, REQUIRED for RAG)"
  pull_model "gemma3:latest"    "gemma3:latest  (~2.3 GB — general reasoning, Atlas agents)"
fi

MODELS_NOW=$(curl -sf "$OLLAMA_URL/api/tags" | python3 -c \
  "import json,sys; models=[m['name'] for m in json.load(sys.stdin).get('models',[])]; print('\n'.join(models))" 2>/dev/null || true)

echo ""
log "Available models in Ollama:"
echo "$MODELS_NOW" | sed 's/^/  • /'
echo ""
log "Open WebUI: http://localhost:8091"
log "Ollama API: $OLLAMA_URL"
log ""
log "Pull extra model: bash scripts/bootstrap/pull-default-model.sh --model llama3.2:3b"
log "Heavy code model: bash scripts/bootstrap/pull-default-model.sh --model devstral-small-2"
