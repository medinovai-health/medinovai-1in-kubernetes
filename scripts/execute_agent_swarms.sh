#!/bin/bash

# MedinovAI Agent Swarms Execution Script
# This script executes all agent swarms in parallel

set -euo pipefail

# Configuration
SWARM_CONFIG_DIR="swarm_configs"
LOG_DIR="swarm_logs"
MAX_CONCURRENT_SWARMS=3

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

log_coordinator() {
    echo -e "${CYAN}🎯 $1${NC}"
}

# Execute swarm
execute_swarm() {
    local swarm_id="$1"
    local coordinator_script="$SWARM_CONFIG_DIR/coordinator_${swarm_id}.sh"
    
    if [[ ! -f "$coordinator_script" ]]; then
        log_error "Coordinator script not found for Swarm $swarm_id"
        return 1
    fi
    
    log_swarm "Starting Swarm $swarm_id"
    
    # Execute coordinator in background
    "$coordinator_script" "$swarm_id" "$SWARM_CONFIG_DIR/swarm_${swarm_id}_config.json" "$LOG_DIR" &
    local coordinator_pid=$!
    
    # Store PID for monitoring
    echo "$coordinator_pid" > "$LOG_DIR/swarm_${swarm_id}.pid"
    
    log_success "Swarm $swarm_id started with PID $coordinator_pid"
    return 0
}

# Monitor swarms
monitor_swarms() {
    local swarm_pids=()
    local swarm_count=0
    
    log_coordinator "Starting swarm monitoring"
    
    # Collect swarm PIDs
    for pid_file in "$LOG_DIR"/swarm_*.pid; do
        if [[ -f "$pid_file" ]]; then
            local pid
            pid=$(cat "$pid_file")
            if kill -0 "$pid" 2>/dev/null; then
                swarm_pids+=("$pid")
                ((swarm_count++))
            fi
        fi
    done
    
    log_coordinator "Monitoring $swarm_count active swarms"
    
    # Monitor until all swarms complete
    local completed_swarms=0
    while [[ $completed_swarms -lt $swarm_count ]]; do
        for i in "${!swarm_pids[@]}"; do
            if ! kill -0 "${swarm_pids[$i]}" 2>/dev/null; then
                wait "${swarm_pids[$i]}"
                local exit_code=$?
                if [[ $exit_code -eq 0 ]]; then
                    log_success "Swarm $((i+1)) completed successfully"
                else
                    log_error "Swarm $((i+1)) failed with exit code $exit_code"
                fi
                unset swarm_pids[$i]
                ((completed_swarms++))
            fi
        done
        
        # Show progress
        if [[ $((completed_swarms % 5)) -eq 0 ]]; then
            log_info "Progress: $completed_swarms/$swarm_count swarms completed"
        fi
        
        sleep 10
    done
    
    log_success "All swarms completed"
}

# Generate execution report
generate_execution_report() {
    log_info "Generating execution report"
    
    local total_repos=0
    local total_success=0
    local total_failed=0
    local swarm_count=0
    
    # Collect data from all swarm reports
    for report_file in "$LOG_DIR"/swarm_*_report.json; do
        if [[ -f "$report_file" ]]; then
            local repos=$(jq -r '.total_repositories' "$report_file")
            local success=$(jq -r '.successful_repositories' "$report_file")
            local failed=$(jq -r '.failed_repositories' "$report_file")
            
            total_repos=$((total_repos + repos))
            total_success=$((total_success + success))
            total_failed=$((total_failed + failed))
            ((swarm_count++))
        fi
    done
    
    # Generate comprehensive report
    cat > "$LOG_DIR/execution_report.json" << EOF
{
  "execution_summary": {
    "total_swarms": $swarm_count,
    "total_repositories": $total_repos,
    "successful_repositories": $total_success,
    "failed_repositories": $total_failed,
    "success_rate": $(echo "scale=2; $total_success * 100 / $total_repos" | bc -l),
    "execution_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "status": "completed"
  },
  "swarm_details": [
EOF
    
    # Add individual swarm details
    local first=true
    for report_file in "$LOG_DIR"/swarm_*_report.json; do
        if [[ -f "$report_file" ]]; then
            if [[ "$first" == "true" ]]; then
                first=false
            else
                echo "," >> "$LOG_DIR/execution_report.json"
            fi
            jq '.swarm_id, .phase, .total_repositories, .successful_repositories, .failed_repositories, .success_rate' "$report_file" | jq -s '{
                swarm_id: .[0],
                phase: .[1],
                total_repositories: .[2],
                successful_repositories: .[3],
                failed_repositories: .[4],
                success_rate: .[5]
            }' >> "$LOG_DIR/execution_report.json"
        fi
    done
    
    cat >> "$LOG_DIR/execution_report.json" << EOF
  ]
}
EOF
    
    log_success "Execution report generated: $total_success/$total_repos repositories successful"
}

