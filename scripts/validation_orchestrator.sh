#!/bin/bash

# MedinovAI Validation Orchestrator
# This script orchestrates comprehensive validation of all repository changes

set -euo pipefail

# Configuration
ORG="myonsite-healthcare"
REPO_PATTERN="medinovai"
SWARM_SIZE=10
MAX_CONCURRENT_SWARMS=3
LOG_DIR="validation_logs"
SWARM_CONFIG_DIR="validation_configs"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

log_validation() {
    echo -e "${PURPLE}🔍 $1${NC}"
}

log_orchestrator() {
    echo -e "${CYAN}🎯 $1${NC}"
}

# Execute validation phase
execute_validation_phase() {
    local phase="$1"
    local phase_name="$2"
    
    log_orchestrator "Starting Validation Phase: $phase_name"
    echo "================================================"
    
    # Create validation swarms for this phase
    log_info "Creating validation swarms for $phase_name phase..."
    if ! ./scripts/create_validation_swarms.sh --validation-type "$phase" --swarm-size "$SWARM_SIZE"; then
        log_error "Failed to create validation swarms for $phase_name phase"
        return 1
    fi
    
    # Execute validation swarms
    log_info "Executing validation swarms for $phase_name phase..."
    if ! ./scripts/execute_validation_swarms.sh; then
        log_error "Failed to execute validation swarms for $phase_name phase"
        return 1
    fi
    
    # Generate phase report
    log_info "Generating $phase_name phase validation report..."
    generate_validation_phase_report "$phase"
    
    log_success "$phase_name phase validation completed successfully"
    return 0
}

# Generate validation phase report
generate_validation_phase_report() {
    local phase="$1"
    local report_file="$LOG_DIR/${phase}_validation_report.json"
    
    local total_repos=0
    local total_success=0
    local total_failed=0
    
    # Collect data from validation execution report
    if [[ -f "$LOG_DIR/validation_execution_report.json" ]]; then
        total_repos=$(jq -r '.validation_summary.total_repositories' "$LOG_DIR/validation_execution_report.json")
        total_success=$(jq -r '.validation_summary.successful_validations' "$LOG_DIR/validation_execution_report.json")
        total_failed=$(jq -r '.validation_summary.failed_validations' "$LOG_DIR/validation_execution_report.json")
    fi
    
    cat > "$report_file" << EOF
{
  "phase": "$phase",
  "total_repositories": $total_repos,
  "successful_validations": $total_success,
  "failed_validations": $total_failed,
  "success_rate": $(echo "scale=2; $total_success * 100 / $total_repos" | bc -l),
  "completed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "completed"
}
EOF
    
    log_success "$phase validation report generated: $total_success/$total_repos successful"
}

# Generate final validation report
generate_final_validation_report() {
    log_info "Generating final validation report..."
    
    local total_repos=0
    local total_success=0
    local total_failed=0
    local phases_completed=0
    
    # Collect data from all phase reports
    for phase in comprehensive security performance observability; do
        local report_file="$LOG_DIR/${phase}_validation_report.json"
        if [[ -f "$report_file" ]]; then
            local repos=$(jq -r '.total_repositories' "$report_file")
            local success=$(jq -r '.successful_validations' "$report_file")
            local failed=$(jq -r '.failed_validations' "$report_file")
            
            total_repos=$((total_repos + repos))
            total_success=$((total_success + success))
            total_failed=$((total_failed + failed))
            ((phases_completed++))
        fi
    done
    
    # Generate comprehensive final report
    cat > "$LOG_DIR/final_validation_report.json" << EOF
{
  "validation_summary": {
    "total_phases": 4,
    "completed_phases": $phases_completed,
    "total_repositories": $total_repos,
    "successful_validations": $total_success,
    "failed_validations": $total_failed,
    "overall_success_rate": $(echo "scale=2; $total_success * 100 / $total_repos" | bc -l),
    "validation_completed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "status": "completed"
  },
  "phase_summaries": [
EOF
    
    # Add individual phase summaries
    local first=true
    for phase in comprehensive security performance observability; do
        local report_file="$LOG_DIR/${phase}_validation_report.json"
        if [[ -f "$report_file" ]]; then
            if [[ "$first" == "true" ]]; then
                first=false
            else
                echo "," >> "$LOG_DIR/final_validation_report.json"
            fi
            jq '.phase, .total_repositories, .successful_validations, .failed_validations, .success_rate, .completed_at' "$report_file" | jq -s '{
                phase: .[0],
                total_repositories: .[1],
                successful_validations: .[2],
                failed_validations: .[3],
                success_rate: .[4],
                completed_at: .[5]
            }' >> "$LOG_DIR/final_validation_report.json"
        fi
    done
    
    cat >> "$LOG_DIR/final_validation_report.json" << EOF
  ]
}
EOF
    
    log_success "Final validation report generated"
}

