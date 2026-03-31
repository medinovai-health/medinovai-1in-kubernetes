#!/usr/bin/env bash
# ─── create_agents.sh ────────────────────────────────────────────────────────
# Registers agents with MedinovAI Atlas using the CLI.
# Run this AFTER deploy_config.sh has set up workspaces.
#
# Usage:
#   bash scripts/create_agents.sh
#
# Note: If agents are defined in atlas.json, they're auto-loaded.
#       This script is for explicit CLI-based setup or overrides.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

ATLAS_HOME="$HOME/.atlas"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          MedinovAI Atlas Agent Registration                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ─── Check MedinovAI Atlas is installed ─────────────────────────────────────────────
if ! command -v atlas &> /dev/null; then
    echo "✗ atlas not found. Run: bash scripts/install_atlas.sh"
    exit 1
fi

# ─── Model selection ─────────────────────────────────────────────────────────
# Default model — override with MODEL env var
MODEL="${MODEL:-anthropic/claude-opus-4-6}"
echo "▸ Using model: $MODEL"
echo "  (Override with: MODEL=openai/gpt-5.2 bash scripts/create_agents.sh)"
echo ""

# ─── Register agents ─────────────────────────────────────────────────────────

echo "▸ Registering: ops (default agent)"
atlas agents add ops \
    --workspace "$ATLAS_HOME/workspace-ops" \
    --model "$MODEL" \
    --default \
    --non-interactive \
    --json 2>/dev/null || echo "  (agent may already exist — continuing)"

echo "▸ Registering: sales"
atlas agents add sales \
    --workspace "$ATLAS_HOME/workspace-sales" \
    --model "$MODEL" \
    --non-interactive \
    --json 2>/dev/null || echo "  (agent may already exist — continuing)"

echo "▸ Registering: support"
atlas agents add support \
    --workspace "$ATLAS_HOME/workspace-support" \
    --model "$MODEL" \
    --non-interactive \
    --json 2>/dev/null || echo "  (agent may already exist — continuing)"

echo "▸ Registering: finance"
atlas agents add finance \
    --workspace "$ATLAS_HOME/workspace-finance" \
    --model "$MODEL" \
    --non-interactive \
    --json 2>/dev/null || echo "  (agent may already exist — continuing)"

echo "▸ Registering: eng"
atlas agents add eng \
    --workspace "$ATLAS_HOME/workspace-eng" \
    --model "$MODEL" \
    --non-interactive \
    --json 2>/dev/null || echo "  (agent may already exist — continuing)"

echo "▸ Registering: supervisor (meta-agent)"
atlas agents add supervisor \
    --workspace "$ATLAS_HOME/workspace-supervisor" \
    --model "$MODEL" \
    --non-interactive \
    --json 2>/dev/null || echo "  (agent may already exist — continuing)"

echo "▸ Registering: guardian (policy validator)"
atlas agents add guardian \
    --workspace "$ATLAS_HOME/workspace-guardian" \
    --model "$MODEL" \
    --non-interactive \
    --json 2>/dev/null || echo "  (agent may already exist — continuing)"

echo ""
echo "▸ Listing registered agents:"
atlas agents list 2>/dev/null || echo "  (list command may require gateway running)"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✓ Agents registered!                                       ║"
echo "║  Start gateway: atlas gateway --port 18789               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
