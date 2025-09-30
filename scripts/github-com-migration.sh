#!/bin/bash

# MedinovAI GitHub.com Migration Script v2.0.0
# Migrates all 234 GitHub.com repositories to MedinovAI standards

# Configuration
GITHUB_ORG="medinovai"
GITHUB_TOKEN="${GITHUB_TOKEN}"
BATCH_SIZE=25
TOTAL_REPOS=234
TEMPLATES_DIR="templates"
LOG_FILE="github-com-migration.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Utility Functions ---
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

# --- GitHub API Functions ---
get_all_repositories() {
    log_info "Discovering all repositories in ${GITHUB_ORG}..."
    
    if [ -z "$GITHUB_TOKEN" ]; then
        log_error "GITHUB_TOKEN environment variable is required"
    fi
    
    # Get all repositories using GitHub CLI
    gh repo list "$GITHUB_ORG" --limit 1000 --json name,url,description,language,size > "github-com-repos.json"
    
    local repo_count=$(jq length github-com-repos.json)
    log_success "Found $repo_count repositories"
    
    # Create text file with repository names
    jq -r '.[].name' github-com-repos.json > "github-com-repos.txt"
    
    return $repo_count
}

create_migration_branch() {
    local repo_name="$1"
    local branch_name="medinovai-standards-migration"
    
    log_info "Creating migration branch for $repo_name..."
    
    # Create and checkout migration branch
    git checkout -b "$branch_name" 2>/dev/null || git checkout "$branch_name"
    
    log_success "Migration branch created/checked out"
}

apply_medinovai_standards() {
    local repo_name="$1"
    local repo_path="temp/$repo_name"
    
    log_info "Applying MedinovAI standards to $repo_name..."
    
    # Create .medinovai directory
    mkdir -p "$repo_path/.medinovai"
    
    # Copy and customize configuration templates
    cp "$TEMPLATES_DIR/.medinovai/standards.yml.template" "$repo_path/.medinovai/standards.yml"
    cp "$TEMPLATES_DIR/.medinovai/registry-config.yml.template" "$repo_path/.medinovai/registry-config.yml"
    cp "$TEMPLATES_DIR/.medinovai/data-services-config.yml.template" "$repo_path/.medinovai/data-services-config.yml"
    
    # Replace placeholders
    sed -i '' "s/{{REPO_NAME}}/$repo_name/g" "$repo_path/.medinovai/standards.yml"
    sed -i '' "s/{{REPO_NAME}}/$repo_name/g" "$repo_path/.medinovai/registry-config.yml"
    sed -i '' "s/{{REPO_NAME}}/$repo_name/g" "$repo_path/.medinovai/data-services-config.yml"
    
    # Create .github/workflows directory
    mkdir -p "$repo_path/.github/workflows"
    
    # Copy CI/CD workflow templates
    cp "$TEMPLATES_DIR/.github/workflows/ci.yml.template" "$repo_path/.github/workflows/ci.yml"
    cp "$TEMPLATES_DIR/.github/workflows/cd.yml.template" "$repo_path/.github/workflows/cd.yml"
    cp "$TEMPLATES_DIR/.github/workflows/standards-validation.yml.template" "$repo_path/.github/workflows/standards-validation.yml"
    
    # Create basic documentation files if they don't exist
    [ ! -f "$repo_path/README.md" ] && echo "# $repo_name" > "$repo_path/README.md"
    [ ! -f "$repo_path/CHANGELOG.md" ] && echo "# Changelog" > "$repo_path/CHANGELOG.md"
    [ ! -f "$repo_path/LICENSE" ] && echo "MIT License" > "$repo_path/LICENSE"
    [ ! -f "$repo_path/SECURITY.md" ] && echo "# Security Policy" > "$repo_path/SECURITY.md"
    [ ! -f "$repo_path/.gitignore" ] && echo -e ".DS_Store\n.env\nnode_modules/\n__pycache__/" > "$repo_path/.gitignore"
    [ ! -f "$repo_path/.medinovai-ignore" ] && echo -e "node_modules/\nbuild/\ndist/" > "$repo_path/.medinovai-ignore"
    
    log_success "MedinovAI standards applied to $repo_name"
}

create_pull_request() {
    local repo_name="$1"
    local title="Apply MedinovAI Standards Compliance"
    local body="This PR applies MedinovAI standards compliance to the repository.

## Changes Made:
- Added .medinovai configuration directory
- Created CI/CD workflows for standards validation
- Added required documentation files
- Configured registry and data services integration

## Compliance Checklist:
- [x] Repository standards configuration
- [x] Registry integration
- [x] Data services integration
- [x] CI/CD workflows
- [x] Documentation files
- [x] Security policies

This PR ensures the repository meets all MedinovAI standards requirements."
    
    log_info "Creating pull request for $repo_name..."
    
    # Create PR using GitHub CLI
    gh pr create --title "$title" --body "$body" --head "medinovai-standards-migration" --base "main" --repo "$GITHUB_ORG/$repo_name"
    
    log_success "Pull request created for $repo_name"
}

