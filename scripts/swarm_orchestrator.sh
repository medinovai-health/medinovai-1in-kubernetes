#!/bin/bash

# MedinovAI Swarm Orchestrator
# This script orchestrates the complete BMAD implementation using agent swarms

set -euo pipefail

# Configuration
ORG="myonsite-healthcare"
REPO_PATTERN="medinovai"
SWARM_SIZE=10
MAX_CONCURRENT_SWARMS=3
LOG_DIR="swarm_logs"
SWARM_CONFIG_DIR="swarm_configs"

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

log_swarm() {
    echo -e "${PURPLE}🤖 $1${NC}"
}

log_orchestrator() {
    echo -e "${CYAN}🎯 $1${NC}"
}

# Execute BMAD phase with swarms
execute_bmad_phase() {
    local phase="$1"
    local phase_name="$2"
    
    log_orchestrator "Starting BMAD Phase: $phase_name"
    echo "================================================"
    
    # Create agent swarms for this phase
    log_info "Creating agent swarms for $phase_name phase..."
    if ! ./scripts/create_agent_swarms.sh --phase "$phase" --swarm-size "$SWARM_SIZE"; then
        log_error "Failed to create agent swarms for $phase_name phase"
        return 1
    fi
    
    # Execute swarms
    log_info "Executing agent swarms for $phase_name phase..."
    if ! ./scripts/execute_agent_swarms.sh; then
        log_error "Failed to execute agent swarms for $phase_name phase"
        return 1
    fi
    
    # Generate phase report
    log_info "Generating $phase_name phase report..."
    generate_phase_report "$phase"
    
    log_success "$phase_name phase completed successfully"
    return 0
}

# Generate phase report
generate_phase_report() {
    local phase="$1"
    local report_file="$LOG_DIR/${phase}_phase_report.json"
    
    local total_repos=0
    local total_success=0
    local total_failed=0
    
    # Collect data from execution report
    if [[ -f "$LOG_DIR/execution_report.json" ]]; then
        total_repos=$(jq -r '.execution_summary.total_repositories' "$LOG_DIR/execution_report.json")
        total_success=$(jq -r '.execution_summary.successful_repositories' "$LOG_DIR/execution_report.json")
        total_failed=$(jq -r '.execution_summary.failed_repositories' "$LOG_DIR/execution_report.json")
    fi
    
    cat > "$report_file" << EOF
{
  "phase": "$phase",
  "total_repositories": $total_repos,
  "successful_repositories": $total_success,
  "failed_repositories": $total_failed,
  "success_rate": $(echo "scale=2; $total_success * 100 / $total_repos" | bc -l),
  "completed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "completed"
}
EOF
    
    log_success "$phase phase report generated: $total_success/$total_repos successful"
}

# Generate final implementation report
generate_final_report() {
    log_info "Generating final implementation report..."
    
    local total_repos=0
    local total_success=0
    local total_failed=0
    local phases_completed=0
    
    # Collect data from all phase reports
    for phase in bootstrap migrate audit deepen; do
        local report_file="$LOG_DIR/${phase}_phase_report.json"
        if [[ -f "$report_file" ]]; then
            local repos=$(jq -r '.total_repositories' "$report_file")
            local success=$(jq -r '.successful_repositories' "$report_file")
            local failed=$(jq -r '.failed_repositories' "$report_file")
            
            total_repos=$((total_repos + repos))
            total_success=$((total_success + success))
            total_failed=$((total_failed + failed))
            ((phases_completed++))
        fi
    done
    
    # Generate comprehensive final report
    cat > "$LOG_DIR/final_implementation_report.json" << EOF
{
  "implementation_summary": {
    "total_phases": 4,
    "completed_phases": $phases_completed,
    "total_repositories": $total_repos,
    "successful_repositories": $total_success,
    "failed_repositories": $total_failed,
    "overall_success_rate": $(echo "scale=2; $total_success * 100 / $total_repos" | bc -l),
    "implementation_completed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "status": "completed"
  },
  "phase_summaries": [
EOF
    
    # Add individual phase summaries
    local first=true
    for phase in bootstrap migrate audit deepen; do
        local report_file="$LOG_DIR/${phase}_phase_report.json"
        if [[ -f "$report_file" ]]; then
            if [[ "$first" == "true" ]]; then
                first=false
            else
                echo "," >> "$LOG_DIR/final_implementation_report.json"
            fi
            jq '.phase, .total_repositories, .successful_repositories, .failed_repositories, .success_rate, .completed_at' "$report_file" | jq -s '{
                phase: .[0],
                total_repositories: .[1],
                successful_repositories: .[2],
                failed_repositories: .[3],
                success_rate: .[4],
                completed_at: .[5]
            }' >> "$LOG_DIR/final_implementation_report.json"
        fi
    done
    
    cat >> "$LOG_DIR/final_implementation_report.json" << EOF
  ]
}
EOF
    
    log_success "Final implementation report generated"
}

