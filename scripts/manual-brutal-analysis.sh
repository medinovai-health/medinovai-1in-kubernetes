#!/bin/bash

# Manual Brutal Analysis Script - Direct Analysis Without Model Timeouts
# This script performs manual analysis of critical files to provide brutal honesty

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
RESULTS_DIR="$PROJECT_ROOT/manual_brutal_analysis"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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

# Manual analysis function
manual_analyze_file() {
    local file_path="$1"
    local file_name=$(basename "$file_path")
    local output_file="$RESULTS_DIR/${file_name}_manual_analysis.md"
    
    log_brutal "MANUAL BRUTAL ANALYSIS: $file_name"
    
    if [[ ! -f "$file_path" ]]; then
        log_warning "File not found: $file_path"
        return 1
    fi
    
    # Create manual analysis based on file type and content
    cat > "$output_file" << EOF
# BRUTAL MANUAL ANALYSIS: $file_name

**Analysis Date:** $(date)
**File Path:** $file_path
**File Size:** $(wc -c < "$file_path") bytes
**Lines:** $(wc -l < "$file_path")

## CRITICAL ISSUES FOUND

EOF

    # Analyze based on file extension
    case "$file_path" in
        *.sh)
            analyze_shell_script "$file_path" "$output_file"
            ;;
        *.py)
            analyze_python_script "$file_path" "$output_file"
            ;;
        *.yaml|*.yml)
            analyze_yaml_file "$file_path" "$output_file"
            ;;
        *.json)
            analyze_json_file "$file_path" "$output_file"
            ;;
        *.js|*.ts)
            analyze_javascript_file "$file_path" "$output_file"
            ;;
        *)
            analyze_generic_file "$file_path" "$output_file"
            ;;
    esac
    
    log_success "Manual analysis completed for $file_name"
}

# Shell script analysis
analyze_shell_script() {
    local file_path="$1"
    local output_file="$2"
    
    cat >> "$output_file" << EOF

### SECURITY VULNERABILITIES
EOF

    # Check for hardcoded credentials
    if grep -q -i "password\|secret\|key\|token" "$file_path"; then
        echo "- **CRITICAL**: Hardcoded credentials found" >> "$output_file"
        grep -n -i "password\|secret\|key\|token" "$file_path" >> "$output_file"
    fi
    
    # Check for unsafe practices
    if grep -q "rm -rf" "$file_path"; then
        echo "- **HIGH**: Dangerous rm -rf commands found" >> "$output_file"
        grep -n "rm -rf" "$file_path" >> "$output_file"
    fi
    
    if grep -q "curl.*http://" "$file_path"; then
        echo "- **MEDIUM**: Insecure HTTP connections found" >> "$output_file"
        grep -n "curl.*http://" "$file_path" >> "$output_file"
    fi
    
    cat >> "$output_file" << EOF

### CODE QUALITY ISSUES
EOF

    # Check for missing error handling
    if ! grep -q "set -e" "$file_path"; then
        echo "- **MEDIUM**: Missing 'set -e' for error handling" >> "$output_file"
    fi
    
    if ! grep -q "set -u" "$file_path"; then
        echo "- **MEDIUM**: Missing 'set -u' for undefined variable handling" >> "$output_file"
    fi
    
    # Check for unquoted variables
    if grep -q '\$[A-Za-z_][A-Za-z0-9_]*[^"]' "$file_path"; then
        echo "- **LOW**: Unquoted variables found" >> "$output_file"
    fi
}

# Python script analysis
analyze_python_script() {
    local file_path="$1"
    local output_file="$2"
    
    cat >> "$output_file" << EOF

### SECURITY VULNERABILITIES
EOF

    # Check for hardcoded credentials
    if grep -q -i "password\|secret\|key\|token" "$file_path"; then
        echo "- **CRITICAL**: Hardcoded credentials found" >> "$output_file"
        grep -n -i "password\|secret\|key\|token" "$file_path" >> "$output_file"
    fi
    
    # Check for SQL injection risks
    if grep -q "execute.*%" "$file_path"; then
        echo "- **CRITICAL**: Potential SQL injection vulnerability" >> "$output_file"
        grep -n "execute.*%" "$file_path" >> "$output_file"
    fi
    
    # Check for eval usage
    if grep -q "eval(" "$file_path"; then
        echo "- **CRITICAL**: eval() usage found - major security risk" >> "$output_file"
        grep -n "eval(" "$file_path" >> "$output_file"
    fi
    
    cat >> "$output_file" << EOF

### CODE QUALITY ISSUES
EOF

    # Check for missing error handling
    if ! grep -q "try:" "$file_path"; then
        echo "- **MEDIUM**: No try-catch blocks found" >> "$output_file"
    fi
    
    # Check for print statements
    if grep -q "print(" "$file_path"; then
        echo "- **LOW**: print() statements found (should use logging)" >> "$output_file"
    fi
}

# YAML file analysis
analyze_yaml_file() {
    local file_path="$1"
    local output_file="$2"
    
    cat >> "$output_file" << EOF

### SECURITY VULNERABILITIES
EOF

    # Check for hardcoded credentials
    if grep -q -i "password\|secret\|key\|token" "$file_path"; then
        echo "- **CRITICAL**: Hardcoded credentials found" >> "$output_file"
        grep -n -i "password\|secret\|key\|token" "$file_path" >> "$output_file"
    fi
    
    # Check for insecure configurations
    if grep -q "privileged: true" "$file_path"; then
        echo "- **HIGH**: Privileged containers found" >> "$output_file"
        grep -n "privileged: true" "$file_path" >> "$output_file"
    fi
    
    if grep -q "hostNetwork: true" "$file_path"; then
        echo "- **HIGH**: Host network access found" >> "$output_file"
        grep -n "hostNetwork: true" "$file_path" >> "$output_file"
    fi
}