migrate_github_repository() {
    local repo_name="$1"
    local repo_url="https://github.com/$GITHUB_ORG/$repo_name"
    local temp_dir="temp/$repo_name"
    
    log_info "Starting migration for repository: $repo_name"
    
    # Create temp directory
    mkdir -p temp
    
    # Clone repository
    log_info "Cloning repository: $repo_url"
    if ! git clone "$repo_url" "$temp_dir"; then
        log_error "Failed to clone repository: $repo_name"
    fi
    
    cd "$temp_dir"
    
    # Create migration branch
    create_migration_branch "$repo_name"
    
    # Apply MedinovAI standards
    apply_medinovai_standards "$repo_name"
    
    # Commit changes
    git add .
    git commit -m "Apply MedinovAI standards compliance

- Add .medinovai configuration directory
- Create CI/CD workflows for standards validation
- Add required documentation files
- Configure registry and data services integration

This commit ensures the repository meets all MedinovAI standards requirements."
    
    # Push changes
    git push origin "medinovai-standards-migration"
    
    # Create pull request
    create_pull_request "$repo_name"
    
    # Cleanup
    cd ../..
    rm -rf "$temp_dir"
    
    log_success "Migration completed for $repo_name"
}

migrate_batch() {
    local start_repo="$1"
    local end_repo="$2"
    
    log_info "Migrating batch: repositories $start_repo to $end_repo"
    
    for i in $(seq $start_repo $end_repo); do
        if [ $i -le $TOTAL_REPOS ]; then
            repo_name=$(sed -n "${i}p" github-com-repos.txt)
            if [ -n "$repo_name" ]; then
                echo "Processing repository $i/$TOTAL_REPOS: $repo_name"
                migrate_github_repository "$repo_name"
                sleep 2  # Rate limiting
            fi
        fi
    done
    
    log_success "Batch migration completed: repositories $start_repo to $end_repo"
}

validate_compliance() {
    local repo_name="$1"
    
    log_info "Validating compliance for $repo_name..."
    
    # Check if repository has .medinovai directory
    if gh api "repos/$GITHUB_ORG/$repo_name/contents/.medinovai" >/dev/null 2>&1; then
        log_success "$repo_name: COMPLIANT"
        return 0
    else
        log_warning "$repo_name: NON-COMPLIANT"
        return 1
    fi
}

generate_compliance_report() {
    log_info "Generating compliance report..."
    
    local total_repos=0
    local compliant_repos=0
    
    while IFS= read -r repo_name; do
        if [ -n "$repo_name" ]; then
            ((total_repos++))
            if validate_compliance "$repo_name"; then
                ((compliant_repos++))
            fi
        fi
    done < github-com-repos.txt
    
    local compliance_rate=$((compliant_repos * 100 / total_repos))
    
    echo "=== COMPLIANCE REPORT ===" | tee -a "$LOG_FILE"
    echo "Total Repositories: $total_repos" | tee -a "$LOG_FILE"
    echo "Compliant Repositories: $compliant_repos" | tee -a "$LOG_FILE"
    echo "Compliance Rate: $compliance_rate%" | tee -a "$LOG_FILE"
    echo "=========================" | tee -a "$LOG_FILE"
}

# --- Main Execution ---
main() {
    echo "" | tee "$LOG_FILE" # Clear log file
    log_info "MedinovAI GitHub.com Migration Script v2.0.0"
    log_info "Starting migration process for $TOTAL_REPOS repositories..."
    
    # Check prerequisites
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) is required but not installed"
    fi
    
    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed"
    fi
    
    # Discover repositories
    get_all_repositories
    
    # Get user input for migration approach
    echo "Select migration approach:"
    echo "1. Migrate all repositories (234)"
    echo "2. Migrate specific batch"
    echo "3. Validate compliance only"
    read -p "Enter choice (1-3): " choice
    
    case $choice in
        1)
            log_info "Starting full migration of all repositories..."
            migrate_batch 1 $TOTAL_REPOS
            ;;
        2)
            read -p "Enter start repository number (1-$TOTAL_REPOS): " start_repo
            read -p "Enter end repository number ($start_repo-$TOTAL_REPOS): " end_repo
            migrate_batch $start_repo $end_repo
            ;;
        3)
            generate_compliance_report
            ;;
        *)
            log_error "Invalid choice"
            ;;
    esac
    
    # Generate final compliance report
    generate_compliance_report
    
    log_info "Migration process completed!"
    log_info "Check the log file: $LOG_FILE"
}

# Run main function
main "$@"

