#!/usr/bin/env bash
# ─── install_atlas.sh ─────────────────────────────────────────────────────
# Installs MedinovAI Atlas globally and runs initial onboarding.
# Does NOT hardcode secrets — those come from .env or interactive prompts.
#
# Usage:
#   bash scripts/install_atlas.sh
#
# Prerequisites:
#   - Node.js 22+ installed
#   - npm available on PATH
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           MedinovAI Atlas Installation Script                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ─── Check prerequisites ─────────────────────────────────────────────────────
echo "▸ Checking prerequisites..."

if ! command -v node &> /dev/null; then
    echo "✗ Node.js not found. Please install Node.js 22+ first."
    echo "  https://nodejs.org/en/download/"
    exit 1
fi

NODE_VERSION=$(node -v | sed 's/v//' | cut -d. -f1)
if [ "$NODE_VERSION" -lt 22 ]; then
    echo "✗ Node.js 22+ required. Found: $(node -v)"
    exit 1
fi
echo "  ✓ Node.js $(node -v)"

if ! command -v npm &> /dev/null; then
    echo "✗ npm not found. Please install npm."
    exit 1
fi
echo "  ✓ npm $(npm -v)"

# ─── Install MedinovAI Atlas ────────────────────────────────────────────────────────
echo ""
echo "▸ Installing MedinovAI Atlas globally..."
npm install -g atlas@latest

echo ""
echo "▸ Verifying installation..."
if ! command -v atlas &> /dev/null; then
    echo "✗ atlas command not found after install. Check your PATH."
    exit 1
fi
echo "  ✓ atlas installed: $(atlas --version 2>/dev/null || echo 'version check not supported')"

# ─── Run Onboarding ──────────────────────────────────────────────────────────
echo ""
echo "▸ Running MedinovAI Atlas onboarding (installs daemon)..."
atlas onboard --install-daemon

# ─── Create config directory ─────────────────────────────────────────────────
echo ""
echo "▸ Ensuring ~/.atlas/ directory exists..."
mkdir -p ~/.atlas

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✓ Installation complete!                                   ║"
echo "║                                                             ║"
echo "║  Next steps:                                                ║"
echo "║  1. Copy config:  bash scripts/deploy_config.sh             ║"
echo "║  2. Set secrets:  Edit ~/.atlas/.env                     ║"
echo "║  3. Start:        atlas gateway --port 18789             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
