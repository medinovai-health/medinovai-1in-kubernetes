#!/bin/bash

# Optimized Model Analysis Script
# Addresses timeout issues and provides efficient analysis

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Optimized model selection
FAST_MODELS=(
    "llama3.2:3b"           # Fastest for initial analysis
    "qwen2.5:7b"            # Good balance of speed and quality
    "deepseek-coder:6.7b"   # Code-specific analysis
)

CRITICAL_MODELS=(
    "deepseek-r1-70b-analysis:latest"  # Best for critical analysis
    "qwen2.5:72b"                     # High quality analysis
)

# Analysis categories
CATEGORIES=(
    "security_vulnerabilities"
    "performance_issues"
    "code_quality"
    "architecture_problems"
    "documentation_gaps"
    "test_coverage"
    "deployment_issues"
    "configuration_errors"
    "dependency_issues"
    "error_handling"
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

# Create output directories
mkdir -p optimized_analysis_results/{fast,critical,chunks,results}

# Function to analyze file in chunks
analyze_file_chunks() {
    local file="$1"
    local model="$2"
    local category="$3"
    local chunk_size=50  # Smaller chunks for faster processing
    
    if [[ ! -f "$file" ]]; then
        print_error "File not found: $file"
        return 1
    fi
    
    local file_size=$(wc -l < "$file")
    local num_chunks=$(( (file_size + chunk_size - 1) / chunk_size ))
    
    print_status "Analyzing $file in $num_chunks chunks with $model"
    
    local output_file="optimized_analysis_results/fast/${model//[^a-zA-Z0-9]/_}_${category}_$(basename "$file" | tr '/' '_')"
    
    echo "ANALYSIS REPORT" > "$output_file"
    echo "File: $file" >> "$output_file"
    echo "Model: $model" >> "$output_file"
    echo "Category: $category" >> "$output_file"
    echo "Chunks: $num_chunks" >> "$output_file"
    echo "Date: $(date)" >> "$output_file"
    echo "========================================" >> "$output_file"
    echo "" >> "$output_file"
    
    local chunk_num=1
    local total_issues=0
    
    # Split file into chunks and analyze each
    while IFS= read -r -d '' chunk_file; do
        print_status "Analyzing chunk $chunk_num/$num_chunks"
        
        local chunk_content=$(head -$chunk_size "$chunk_file" 2>/dev/null || cat "$chunk_file")
        
        local prompt="
QUICK ANALYSIS - CHUNK $chunk_num of $num_chunks

File: $file
Category: $category
Model: $model

Analyze this code chunk for $category:

$chunk_content

Focus on:
1. Critical issues (CRITICAL/HIGH severity)
2. Specific line numbers
3. Exact problems found
4. Suggested fixes

Be concise but thorough. List specific issues found.
"
        
        local chunk_output="optimized_analysis_results/chunks/chunk_${chunk_num}_$(basename "$file" | tr '/' '_')"
        
        timeout 30 ollama run "$model" "$prompt" > "$chunk_output" 2>&1 || {
            print_warning "Chunk $chunk_num analysis timeout"
            echo "ANALYSIS TIMEOUT" > "$chunk_output"
        }
        
        # Extract issues from chunk analysis
        local issues=$(grep -i "CRITICAL\|HIGH\|issue\|problem\|vulnerability" "$chunk_output" | wc -l)
        total_issues=$((total_issues + issues))
        
        echo "CHUNK $chunk_num ANALYSIS:" >> "$output_file"
        cat "$chunk_output" >> "$output_file"
        echo "" >> "$output_file"
        
        ((chunk_num++))
        
        # Move to next chunk
        tail -n +$((chunk_size + 1)) "$chunk_file" > "${chunk_file}.tmp" 2>/dev/null || true
        mv "${chunk_file}.tmp" "$chunk_file" 2>/dev/null || true
        
    done < <(find "$file" -type f -print0)
    
    echo "TOTAL ISSUES FOUND: $total_issues" >> "$output_file"
    print_status "Analysis completed: $output_file ($total_issues issues)"
}

# Function for critical analysis with larger models
critical_analysis() {
    local file="$1"
    local model="$2"
    local category="$3"
    
    if [[ ! -f "$file" ]]; then
        print_error "File not found: $file"
        return 1
    fi
    
    local output_file="optimized_analysis_results/critical/${model//[^a-zA-Z0-9]/_}_${category}_$(basename "$file" | tr '/' '_')"
    
    print_status "Critical analysis of $file with $model"
    
    # Get first 200 lines for critical analysis
    local file_content=$(head -200 "$file" 2>/dev/null || echo "Could not read file")
    
    local prompt="
CRITICAL SECURITY ANALYSIS

File: $file
Category: $category
Model: $model

CRITICAL ANALYSIS REQUIRED:
Find ALL security vulnerabilities, bugs, and critical issues in this code:

$file_content

ANALYSIS REQUIREMENTS:
1. Security vulnerabilities (CRITICAL priority)
2. Authentication/authorization issues
3. Input validation problems
4. Error handling gaps
5. Configuration issues
6. Performance bottlenecks
7. Code quality issues
8. Architecture problems

SEVERITY LEVELS:
- CRITICAL: Immediate security risk
- HIGH: Significant security risk
- MEDIUM: Moderate risk
- LOW: Minor issue

For each issue found:
- Line number (if applicable)
- Exact problem description
- Severity level
- Suggested fix
- Risk assessment

BE BRUTALLY HONEST - NO ISSUE IS TOO SMALL!
"
    
    timeout 120 ollama run "$model" "$prompt" > "$output_file" 2>&1 || {
        print_warning "Critical analysis timeout for $model on $file"
        echo "CRITICAL ANALYSIS TIMEOUT" > "$output_file"
    }
    
    print_status "Critical analysis completed: $output_file"
}

# Function to generate detailed comments
generate_detailed_comments() {
    local file="$1"
    local model="$2"
    
    if [[ ! -f "$file" ]]; then
        print_error "File not found: $file"
        return 1
    fi
    
    local output_file="optimized_analysis_results/results/${model//[^a-zA-Z0-9]/_}_comments_$(basename "$file" | tr '/' '_')"
    
    print_status "Generating detailed comments for $file with $model"
    
    # Get first 100 lines for comment generation
    local file_content=$(head -100 "$file" 2>/dev/null || echo "Could not read file")
    
    local prompt="
DETAILED CODE DOCUMENTATION

File: $file
Model: $model

Generate EXTREMELY detailed comments for this code:

$file_content

REQUIREMENTS:
1. Comment EVERY line of code
2. Explain EVERY function, class, variable
3. Document EVERY parameter and return value
4. Explain business logic and context
5. Add TODO comments for improvements
6. Document error conditions
7. Explain configuration options
8. Add usage examples

COMMENT FORMAT:
- Line-by-line comments
- Function docstrings
- Class documentation
- Variable explanations
- Business logic documentation

GENERATE COMPREHENSIVE DOCUMENTATION NOW!
"
    
    timeout 60 ollama run "$model" "$prompt" > "$output_file" 2>&1 || {
        print_warning "Comment generation timeout for $model on $file"
        echo "COMMENT GENERATION TIMEOUT" > "$output_file"
    }
    
    print_status "Comment generation completed: $output_file"
}

# Function to generate test cases
generate_test_cases() {
    local file="$1"
    local model="$2"
    
    if [[ ! -f "$file" ]]; then
        print_error "File not found: $file"
        return 1
    fi
    
    local output_file="optimized_analysis_results/results/${model//[^a-zA-Z0-9]/_}_tests_$(basename "$file" | tr '/' '_')"
    
    print_status "Generating test cases for $file with $model"
    
    # Get first 100 lines for test generation
    local file_content=$(head -100 "$file" 2>/dev/null || echo "Could not read file")
    
    local prompt="
COMPREHENSIVE TEST CASE GENERATION

File: $file
Model: $model

Generate comprehensive Playwright test cases for this code:

$file_content

TEST REQUIREMENTS:
1. Unit tests for every function
2. Integration tests for every endpoint
3. Security tests for every input
4. Performance tests for every operation
5. Error handling tests for every error case
6. Accessibility tests for every UI component
7. Cross-browser tests for every feature
8. Mobile tests for every responsive element

TEST TYPES:
- Unit tests (Jest/Vitest)
- Integration tests (Playwright)
- Security tests (Playwright)
- Performance tests (Playwright)
- E2E tests (Playwright)
- API tests (Playwright)

TEST FORMAT:
- Playwright JavaScript/TypeScript
- Comprehensive test coverage
- Automated test execution
- Database integration
- CI/CD pipeline integration

GENERATE COMPREHENSIVE TEST SUITE NOW!
"
    
    timeout 60 ollama run "$model" "$prompt" > "$output_file" 2>&1 || {
        print_warning "Test generation timeout for $model on $file"
        echo "TEST GENERATION TIMEOUT" > "$output_file"
    }
    
    print_status "Test generation completed: $output_file"
}

# Function to get critical files
get_critical_files() {
    find . -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.yaml" -o -name "*.yml" -o -name "*.sh" \) \
    ! -path "./.git/*" \
    ! -path "./node_modules/*" \
    ! -path "./venv/*" \
    ! -path "./.venv/*" \
    ! -path "./__pycache__/*" \
    ! -path "./checkpoints/*" \
    ! -path "./istio-1.27.1/*" \
    ! -path "./optimized_analysis_results/*" \
    ! -path "./code_review_results/*" \
    ! -path "./critical_analysis_results/*" \
    ! -path "./quick_security_results/*" \
    | head -20  # Limit to first 20 files for optimization
}

# Main execution function
main() {
    print_header "OPTIMIZED MODEL ANALYSIS - ITERATIVE DEVELOPMENT"
    print_status "Starting optimized analysis with timeout-resistant approach"
    
    # Get critical files
    local files=($(get_critical_files))
    print_status "Found ${#files[@]} critical files to analyze"
    
    # Phase 1: Fast analysis with smaller models
    print_header "PHASE 1: FAST ANALYSIS WITH SMALLER MODELS"
    
    for file in "${files[@]}"; do
        print_status "Processing file: $file"
        
        for model in "${FAST_MODELS[@]}"; do
            for category in "${CATEGORIES[@]}"; do
                analyze_file_chunks "$file" "$model" "$category"
            done
        done
    done
    
    # Phase 2: Critical analysis with larger models (only for critical files)
    print_header "PHASE 2: CRITICAL ANALYSIS WITH LARGER MODELS"
    
    local critical_files=(
        "scripts/deploy_infrastructure.sh"
        "medinovai-deployment/services/api-gateway/main.py"
        "medinovai-deployment/services/healthllm/main.py"
        "istio-gateway-config.yaml"
        "package.json"
    )
    
    for file in "${critical_files[@]}"; do
        if [[ -f "$file" ]]; then
            print_status "Critical analysis of: $file"
            
            for model in "${CRITICAL_MODELS[@]}"; do
                for category in "${CATEGORIES[@]}"; do
                    critical_analysis "$file" "$model" "$category"
                done
            done
        fi
    done
    
    # Phase 3: Generate detailed comments and test cases
    print_header "PHASE 3: DETAILED COMMENTS AND TEST CASES"
    
    for file in "${files[@]}"; do
        print_status "Generating comments and tests for: $file"
        
        for model in "${FAST_MODELS[@]}"; do
            generate_detailed_comments "$file" "$model"
            generate_test_cases "$file" "$model"
        done
    done
    
    # Compile results
    print_header "COMPILING OPTIMIZED ANALYSIS RESULTS"
    
    local final_report="optimized_analysis_results/OPTIMIZED_ANALYSIS_REPORT.md"
    
    cat > "$final_report" << EOF
# Optimized Model Analysis Report
Generated: $(date)

## Analysis Summary
- Files analyzed: ${#files[@]}
- Fast models used: ${#FAST_MODELS[@]}
- Critical models used: ${#CRITICAL_MODELS[@]}
- Categories analyzed: ${#CATEGORIES[@]}

## Fast Models Used
$(printf '%s\n' "${FAST_MODELS[@]}")

## Critical Models Used
$(printf '%s\n' "${CRITICAL_MODELS[@]}")

## Analysis Categories
$(printf '%s\n' "${CATEGORIES[@]}")

## Files Analyzed
$(printf '%s\n' "${files[@]}")

## Results
- Fast analysis results: optimized_analysis_results/fast/
- Critical analysis results: optimized_analysis_results/critical/
- Detailed comments: optimized_analysis_results/results/
- Test cases: optimized_analysis_results/results/

## Next Steps
1. Review all analysis results
2. Implement critical fixes
3. Run comprehensive tests
4. Continue iterative development
EOF
    
    print_status "Optimized analysis completed!"
    print_status "Results saved in optimized_analysis_results/"
    print_status "Report: $final_report"
    
    # Show summary
    print_header "ANALYSIS SUMMARY"
    echo "Files analyzed: ${#files[@]}"
    echo "Fast models: ${#FAST_MODELS[@]}"
    echo "Critical models: ${#CRITICAL_MODELS[@]}"
    echo "Categories: ${#CATEGORIES[@]}"
    echo "Total analyses: $((${#files[@]} * ${#FAST_MODELS[@]} * ${#CATEGORIES[@]} + ${#critical_files[@]} * ${#CRITICAL_MODELS[@]} * ${#CATEGORIES[@]}))"
}

# Run main function
main "$@"
