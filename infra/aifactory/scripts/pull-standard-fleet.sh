#!/usr/bin/env bash
# pull-standard-fleet.sh
# Pull the AIFactory standard model fleet on any Ollama node
# Usage: ./pull-standard-fleet.sh [tier1|tier2|tier3|all|india]
# Run this on the target node, or prefix with: ssh user@node 'bash -s' < pull-standard-fleet.sh

set -euo pipefail

TIER=${1:-tier1}
OLLAMA_HOST=${OLLAMA_HOST:-http://localhost:11434}

log() { echo "[$(date +%H:%M:%S)] $*"; }
pull() { log "Pulling $1..."; ollama pull "$1" && log "✅ $1" || log "❌ $1 FAILED"; }

# ── Tier 1: Intern defaults (all nodes) ──────────────────────────────────────
pull_tier1() {
  pull qwen3-coder:latest
  pull phi4:14b
  pull qwen3:8b
  pull nomic-embed-text:latest
  pull mxbai-embed-large:latest
}

# ── Tier 2: Power users (nodes with >64GB RAM) ───────────────────────────────
pull_tier2() {
  pull qwen2.5-coder:32b
  pull deepseek-r1:32b
  pull gpt-oss:20b
  pull qwen3:32b
  pull codestral:22b
}

# ── Tier 3: Heavy review (nodes with >256GB RAM or high-VRAM GPU) ────────────
pull_tier3() {
  pull deepseek-r1:70b
  pull llama3.3:70b
  pull qwen2.5:72b
}

# ── Specialists ───────────────────────────────────────────────────────────────
pull_specialists() {
  pull meditron:7b
  pull deepseek-ocr:latest
  pull qwen3-vl:latest
}

# ── India fleet (Tier 1 + Tier 2 + healthcare, no 70B) ───────────────────────
pull_india() {
  pull_tier1
  pull_tier2
  pull meditron:7b
}

log "=== AIFactory Standard Fleet Pull ==="
log "Target: $OLLAMA_HOST"
log "Tier: $TIER"
echo ""

case $TIER in
  tier1)     pull_tier1 ;;
  tier2)     pull_tier1; pull_tier2 ;;
  tier3)     pull_tier1; pull_tier2; pull_tier3 ;;
  all)       pull_tier1; pull_tier2; pull_tier3; pull_specialists ;;
  india)     pull_india ;;
  *)         echo "Usage: $0 [tier1|tier2|tier3|all|india]"; exit 1 ;;
esac

log ""
log "=== Complete. Installed models ==="
curl -s ${OLLAMA_HOST}/api/tags | python3 -c "
import json,sys
d=json.load(sys.stdin)
models=d.get('models',[])
total=sum(m.get('size',0) for m in models)
for m in sorted(models,key=lambda x:x['name']):
    print(f\"  {m['name']:<45} {m.get('size',0)/1e9:.1f}GB\")
print(f'\nTotal: {len(models)} models, {total/1e9:.1f}GB')
"