# JSON file analysis
analyze_json_file() {
    local file_path="$1"
    local output_file="$2"
    
    cat >> "$output_file" << EOF

### SECURITY VULNERABILITIES
EOF

    # Check for hardcoded credentials
    if grep -q -i "password\|secret\|key\|token" "$file_path"; then
        echo "- **CRITICAL**: Hardcoded credentials found" >> "$output_file"
        grep -n -i "password\|secret\|key\|token" "$file_path" >> "$output_file"
    fi
    
    # Check JSON validity
    if ! python3 -m json.tool "$file_path" > /dev/null 2>&1; then
        echo "- **HIGH**: Invalid JSON syntax" >> "$output_file"
    fi
}

# JavaScript/TypeScript analysis
analyze_javascript_file() {
    local file_path="$1"
    local output_file="$2"
    
    cat >> "$output_file" << EOF

### SECURITY VULNERABILITIES
EOF

    # Check for hardcoded credentials
    if grep -q -i "password\|secret\|key\|token" "$file_path"; then
        echo "- **CRITICAL**: Hardcoded credentials found" >> "$output_file"
        grep -n -i "password\|secret\|key\|token" "$file_path" >> "$output_file"
    fi
    
    # Check for eval usage
    if grep -q "eval(" "$file_path"; then
        echo "- **CRITICAL**: eval() usage found - major security risk" >> "$output_file"
        grep -n "eval(" "$file_path" >> "$output_file"
    fi
    
    # Check for innerHTML usage
    if grep -q "innerHTML" "$file_path"; then
        echo "- **HIGH**: innerHTML usage found - XSS risk" >> "$output_file"
        grep -n "innerHTML" "$file_path" >> "$output_file"
    fi
}

# Generic file analysis
analyze_generic_file() {
    local file_path="$1"
    local output_file="$2"
    
    cat >> "$output_file" << EOF

### SECURITY VULNERABILITIES
EOF

    # Check for hardcoded credentials
    if grep -q -i "password\|secret\|key\|token" "$file_path"; then
        echo "- **CRITICAL**: Hardcoded credentials found" >> "$output_file"
        grep -n -i "password\|secret\|key\|token" "$file_path" >> "$output_file"
    fi
    
    # Check for IP addresses
    if grep -q -E "([0-9]{1,3}\.){3}[0-9]{1,3}" "$file_path"; then
        echo "- **MEDIUM**: Hardcoded IP addresses found" >> "$output_file"
        grep -n -E "([0-9]{1,3}\.){3}[0-9]{1,3}" "$file_path" >> "$output_file"
    fi
}

# Main analysis function
main() {
    log_brutal "🔥 MANUAL BRUTAL ANALYSIS STARTING 🔥"
    log_brutal "Performing direct file analysis without model dependencies"
    
    # Critical files for analysis
    local critical_files=(
        "scripts/deploy_infrastructure.sh"
        "medinovai-deployment/services/api-gateway/main.py"
        "medinovai-deployment/services/healthllm/main.py"
        "istio-gateway-config.yaml"
        "package.json"
        "requirements.txt"
        "scripts/implement-critical-fixes-standalone.sh"
    )
    
    local total_files=0
    local analyzed_files=0
    local issues_found=0
    
    # Analyze each critical file
    for file_path in "${critical_files[@]}"; do
        total_files=$((total_files + 1))
        
        if manual_analyze_file "$file_path"; then
            analyzed_files=$((analyzed_files + 1))
            
            # Count issues in this file
            local file_issues=$(grep -c "CRITICAL\|HIGH\|MEDIUM\|LOW" "$RESULTS_DIR/$(basename "$file_path")_manual_analysis.md" 2>/dev/null || echo "0")
            issues_found=$((issues_found + file_issues))
        fi
    done
    
    # Compile final report
    log_brutal "🔥 COMPILING MANUAL ANALYSIS RESULTS 🔥"
    
    local summary_file="$RESULTS_DIR/MANUAL_BRUTAL_ANALYSIS_SUMMARY.md"
    cat > "$summary_file" << EOF
# MANUAL BRUTAL ANALYSIS SUMMARY

**Analysis Date:** $(date)
**Total Files:** $total_files
**Analyzed:** $analyzed_files
**Total Issues Found:** $issues_found

## CRITICAL FINDINGS

EOF
    
    # Find all critical issues
    for result_file in "$RESULTS_DIR"/*_manual_analysis.md; do
        if [[ -f "$result_file" ]]; then
            local file_name=$(basename "$result_file" _manual_analysis.md)
            local critical_count=$(grep -c "CRITICAL" "$result_file" 2>/dev/null || echo "0")
            local high_count=$(grep -c "HIGH" "$result_file" 2>/dev/null || echo "0")
            
            if [[ "$critical_count" -gt 0 || "$high_count" -gt 0 ]]; then
                echo "### $file_name" >> "$summary_file"
                echo "- **Critical Issues:** $critical_count" >> "$summary_file"
                echo "- **High Issues:** $high_count" >> "$summary_file"
                echo "" >> "$summary_file"
            fi
        fi
    done
    
    echo "## DETAILED RESULTS" >> "$summary_file"
    echo "See individual analysis files in: $RESULTS_DIR" >> "$summary_file"
    
    log_brutal "🔥 MANUAL ANALYSIS COMPLETE 🔥"
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
