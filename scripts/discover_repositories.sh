#!/bin/bash

# MedinovAI Repository Discovery Script
# This script discovers all repositories in the myonsite-healthcare organization

set -euo pipefail

ORG="myonsite-healthcare"
OUTPUT_FILE="medinovai_repositories.json"
REPORT_FILE="repository_discovery_report.md"

echo "🔍 Discovering MedinovAI repositories in $ORG organization..."

# Check if GitHub CLI is authenticated
if ! gh auth status >/dev/null 2>&1; then
    echo "❌ GitHub CLI not authenticated. Please run: gh auth login"
    exit 1
fi

# Discover all repositories
echo "📡 Fetching repository list..."
gh repo list "$ORG" --limit 1000 --json name,description,language,archived,private,createdAt,updatedAt,defaultBranchRef > "$OUTPUT_FILE"

# Filter for medinovai repositories and create detailed list
echo "🔍 Filtering for MedinovAI repositories..."
jq -r '.[] | select(.name | contains("medinovai")) | .name' "$OUTPUT_FILE" > medinovai_repo_names.txt

# Count repositories
TOTAL_REPOS=$(jq -r '.[] | select(.name | contains("medinovai")) | .name' "$OUTPUT_FILE" | wc -l)
echo "📊 Found $TOTAL_REPOS MedinovAI repositories"

# Generate detailed report
echo "📝 Generating discovery report..."
cat > "$REPORT_FILE" << EOF
# MedinovAI Repository Discovery Report

**Date:** $(date)
**Organization:** $ORG
**Total MedinovAI Repositories:** $TOTAL_REPOS

## Repository Categories

### Core Services (Estimated: 40 repositories)
- API services
- Microservices
- Authentication services
- Business logic services

### Data Services (Estimated: 20 repositories)
- Database services
- Analytics services
- ML/AI pipelines
- Data processing services

### UI/Frontend Services (Estimated: 25 repositories)
- Web applications
- Mobile applications
- Dashboards
- Portals

### Infrastructure Repositories (Estimated: 15 repositories)
- Terraform configurations
- Kubernetes manifests
- Monitoring configurations
- CI/CD configurations

### Libraries/SDKs (Estimated: 10 repositories)
- Shared libraries
- SDKs
- Common utilities
- Shared components

### Documentation Repositories (Estimated: 5 repositories)
- Documentation sites
- API documentation
- Wikis
- Knowledge bases

### Tools/Utilities (Estimated: 5 repositories)
- Scripts
- Automation tools
- Development utilities
- Maintenance tools

## Repository List

EOF

# Add repository details to report
jq -r '.[] | select(.name | contains("medinovai")) | "- **\(.name)**: \(.description // "No description") (\(.language // "Unknown language"))"' "$OUTPUT_FILE" >> "$REPORT_FILE"

echo "✅ Repository discovery complete!"
echo "📄 Results saved to: $OUTPUT_FILE"
echo "📊 Report saved to: $REPORT_FILE"
echo "📋 Repository names saved to: medinovai_repo_names.txt"

# Display summary
echo ""
echo "📈 Summary:"
echo "  - Total repositories: $TOTAL_REPOS"
echo "  - JSON data: $OUTPUT_FILE"
echo "  - Report: $REPORT_FILE"
echo "  - Names list: medinovai_repo_names.txt"








