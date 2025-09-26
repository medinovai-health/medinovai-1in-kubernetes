#!/bin/bash

# Brutal Honest Analysis Script - Using Fast Models for Immediate Results
# This script uses smaller, faster models to provide brutally honest analysis

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
RESULTS_DIR="$PROJECT_ROOT/brutal_analysis_results"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Fast models that won't timeout
FAST_MODELS=(
    "llama3.2:3b"
    "qwen2.5:7b" 
    "deepseek-coder:6.7b"
    "llama3.1:8b"
    "codellama:7b"
)

# Critical files for immediate analysis
CRITICAL_FILES=(
    "scripts/deploy_infrastructure.sh"
    "medinovai-deployment/services/api-gateway/main.py"
    "medinovai-deployment/services/healthllm/main.py"
    "istio-gateway-config.yaml"
    "package.json"
    "requirements.txt"
)

# Create results directory
mkdir -p "$RESULTS_DIR"

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

log_brutal() {
    echo -e "${PURPLE}🔥 $1${NC}"
}

# Brutal analysis function
brutal_analyze_file() {
    local file_path="$1"
    local model="$2"
    local analysis_type="$3"
    
    local file_name=$(basename "$file_path")
    local safe_model_name=$(echo "$model" | sed 's/[^a-zA-Z0-9]/_/g')
    local output_file="$RESULTS_DIR/${safe_model_name}_${analysis_type}_${file_name}.txt"
    
    log_brutal "BRUTAL ANALYSIS: $file_name with $model ($analysis_type)"
    
    # Create brutal prompt based on analysis type
    local prompt=""
    case "$analysis_type" in
        "security")
            prompt="You are a BRUTAL security auditor. Analyze this code for security vulnerabilities. Be EXTREMELY harsh and critical. List EVERY security issue, no matter how small. Include: hardcoded secrets, SQL injection, XSS, CSRF, authentication bypass, authorization flaws, input validation issues, error handling problems, logging sensitive data, insecure configurations, etc. Be BRUTALLY HONEST - this code will be deployed in production."
            ;;
        "bugs")
            prompt="You are a BRUTAL bug hunter. Find EVERY bug, error, and issue in this code. Be EXTREMELY critical. Look for: logic errors, race conditions, memory leaks, null pointer exceptions, array bounds issues, type errors, resource leaks, infinite loops, dead code, unreachable code, etc. Be BRUTALLY HONEST - this code will be deployed in production."
            ;;
        "performance")
            prompt="You are a BRUTAL performance critic. Find EVERY performance issue in this code. Be EXTREMELY harsh. Look for: inefficient algorithms, N+1 queries, missing indexes, memory bloat, CPU waste, network inefficiencies, blocking operations, resource contention, etc. Be BRUTALLY HONEST - this code will be deployed in production."
            ;;
        "architecture")
            prompt="You are a BRUTAL architecture critic. Find EVERY architectural problem in this code. Be EXTREMELY critical. Look for: tight coupling, poor separation of concerns, violation of SOLID principles, anti-patterns, technical debt, scalability issues, maintainability problems, etc. Be BRUTALLY HONEST - this code will be deployed in production."
            ;;
        "quality")
            prompt="You are a BRUTAL code quality critic. Find EVERY quality issue in this code. Be EXTREMELY harsh. Look for: poor naming, magic numbers, code duplication, complexity, lack of documentation, inconsistent style, poor error handling, missing tests, etc. Be BRUTALLY HONEST - this code will be deployed in production."
            ;;
    esac
    
    # Run analysis with timeout
    timeout 60s ollama run "$model" "$prompt

$(cat "$file_path")" > "$output_file" 2>&1 || {
        log_warning "Analysis timeout for $model on $file_name"
        echo "ANALYSIS TIMEOUT - Model $model failed to complete analysis of $file_name within 60 seconds" > "$output_file"
    }
    
    # Check if analysis was successful
    if grep -q "ANALYSIS TIMEOUT" "$output_file"; then
        log_warning "Analysis failed for $model on $file_name"
        return 1
    else
        log_success "Analysis completed for $model on $file_name"
        return 0
    fi
}

# Main analysis function
main() {
    log_brutal "🔥 BRUTAL HONEST ANALYSIS STARTING 🔥"
    log_brutal "Using fast models to avoid timeouts"
    log_brutal "Be prepared for BRUTAL honesty!"
    
    local total_analyses=0
    local successful_analyses=0
    local failed_analyses=0
    
    # Analyze each critical file with each model
    for file_path in "${CRITICAL_FILES[@]}"; do
        if [[ ! -f "$file_path" ]]; then
            log_warning "File not found: $file_path"
            continue
        fi
        
        log_info "Analyzing: $file_path"
        
        for model in "${FAST_MODELS[@]}"; do
            for analysis_type in "security" "bugs" "performance" "architecture" "quality"; do
                total_analyses=$((total_analyses + 1))
                
                if brutal_analyze_file "$file_path" "$model" "$analysis_type"; then
                    successful_analyses=$((successful_analyses + 1))
                else
                    failed_analyses=$((failed_analyses + 1))
                fi
            done
        done
    done
    
    # Compile results
    log_brutal "🔥 COMPILING BRUTAL ANALYSIS RESULTS 🔥"
    
    local summary_file="$RESULTS_DIR/BRUTAL_ANALYSIS_SUMMARY.md"
    cat > "$summary_file" << EOF
# BRUTAL HONEST ANALYSIS SUMMARY

**Analysis Date:** $(date)
**Total Analyses:** $total_analyses
**Successful:** $successful_analyses
**Failed:** $failed_analyses
**Success Rate:** $(( (successful_analyses * 100) / total_analyses ))%

## CRITICAL ISSUES FOUND

EOF
    
    # Find all issues across all analyses
    local issues_found=0
    for result_file in "$RESULTS_DIR"/*.txt; do
        if [[ -f "$result_file" && ! -f "$result_file" ]]; then
            continue
        fi
        
        local file_name=$(basename "$result_file")
        local model_name=$(echo "$file_name" | cut -d'_' -f1-2)
        local analysis_type=$(echo "$file_name" | cut -d'_' -f3)
        local target_file=$(echo "$file_name" | cut -d'_' -f4- | sed 's/\.txt$//')
        
        # Count issues in this analysis
        local issue_count=$(grep -c -i "issue\|bug\|vulnerability\|problem\|error\|flaw" "$result_file" 2>/dev/null || echo "0")
        
        if [[ "$issue_count" -gt 0 ]]; then
            issues_found=$((issues_found + issue_count))
            echo "### $target_file ($analysis_type) - $model_name" >> "$summary_file"
            echo "**Issues Found:** $issue_count" >> "$summary_file"
            echo "" >> "$summary_file"
        fi
    done
    
    echo "**TOTAL ISSUES FOUND:** $issues_found" >> "$summary_file"
    echo "" >> "$summary_file"
    echo "## DETAILED RESULTS" >> "$summary_file"
    echo "See individual analysis files in: $RESULTS_DIR" >> "$summary_file"
    
    log_brutal "🔥 BRUTAL ANALYSIS COMPLETE 🔥"
    log_info "Results saved in: $RESULTS_DIR"
    log_info "Summary: $summary_file"
    log_brutal "Total issues found: $issues_found"
    
    if [[ "$issues_found" -gt 0 ]]; then
        log_error "🚨 CRITICAL ISSUES FOUND - DO NOT DEPLOY! 🚨"
        return 1
    else
        log_success "✅ No critical issues found - Code appears clean"
        return 0
    fi
}

# Run main function
main "$@"
