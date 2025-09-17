#!/bin/bash

# MedinovAI Validation Swarm Monitoring Script
# This script provides real-time monitoring of validation swarms

set -euo pipefail

# Configuration
LOG_DIR="validation_logs"
SWARM_CONFIG_DIR="validation_configs"
REFRESH_INTERVAL=10

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

log_coordinator() {
    echo -e "${CYAN}🎯 $1${NC}"
}

# Get validation swarm status
get_validation_swarm_status() {
    local swarm_id="$1"
    local status_file="$LOG_DIR/validation_swarm_${swarm_id}_status.json"
    
    if [[ -f "$status_file" ]]; then
        jq -r '.status' "$status_file" 2>/dev/null || echo "unknown"
    else
        echo "not_started"
    fi
}

# Get validation agent status
get_validation_agent_status() {
    local swarm_id="$1"
    local agent_id="$2"
    local status_file="$LOG_DIR/validation_swarm_${swarm_id}_agent_${agent_id}_status.json"
    
    if [[ -f "$status_file" ]]; then
        local status
        status=$(jq -r '.status' "$status_file" 2>/dev/null || echo "unknown")
        local success
        success=$(jq -r '.success_count' "$status_file" 2>/dev/null || echo "0")
        local failed
        failed=$(jq -r '.failed_count' "$status_file" 2>/dev/null || echo "0")
        echo "$status:$success:$failed"
    else
        echo "not_started:0:0"
    fi
}

# Display validation dashboard
display_validation_dashboard() {
    clear
    echo "🔍 MedinovAI Validation Swarms Dashboard"
    echo "========================================"
    echo "Last Updated: $(date)"
    echo ""
    
    # Get all validation swarm configurations
    local swarm_count=0
    local total_repos=0
    local total_success=0
    local total_failed=0
    local active_swarms=0
    local completed_swarms=0
    
    for config_file in "$SWARM_CONFIG_DIR"/validation_swarm_*_config.json; do
        if [[ -f "$config_file" ]]; then
            local swarm_id
            swarm_id=$(jq -r '.swarm_id' "$config_file")
            local validation_type
            validation_type=$(jq -r '.validation_type' "$config_file")
            local repo_count
            repo_count=$(jq -r '.repositories | length' "$config_file")
            
            ((swarm_count++))
            total_repos=$((total_repos + repo_count))
            
            # Get swarm status
            local swarm_status
            swarm_status=$(get_validation_swarm_status "$swarm_id")
            
            case "$swarm_status" in
                "running")
                    echo -e "${YELLOW}🔍 Validation Swarm $swarm_id ($validation_type): RUNNING${NC}"
                    ((active_swarms++))
                    ;;
                "completed")
                    echo -e "${GREEN}✅ Validation Swarm $swarm_id ($validation_type): COMPLETED${NC}"
                    ((completed_swarms++))
                    ;;
                "failed")
                    echo -e "${RED}❌ Validation Swarm $swarm_id ($validation_type): FAILED${NC}"
                    ;;
                *)
                    echo -e "${BLUE}⏳ Validation Swarm $swarm_id ($validation_type): NOT STARTED${NC}"
                    ;;
            esac
            
            # Show agent details
            for agent_id in $(seq 1 5); do
                local agent_status_info
                agent_status_info=$(get_validation_agent_status "$swarm_id" "$agent_id")
                local agent_status
                agent_status=$(echo "$agent_status_info" | cut -d: -f1)
                local agent_success
                agent_success=$(echo "$agent_status_info" | cut -d: -f2)
                local agent_failed
                agent_failed=$(echo "$agent_status_info" | cut -d: -f3)
                
                case "$agent_status" in
                    "completed")
                        echo -e "  ${GREEN}  ✅ Validation Agent $agent_id: $agent_success successful, $agent_failed failed${NC}"
                        total_success=$((total_success + agent_success))
                        total_failed=$((total_failed + agent_failed))
                        ;;
                    "running")
                        echo -e "  ${YELLOW}  🔄 Validation Agent $agent_id: Running...${NC}"
                        ;;
                    "failed")
                        echo -e "  ${RED}  ❌ Validation Agent $agent_id: Failed${NC}"
                        ;;
                    *)
                        echo -e "  ${BLUE}  ⏳ Validation Agent $agent_id: Not started${NC}"
                        ;;
                esac
            done
            echo ""
        fi
    done
    
    # Display summary
    echo "📊 Validation Summary:"
    echo "  🔍 Total Validation Swarms: $swarm_count"
    echo "  🔄 Active Validation Swarms: $active_swarms"
    echo "  ✅ Completed Validation Swarms: $completed_swarms"
    echo "  📁 Total Repositories: $total_repos"
    echo "  ✅ Successful Validations: $total_success"
    echo "  ❌ Failed Validations: $total_failed"
    
    if [[ $total_repos -gt 0 ]]; then
        local success_rate
        success_rate=$(echo "scale=1; $total_success * 100 / $total_repos" | bc -l)
        echo "  📈 Validation Success Rate: ${success_rate}%"
    fi
    
    echo ""
    echo "Press Ctrl+C to exit monitoring"
}

