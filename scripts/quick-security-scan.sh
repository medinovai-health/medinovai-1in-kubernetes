#!/bin/bash

# Quick Security Scan - Focused analysis with faster models
# Uses smaller, faster models for immediate security feedback

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Faster models for quick analysis
FAST_MODELS=(
    "deepseek-coder-6.7b-analysis:latest"
    "llama3.1:8b-analysis"
    "codellama:7b-analysis"
)

# Critical security patterns to check
SECURITY_PATTERNS=(
    "password.*=.*['\"].*['\"]"
    "secret.*=.*['\"].*['\"]"
    "key.*=.*['\"].*['\"]"
    "token.*=.*['\"].*['\"]"
    "api_key.*=.*['\"].*['\"]"
    "private_key.*=.*['\"].*['\"]"
    "eval\\("
    "exec\\("
    "system\\("
    "shell_exec\\("
    "passthru\\("
    "proc_open\\("
    "popen\\("
    "SELECT.*FROM.*WHERE.*=.*\\$"
    "INSERT.*INTO.*VALUES.*\\$"
    "UPDATE.*SET.*WHERE.*\\$"
    "DELETE.*FROM.*WHERE.*\\$"
    "curl.*\\$"
    "wget.*\\$"
    "rm.*-rf.*\\$"
    "chmod.*777"
    "chmod.*666"
    "chown.*root"
    "sudo.*without.*password"
    "localhost.*without.*auth"
    "0.0.0.0.*without.*auth"
    "debug.*=.*true"
    "verbose.*=.*true"
    "log.*level.*debug"
)

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create output directory
mkdir -p quick_security_results

# Function to scan file for security patterns
scan_security_patterns() {
    local file="$1"
    local output_file="quick_security_results/$(basename "$file" | tr '/' '_')_security_scan.txt"
    
    print_status "Scanning $file for security patterns"
    
    echo "SECURITY SCAN REPORT" > "$output_file"
    echo "File: $file" >> "$output_file"
    echo "Date: $(date)" >> "$output_file"
    echo "========================================" >> "$output_file"
    echo "" >> "$output_file"
    
    local issues_found=0
    
    for pattern in "${SECURITY_PATTERNS[@]}"; do
        local matches=$(grep -n -i "$pattern" "$file" 2>/dev/null || true)
        if [[ -n "$matches" ]]; then
            echo "SECURITY ISSUE FOUND:" >> "$output_file"
            echo "Pattern: $pattern" >> "$output_file"
            echo "Matches:" >> "$output_file"
            echo "$matches" >> "$output_file"
            echo "" >> "$output_file"
            ((issues_found++))
        fi
    done
    
    if [[ $issues_found -eq 0 ]]; then
        echo "No obvious security patterns found." >> "$output_file"
    else
        echo "TOTAL ISSUES FOUND: $issues_found" >> "$output_file"
    fi
    
    print_status "Security scan completed: $output_file ($issues_found issues)"
}

# Function to analyze file with fast model
analyze_with_fast_model() {
    local file="$1"
    local model="$2"
    
    if [[ ! -f "$file" ]]; then
        print_error "File not found: $file"
        return 1
    fi
    
    local output_file="quick_security_results/${model//[^a-zA-Z0-9]/_}_$(basename "$file" | tr '/' '_')"
    
    print_status "Quick analysis of $file with $model"
    
    # Get first 100 lines for quick analysis
    local file_content=$(head -100 "$file" 2>/dev/null || echo "Could not read file")
    
    local prompt="
QUICK SECURITY ANALYSIS

File: $file
Model: $model

Find CRITICAL security issues in this code:

$file_content

Focus on:
1. Hardcoded secrets/passwords
2. SQL injection risks
3. Command injection risks
4. Authentication bypasses
5. Authorization issues
6. Input validation problems
7. Error handling gaps
8. Configuration issues

Be concise but thorough. List specific line numbers and issues.
"
    
    timeout 120 ollama run "$model" "$prompt" > "$output_file" 2>&1 || {
        print_warning "Analysis timeout for $model on $file"
        echo "ANALYSIS TIMEOUT" > "$output_file"
    }
}

