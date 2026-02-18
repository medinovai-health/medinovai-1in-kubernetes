#!/usr/bin/env bash
# ─── embed_atlasos.sh ─────────────────────────────────────────────────────────
# Embed AtlasOS agents in every MedinovAI repo.
# Reads config/repo_registry.json5 and deploys category-specific agent kits.
#
# Usage:
#   bash scripts/agents/embed_atlasos.sh --all                  # All repos
#   bash scripts/agents/embed_atlasos.sh --repo medinovai-CTMS  # Single repo
#   bash scripts/agents/embed_atlasos.sh --category clinical    # All clinical repos
#   bash scripts/agents/embed_atlasos.sh --all --dry-run        # Show what would change
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
GITHUB_DIR="${GITHUB_DIR:-$HOME/Github}"
REGISTRY="$REPO_ROOT/config/repo_registry.json5"
TEMPLATES_DIR="$REPO_ROOT/templates/repo-agents"

TARGET_ALL=false
TARGET_REPO=""
TARGET_CATEGORY=""
DRY_RUN=false
COMMIT=false
PUSH=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --all)        TARGET_ALL=true; shift ;;
        --repo)       TARGET_REPO="$2"; shift 2 ;;
        --category)   TARGET_CATEGORY="$2"; shift 2 ;;
        --dry-run)    DRY_RUN=true; shift ;;
        --commit)     COMMIT=true; shift ;;
        --push)       PUSH=true; COMMIT=true; shift ;;
        --github-dir) GITHUB_DIR="$2"; shift 2 ;;
        *)            echo "Unknown option: $1"; exit 1 ;;
    esac
done

if ! $TARGET_ALL && [ -z "$TARGET_REPO" ] && [ -z "$TARGET_CATEGORY" ]; then
    echo "ERROR: Specify --all, --repo <name>, or --category <cat>"
    exit 1
fi

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $1"; }

TOTAL=0
UPDATED=0
SKIPPED=0
ERRORS=0

# ─── Parse registry ─────────────────────────────────────────────────────────
REPOS=$(python3 -c "
import json, re, sys

with open('$REGISTRY') as f:
    text = re.sub(r'//.*', '', f.read())
    text = re.sub(r'/\*.*?\*/', '', text, flags=re.DOTALL)
    # Remove trailing commas
    text = re.sub(r',\s*([}\]])', r'\1', text)
    registry = json.loads(text)

for repo in registry['repos']:
    name = repo['name']
    cat = repo.get('agent_profile', repo.get('category', 'backend-service'))
    include = False
    if '$TARGET_ALL' == 'true':
        include = True
    elif '$TARGET_REPO' and name == '$TARGET_REPO':
        include = True
    elif '$TARGET_CATEGORY' and cat == '$TARGET_CATEGORY':
        include = True
    if include:
        print(f\"{name}|{cat}\")
" 2>/dev/null)

if [ -z "$REPOS" ]; then
    log "No repos matched the filter."
    exit 0
fi

deploy_to_repo() {
    local repo_name="$1"
    local category="$2"
    local repo_path="$GITHUB_DIR/$repo_name"

    TOTAL=$((TOTAL + 1))

    if [ ! -d "$repo_path" ]; then
        log "  SKIP $repo_name — not found at $repo_path"
        SKIPPED=$((SKIPPED + 1))
        return 0
    fi

    if [ ! -d "$repo_path/.git" ]; then
        log "  SKIP $repo_name — not a git repo"
        SKIPPED=$((SKIPPED + 1))
        return 0
    fi

    local template_dir="$TEMPLATES_DIR/$category"
    if [ ! -d "$template_dir" ]; then
        template_dir="$TEMPLATES_DIR/backend-service"
    fi

    log "  DEPLOY $repo_name ($category)"

    if $DRY_RUN; then
        log "    [DRY RUN] Would deploy from $template_dir"
        return 0
    fi

    # Deploy Cursor rules
    mkdir -p "$repo_path/.cursor/rules"
    cp -f "$REPO_ROOT/.cursor/rules/atlas-autonomous-brain.mdc" "$repo_path/.cursor/rules/" 2>/dev/null || true
    cp -f "$REPO_ROOT/.cursor/rules/ai-governance-controls.mdc" "$repo_path/.cursor/rules/" 2>/dev/null || true

    # Deploy agent files (only if template exists)
    if [ -d "$template_dir" ]; then
        for f in AGENTS.md HEARTBEAT.md SOUL.md TOOLS.md MISTAKES.md; do
            if [ -f "$template_dir/$f" ]; then
                cp -f "$template_dir/$f" "$repo_path/$f"
            fi
        done
    fi

    # Deploy category-specific Cursor rules
    if [ -f "$template_dir/.cursor-rules/"*.mdc 2>/dev/null ]; then
        cp -f "$template_dir/.cursor-rules/"*.mdc "$repo_path/.cursor/rules/" 2>/dev/null || true
    fi

    # Commit if requested
    if $COMMIT; then
        cd "$repo_path"
        git add -A .cursor/rules/ AGENTS.md HEARTBEAT.md SOUL.md TOOLS.md MISTAKES.md 2>/dev/null || true
        if ! git diff --cached --quiet 2>/dev/null; then
            git commit -m "chore: embed AtlasOS agent kit ($category profile)" 2>/dev/null || true
            if $PUSH; then
                git push 2>/dev/null || log "    WARN: push failed for $repo_name"
            fi
        fi
        cd "$REPO_ROOT"
    fi

    UPDATED=$((UPDATED + 1))
}

log "╔══════════════════════════════════════════════════════════════╗"
log "║     AtlasOS Embedding — Deploy Agents to All Repos          ║"
log "╚══════════════════════════════════════════════════════════════╝"
log ""
log "Source: $TEMPLATES_DIR"
log "Target: $GITHUB_DIR"
log "Dry run: $DRY_RUN"
log ""

while IFS='|' read -r repo_name category; do
    deploy_to_repo "$repo_name" "$category"
done <<< "$REPOS"

log ""
log "────────────────────────────────────────────────────────────────"
log "Results: $TOTAL total, $UPDATED updated, $SKIPPED skipped, $ERRORS errors"