# Monitor validation swarms continuously
monitor_continuous() {
    log_info "Starting continuous validation monitoring (refresh every ${REFRESH_INTERVAL}s)"
    
    while true; do
        display_validation_dashboard
        sleep "$REFRESH_INTERVAL"
    done
}

# Show validation swarm logs
show_validation_swarm_logs() {
    local swarm_id="$1"
    local log_file="$LOG_DIR/validation_swarm_${swarm_id}.log"
    
    if [[ -f "$log_file" ]]; then
        echo "📋 Validation Swarm $swarm_id Logs:"
        echo "==================================="
        tail -50 "$log_file"
    else
        log_warning "No logs found for Validation Swarm $swarm_id"
    fi
}

# Show validation agent logs
show_validation_agent_logs() {
    local swarm_id="$1"
    local agent_id="$2"
    local log_file="$LOG_DIR/validation_swarm_${swarm_id}_agent_${agent_id}.log"
    
    if [[ -f "$log_file" ]]; then
        echo "📋 Validation Swarm $swarm_id, Agent $agent_id Logs:"
        echo "=================================================="
        tail -50 "$log_file"
    else
        log_warning "No logs found for Validation Swarm $swarm_id, Agent $agent_id"
    fi
}

# Show validation execution report
show_validation_execution_report() {
    local report_file="$LOG_DIR/validation_execution_report.json"
    
    if [[ -f "$report_file" ]]; then
        echo "📊 Validation Execution Report:"
        echo "==============================="
        jq '.' "$report_file"
    else
        log_warning "No validation execution report found"
    fi
}

# Show Playwright test report
show_playwright_test_report() {
    local report_file="$LOG_DIR/playwright_test_report.json"
    
    if [[ -f "$report_file" ]]; then
        echo "🎭 Playwright Test Report:"
        echo "========================="
        jq '.' "$report_file"
    else
        log_warning "No Playwright test report found"
    fi
}