# Run comprehensive Playwright tests
run_comprehensive_playwright_tests() {
    log_info "Running comprehensive Playwright tests..."
    
    # Check if Playwright is installed
    if ! command -v npx >/dev/null 2>&1; then
        log_warning "npx not available, installing Playwright..."
        npm install @playwright/test
        npx playwright install
    fi
    
    # Run all Playwright tests
    log_info "Executing comprehensive Playwright test suite..."
    if npx playwright test --reporter=html,json,junit --workers=4; then
        log_success "Playwright tests completed successfully"
    else
        log_warning "Playwright tests completed with some failures"
    fi
    
    # Generate comprehensive Playwright report
    if [[ -f "playwright-results.json" ]]; then
        log_info "Generating comprehensive Playwright test report..."
        node -e "
        const fs = require('fs');
        const results = JSON.parse(fs.readFileSync('playwright-results.json', 'utf8'));
        const summary = {
          timestamp: new Date().toISOString(),
          totalTests: results.stats?.total || 0,
          passed: results.stats?.passed || 0,
          failed: results.stats?.failed || 0,
          skipped: results.stats?.skipped || 0,
          duration: results.stats?.duration || 0,
          successRate: results.stats?.total > 0 ? 
            ((results.stats.passed / results.stats.total) * 100).toFixed(2) + '%' : '0%',
          testSuites: results.suites?.length || 0,
          browsers: ['chromium', 'firefox', 'webkit'],
          environments: ['desktop', 'mobile']
        };
        fs.writeFileSync('$LOG_DIR/comprehensive_playwright_report.json', JSON.stringify(summary, null, 2));
        console.log('Comprehensive Playwright test report generated');
        "
    fi
}

# Cleanup function
cleanup() {
    log_info "Cleaning up validation processes and temporary files"
    
    # Kill any remaining validation swarm processes
    for pid_file in "$LOG_DIR"/validation_swarm_*.pid; do
        if [[ -f "$pid_file" ]]; then
            local pid
            pid=$(cat "$pid_file")
            if kill -0 "$pid" 2>/dev/null; then
                log_warning "Terminating validation swarm process $pid"
                kill "$pid" 2>/dev/null || true
            fi
            rm -f "$pid_file"
        fi
    done
    
    # Clean up temporary directories
    rm -rf /tmp/medinovai-validation-*
}

# Main execution
main() {
    echo "🔍 MedinovAI Validation Orchestrator"
    echo "===================================="
    echo "Organization: $ORG"
    echo "Repository Pattern: $REPO_PATTERN"
    echo "Swarm Size: $SWARM_SIZE"
    echo "Max Concurrent Swarms: $MAX_CONCURRENT_SWARMS"
    echo "Date: $(date)"
    echo ""
    
    # Create directories
    mkdir -p "$LOG_DIR" "$SWARM_CONFIG_DIR"
    
    # Set up cleanup trap
    trap cleanup EXIT INT TERM
    
    # Check prerequisites
    log_info "Checking prerequisites..."
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) is required"
        exit 1
    fi
    
    if ! gh auth status &> /dev/null; then
        log_error "GitHub CLI is not authenticated"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log_error "jq is required for JSON processing"
        exit 1
    fi
    
    if ! command -v bc &> /dev/null; then
        log_error "bc is required for calculations"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
    
    # Ask for confirmation
    log_warning "This will validate ALL repository changes using agent swarms and Playwright tests."
    echo "The validation will run comprehensive checks across multiple phases for maximum coverage."
    echo ""
    read -p "Are you sure you want to proceed with comprehensive validation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Validation cancelled"
        exit 0
    fi
    
    # Execute validation phases
    log_orchestrator "Starting comprehensive validation with agent swarms"
    echo "============================================================="
    
    # Phase 1: Comprehensive Validation
    if ! execute_validation_phase "comprehensive" "Comprehensive"; then
        log_error "Comprehensive validation phase failed"
        exit 1
    fi
    
    # Phase 2: Security Validation
    if ! execute_validation_phase "security" "Security"; then
        log_error "Security validation phase failed"
        exit 1
    fi
    
    # Phase 3: Performance Validation
    if ! execute_validation_phase "performance" "Performance"; then
        log_error "Performance validation phase failed"
        exit 1
    fi
    
    # Phase 4: Observability Validation
    if ! execute_validation_phase "observability" "Observability"; then
        log_error "Observability validation phase failed"
        exit 1
    fi
    
    # Run comprehensive Playwright tests
    run_comprehensive_playwright_tests
    
    # Generate final report
    generate_final_validation_report
    
    echo ""
    log_success "🎉 MedinovAI Comprehensive Validation Complete!"
    echo ""
    echo "📊 Validation Summary:"
    echo "  📁 Log Directory: $LOG_DIR"
    echo "  📄 Final Report: $LOG_DIR/final_validation_report.json"
    echo "  📋 Phase Reports: $LOG_DIR/*_validation_report.json"
    echo "  📋 Swarm Reports: $LOG_DIR/validation_swarm_*_report.json"
    echo "  🎭 Playwright Report: $LOG_DIR/comprehensive_playwright_report.json"
    echo ""
    echo "🔍 Next Steps:"
    echo "  1. Review final validation report: cat $LOG_DIR/final_validation_report.json"
    echo "  2. Check individual validation logs: ls $LOG_DIR/validation_swarm_*.log"
    echo "  3. Review Playwright test results: open playwright-report/index.html"
    echo "  4. Address any validation failures"
    echo "  5. Re-run validation if needed"
    echo ""
    echo "📞 Support:"
    echo "  - Platform Team: platform-team@myonsitehealthcare.com"
    echo "  - Security Team: security-team@myonsitehealthcare.com"
    echo "  - On-Call: @platform-oncall"
}

# Run main function
main "$@"

