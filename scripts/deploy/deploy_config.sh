#!/usr/bin/env bash
# ─── deploy_config.sh ────────────────────────────────────────────────────────
# Copies config/atlas.json5 to ~/.atlas/atlas.json
# and sets up workspace directories for all agents.
#
# Usage:
#   bash scripts/deploy_config.sh
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
ATLAS_HOME="${ATLAS_HOME:-$HOME/.atlas}"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          MedinovAI Atlas Config Deployment                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ─── Create MedinovAI Atlas home ────────────────────────────────────────────────────
echo "▸ Ensuring $ATLAS_HOME exists..."
mkdir -p "$ATLAS_HOME"

# ─── Backup existing config ──────────────────────────────────────────────────
if [ -f "$ATLAS_HOME/atlas.json" ]; then
    BACKUP="$ATLAS_HOME/atlas.json.backup.$(date +%Y%m%d_%H%M%S)"
    echo "▸ Backing up existing config to: $BACKUP"
    cp "$ATLAS_HOME/atlas.json" "$BACKUP"
fi

# ─── Copy config ─────────────────────────────────────────────────────────────
echo "▸ Copying config/deploy.json5 → $ATLAS_HOME/atlas.json"
cp "$REPO_ROOT/config/deploy.json5" "$ATLAS_HOME/atlas.json"

# ─── Copy .env.example if no .env exists ─────────────────────────────────────
if [ ! -f "$ATLAS_HOME/.env" ]; then
    echo "▸ Copying .env.example → $ATLAS_HOME/.env (edit with real values!)"
    cp "$REPO_ROOT/config/.env.example" "$ATLAS_HOME/.env"
else
    echo "▸ .env already exists at $ATLAS_HOME/.env — skipping."
fi

# ─── Create workspace directories ────────────────────────────────────────────
echo ""
echo "▸ Creating workspace directories..."
AGENTS=("ops" "sales" "support" "finance" "eng" "supervisor" "guardian")

for agent in "${AGENTS[@]}"; do
    WS="$ATLAS_HOME/workspace-$agent"
    if [ -d "$WS" ]; then
        echo "  ✓ $WS already exists"
    else
        echo "  ▸ Creating $WS"
        mkdir -p "$WS"
    fi
done

# ─── Copy workspace templates ────────────────────────────────────────────────
echo ""
echo "▸ Copying workspace templates (will NOT overwrite existing files)..."

for agent in ops support sales finance eng supervisor guardian; do
    SRC="$REPO_ROOT/workspaces/$agent"
    DEST="$ATLAS_HOME/workspace-$agent"

    if [ -d "$SRC" ]; then
        # Copy files without overwriting existing ones
        find "$SRC" -type f | while read -r file; do
            REL="${file#$SRC/}"
            DEST_FILE="$DEST/$REL"
            DEST_DIR="$(dirname "$DEST_FILE")"
            mkdir -p "$DEST_DIR"
            if [ ! -f "$DEST_FILE" ]; then
                cp "$file" "$DEST_FILE"
                echo "  ✓ Copied: workspace-$agent/$REL"
            else
                echo "  · Skipped (exists): workspace-$agent/$REL"
            fi
        done
    fi
done

# ─── Create utility directories in workspaces ────────────────────────────────
echo ""
echo "▸ Creating utility directories in workspaces..."
for agent in "${AGENTS[@]}"; do
    for dir in logs outputs state config audit; do
        mkdir -p "$ATLAS_HOME/workspace-$agent/$dir"
    done
    # Create state subdirectories for reliability + observability
    for subdir in dead_letter checkpoints memory slo telemetry outcomes feedback; do
        mkdir -p "$ATLAS_HOME/workspace-$agent/state/$subdir"
    done
done

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✓ Config deployed!                                         ║"
echo "║                                                             ║"
echo "║  IMPORTANT: Edit these files with real values:              ║"
echo "║  • $ATLAS_HOME/.env                   ║"
echo "║  • $ATLAS_HOME/atlas.json (channel IDs)    ║"
echo "║                                                             ║"
echo "║  Then run: atlas gateway --port 18789                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
