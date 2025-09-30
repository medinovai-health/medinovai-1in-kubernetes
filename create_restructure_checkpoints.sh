#!/bin/bash

# RESTRUCTURE001 Checkpoint Creation Script
# Creates checkpoints across all MedinovAI repositories

set -e

CHECKPOINT_TAG="RESTRUCTURE001"
LOG_FILE="checkpoint_creation.log"
CHECKPOINT_DIR="checkpoints/RESTRUCTURE001"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Initialize logging
exec 1> >(tee -a "${LOG_FILE}")
exec 2> >(tee -a "${LOG_FILE}" >&2)

echo "🚀 STARTING RESTRUCTURE001 CHECKPOINT CREATION"
echo "================================================"
echo "Timestamp: ${TIMESTAMP}"
echo "Checkpoint Tag: ${CHECKPOINT_TAG}"
echo ""

# Create checkpoint directory
mkdir -p "${CHECKPOINT_DIR}"

# Repository list (based on discovery)
declare -a REPOSITORIES=(
    "medinovai-infrastructure"
    "MedinovAI-AI-Standards" 
    "medinovaios"
    "manus-consolidation-platform"
    "medinovai-credentialimg"
    "medinovai-security"
    "ComplianceManus"
    "medinovai-data-services"
    "dataOfficer"
    "MedinovAI-Chatbot"
    "ATS"
    "AutoBidPro"
    "automarketingpro"
    "autosalespro"
    "autobidpro"
    "medinovai-subscription"
    "personalassistant"
    "ResearchSuite"
    "medinovai-Developer"
    "medinovai-Uiux"
    "medinovai-devops-telemetry"
    "medinovai-edge-cache-cdn"
    "medinovai-encryption-vault"
    "medinovai-consent-preference-api"
    "medinovai-audit-trail-explorer"
    "DocuGenie"
    "Insights"
    "medinovai-feature-flag-console"
    "ai-chatbot"
    "mos-chatbot"
    "medinovai-remote-vitals-ingest"
    "medinovai-test-repo"
    "lis-1.0-silverlight"
    "lis-iss"
)

# Counters
TOTAL_REPOS=${#REPOSITORIES[@]}
COMPLETED=0
FAILED=0

echo "📦 Processing ${TOTAL_REPOS} repositories..."
echo ""

# Function to create checkpoint for a single repository
create_checkpoint() {
    local repo_name="$1"
    local repo_path="/Users/dev1/github/${repo_name}"
    local checkpoint_file="${CHECKPOINT_DIR}/${repo_name}_checkpoint.json"
    
    echo "🏷️  Creating checkpoint for ${repo_name}..."
    
    # Check if repository exists locally
    if [ ! -d "${repo_path}" ]; then
        echo "⚠️  Repository ${repo_name} not found locally at ${repo_path}"
        # Try alternative paths
        if [ -d "/Users/dev1/github/medinovai-infrastructure/${repo_name}" ]; then
            repo_path="/Users/dev1/github/medinovai-infrastructure/${repo_name}"
        elif [ -d "/Users/dev1/Projects/${repo_name}" ]; then
            repo_path="/Users/dev1/Projects/${repo_name}"
        else
            echo "❌ Repository ${repo_name} not found in any expected location"
            return 1
        fi
    fi
    
    cd "${repo_path}" 2>/dev/null || {
        echo "❌ Cannot access repository ${repo_name}"
        return 1
    }
    
    # Get current git state
    local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
    local current_hash=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
    local repo_url=$(git remote get-url origin 2>/dev/null || echo "unknown")
    
    # Create git tag for checkpoint
    if git tag "${CHECKPOINT_TAG}" 2>/dev/null; then
        echo "✅ Created git tag ${CHECKPOINT_TAG} for ${repo_name}"
    else
        if git tag -d "${CHECKPOINT_TAG}" 2>/dev/null && git tag "${CHECKPOINT_TAG}" 2>/dev/null; then
            echo "✅ Updated git tag ${CHECKPOINT_TAG} for ${repo_name}"
        else
            echo "⚠️  Could not create git tag for ${repo_name}"
        fi
    fi
    
    # Create checkpoint metadata
    cat > "${checkpoint_file}" << EOF
{
  "repository_name": "${repo_name}",
  "checkpoint_id": "${CHECKPOINT_TAG}",
  "timestamp": "${TIMESTAMP}",
  "git_hash": "${current_hash}",
  "current_branch": "${current_branch}",
  "repository_url": "${repo_url}",
  "local_path": "${repo_path}",
  "file_count": $(find . -type f | wc -l),
  "git_status": "$(git status --porcelain 2>/dev/null || echo 'unknown')",
  "last_commit": "$(git log -1 --format='%H %s %an %ad' 2>/dev/null || echo 'unknown')",
  "dependencies_analyzed": false,
  "event_driven_transformation_ready": false
}
EOF
    
    echo "💾 Checkpoint metadata saved for ${repo_name}"
    return 0
}

# Create checkpoints for all repositories
for repo in "${REPOSITORIES[@]}"; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if create_checkpoint "${repo}"; then
        ((COMPLETED++))
        echo "✅ Checkpoint created for ${repo} (${COMPLETED}/${TOTAL_REPOS})"
    else
        ((FAILED++))
        echo "❌ Checkpoint failed for ${repo} (${FAILED} failed)"
    fi
    
    echo ""
done

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 CHECKPOINT CREATION SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Total Repositories: ${TOTAL_REPOS}"
echo "Completed: ${COMPLETED}"
echo "Failed: ${FAILED}"
echo "Success Rate: $(( (COMPLETED * 100) / TOTAL_REPOS ))%"
echo ""
echo "📄 Log file: ${LOG_FILE}"
echo "📁 Checkpoint directory: ${CHECKPOINT_DIR}"
echo ""

if [ "${FAILED}" -eq 0 ]; then
    echo "🎉 ALL CHECKPOINTS CREATED SUCCESSFULLY!"
    echo "✅ Ready to proceed with event-driven architecture transformation"
else
    echo "⚠️  ${FAILED} repositories failed checkpoint creation"
    echo "🔧 Manual intervention may be required for failed repositories"
fi

echo ""
echo "🔄 Next Steps:"
echo "1. Review failed repositories (if any)"
echo "2. Start agent swarm deployment"
echo "3. Begin event-driven architecture transformation"
echo "4. Execute parallel repository processing"

