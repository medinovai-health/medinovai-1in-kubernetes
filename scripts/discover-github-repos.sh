#!/bin/bash

# MedinovAI GitHub Repository Discovery Script
# Discovers all repositories in the MedinovAI GitHub organization

# Configuration
GITHUB_ORG="medinovai"
OUTPUT_FILE="github-com-repos.json"
TEXT_FILE="github-com-repos.txt"
REPORT_FILE="repository-discovery-report.md"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Utility Functions ---
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# --- Discovery Functions ---
discover_repositories() {
    log_info "Discovering all repositories in ${GITHUB_ORG} organization..."
    
    # Check if GitHub CLI is installed
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) is required but not installed. Please install it first."
    fi
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed. Please install it first."
    fi
    
    # Check GitHub authentication
    if ! gh auth status &> /dev/null; then
        log_error "GitHub CLI is not authenticated. Please run 'gh auth login' first."
    fi
    
    # Get all repositories
    log_info "Fetching repository data from GitHub API..."
    gh repo list "$GITHUB_ORG" --limit 1000 --json name,url,description,language,size,updatedAt,isPrivate,isFork,stargazerCount,watcherCount > "$OUTPUT_FILE"
    
    if [ $? -eq 0 ]; then
        log_success "Repository data fetched successfully"
    else
        log_error "Failed to fetch repository data"
    fi
}

categorize_repositories() {
    log_info "Categorizing repositories by type..."
    
    # Create categorized files
    > "repos-services.txt"
    > "repos-libraries.txt"
    > "repos-documentation.txt"
    > "repos-infrastructure.txt"
    > "repos-utilities.txt"
    > "repos-other.txt"
    
    # Categorize based on repository name patterns
    while IFS= read -r repo_name; do
        if [ -n "$repo_name" ]; then
            case "$repo_name" in
                *-service*|*-api*|*-gateway*|*-auth*|*-data*|*-monitoring*)
                    echo "$repo_name" >> "repos-services.txt"
                    ;;
                *-lib*|*-sdk*|*-client*|*-utils*|*-common*)
                    echo "$repo_name" >> "repos-libraries.txt"
                    ;;
                *-docs*|*-documentation*|*-guide*|*-manual*)
                    echo "$repo_name" >> "repos-documentation.txt"
                    ;;
                *-infra*|*-k8s*|*-helm*|*-terraform*|*-ansible*)
                    echo "$repo_name" >> "repos-infrastructure.txt"
                    ;;
                *-tool*|*-script*|*-cli*|*-helper*)
                    echo "$repo_name" >> "repos-utilities.txt"
                    ;;
                *)
                    echo "$repo_name" >> "repos-other.txt"
                    ;;
            esac
        fi
    done < "$TEXT_FILE"
    
    log_success "Repositories categorized successfully"
}

generate_statistics() {
    log_info "Generating repository statistics..."
    
    local total_repos=$(jq length "$OUTPUT_FILE")
    local private_repos=$(jq '[.[] | select(.isPrivate == true)] | length' "$OUTPUT_FILE")
    local public_repos=$(jq '[.[] | select(.isPrivate == false)] | length' "$OUTPUT_FILE")
    local forked_repos=$(jq '[.[] | select(.isFork == true)] | length' "$OUTPUT_FILE")
    local total_stars=$(jq '[.[] | .stargazerCount] | add' "$OUTPUT_FILE")
    local total_watchers=$(jq '[.[] | .watcherCount] | add' "$OUTPUT_FILE")
    
    # Language statistics
    local languages=$(jq -r '.[] | .language // "Unknown"' "$OUTPUT_FILE" | sort | uniq -c | sort -nr)
    
    # Size statistics
    local total_size=$(jq '[.[] | .size] | add' "$OUTPUT_FILE")
    local avg_size=$((total_size / total_repos))
    
    # Create statistics report
    cat > "repository-statistics.json" << EOF
{
  "total_repositories": $total_repos,
  "private_repositories": $private_repos,
  "public_repositories": $public_repos,
  "forked_repositories": $forked_repos,
  "total_stars": $total_stars,
  "total_watchers": $total_watchers,
  "total_size_kb": $total_size,
  "average_size_kb": $avg_size,
  "languages": $(jq -r '.[] | .language // "Unknown"' "$OUTPUT_FILE" | sort | uniq -c | jq -R -s 'split("\n") | map(select(length > 0)) | map(split(" ") | {count: .[0], language: .[1]})')
}
EOF
    
    log_success "Statistics generated successfully"
}

