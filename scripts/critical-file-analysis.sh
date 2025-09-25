#!/bin/bash

# Critical File Analysis Script
# Analyzes the most important files with all models for immediate feedback

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Critical files to analyze first
CRITICAL_FILES=(
    "scripts/deploy_infrastructure.sh"
    "scripts/master_deployment.sh"
    "medinovai-deployment/services/api-gateway/main.py"
    "medinovai-deployment/services/healthllm/main.py"
    "medinovai-infrastructure-standards/STANDARDS.yaml"
    "istio-gateway-config.yaml"
    "istio-port-management.yaml"
    "playwright.config.js"
    "package.json"
    "requirements.txt"
)

# Top models for immediate analysis
MODELS=(
    "deepseek-r1-70b-analysis:latest"
    "qwen2.5:72b"
    "codellama:70b"
)

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create output directory
mkdir -p critical_analysis_results

# Function to analyze critical file
analyze_critical_file() {
    local file="$1"
    local model="$2"
    
    if [[ ! -f "$file" ]]; then
        print_error "File not found: $file"
        return 1
    fi
    
    local output_file="critical_analysis_results/${model//[^a-zA-Z0-9]/_}_$(basename "$file" | tr '/' '_')"
    
    print_status "Analyzing $file with $model"
    
    local prompt="
CRITICAL SECURITY AND CODE ANALYSIS - BE BRUTALLY HONEST

File: $file
Model: $model
Timestamp: $(date)

INSTRUCTIONS:
1. This is a CRITICAL file analysis - find EVERY possible issue
2. Focus on SECURITY VULNERABILITIES, DEPLOYMENT RISKS, and CRITICAL BUGS
3. Be extremely harsh and thorough - no issue is too small
4. Provide specific line numbers and exact problems
5. Rate severity as CRITICAL/HIGH/MEDIUM/LOW
6. Suggest immediate fixes
7. Identify deployment risks
8. Check for hardcoded secrets, weak authentication, injection vulnerabilities
9. Analyze configuration errors and misconfigurations
10. Look for race conditions, memory leaks, and performance issues

CRITICAL FILE CONTENT:
$(head -300 "$file" 2>/dev/null || echo "Could not read file")

ANALYSIS REQUIRED:
- Security vulnerabilities (CRITICAL PRIORITY)
- Deployment configuration issues
- Hardcoded credentials or secrets
- Input validation problems
- Error handling gaps
- Performance bottlenecks
- Race conditions
- Memory leaks
- Configuration errors
- Missing error handling
- Weak authentication/authorization
- SQL injection possibilities
- XSS vulnerabilities
- CSRF issues
- File inclusion vulnerabilities
- Command injection risks
- Path traversal issues
- Buffer overflow potential
- Integer overflow issues
- Logic errors
- Missing input sanitization
- Weak encryption
- Insecure communication
- Missing security headers
- Weak session management
- Insufficient logging
- Missing audit trails

BE BRUTALLY HONEST - THIS IS A CRITICAL ANALYSIS!
"
    
    timeout 600 ollama run "$model" "$prompt" > "$output_file" 2>&1 || {
        print_error "Analysis timeout for $model on $file"
        echo "ANALYSIS TIMEOUT - MODEL TOO SLOW" > "$output_file"
    }
    
    print_status "Analysis completed: $output_file"
}

# Main execution
print_header "CRITICAL FILE ANALYSIS - IMMEDIATE SECURITY REVIEW"

for file in "${CRITICAL_FILES[@]}"; do
    print_header "Analyzing Critical File: $file"
    
    for model in "${MODELS[@]}"; do
        analyze_critical_file "$file" "$model"
    done
done

# Compile critical issues
print_header "COMPILING CRITICAL ISSUES"

cat > critical_analysis_results/CRITICAL_ISSUES_SUMMARY.md << EOF
# CRITICAL ISSUES SUMMARY
Generated: $(date)

## Files Analyzed
$(printf '%s\n' "${CRITICAL_FILES[@]}")

## Models Used
$(printf '%s\n' "${MODELS[@]}")

## Critical Issues Found

EOF

# Extract critical issues from all analysis files
for file in critical_analysis_results/*.md; do
    if [[ -f "$file" && "$(basename "$file")" != "CRITICAL_ISSUES_SUMMARY.md" ]]; then
        echo "### $(basename "$file")" >> critical_analysis_results/CRITICAL_ISSUES_SUMMARY.md
        echo "" >> critical_analysis_results/CRITICAL_ISSUES_SUMMARY.md
        
        # Extract CRITICAL and HIGH severity issues
        grep -A 5 -B 5 -i "CRITICAL\|HIGH" "$file" >> critical_analysis_results/CRITICAL_ISSUES_SUMMARY.md 2>/dev/null || true
        echo "" >> critical_analysis_results/CRITICAL_ISSUES_SUMMARY.md
    fi
done

print_status "Critical analysis completed!"
print_status "Results saved in critical_analysis_results/"
print_status "Summary: critical_analysis_results/CRITICAL_ISSUES_SUMMARY.md"

# Show immediate critical issues
print_header "IMMEDIATE CRITICAL ISSUES"
if [[ -f "critical_analysis_results/CRITICAL_ISSUES_SUMMARY.md" ]]; then
    grep -i "CRITICAL\|HIGH" critical_analysis_results/CRITICAL_ISSUES_SUMMARY.md | head -20
fi
