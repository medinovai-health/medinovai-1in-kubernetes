#!/usr/bin/env bash
# ─── embed_atlasos.sh ─────────────────────────────────────────────────────────
# Embed AtlasOS agent capabilities into all MedinovAI repositories.
# Deploys domain-specific agent kits, Cursor rules, and autonomous brain
# training to every repo in the platform.
#
# Usage:
#   bash scripts/agents/embed_atlasos.sh --all                    # All repos
#   bash scripts/agents/embed_atlasos.sh --repo medinovai-CTMS    # Single repo
#   bash scripts/agents/embed_atlasos.sh --category clinical      # All clinical repos
#   bash scripts/agents/embed_atlasos.sh --all --dry-run           # Preview changes
#   bash scripts/agents/embed_atlasos.sh --all --include-sdk      # Also copy agent auth SDK (middleware + health routes)
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
REGISTRY="$REPO_ROOT/config/repo_registry.json5"
TEMPLATES_DIR="$REPO_ROOT/templates/repo-agents"
GITHUB_DIR="${GITHUB_DIR:-$HOME/Github}"

TARGET_REPO=""
TARGET_CATEGORY=""
ALL_REPOS=false
DRY_RUN=false
AUTO_COMMIT=false
INCLUDE_SDK=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --all)         ALL_REPOS=true; shift ;;
        --repo)        TARGET_REPO="$2"; shift 2 ;;
        --category)    TARGET_CATEGORY="$2"; shift 2 ;;
        --dry-run)     DRY_RUN=true; shift ;;
        --commit)      AUTO_COMMIT=true; shift ;;
        --include-sdk) INCLUDE_SDK=true; shift ;;
        *)             echo "Unknown option: $1"; exit 1 ;;
    esac
done

if ! $ALL_REPOS && [ -z "$TARGET_REPO" ] && [ -z "$TARGET_CATEGORY" ]; then
    echo "Usage: $0 --all | --repo <name> | --category <cat> [--dry-run] [--commit] [--include-sdk]"
    exit 1
fi

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $1"; }

# Parse JSON5 registry (strip comments, trailing commas)
parse_registry() {
    python3 -c "
import json, re, sys
with open('$REGISTRY') as f:
    content = re.sub(r'//.*', '', f.read())
    content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)
    content = re.sub(r',\s*([\]}])', r'\1', content)
    data = json.loads(content)
    print(json.dumps(data.get('repos', [])))
"
}

# Deploy agent kit to a single repo
embed_repo() {
    local repo_name="$1"
    local category="$2"
    local repo_path="$GITHUB_DIR/$repo_name"

    if [ ! -d "$repo_path" ]; then
        log "  SKIP: $repo_name — directory not found at $repo_path"
        return 0
    fi

    if [ ! -d "$repo_path/.git" ] && [ ! -f "$repo_path/.git" ]; then
        log "  SKIP: $repo_name — not a git repository"
        return 0
    fi

    local template_dir="$TEMPLATES_DIR/$category"
    if [ ! -d "$template_dir" ]; then
        template_dir="$TEMPLATES_DIR/backend-service"
        log "  WARN: No template for category '$category', using backend-service"
    fi

    log "  Embedding AtlasOS into $repo_name (category: $category)"

    if $DRY_RUN; then
        log "    [DRY RUN] Would copy $template_dir/* → $repo_path/"
        $INCLUDE_SDK && log "    [DRY RUN] Would copy SDK (middleware + routes) → $repo_path/atlasos-sdk/"
        return 0
    fi

    # Deploy Cursor rules
    mkdir -p "$repo_path/.cursor/rules"
    cp -f "$template_dir/.cursor/rules/"*.mdc "$repo_path/.cursor/rules/" 2>/dev/null || true

    # Deploy shared autonomous brain rules if they exist
    local brain_rule="$REPO_ROOT/templates/shared/atlas-autonomous-brain.mdc"
    if [ -f "$brain_rule" ]; then
        cp -f "$brain_rule" "$repo_path/.cursor/rules/"
    fi
    local gov_rule="$REPO_ROOT/templates/shared/ai-governance-controls.mdc"
    if [ -f "$gov_rule" ]; then
        cp -f "$gov_rule" "$repo_path/.cursor/rules/"
    fi

    # Deploy agent workspace files
    for f in AGENTS.md HEARTBEAT.md SOUL.md TOOLS.md MISTAKES.md; do
        if [ -f "$template_dir/$f" ]; then
            cp -f "$template_dir/$f" "$repo_path/$f"
        fi
    done

    # Deploy SDK (middleware + health routes) when --include-sdk
    if $INCLUDE_SDK; then
        local sdk_middleware="$REPO_ROOT/templates/repo-agents/middleware"
        local sdk_routes="$REPO_ROOT/templates/repo-agents/routes"
        local dest_middleware="$repo_path/atlasos-sdk/middleware"
        local dest_routes="$repo_path/atlasos-sdk/routes"
        if [ -d "$sdk_middleware" ]; then
            mkdir -p "$dest_middleware"
            cp -f "$sdk_middleware"/agent_auth.py "$dest_middleware/" 2>/dev/null || true
            cp -f "$sdk_middleware"/agent_auth.js "$dest_middleware/" 2>/dev/null || true
            log "    SDK: copied middleware (agent_auth.py, agent_auth.js)"
        fi
        if [ -d "$sdk_routes" ]; then
            mkdir -p "$dest_routes"
            cp -f "$sdk_routes"/agent_health.py "$dest_routes/" 2>/dev/null || true
            cp -f "$sdk_routes"/agent_health.js "$dest_routes/" 2>/dev/null || true
            log "    SDK: copied routes (agent_health.py, agent_health.js)"
        fi
    fi

    # Auto-commit if requested
    if $AUTO_COMMIT; then
        cd "$repo_path"
        if git diff --quiet && git diff --cached --quiet; then
            log "    No changes to commit"
        else
            git add -A .cursor/rules/ AGENTS.md HEARTBEAT.md SOUL.md TOOLS.md MISTAKES.md 2>/dev/null || true
            git commit -m "Embed AtlasOS agent kit (category: $category)" --no-verify 2>/dev/null || true
            log "    Committed changes"
        fi
        cd "$REPO_ROOT"
    fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────
log "╔══════════════════════════════════════════════════════════════╗"
log "║     MedinovAI Deploy — Embed AtlasOS in All Repos            ║"
log "╚══════════════════════════════════════════════════════════════╝"

if [ ! -f "$REGISTRY" ]; then
    log "ERROR: Repo registry not found at $REGISTRY"
    exit 1
fi

REPOS_JSON=$(parse_registry)
TOTAL=$(echo "$REPOS_JSON" | jq 'length')
EMBEDDED=0
SKIPPED=0

log "Registry: $TOTAL repos"
log ""

echo "$REPOS_JSON" | jq -c '.[]' | while IFS= read -r repo; do
    name=$(echo "$repo" | jq -r '.name')
    category=$(echo "$repo" | jq -r '.category // "backend-service"')

    if [ -n "$TARGET_REPO" ] && [ "$name" != "$TARGET_REPO" ]; then
        continue
    fi

    if [ -n "$TARGET_CATEGORY" ] && [ "$category" != "$TARGET_CATEGORY" ]; then
        continue
    fi

    embed_repo "$name" "$category"
done

log ""
log "AtlasOS embedding complete."
if $DRY_RUN; then
    log "  (Dry run — no changes made)"
fi