# Cleanup function
cleanup() {
    log_info "Cleaning up swarm processes"
    
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
}

# Main execution
main() {
    echo "🚀 MedinovAI Agent Swarms Execution"
    echo "==================================="
    echo "Date: $(date)"
    echo "Max Concurrent Swarms: $MAX_CONCURRENT_SWARMS"
    echo ""
    
    # Check if swarm configurations exist
    if [[ ! -d "$SWARM_CONFIG_DIR" ]]; then
        log_error "Swarm configurations not found. Run create_agent_swarms.sh first."
        exit 1
    fi
    
    # Create log directory
    mkdir -p "$LOG_DIR"
    
    # Set up cleanup trap
    trap cleanup EXIT INT TERM
    
    log_info "Starting agent swarms execution..."
    
    # Find all swarm configurations
    local swarm_configs=()
    for config_file in "$SWARM_CONFIG_DIR"/swarm_*_config.json; do
        if [[ -f "$config_file" ]]; then
            swarm_configs+=("$config_file")
        fi
    done
    
    if [[ ${#swarm_configs[@]} -eq 0 ]]; then
        log_error "No swarm configurations found"
        exit 1
    fi
    
    log_success "Found ${#swarm_configs[@]} swarm configurations"
    
    # Execute swarms in batches
    local batch_start=0
    while [[ $batch_start -lt ${#swarm_configs[@]} ]]; do
        local batch_end=$((batch_start + MAX_CONCURRENT_SWARMS))
        if [[ $batch_end -gt ${#swarm_configs[@]} ]]; then
            batch_end=${#swarm_configs[@]}
        fi
        
        log_info "Executing batch: swarms $((batch_start + 1))-$batch_end"
        
        # Start swarms in current batch
        for ((i=batch_start; i<batch_end; i++)); do
            local config_file="${swarm_configs[$i]}"
            local swarm_id
            swarm_id=$(jq -r '.swarm_id' "$config_file")
            execute_swarm "$swarm_id"
        done
        
        # Monitor current batch
        monitor_swarms
        
        # Move to next batch
        batch_start=$batch_end
        
        if [[ $batch_start -lt ${#swarm_configs[@]} ]]; then
            log_info "Starting next batch of swarms..."
            sleep 5
        fi
    done
    
    # Generate final report
    generate_execution_report
    
    echo ""
    log_success "🎉 All agent swarms execution completed!"
    echo ""
    echo "📊 Execution Summary:"
    echo "  📁 Log Directory: $LOG_DIR"
    echo "  📄 Execution Report: $LOG_DIR/execution_report.json"
    echo "  📋 Individual Swarm Reports: $LOG_DIR/swarm_*_report.json"
    echo ""
    echo "🔍 Next Steps:"
    echo "  1. Review execution report: cat $LOG_DIR/execution_report.json"
    echo "  2. Check individual swarm logs: ls $LOG_DIR/swarm_*.log"
    echo "  3. Monitor created PRs in GitHub"
    echo "  4. Proceed to next BMAD phase if needed"
}

# Run main function
main "$@"