# Get all code files
get_code_files() {
    find . -type f \( -name "*.py" -o -name "*.js" -o -name "*.sh" -o -name "*.yaml" -o -name "*.yml" -o -name "*.json" \) \
    ! -path "./.git/*" \
    ! -path "./node_modules/*" \
    ! -path "./venv/*" \
    ! -path "./.venv/*" \
    ! -path "./__pycache__/*" \
    ! -path "./checkpoints/*" \
    ! -path "./istio-1.27.1/*" \
    ! -path "./quick_security_results/*" \
    ! -path "./critical_analysis_results/*" \
    ! -path "./code_review_results/*" \
    | head -20  # Limit to first 20 files for quick scan
}

# Main execution
print_header "QUICK SECURITY SCAN - IMMEDIATE THREAT ASSESSMENT"

# Get files to scan
files=($(get_code_files))
print_status "Found ${#files[@]} files to scan"

# Scan each file for security patterns
for file in "${files[@]}"; do
    scan_security_patterns "$file"
done

# Analyze critical files with fast models
CRITICAL_FILES=(
    "scripts/deploy_infrastructure.sh"
    "scripts/master_deployment.sh"
    "medinovai-deployment/services/api-gateway/main.py"
    "medinovai-deployment/services/healthllm/main.py"
    "istio-gateway-config.yaml"
    "package.json"
)

for file in "${CRITICAL_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        print_header "Quick Analysis: $file"
        
        for model in "${FAST_MODELS[@]}"; do
            analyze_with_fast_model "$file" "$model"
        done
    fi
done

# Compile quick security report
print_header "COMPILING QUICK SECURITY REPORT"

cat > quick_security_results/QUICK_SECURITY_REPORT.md << EOF
# QUICK SECURITY SCAN REPORT
Generated: $(date)

## Files Scanned
$(printf '%s\n' "${files[@]}")

## Critical Files Analyzed
$(printf '%s\n' "${CRITICAL_FILES[@]}")

## Models Used
$(printf '%s\n' "${FAST_MODELS[@]}")

## Security Pattern Scan Results

EOF

# Add pattern scan results
for file in quick_security_results/*_security_scan.txt; do
    if [[ -f "$file" ]]; then
        echo "### $(basename "$file")" >> quick_security_results/QUICK_SECURITY_REPORT.md
        echo "" >> quick_security_results/QUICK_SECURITY_REPORT.md
        cat "$file" >> quick_security_results/QUICK_SECURITY_REPORT.md
        echo "" >> quick_security_results/QUICK_SECURITY_REPORT.md
    fi
done

# Add model analysis results
echo "## Model Analysis Results" >> quick_security_results/QUICK_SECURITY_REPORT.md
echo "" >> quick_security_results/QUICK_SECURITY_REPORT.md

for file in quick_security_results/*.txt; do
    if [[ -f "$file" && "$(basename "$file")" != "QUICK_SECURITY_REPORT.md" && ! "$file" =~ _security_scan.txt$ ]]; then
        echo "### $(basename "$file")" >> quick_security_results/QUICK_SECURITY_REPORT.md
        echo "" >> quick_security_results/QUICK_SECURITY_REPORT.md
        head -50 "$file" >> quick_security_results/QUICK_SECURITY_REPORT.md
        echo "" >> quick_security_results/QUICK_SECURITY_REPORT.md
    fi
done

print_status "Quick security scan completed!"
print_status "Results saved in quick_security_results/"
print_status "Report: quick_security_results/QUICK_SECURITY_REPORT.md"

# Show immediate critical issues
print_header "IMMEDIATE SECURITY ISSUES FOUND"
if [[ -f "quick_security_results/QUICK_SECURITY_REPORT.md" ]]; then
    grep -i "SECURITY ISSUE\|CRITICAL\|HIGH\|password\|secret\|key\|injection" quick_security_results/QUICK_SECURITY_REPORT.md | head -20
fi
