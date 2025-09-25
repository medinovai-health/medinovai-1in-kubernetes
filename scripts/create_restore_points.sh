#!/bin/bash

# MedinovAI Restore Points Creation Script
# This script creates restore points for all MedinovAI repositories

set -euo pipefail

ORG="myonsite-healthcare"
RESTORE_TAG="pre-medinovai-standards-$(date +%Y%m%d)"
REPO_LIST_FILE="medinovai_repo_names.txt"
LOG_FILE="restore_points_creation.log"
SUCCESS_COUNT=0
FAILED_COUNT=0
SKIPPED_COUNT=0

echo "🛡️ Creating restore points for all MedinovAI repositories..."
echo "📅 Restore tag: $RESTORE_TAG"
echo "📝 Log file: $LOG_FILE"

# Check if repository list exists
if [[ ! -f "$REPO_LIST_FILE" ]]; then
    echo "❌ Repository list file not found: $REPO_LIST_FILE"
    echo "Please run discover_repositories.sh first"
    exit 1
fi

# Check if GitHub CLI is authenticated
if ! gh auth status >/dev/null 2>&1; then
    echo "❌ GitHub CLI not authenticated. Please run: gh auth login"
    exit 1
fi

# Create log file
echo "MedinovAI Restore Points Creation Log" > "$LOG_FILE"
echo "Date: $(date)" >> "$LOG_FILE"
echo "Restore Tag: $RESTORE_TAG" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"

# Function to create restore point for a repository
create_restore_point() {
    local repo_name="$1"
    local full_repo="$ORG/$repo_name"
    
    echo "🔄 Processing repository: $repo_name"
    
    # Check if repository exists and is accessible
    if ! gh repo view "$full_repo" >/dev/null 2>&1; then
        echo "⚠️  Repository $full_repo not accessible, skipping..."
        echo "SKIPPED: $repo_name - Not accessible" >> "$LOG_FILE"
        ((SKIPPED_COUNT++))
        return 1
    fi
    
    # Clone repository temporarily
    local temp_dir="/tmp/medinovai-restore-$repo_name"
    rm -rf "$temp_dir"
    
    if ! git clone "https://github.com/$full_repo.git" "$temp_dir" >/dev/null 2>&1; then
        echo "❌ Failed to clone $repo_name"
        echo "FAILED: $repo_name - Clone failed" >> "$LOG_FILE"
        ((FAILED_COUNT++))
        return 1
    fi
    
    cd "$temp_dir"
    
    # Get current branch and commit
    local current_branch=$(git branch --show-current)
    local current_commit=$(git rev-parse HEAD)
    
    # Check if tag already exists
    if git tag -l | grep -q "^$RESTORE_TAG$"; then
        echo "⚠️  Tag $RESTORE_TAG already exists for $repo_name, skipping..."
        echo "SKIPPED: $repo_name - Tag already exists" >> "$LOG_FILE"
        ((SKIPPED_COUNT++))
        cd - >/dev/null
        rm -rf "$temp_dir"
        return 0
    fi
    
    # Create restore point tag
    if git tag -a "$RESTORE_TAG" -m "Restore point before MedinovAI standards implementation

Repository: $repo_name
Date: $(date)
Current Branch: $current_branch
Current Commit: $current_commit
Purpose: Restore point before implementing MedinovAI Unified Infrastructure Standards

Rollback Procedure:
1. git checkout $RESTORE_TAG
2. git push origin $current_branch --force
3. Notify team of rollback
4. Document rollback reason

This tag represents the state of the repository before implementing:
- BMAD methodology (Bootstrap-Migrate-Audit-Deepen)
- GitOps deployment structure
- Security policy enforcement
- Observability integration
- Supply chain security" >/dev/null 2>&1; then
        
        # Push tag to remote
        if git push origin "$RESTORE_TAG" >/dev/null 2>&1; then
            echo "✅ Created restore point for $repo_name"
            echo "SUCCESS: $repo_name - Tag created and pushed" >> "$LOG_FILE"
            ((SUCCESS_COUNT++))
        else
            echo "❌ Failed to push tag for $repo_name"
            echo "FAILED: $repo_name - Tag push failed" >> "$LOG_FILE"
            ((FAILED_COUNT++))
        fi
    else
        echo "❌ Failed to create tag for $repo_name"
        echo "FAILED: $repo_name - Tag creation failed" >> "$LOG_FILE"
        ((FAILED_COUNT++))
    fi
    
    cd - >/dev/null
    rm -rf "$temp_dir"
}

# Process each repository
while IFS= read -r repo_name; do
    if [[ -n "$repo_name" ]]; then
        create_restore_point "$repo_name"
        echo "" # Add blank line for readability
    fi
done < "$REPO_LIST_FILE"

# Generate summary report
echo "📊 Restore Points Creation Summary" >> "$LOG_FILE"
echo "=================================" >> "$LOG_FILE"
echo "Total repositories processed: $((SUCCESS_COUNT + FAILED_COUNT + SKIPPED_COUNT))" >> "$LOG_FILE"
echo "Successful: $SUCCESS_COUNT" >> "$LOG_FILE"
echo "Failed: $FAILED_COUNT" >> "$LOG_FILE"
echo "Skipped: $SKIPPED_COUNT" >> "$LOG_FILE"

echo ""
echo "📊 Restore Points Creation Summary:"
echo "  ✅ Successful: $SUCCESS_COUNT"
echo "  ❌ Failed: $FAILED_COUNT"
echo "  ⚠️  Skipped: $SKIPPED_COUNT"
echo "  📝 Log file: $LOG_FILE"

if [[ $FAILED_COUNT -gt 0 ]]; then
    echo ""
    echo "⚠️  Some repositories failed to create restore points. Check the log file for details."
    exit 1
fi

echo ""
echo "✅ Restore points creation complete!"
echo "🛡️ All repositories now have restore points with tag: $RESTORE_TAG"








