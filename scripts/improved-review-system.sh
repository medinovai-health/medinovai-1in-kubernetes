#!/bin/bash

# Improved Review System with Top 3 Ollama Models
# Reviews every step and iterates until 9/10 quality is achieved

set -euo pipefail

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

log_deploy() {
    echo -e "${PURPLE}🚀 $1${NC}"
}

log_review() {
    echo -e "${CYAN}🔍 $1${NC}"
}

# Configuration
REVIEW_DIR="/Users/dev1/github/medinovai-infrastructure/improved-reviews"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Top 3 models for review
MODEL_1="deepseek-r1-70b-analysis:latest"
MODEL_2="qwen2.5:72b"
MODEL_3="codellama:70b"

log_deploy "Initializing Improved Review System with Top 3 Ollama Models"

# Create review directory
mkdir -p "$REVIEW_DIR"

# Function to run model review with better prompt
run_model_review() {
    local model_name="$1"
    local review_type="$2"
    local content="$3"
    local output_file="$4"
    
    log_review "Running review with $model_name for $review_type..."
    
    # Create focused review prompt
    local prompt="Rate this $review_type configuration from 1-10 and provide specific recommendations.

Configuration:
$content

Please respond with:
SCORE: [number from 1-10]
ANALYSIS: [detailed analysis]
RECOMMENDATIONS: [specific actionable recommendations]
CRITICAL_ISSUES: [issues that must be fixed immediately]"
    
    # Run the model review with timeout
    timeout 300 bash -c "echo '$prompt' | ollama run '$model_name'" > "$output_file" 2>&1 || {
        log_error "Review with $model_name timed out or failed"
        echo "SCORE: 0" > "$output_file"
        return 1
    }
    
    log_success "Review completed with $model_name"
}

# Function to extract score from review
extract_score() {
    local review_file="$1"
    local model_name="$2"
    
    # Clean the file and extract score
    local score=$(grep -i "SCORE:" "$review_file" | head -1 | grep -oE "[0-9]+" | head -1)
    
    if [ -z "$score" ]; then
        # Try alternative patterns
        score=$(grep -iE "score.*[0-9]+|rating.*[0-9]+|rate.*[0-9]+" "$review_file" | head -1 | grep -oE "[0-9]+" | head -1)
    fi
    
    if [ -z "$score" ]; then
        log_warning "Could not extract score from $model_name review"
        score="0"
    fi
    
    # Ensure score is between 1-10
    if [ "$score" -gt 10 ]; then
        score="10"
    elif [ "$score" -lt 1 ]; then
        score="1"
    fi
    
    echo "$score"
}

# Function to run comprehensive review
run_comprehensive_review() {
    local review_type="$1"
    local content="$2"
    local iteration="$3"
    
    log_review "Starting comprehensive review iteration $iteration for $review_type"
    
    local review_dir="$REVIEW_DIR/$review_type/iteration_$iteration"
    mkdir -p "$review_dir"
    
    # Run reviews with all 3 models
    run_model_review "$MODEL_1" "$review_type" "$content" "$review_dir/model1_review.md"
    run_model_review "$MODEL_2" "$review_type" "$content" "$review_dir/model2_review.md"
    run_model_review "$MODEL_3" "$review_type" "$content" "$review_dir/model3_review.md"
    
    # Extract scores
    local score1=$(extract_score "$review_dir/model1_review.md" "$MODEL_1")
    local score2=$(extract_score "$review_dir/model2_review.md" "$MODEL_2")
    local score3=$(extract_score "$review_dir/model3_review.md" "$MODEL_3")
    
    # Calculate average score
    local avg_score=$(echo "scale=1; ($score1 + $score2 + $score3) / 3" | bc -l)
    
    # Create summary report
    cat > "$review_dir/SUMMARY.md" << EOF
# Review Summary - Iteration $iteration
Generated: $(date)

## Review Type: $review_type

## Model Scores:
- **$MODEL_1**: $score1/10
- **$MODEL_2**: $score2/10  
- **$MODEL_3**: $score3/10

## Average Score: $avg_score/10

## Target Score: 9/10

## Status: $([ $(echo "$avg_score >= 9" | bc -l) -eq 1 ] && echo "✅ PASSED" || echo "❌ NEEDS IMPROVEMENT")

## Next Steps:
$([ $(echo "$avg_score >= 9" | bc -l) -eq 1 ] && echo "- Configuration meets quality standards" || echo "- Review individual model feedback and implement improvements")
EOF
    
    log_info "Review completed - Average Score: $avg_score/10"
    
    # Return the average score
    echo "$avg_score"
}

# Function to review Kubernetes cluster configuration
review_kubernetes_cluster() {
    local iteration=1
    local max_iterations=3
    local target_score=9.0
    
    log_deploy "Starting iterative review of Kubernetes cluster configuration"
    
    # Read cluster configuration
    local cluster_config=""
    if [ -f "/Users/dev1/github/medinovai-infrastructure/k8s-cluster-config/k3d-config-v5.yaml" ]; then
        cluster_config=$(cat "/Users/dev1/github/medinovai-infrastructure/k8s-cluster-config/k3d-config-v5.yaml")
    else
        cluster_config="Kubernetes cluster configuration files not found"
    fi
    
    while [ $iteration -le $max_iterations ]; do
        log_info "Kubernetes Cluster Review - Iteration $iteration"
        
        local score=$(run_comprehensive_review "kubernetes_cluster" "$cluster_config" "$iteration")
        
        if [ $(echo "$score >= $target_score" | bc -l) -eq 1 ]; then
            log_success "🎉 Kubernetes cluster configuration achieved target score of $target_score!"
            break
        else
            log_warning "Score $score is below target $target_score. Reviewing feedback for improvements..."
            
            # Read feedback and suggest improvements
            local feedback_file="$REVIEW_DIR/kubernetes_cluster/iteration_$iteration/SUMMARY.md"
            if [ -f "$feedback_file" ]; then
                log_info "Review feedback available in: $feedback_file"
            fi
            
            iteration=$((iteration + 1))
        fi
    done
    
    if [ $iteration -gt $max_iterations ]; then
        log_warning "Maximum iterations reached. Final score: $score"
    fi
}

# Main execution
case "${1:-kubernetes}" in
    "kubernetes")
        review_kubernetes_cluster
        ;;
    "help"|*)
        echo "Usage: $0 {kubernetes|help}"
        echo ""
        echo "Commands:"
        echo "  kubernetes    - Review Kubernetes cluster configuration"
        echo "  help          - Show this help message"
        ;;
esac

log_success "🎉 Improved review system completed!"
echo ""
echo "📊 Review Summary:"
echo "  📁 Review directory: $REVIEW_DIR/"
echo "  🤖 Models used: $MODEL_1, $MODEL_2, $MODEL_3"
echo "  🎯 Target score: 9/10"
echo "  📋 Review reports: Available in $REVIEW_DIR/"
echo ""
echo "📖 Review all feedback and implement improvements as needed"