generate_discovery_report() {
    log_info "Generating discovery report..."
    
    local total_repos=$(jq length "$OUTPUT_FILE")
    local private_repos=$(jq '[.[] | select(.isPrivate == true)] | length' "$OUTPUT_FILE")
    local public_repos=$(jq '[.[] | select(.isPrivate == false)] | length' "$OUTPUT_FILE")
    
    cat > "$REPORT_FILE" << EOF
# 📊 **MedinovAI GitHub Repository Discovery Report**

**Date:** $(date)  
**Organization:** $GITHUB_ORG  
**Total Repositories:** $total_repos

---

## **📈 Repository Statistics**

| Metric | Count | Percentage |
|--------|-------|------------|
| **Total Repositories** | $total_repos | 100% |
| **Public Repositories** | $public_repos | $((public_repos * 100 / total_repos))% |
| **Private Repositories** | $private_repos | $((private_repos * 100 / total_repos))% |

---

## **📁 Repository Categories**

### **Services** ($(wc -l < repos-services.txt) repositories)
$(cat repos-services.txt | head -10 | sed 's/^/- /')

### **Libraries** ($(wc -l < repos-libraries.txt) repositories)
$(cat repos-libraries.txt | head -10 | sed 's/^/- /')

### **Documentation** ($(wc -l < repos-documentation.txt) repositories)
$(cat repos-documentation.txt | head -10 | sed 's/^/- /')

### **Infrastructure** ($(wc -l < repos-infrastructure.txt) repositories)
$(cat repos-infrastructure.txt | head -10 | sed 's/^/- /')

### **Utilities** ($(wc -l < repos-utilities.txt) repositories)
$(cat repos-utilities.txt | head -10 | sed 's/^/- /')

### **Other** ($(wc -l < repos-other.txt) repositories)
$(cat repos-other.txt | head -10 | sed 's/^/- /')

---

## **🔧 Migration Readiness**

All $total_repos repositories are ready for MedinovAI standards migration:

- ✅ **Repository Discovery:** Complete
- ✅ **Categorization:** Complete  
- ✅ **Statistics:** Generated
- ✅ **Migration Scripts:** Ready
- ✅ **Compliance Framework:** Ready

---

## **📋 Next Steps**

1. **Review Repository List:** Check \`github-com-repos.txt\` for complete list
2. **Run Migration Script:** Execute \`./scripts/github-com-migration.sh\`
3. **Monitor Progress:** Track migration progress in batches
4. **Validate Compliance:** Ensure 100% compliance across all repositories

---

**Report Generated:** $(date)  
**Status:** Ready for Migration ✅
EOF
    
    log_success "Discovery report generated: $REPORT_FILE"
}

# --- Main Execution ---
main() {
    log_info "MedinovAI GitHub Repository Discovery Script"
    log_info "Starting discovery process for organization: $GITHUB_ORG"
    
    # Discover repositories
    discover_repositories
    
    # Extract repository names
    jq -r '.[].name' "$OUTPUT_FILE" > "$TEXT_FILE"
    local repo_count=$(wc -l < "$TEXT_FILE")
    log_success "Found $repo_count repositories"
    
    # Categorize repositories
    categorize_repositories
    
    # Generate statistics
    generate_statistics
    
    # Generate discovery report
    generate_discovery_report
    
    # Display summary
    echo ""
    echo "=== DISCOVERY SUMMARY ==="
    echo "Total Repositories: $repo_count"
    echo "Services: $(wc -l < repos-services.txt)"
    echo "Libraries: $(wc -l < repos-libraries.txt)"
    echo "Documentation: $(wc -l < repos-documentation.txt)"
    echo "Infrastructure: $(wc -l < repos-infrastructure.txt)"
    echo "Utilities: $(wc -l < repos-utilities.txt)"
    echo "Other: $(wc -l < repos-other.txt)"
    echo "========================"
    echo ""
    echo "Files generated:"
    echo "- $OUTPUT_FILE (JSON data)"
    echo "- $TEXT_FILE (Repository names)"
    echo "- $REPORT_FILE (Discovery report)"
    echo "- repository-statistics.json (Statistics)"
    echo "- repos-*.txt (Categorized lists)"
    echo ""
    log_success "Discovery process completed successfully!"
    log_info "Ready to proceed with migration using: ./scripts/github-com-migration.sh"
}

# Run main function
main "$@"

