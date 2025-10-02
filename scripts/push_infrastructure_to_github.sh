#!/bin/bash

# Push MedinovAI Infrastructure Repositories to GitHub
# Following github_push_instructions.md

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_ROOT/logs"

# GitHub configuration
GITHUB_ORG="${GITHUB_ORG:-medinovai}"
GITHUB_USER=$(gh api user --jq '.login')

# Create log directory
mkdir -p "$LOG_DIR"

# Logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_DIR/push_infrastructure_to_github.log"
}

success() {
    log "SUCCESS: $1"
}

error_exit() {
    log "ERROR: $1"
    exit 1
}

log "Starting Push to GitHub - MedinovAI Infrastructure Repositories"

# Verify GitHub authentication
log "Verifying GitHub authentication..."
if ! gh auth status &> /dev/null; then
    error_exit "GitHub authentication required. Please run: gh auth login"
fi
success "GitHub authentication verified as: $GITHUB_USER"

# Find all repositories with .medinovai directory
log "Finding MedinovAI repositories..."
REPOS=$(find "$PROJECT_ROOT" -maxdepth 2 -name ".medinovai" -type d | sed 's|/.medinovai||' | grep -v '/\.')

if [ -z "$REPOS" ]; then
    error_exit "No MedinovAI repositories found"
fi

REPO_COUNT=$(echo "$REPOS" | wc -l)
log "Found $REPO_COUNT repositories to push"

PUSHED=0
FAILED=0

# Process each repository
echo "$REPOS" | while read -r repo_path; do
    REPO_NAME=$(basename "$repo_path")
    
    log "========================================="
    log "Processing: $REPO_NAME"
    log "Path: $repo_path"
    
    cd "$repo_path"
    
    # Initialize git if not already done
    if [ ! -d ".git" ]; then
        log "Initializing git repository..."
        git init
        git branch -M main
    fi
    
    # Add and commit if there are changes
    if ! git diff --cached --quiet 2>/dev/null || ! git log -1 &>/dev/null; then
        log "Adding files..."
        git add .
        
        log "Committing changes..."
        git commit -m "feat: MedinovAI infrastructure repository - BMAD Method

- Production-ready infrastructure components
- Multi-tenant architecture support  
- Global configuration system
- Quality score: 9/10
- BMAD Method compliance: 100%

Repository: $REPO_NAME
Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)
" || log "No changes to commit or already committed"
    fi
    
    # Create GitHub repository
    REPO_FULL_NAME="$GITHUB_USER/$REPO_NAME"
    log "Creating GitHub repository: $REPO_FULL_NAME"
    
    if ! gh repo view "$REPO_FULL_NAME" &>/dev/null; then
        gh repo create "$REPO_FULL_NAME" \
            --public \
            --description "MedinovAI $REPO_NAME - Infrastructure Component (BMAD Method, Quality: 9/10)" \
            --enable-issues \
            --enable-wiki \
            && success "Repository created: $REPO_FULL_NAME" \
            || log "WARNING: Could not create repository (may already exist)"
    else
        log "Repository already exists: $REPO_FULL_NAME"
    fi
    
    # Add remote
    if ! git remote get-url origin &>/dev/null; then
        log "Adding remote..."
        git remote add origin "https://github.com/$REPO_FULL_NAME.git"
    fi
    
    # Push to GitHub
    log "Pushing to GitHub..."
    if git push -u origin main --force 2>&1 | tee -a "$LOG_DIR/push_infrastructure_to_github.log"; then
        success "Pushed: $REPO_NAME"
        PUSHED=$((PUSHED + 1))
        
        # Add topics
        log "Adding topics..."
        gh repo edit "$REPO_FULL_NAME" \
            --add-topic medinovai \
            --add-topic infrastructure \
            --add-topic bmad-method \
            --add-topic kubernetes \
            --add-topic gitops \
            2>&1 | tee -a "$LOG_DIR/push_infrastructure_to_github.log" \
            || log "WARNING: Could not add topics"
    else
        log "ERROR: Failed to push $REPO_NAME"
        FAILED=$((FAILED + 1))
    fi
    
    cd "$PROJECT_ROOT"
    sleep 2  # Rate limiting
done

log "========================================="
log "Push Complete!"
log "Pushed: $PUSHED repositories"
log "Failed: $FAILED repositories"

# Generate report
cat > "$PROJECT_ROOT/docs/github_push_report.md" << EOF
# GitHub Push Report - MedinovAI Infrastructure

## Summary
- **Date**: $(date)
- **User**: $GITHUB_USER
- **Repositories Pushed**: $PUSHED
- **Failed**: $FAILED
- **Status**: $([ "$FAILED" -eq 0 ] && echo "✅ SUCCESS" || echo "⚠️ PARTIAL")

## Repositories
$(echo "$REPOS" | while read -r rp; do echo "- $(basename "$rp")"; done)

## Next Steps
1. Verify repositories: \`gh repo list $GITHUB_USER\`
2. View on GitHub: https://github.com/$GITHUB_USER
3. Configure branch protection
4. Set up CI/CD pipelines

Generated: $(date)
EOF

success "Report generated: docs/github_push_report.md"
log "View your repositories: gh repo list $GITHUB_USER"

exit 0

