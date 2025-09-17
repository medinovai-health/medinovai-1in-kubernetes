#!/bin/bash

# MedinovAI Implementation Validation Script
# This script validates that all components are ready for implementation

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Validation counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((PASSED_CHECKS++))
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((WARNING_CHECKS++))
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    ((FAILED_CHECKS++))
}

# Validation functions
validate_script() {
    local script_path="$1"
    local script_name="$2"
    ((TOTAL_CHECKS++))
    
    if [[ -f "$script_path" ]]; then
        if [[ -x "$script_path" ]]; then
            log_success "$script_name exists and is executable"
        else
            log_error "$script_name exists but is not executable"
        fi
    else
        log_error "$script_name not found: $script_path"
    fi
}

validate_file() {
    local file_path="$1"
    local file_name="$2"
    ((TOTAL_CHECKS++))
    
    if [[ -f "$file_path" ]]; then
        log_success "$file_name exists"
    else
        log_error "$file_name not found: $file_path"
    fi
}

validate_directory() {
    local dir_path="$1"
    local dir_name="$2"
    ((TOTAL_CHECKS++))
    
    if [[ -d "$dir_path" ]]; then
        log_success "$dir_name exists"
    else
        log_error "$dir_name not found: $dir_path"
    fi
}

validate_command() {
    local command="$1"
    local command_name="$2"
    ((TOTAL_CHECKS++))
    
    if command -v "$command" &> /dev/null; then
        log_success "$command_name is available"
    else
        log_error "$command_name is not installed or not in PATH"
    fi
}

