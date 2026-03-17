#!/usr/bin/env bash
# deploy_brain.sh -- Deploy MedinovAI Atlas brain training files to all repos
# Usage: bash scripts/deploy_brain.sh
set -euo pipefail

GITHUB_DIR="${GITHUB_DIR:?GITHUB_DIR is required. Set to your GitHub repos directory.}"
MASTER_DOC="$GITHUB_DIR/MedinovAI Atlas/docs/ATLAS_AUTONOMOUS_ARCHITECTURE.md"
MASTER_RULE="$GITHUB_DIR/MedinovAI Atlas/.cursor/rules/atlas-autonomous-brain.mdc"
COMMIT_MSG="Add MedinovAI Atlas autonomous brain training and architecture reference"

SUCCESS=0
SKIPPED=0
FAILED=0
FAILED_LIST=""

for dir in "$GITHUB_DIR"/*/; do
    repo_name=$(basename "$dir")

    # Skip MedinovAI Atlas itself
    if [ "$repo_name" = "MedinovAI Atlas" ]; then
        continue
    fi

    # Skip non-git repos
    if [ ! -d "$dir/.git" ]; then
        echo "SKIP (no .git): $repo_name"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    # Skip hidden/special directories
    if [[ "$repo_name" == .* ]]; then
        echo "SKIP (hidden): $repo_name"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    echo "--- Deploying to: $repo_name ---"

    # Create directories
    mkdir -p "$dir/docs"
    mkdir -p "$dir/.cursor/rules"

    # Copy files
    cp "$MASTER_DOC" "$dir/docs/ATLAS_AUTONOMOUS_ARCHITECTURE.md"
    cp "$MASTER_RULE" "$dir/.cursor/rules/atlas-autonomous-brain.mdc"

    # Git add and commit
    cd "$dir"
    git add "docs/ATLAS_AUTONOMOUS_ARCHITECTURE.md" ".cursor/rules/atlas-autonomous-brain.mdc" 2>/dev/null || true

    if git diff --cached --quiet 2>/dev/null; then
        echo "  SKIP (no changes): $repo_name"
        SKIPPED=$((SKIPPED + 1))
    else
        if git commit -m "$COMMIT_MSG" --no-verify 2>/dev/null; then
            echo "  OK: $repo_name"
            SUCCESS=$((SUCCESS + 1))
        else
            echo "  FAIL: $repo_name"
            FAILED=$((FAILED + 1))
            FAILED_LIST="$FAILED_LIST $repo_name"
        fi
    fi

    cd "$GITHUB_DIR"
done

echo ""
echo "=== DEPLOYMENT SUMMARY ==="
echo "Success: $SUCCESS"
echo "Skipped: $SKIPPED"
echo "Failed:  $FAILED"
if [ -n "$FAILED_LIST" ]; then
    echo "Failed repos:$FAILED_LIST"
fi
