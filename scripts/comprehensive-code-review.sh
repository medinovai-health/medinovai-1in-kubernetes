#!/bin/bash

# MedinovAI Comprehensive Code Review Script
# Uses top 5 Ollama models for brutal, honest code analysis

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Top 5 models for code review (best for analysis)
MODELS=(
    "deepseek-r1-70b-analysis:latest"    # Best for reasoning and analysis
    "qwen2.5:72b"                       # Excellent for code understanding
    "codellama:70b"                     # Specialized for code analysis
    "qwen3-30b-a3b-analysis:latest"     # Strong analytical capabilities
    "deepseek-coder-6.7b-analysis:latest" # Code-specific analysis
)

# Review categories
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

# Create output directories
mkdir -p code_review_results/{iterations,issues,comments,test_cases}
mkdir -p code_review_results/iterations/{iteration_1,iteration_2,iteration_3}

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

print_model() {
    echo -e "${PURPLE}[MODEL: $1]${NC} $2"
}

# Function to get all code files
get_code_files() {
    find . -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.yaml" -o -name "*.yml" -o -name "*.sh" -o -name "*.sql" -o -name "*.json" -o -name "*.md" -o -name "*.go" -o -name "*.rs" -o -name "*.java" -o -name "*.cpp" -o -name "*.c" -o -name "*.h" \) \
    ! -path "./.git/*" \
    ! -path "./node_modules/*" \
    ! -path "./venv/*" \
    ! -path "./.venv/*" \
    ! -path "./__pycache__/*" \
    ! -path "./checkpoints/*" \
    ! -path "./istio-1.27.1/*" \
    ! -path "./code_review_results/*" \
    | head -50  # Limit to first 50 files for initial review
}

# Function to analyze file with a specific model
analyze_file_with_model() {
    local file="$1"
    local model="$2"
    local iteration="$3"
    local category="$4"
    
    local output_file="code_review_results/iterations/iteration_${iteration}/${model//[^a-zA-Z0-9]/_}_${category}_$(basename "$file" | tr '/' '_')"
    
    print_model "$model" "Analyzing $file for $category"
    
    # Create comprehensive analysis prompt
    local prompt="
BRUTAL CODE REVIEW - BE EXTREMELY CRITICAL AND HONEST

File: $file
Category: $category
Iteration: $iteration

INSTRUCTIONS:
1. Analyze this code with ZERO tolerance for issues
2. Find EVERY possible bug, vulnerability, weakness, or problem
3. Be brutally honest - no sugar-coating
4. Focus specifically on: $category
5. Provide specific line numbers and exact issues
6. Suggest concrete fixes
7. Rate severity (CRITICAL/HIGH/MEDIUM/LOW)
8. If this is iteration 2 or 3, also check if previous issues were fixed

CODE TO ANALYZE:
$(head -200 "$file" 2>/dev/null || echo "Could not read file")

ANALYSIS REQUIRED:
- Security vulnerabilities
- Performance bottlenecks  
- Code quality issues
- Architecture problems
- Missing error handling
- Configuration issues
- Documentation gaps
- Test coverage gaps
- Deployment problems
- Dependency issues

BE BRUTALLY HONEST - NO ISSUE IS TOO SMALL TO REPORT!
"
    
    # Run analysis with timeout
    timeout 300 ollama run "$model" "$prompt" > "$output_file" 2>&1 || {
        print_warning "Analysis timeout for $model on $file"
        echo "ANALYSIS TIMEOUT - MODEL TOO SLOW" > "$output_file"
    }
}

# Function to generate detailed comments
generate_detailed_comments() {
    local file="$1"
    local model="$2"
    local iteration="$3"
    
    local output_file="code_review_results/comments/${model//[^a-zA-Z0-9]/_}_comments_$(basename "$file" | tr '/' '_')"
    
    print_model "$model" "Generating detailed comments for $file"
    
    local prompt="
DETAILED CODE DOCUMENTATION GENERATOR

File: $file

INSTRUCTIONS:
1. Generate EXTREMELY detailed comments for EVERY line of code
2. Document EVERY function, class, variable, and data structure
3. Explain the purpose, parameters, return values, side effects
4. Document every table, field, piece of data, and context
5. Add comprehensive inline documentation
6. Include usage examples where appropriate
7. Document error conditions and edge cases
8. Explain business logic and domain knowledge
9. Add TODO comments for improvements
10. Document configuration options and their effects

CODE TO DOCUMENT:
$(head -200 "$file" 2>/dev/null || echo "Could not read file")

REQUIREMENTS:
- Every line must have meaningful comments
- Every function must have complete docstrings
- Every class must have comprehensive documentation
- Every variable must be explained
- Every data structure must be documented
- Every configuration must be explained
- Every business rule must be documented

GENERATE COMPREHENSIVE DOCUMENTATION NOW!
"
    
    timeout 300 ollama run "$model" "$prompt" > "$output_file" 2>&1 || {
        print_warning "Comment generation timeout for $model on $file"
        echo "COMMENT GENERATION TIMEOUT" > "$output_file"
    }
}

# Function to generate test cases
generate_test_cases() {
    local file="$1"
    local model="$2"
    local iteration="$3"
    
    local output_file="code_review_results/test_cases/${model//[^a-zA-Z0-9]/_}_tests_$(basename "$file" | tr '/' '_')"
    
    print_model "$model" "Generating Playwright test cases for $file"
    
    local prompt="
COMPREHENSIVE TEST CASE GENERATOR FOR PLAYWRIGHT

File: $file

INSTRUCTIONS:
1. Generate comprehensive Playwright test cases for this code
2. Create tests for EVERY function, endpoint, and feature
3. Include positive, negative, and edge case tests
4. Test error handling and exception scenarios
5. Test performance and load scenarios
6. Test security vulnerabilities
7. Test accessibility and usability
8. Test cross-browser compatibility
9. Test mobile responsiveness
10. Create integration and end-to-end tests
11. Tests must be self-executing and part of deployment
12. Tests must validate every aspect of functionality

CODE TO TEST:
$(head -200 "$file" 2>/dev/null || echo "Could not read file")

REQUIREMENTS:
- Generate Playwright JavaScript/TypeScript test files
- Include setup and teardown procedures
- Test all user interactions and workflows
- Test API endpoints and data validation
- Test UI components and user experience
- Test error scenarios and edge cases
- Test performance under load
- Test security vulnerabilities
- Tests must be automated and runnable
- Tests must be stored in database for future use
- Tests must be part of deployment pipeline

GENERATE COMPREHENSIVE TEST SUITE NOW!
"
    
    timeout 300 ollama run "$model" "$prompt" > "$output_file" 2>&1 || {
        print_warning "Test generation timeout for $model on $file"
        echo "TEST GENERATION TIMEOUT" > "$output_file"
    }
}

# Function to compile issues from all models
compile_issues() {
    local iteration="$1"
    
    print_header "Compiling Issues from All Models - Iteration $iteration"
    
    local issues_file="code_review_results/issues/compiled_issues_iteration_${iteration}.md"
    
    echo "# MedinovAI Code Review Issues - Iteration $iteration" > "$issues_file"
    echo "Generated: $(date)" >> "$issues_file"
    echo "" >> "$issues_file"
    
    for category in "${CATEGORIES[@]}"; do
        echo "## $category" >> "$issues_file"
        echo "" >> "$issues_file"
        
        for model in "${MODELS[@]}"; do
            echo "### $model" >> "$issues_file"
            echo "" >> "$issues_file"
            
            # Find all analysis files for this model and category
            find "code_review_results/iterations/iteration_${iteration}" -name "*${model//[^a-zA-Z0-9]/_}*${category}*" -exec cat {} \; >> "$issues_file" 2>/dev/null || true
            
            echo "" >> "$issues_file"
        done
    done
    
    print_status "Issues compiled to $issues_file"
}

# Main execution function
main() {
    print_header "MedinovAI Comprehensive Code Review"
    print_status "Starting brutal code review with top 5 models"
    print_status "Models: ${MODELS[*]}"
    
    # Get list of files to analyze
    local files=($(get_code_files))
    print_status "Found ${#files[@]} files to analyze"
    
    # Run 3 iterations of analysis
    for iteration in 1 2 3; do
        print_header "ITERATION $iteration - COMPREHENSIVE ANALYSIS"
        
        for file in "${files[@]}"; do
            print_status "Processing file: $file"
            
            # Analyze with each model for each category
            for model in "${MODELS[@]}"; do
                for category in "${CATEGORIES[@]}"; do
                    analyze_file_with_model "$file" "$model" "$iteration" "$category"
                done
                
                # Generate detailed comments
                generate_detailed_comments "$file" "$model" "$iteration"
                
                # Generate test cases
                generate_test_cases "$file" "$model" "$iteration"
            done
        done
        
        # Compile issues for this iteration
        compile_issues "$iteration"
        
        print_status "Iteration $iteration completed"
    done
    
    # Final compilation
    print_header "FINAL ISSUE COMPILATION"
    
    local final_issues="code_review_results/FINAL_COMPREHENSIVE_ISSUES.md"
    echo "# MedinovAI Final Comprehensive Code Review Issues" > "$final_issues"
    echo "Generated: $(date)" >> "$final_issues"
    echo "" >> "$final_issues"
    
    # Combine all iterations
    for iteration in 1 2 3; do
        echo "## Iteration $iteration Issues" >> "$final_issues"
        cat "code_review_results/issues/compiled_issues_iteration_${iteration}.md" >> "$final_issues" 2>/dev/null || true
        echo "" >> "$final_issues"
    done
    
    print_status "Comprehensive code review completed!"
    print_status "Results saved in code_review_results/"
    print_status "Final issues: $final_issues"
    
    # Show summary
    print_header "REVIEW SUMMARY"
    echo "Files analyzed: ${#files[@]}"
    echo "Models used: ${#MODELS[@]}"
    echo "Categories: ${#CATEGORIES[@]}"
    echo "Iterations: 3"
    echo "Total analyses: $((${#files[@]} * ${#MODELS[@]} * ${#CATEGORIES[@]} * 3))"
}

# Run main function
main "$@"
