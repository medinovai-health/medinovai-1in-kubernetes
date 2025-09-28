#!/bin/bash
# create_restore_points.sh - Create restore points for all MedinovAI repositories

echo "🔥 Creating restore points for all MedinovAI repositories..."
echo "Timestamp: $(date)"
echo "=========================================="

# List of all MedinovAI repositories
REPOS=(
    "medinovai-AI-standards"
    "medinovai-DataOfficer"
    "medinovai-Developer"
    "medinovai-EDC"
    "medinovai-ResearchSuite"
    "medinovai-alerting-services"
    "medinovai-api-gateway"
    "medinovai-audit-logging"
    "medinovai-authentication"
    "medinovai-authorization"
    "medinovai-backup-services"
    "medinovai-clinical-services"
    "medinovai-compliance-services"
    "medinovai-configuration-management"
    "medinovai-core-platform"
    "medinovai-data-services"
    "medinovai-development"
    "medinovai-devkit-infrastructure"
    "medinovai-disaster-recovery"
    "medinovai-etmf"
    "medinovai-healthLLM"
    "medinovai-healthcare-utilities"
    "medinovai-infrastructure"
    "medinovai-integration-services"
    "medinovai-monitoring-services"
    "medinovai-performance-monitoring"
    "medinovai-registry"
    "medinovai-security-services"
    "medinovai-testing-framework"
    "medinovai-ui-components"
    "medinovaios"
)

# Create timestamp for restore point
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESTORE_POINT_BRANCH="restore-point-$TIMESTAMP"
RESTORE_POINT_TAG="restore-point-$TIMESTAMP"

echo "Restore point branch: $RESTORE_POINT_BRANCH"
echo "Restore point tag: $RESTORE_POINT_TAG"
echo ""

# Function to create restore point for a repository
create_restore_point() {
    local repo=$1
    local repo_path="/Users/dev1/github/$repo"
    
    echo "📁 Processing $repo..."
    
    # Check if repository exists
    if [ ! -d "$repo_path" ]; then
        echo "⚠️  Repository $repo not found at $repo_path"
        return 1
    fi
    
    # Navigate to repository
    cd "$repo_path" || {
        echo "❌ Failed to navigate to $repo_path"
        return 1
    }
    
    # Check if it's a git repository
    if [ ! -d ".git" ]; then
        echo "⚠️  $repo is not a git repository, skipping..."
        return 1
    fi
    
    # Get current branch
    CURRENT_BRANCH=$(git branch --show-current)
    echo "   Current branch: $CURRENT_BRANCH"
    
    # Create restore point branch
    echo "   Creating restore point branch: $RESTORE_POINT_BRANCH"
    if git checkout -b "$RESTORE_POINT_BRANCH" 2>/dev/null; then
        echo "   ✅ Restore point branch created"
    else
        echo "   ⚠️  Restore point branch already exists or failed to create"
    fi
    
    # Create restore point tag
    echo "   Creating restore point tag: $RESTORE_POINT_TAG"
    if git tag -a "$RESTORE_POINT_TAG" -m "Restore point before medinovaios migration - $TIMESTAMP" 2>/dev/null; then
        echo "   ✅ Restore point tag created"
    else
        echo "   ⚠️  Restore point tag already exists or failed to create"
    fi
    
    # Return to original branch
    git checkout "$CURRENT_BRANCH" 2>/dev/null
    echo "   ✅ Returned to $CURRENT_BRANCH"
    
    echo "   🎉 Restore point created for $repo"
    echo ""
}

# Create restore points for all repositories
SUCCESS_COUNT=0
TOTAL_COUNT=${#REPOS[@]}

for repo in "${REPOS[@]}"; do
    if create_restore_point "$repo"; then
        ((SUCCESS_COUNT++))
    fi
done

echo "=========================================="
echo "🎉 Restore point creation completed!"
echo "✅ Successfully processed: $SUCCESS_COUNT/$TOTAL_COUNT repositories"
echo "📅 Timestamp: $TIMESTAMP"
echo "🏷️  Restore point tag: $RESTORE_POINT_TAG"
echo "🌿 Restore point branch: $RESTORE_POINT_BRANCH"
echo ""
echo "🔄 To rollback to this restore point, use:"
echo "   git checkout $RESTORE_POINT_TAG"
echo "   or"
echo "   git checkout $RESTORE_POINT_BRANCH"
echo ""
echo "📋 Restore points created for:"
for repo in "${REPOS[@]}"; do
    echo "   - $repo"
done