# Show comprehensive validation summary
show_validation_summary() {
    echo "🔍 MedinovAI Validation Summary"
    echo "==============================="
    echo ""
    
    # Show validation execution report
    if [[ -f "$LOG_DIR/validation_execution_report.json" ]]; then
        echo "📊 Repository Validation Results:"
        local total_repos=$(jq -r '.validation_summary.total_repositories' "$LOG_DIR/validation_execution_report.json")
        local successful=$(jq -r '.validation_summary.successful_validations' "$LOG_DIR/validation_execution_report.json")
        local failed=$(jq -r '.validation_summary.failed_validations' "$LOG_DIR/validation_execution_report.json")
        local success_rate=$(jq -r '.validation_summary.success_rate' "$LOG_DIR/validation_execution_report.json")
        
        echo "  📁 Total Repositories: $total_repos"
        echo "  ✅ Successful Validations: $successful"
        echo "  ❌ Failed Validations: $failed"
        echo "  📈 Success Rate: $success_rate"
        echo ""
    fi
    
    # Show Playwright test report
    if [[ -f "$LOG_DIR/playwright_test_report.json" ]]; then
        echo "🎭 Playwright Test Results:"
        local total_tests=$(jq -r '.totalTests' "$LOG_DIR/playwright_test_report.json")
        local passed_tests=$(jq -r '.passed' "$LOG_DIR/playwright_test_report.json")
        local failed_tests=$(jq -r '.failed' "$LOG_DIR/playwright_test_report.json")
        local test_success_rate=$(jq -r '.successRate' "$LOG_DIR/playwright_test_report.json")
        
        echo "  🧪 Total Tests: $total_tests"
        echo "  ✅ Passed Tests: $passed_tests"
        echo "  ❌ Failed Tests: $failed_tests"
        echo "  📈 Test Success Rate: $test_success_rate"
        echo ""
    fi
    
    # Show overall status
    if [[ -f "$LOG_DIR/validation_execution_report.json" ]] && [[ -f "$LOG_DIR/playwright_test_report.json" ]]; then
        local repo_success_rate=$(jq -r '.validation_summary.success_rate' "$LOG_DIR/validation_execution_report.json")
        local test_success_rate=$(jq -r '.successRate' "$LOG_DIR/playwright_test_report.json")
        
        echo "🎯 Overall Validation Status:"
        if [[ "$repo_success_rate" > "90" ]] && [[ "$test_success_rate" > "90" ]]; then
            echo -e "  ${GREEN}✅ VALIDATION SUCCESSFUL - All systems validated${NC}"
        elif [[ "$repo_success_rate" > "80" ]] && [[ "$test_success_rate" > "80" ]]; then
            echo -e "  ${YELLOW}⚠️  VALIDATION PARTIAL - Some issues detected${NC}"
        else
            echo -e "  ${RED}❌ VALIDATION FAILED - Multiple issues detected${NC}"
        fi
    fi
}

# Main execution
main() {
    case "${1:-dashboard}" in
        "dashboard")
            display_validation_dashboard
            ;;
        "monitor")
            monitor_continuous
            ;;
        "logs")
            if [[ -n "${2:-}" ]]; then
                show_validation_swarm_logs "$2"
            else
                log_error "Please specify swarm ID: $0 logs <swarm_id>"
                exit 1
            fi
            ;;
        "agent-logs")
            if [[ -n "${2:-}" && -n "${3:-}" ]]; then
                show_validation_agent_logs "$2" "$3"
            else
                log_error "Please specify swarm ID and agent ID: $0 agent-logs <swarm_id> <agent_id>"
                exit 1
            fi
            ;;
        "report")
            show_validation_execution_report
            ;;
        "playwright-report")
            show_playwright_test_report
            ;;
        "summary")
            show_validation_summary
            ;;
        "help")
            echo "MedinovAI Validation Swarm Monitoring"
            echo "===================================="
            echo ""
            echo "Usage: $0 [COMMAND] [OPTIONS]"
            echo ""
            echo "Commands:"
            echo "  dashboard         Show current validation swarm status (default)"
            echo "  monitor          Monitor validation swarms continuously"
            echo "  logs <id>        Show logs for specific validation swarm"
            echo "  agent-logs <swarm_id> <agent_id>  Show logs for specific validation agent"
            echo "  report           Show validation execution report"
            echo "  playwright-report  Show Playwright test report"
            echo "  summary          Show comprehensive validation summary"
            echo "  help             Show this help"
            echo ""
            echo "Examples:"
            echo "  $0                    # Show validation dashboard"
            echo "  $0 monitor           # Continuous validation monitoring"
            echo "  $0 logs 1            # Show logs for validation swarm 1"
            echo "  $0 agent-logs 1 2    # Show logs for validation swarm 1, agent 2"
            echo "  $0 report            # Show validation execution report"
            echo "  $0 playwright-report # Show Playwright test report"
            echo "  $0 summary           # Show comprehensive validation summary"
            ;;
        *)
            log_error "Unknown command: $1"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"