# Cleanup function
cleanup() {
    log_info "Cleaning up swarm processes and temporary files"
    
    # Kill any remaining swarm processes
    for pid_file in "$LOG_DIR"/swarm_*.pid; do
        if [[ -f "$pid_file" ]]; then
            local pid
            pid=$(cat "$pid_file")
            if kill -0 "$pid" 2>/dev/null; then
                log_warning "Terminating swarm process $pid"
                kill "$pid" 2>/dev/null || true
            fi
            rm -f "$pid_file"
        fi
    done
    
    # Clean up temporary directories
    rm -rf /tmp/medinovai-agent-*
}

# Main execution
main() {
    echo "🎯 MedinovAI Swarm Orchestrator"
    echo "==============================="
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
    
    log_success "Prerequisites check passed"
    
    # Ask for confirmation
    log_warning "This will implement MedinovAI standards across ALL repositories using agent swarms."
    echo "The implementation will run in parallel across multiple swarms for maximum efficiency."
    echo ""
    read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Implementation cancelled"
        exit 0
    fi
    
    # Execute BMAD phases
    log_orchestrator "Starting BMAD implementation with agent swarms"
    echo "========================================================"
    
    # Phase 1: Bootstrap
    if ! execute_bmad_phase "bootstrap" "Bootstrap"; then
        log_error "Bootstrap phase failed"
        exit 1
    fi
    
    # Phase 2: Migrate
    if ! execute_bmad_phase "migrate" "Migrate"; then
        log_error "Migrate phase failed"
        exit 1
    fi
    
    # Phase 3: Audit
    if ! execute_bmad_phase "audit" "Audit"; then
        log_error "Audit phase failed"
        exit 1
    fi
    
    # Phase 4: Deepen
    if ! execute_bmad_phase "deepen" "Deepen"; then
        log_error "Deepen phase failed"
        exit 1
    fi
    
    # Generate final report
    generate_final_report
    
    echo ""
    log_success "🎉 MedinovAI Infrastructure Implementation Complete!"
    echo ""
    echo "📊 Implementation Summary:"
    echo "  📁 Log Directory: $LOG_DIR"
    echo "  📄 Final Report: $LOG_DIR/final_implementation_report.json"
    echo "  📋 Phase Reports: $LOG_DIR/*_phase_report.json"
    echo "  📋 Swarm Reports: $LOG_DIR/swarm_*_report.json"
    echo ""
    echo "🔍 Next Steps:"
    echo "  1. Review final report: cat $LOG_DIR/final_implementation_report.json"
    echo "  2. Check created PRs in GitHub"
    echo "  3. Review and merge PRs by wave (dev → stage → prod)"
    echo "  4. Monitor deployment status"
    echo "  5. Conduct post-implementation review"
    echo ""
    echo "📞 Support:"
    echo "  - Platform Team: platform-team@myonsitehealthcare.com"
    echo "  - Security Team: security-team@myonsitehealthcare.com"
    echo "  - On-Call: @platform-oncall"
}

# Run main function
main "$@"








