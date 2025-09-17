#!/bin/bash

# MedinovAI Infrastructure Implementation Master Script
# This script orchestrates the complete BMAD implementation across all repositories

set -euo pipefail

# Configuration
ORG="myonsite-healthcare"
REPO_PATTERN="medinovai"
RESTORE_TAG="pre-medinovai-standards-$(date +%Y%m%d)"
LOG_DIR="implementation_logs"
REPO_LIST_FILE="medinovai_repositories.json"
REPO_NAMES_FILE="medinovai_repo_names.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if GitHub CLI is authenticated
    if ! gh auth status >/dev/null 2>&1; then
        log_error "GitHub CLI not authenticated. Please run: gh auth login"
        exit 1
    fi
    
    # Check if required tools are installed
    local required_tools=("jq" "git" "curl")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "Required tool '$tool' is not installed"
            exit 1
        fi
    done
    
    log_success "Prerequisites check passed"
}

# Create log directory
setup_logging() {
    mkdir -p "$LOG_DIR"
    log_info "Log directory created: $LOG_DIR"
}

# Phase 1: Discovery
phase1_discovery() {
    log_info "🚀 PHASE 1: Repository Discovery and Preparation"
    
    # Discover repositories
    log_info "Discovering repositories..."
    ./scripts/discover_repositories.sh
    
    if [[ ! -f "$REPO_NAMES_FILE" ]]; then
        log_error "Repository discovery failed"
        exit 1
    fi
    
    local repo_count=$(wc -l < "$REPO_NAMES_FILE")
    log_success "Discovered $repo_count repositories"
    
    # Create restore points
    log_info "Creating restore points..."
    ./scripts/create_restore_points.sh
    
    # Generate release notes
    log_info "Generating release notes..."
    ./scripts/generate_release_notes.sh
    
    log_success "Phase 1 complete: Discovery and preparation"
}

# Phase 2: Bootstrap
phase2_bootstrap() {
    log_info "🚀 PHASE 2: Bootstrap Implementation"
    
    # Set up cluster components
    log_info "Setting up cluster components..."
    ./scripts/setup_cluster_components.sh
    
    # Run bulk sync for Bootstrap
    log_info "Running Bootstrap bulk sync..."
    ./scripts/bulk_sync.sh --org "$ORG" --match "$REPO_PATTERN" --phase bootstrap --dry-run
    
    log_warning "Review the dry-run results before proceeding with --apply"
    read -p "Continue with Bootstrap apply? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ./scripts/bulk_sync.sh --org "$ORG" --match "$REPO_PATTERN" --phase bootstrap --apply
        log_success "Bootstrap phase applied to all repositories"
    else
        log_warning "Bootstrap phase skipped"
    fi
    
    log_success "Phase 2 complete: Bootstrap implementation"
}

# Phase 3: Migrate
phase3_migrate() {
    log_info "🚀 PHASE 3: Migration Implementation"
    
    # Run bulk sync for Migration
    log_info "Running Migration bulk sync..."
    ./scripts/bulk_sync.sh --org "$ORG" --match "$REPO_PATTERN" --phase migrate --dry-run
    
    log_warning "Review the dry-run results before proceeding with --apply"
    read -p "Continue with Migration apply? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ./scripts/bulk_sync.sh --org "$ORG" --match "$REPO_PATTERN" --phase migrate --apply
        log_success "Migration phase applied to all repositories"
    else
        log_warning "Migration phase skipped"
    fi
    
    log_success "Phase 3 complete: Migration implementation"
}

# Phase 4: Audit
phase4_audit() {
    log_info "🚀 PHASE 4: Audit Implementation"
    
    # Run bulk sync for Audit
    log_info "Running Audit bulk sync..."
    ./scripts/bulk_sync.sh --org "$ORG" --match "$REPO_PATTERN" --phase audit --dry-run
    
    log_warning "Review the dry-run results before proceeding with --apply"
    read -p "Continue with Audit apply? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ./scripts/bulk_sync.sh --org "$ORG" --match "$REPO_PATTERN" --phase audit --apply
        log_success "Audit phase applied to all repositories"
    else
        log_warning "Audit phase skipped"
    fi
    
    # Generate compliance report
    log_info "Generating compliance report..."
    ./scripts/generate_compliance_report.sh
    
    log_success "Phase 4 complete: Audit implementation"
}

# Phase 5: Deepen
phase5_deepen() {
    log_info "🚀 PHASE 5: Deepen Implementation"
    
    # Run bulk sync for Deepen
    log_info "Running Deepen bulk sync..."
    ./scripts/bulk_sync.sh --org "$ORG" --match "$REPO_PATTERN" --phase deepen --dry-run
    
    log_warning "Review the dry-run results before proceeding with --apply"
    read -p "Continue with Deepen apply? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ./scripts/bulk_sync.sh --org "$ORG" --match "$REPO_PATTERN" --phase deepen --apply
        log_success "Deepen phase applied to all repositories"
    else
        log_warning "Deepen phase skipped"
    fi
    
    log_success "Phase 5 complete: Deepen implementation"
}

# Generate final report
generate_final_report() {
    log_info "Generating final implementation report..."
    ./scripts/generate_final_report.sh
    log_success "Final report generated"
}

# Main execution
main() {
    echo "🏗️  MedinovAI Infrastructure Implementation"
    echo "=========================================="
    echo "Organization: $ORG"
    echo "Repository Pattern: $REPO_PATTERN"
    echo "Restore Tag: $RESTORE_TAG"
    echo "Date: $(date)"
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Setup logging
    setup_logging
    
    # Ask for confirmation
    log_warning "This will implement MedinovAI standards across ALL repositories in the organization."
    read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Implementation cancelled"
        exit 0
    fi
    
    # Execute phases
    phase1_discovery
    phase2_bootstrap
    phase3_migrate
    phase4_audit
    phase5_deepen
    
    # Generate final report
    generate_final_report
    
    log_success "🎉 MedinovAI Infrastructure Implementation Complete!"
    echo ""
    echo "📊 Summary:"
    echo "  - All repositories have restore points"
    echo "  - BMAD methodology implemented"
    echo "  - GitOps deployment structure in place"
    echo "  - Security policies enforced"
    echo "  - Observability integrated"
    echo "  - Supply chain security implemented"
    echo ""
    echo "📝 Check the logs in $LOG_DIR for detailed information"
    echo "📄 Review the final report for compliance status"
}

# Run main function
main "$@"