# Main validation function
main() {
    echo "🔍 MedinovAI Implementation Validation"
    echo "======================================"
    echo "Date: $(date)"
    echo ""
    
    log_info "Validating implementation readiness..."
    echo ""
    
    # Validate required commands
    echo "📋 Checking Required Commands:"
    validate_command "gh" "GitHub CLI"
    validate_command "kubectl" "kubectl"
    validate_command "helm" "Helm"
    validate_command "jq" "jq"
    validate_command "curl" "curl"
    validate_command "git" "Git"
    echo ""
    
    # Validate core scripts
    echo "📋 Checking Core Implementation Scripts:"
    validate_script "scripts/implementation_master.sh" "Implementation Master Script"
    validate_script "scripts/discover_repositories.sh" "Repository Discovery Script"
    validate_script "scripts/create_restore_points.sh" "Restore Points Script"
    validate_script "scripts/generate_release_notes.sh" "Release Notes Script"
    validate_script "scripts/setup_github_auth.sh" "GitHub Auth Setup Script"
    validate_script "scripts/setup_cluster_components.sh" "Cluster Setup Script"
    validate_script "scripts/generate_final_report.sh" "Final Report Script"
    echo ""
    
    # Validate enhanced bulk sync script
    echo "📋 Checking Enhanced Bulk Sync Script:"
    validate_script "medinovai-infrastructure-standards/scripts/bulk_sync.sh" "Enhanced Bulk Sync Script"
    echo ""
    
    # Validate existing scripts
    echo "📋 Checking Existing Infrastructure Scripts:"
    validate_script "medinovai-infrastructure-standards/scripts/audit_status.sh" "Audit Status Script"
    validate_script "medinovai-infrastructure-standards/scripts/render_status.py" "Status Render Script"
    echo ""
    
    # Validate documentation
    echo "📋 Checking Documentation:"
    validate_file "README.md" "Main README"
    validate_file "IMPLEMENTATION_STATUS.md" "Implementation Status"
    validate_file "EXECUTION_GUIDE.md" "Execution Guide"
    validate_file "MEDINOVAI-STANDARDS-PROMPT.md" "Standards Prompt"
    validate_file "SECURITY.md" "Security Documentation"
    validate_file "CONTRIBUTING.md" "Contributing Guide"
    echo ""
    
    # Validate configuration files
    echo "📋 Checking Configuration Files:"
    validate_file ".pre-commit-config.yaml" "Pre-commit Configuration"
    validate_file ".yamllint" "YAML Linting Configuration"
    validate_file ".secrets.baseline" "Secrets Baseline"
    validate_file "Makefile" "Makefile"
    validate_file "requirements.txt" "Python Requirements"
    echo ""
    
    # Validate GitHub workflows
    echo "📋 Checking GitHub Workflows:"
    validate_file ".github/workflows/ci.yml" "CI Workflow"
    validate_file ".github/workflows/security-codeql.yml" "Security CodeQL Workflow"
    validate_file ".github/workflows/bulk-update-repos.yml" "Bulk Update Workflow"
    validate_file ".github/workflows/status-dashboard.yml" "Status Dashboard Workflow"
    echo ""
    
    # Validate GitHub configurations
    echo "📋 Checking GitHub Configurations:"
    validate_file ".github/branch-protection.yml" "Branch Protection Configuration"
    validate_file ".github/dependabot.yml" "Dependabot Configuration"
    validate_file ".github/security.yml" "Security Configuration"
    validate_file ".github/ISSUE_TEMPLATE/bug_report.yml" "Bug Report Template"
    validate_file ".github/ISSUE_TEMPLATE/feature_request.yml" "Feature Request Template"
    validate_file ".github/PULL_REQUEST_TEMPLATE.md" "Pull Request Template"
    echo ""
    
    # Validate infrastructure standards
    echo "📋 Checking Infrastructure Standards:"
    validate_directory "medinovai-infrastructure-standards" "Infrastructure Standards Directory"
    validate_file "medinovai-infrastructure-standards/STANDARDS.yaml" "Standards Definition"
    validate_file "medinovai-infrastructure-standards/README.md" "Standards README"
    validate_file "medinovai-infrastructure-standards/docs/BMAD.md" "BMAD Documentation"
    validate_file "medinovai-infrastructure-standards/docs/OPERATIONS.md" "Operations Documentation"
    echo ""
    
    # Validate templates
    echo "📋 Checking Templates:"
    validate_directory "medinovai-infrastructure-standards/templates" "Templates Directory"
    validate_directory "medinovai-infrastructure-standards/templates/medinovai-app" "MedinovAI App Template"
    validate_file "medinovai-infrastructure-standards/templates/medinovai-app/Dockerfile" "Dockerfile Template"
    validate_file "medinovai-infrastructure-standards/templates/medinovai-app/RENOVATE.json" "Renovate Template"
    echo ""
    
    # Validate policies
    echo "📋 Checking Policies:"
    validate_directory "medinovai-infrastructure-standards/policies" "Policies Directory"
    validate_directory "medinovai-infrastructure-standards/policies/kyverno" "Kyverno Policies"
    validate_file "medinovai-infrastructure-standards/policies/kyverno/require-requests-limits.yaml" "Resource Limits Policy"
    validate_file "medinovai-infrastructure-standards/policies/kyverno/disallow-hostports.yaml" "HostPorts Policy"
    validate_file "medinovai-infrastructure-standards/policies/kyverno/verify-images-cosign.yaml" "Image Verification Policy"
    echo ""
    
    # Validate platform configurations
    echo "📋 Checking Platform Configurations:"
    validate_directory "medinovai-infrastructure-standards/platform" "Platform Directory"
    validate_directory "medinovai-infrastructure-standards/platform/addons" "Addons Directory"
    validate_directory "medinovai-infrastructure-standards/platform/charts" "Charts Directory"
    validate_file "medinovai-infrastructure-standards/platform/addons/argocd-appset.yaml" "Argo CD ApplicationSet"
    echo ""
    
    # Validate OPA policies
    echo "📋 Checking OPA Policies:"
    validate_directory "policy" "OPA Policies Directory"
    validate_file "policy/github/policy.rego" "GitHub Policy"
    validate_file "policy/kubernetes/policy.rego" "Kubernetes Policy"
    validate_file "policy/terraform/policy.rego" "Terraform Policy"
    echo ""
    
    # Check GitHub authentication
    echo "📋 Checking GitHub Authentication:"
    ((TOTAL_CHECKS++))
    if gh auth status &> /dev/null; then
        log_success "GitHub CLI is authenticated"
    else
        log_warning "GitHub CLI is not authenticated (required for implementation)"
    fi
    echo ""
    
    # Check cluster access
    echo "📋 Checking Kubernetes Cluster Access:"
    ((TOTAL_CHECKS++))
    if kubectl cluster-info &> /dev/null; then
        log_success "Kubernetes cluster is accessible"
    else
        log_warning "Kubernetes cluster is not accessible (required for cluster setup)"
    fi
    echo ""
    
    # Generate validation summary
    echo "📊 Validation Summary:"
    echo "====================="
    echo "Total Checks: $TOTAL_CHECKS"
    echo "✅ Passed: $PASSED_CHECKS"
    echo "⚠️  Warnings: $WARNING_CHECKS"
    echo "❌ Failed: $FAILED_CHECKS"
    echo ""
    
    # Determine overall status
    if [[ $FAILED_CHECKS -eq 0 ]]; then
        if [[ $WARNING_CHECKS -eq 0 ]]; then
            log_success "🎉 All validations passed! Implementation is ready to proceed."
            echo ""
            echo "🚀 Next Steps:"
            echo "1. Authenticate with GitHub: ./scripts/setup_github_auth.sh"
            echo "2. Start implementation: ./scripts/implementation_master.sh"
            exit 0
        else
            log_warning "⚠️  Implementation is ready with warnings."
            echo ""
            echo "⚠️  Warnings to address:"
            echo "- GitHub authentication required"
            echo "- Kubernetes cluster access required"
            echo ""
            echo "🚀 Next Steps:"
            echo "1. Authenticate with GitHub: ./scripts/setup_github_auth.sh"
            echo "2. Ensure cluster access for cluster setup phase"
            echo "3. Start implementation: ./scripts/implementation_master.sh"
            exit 0
        fi
    else
        log_error "❌ Implementation is not ready. Please fix the failed checks above."
        echo ""
        echo "🔧 Required Actions:"
        echo "- Fix all failed checks before proceeding"
        echo "- Ensure all required tools are installed"
        echo "- Verify all scripts and configurations are in place"
        exit 1
    fi
}

# Run main function
main "$@"

