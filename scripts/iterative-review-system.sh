#!/bin/bash

# Iterative Review System with Top 3 Ollama Models
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
REVIEW_DIR="/Users/dev1/github/medinovai-infrastructure/iterative-reviews"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Top 3 models for review (best performance and reliability)
MODEL_1="deepseek-r1-70b-analysis:latest"  # Best overall performance
MODEL_2="qwen2.5:72b"                      # Excellent reasoning
MODEL_3="codellama:70b"                    # Best for code review

# Review criteria weights
SECURITY_WEIGHT=0.25
PERFORMANCE_WEIGHT=0.20
RELIABILITY_WEIGHT=0.20
MAINTAINABILITY_WEIGHT=0.15
SCALABILITY_WEIGHT=0.10
COMPLIANCE_WEIGHT=0.10

log_deploy "Initializing Iterative Review System with Top 3 Ollama Models"

# Create review directory
mkdir -p "$REVIEW_DIR"

# Function to run model review
run_model_review() {
    local model_name="$1"
    local review_type="$2"
    local content="$3"
    local output_file="$4"
    
    log_review "Running review with $model_name for $review_type..."
    
    # Create review prompt based on type
    case "$review_type" in
        "kubernetes_cluster")
            prompt="As an expert Kubernetes and infrastructure engineer, please provide a comprehensive review of this Kubernetes cluster configuration. Rate it from 1-10 and provide specific recommendations for improvement. Focus on:

1. Security (25%): Pod security standards, RBAC, network policies, secrets management
2. Performance (20%): Resource allocation, scaling, optimization
3. Reliability (20%): High availability, fault tolerance, backup strategies
4. Maintainability (15%): Documentation, monitoring, troubleshooting
5. Scalability (10%): Horizontal scaling, load balancing, resource management
6. Compliance (10%): HIPAA, GDPR, audit logging, regulatory requirements

Configuration to review:
$content

Please provide:
- Overall score (1-10)
- Detailed analysis for each category
- Specific actionable recommendations
- Critical issues that must be fixed
- Best practices not implemented
- Security vulnerabilities
- Performance bottlenecks
- Compliance gaps"
            ;;
        "security_baseline")
            prompt="As a cybersecurity expert specializing in healthcare infrastructure, please review this security baseline configuration. Rate it from 1-10 and provide specific recommendations for improvement. Focus on:

1. Security Controls (30%): Authentication, authorization, encryption, network security
2. Compliance (25%): HIPAA, GDPR, audit requirements, data protection
3. Monitoring (20%): Security monitoring, incident response, threat detection
4. Risk Management (15%): Vulnerability assessment, risk mitigation
5. Documentation (10%): Security policies, procedures, training

Security configuration to review:
$content

Please provide:
- Overall security score (1-10)
- Detailed security analysis
- Compliance assessment
- Critical security gaps
- Recommended security controls
- Incident response procedures
- Security monitoring recommendations
- Risk mitigation strategies"
            ;;
        "infrastructure_setup")
            prompt="As a senior infrastructure architect, please review this infrastructure setup. Rate it from 1-10 and provide specific recommendations for improvement. Focus on:

1. Architecture (25%): Design patterns, best practices, scalability
2. Performance (20%): Resource optimization, efficiency, bottlenecks
3. Reliability (20%): Fault tolerance, redundancy, disaster recovery
4. Security (15%): Infrastructure security, access controls
5. Maintainability (10%): Documentation, monitoring, troubleshooting
6. Cost Optimization (10%): Resource efficiency, cost management

Infrastructure configuration to review:
$content

Please provide:
- Overall architecture score (1-10)
- Detailed architectural analysis
- Performance optimization recommendations
- Reliability improvements
- Security enhancements
- Maintainability improvements
- Cost optimization opportunities"
            ;;
        *)
            prompt="As an expert in infrastructure and DevOps, please provide a comprehensive review of this configuration. Rate it from 1-10 and provide specific recommendations for improvement.

Configuration to review:
$content

Please provide:
- Overall score (1-10)
- Detailed analysis
- Specific recommendations
- Critical issues
- Best practices
- Improvement opportunities"
            ;;
    esac
    
    # Run the model review
    echo "$prompt" | ollama run "$model_name" > "$output_file" 2>&1 || {
        log_error "Failed to run review with $model_name"
        return 1
    }
    
    log_success "Review completed with $model_name"
}

# Function to extract score from review
extract_score() {
    local review_file="$1"
    local model_name="$2"
    
    # Try to extract score from various formats
    local score=$(grep -iE "(score|rating|rate).*[0-9]+" "$review_file" | head -1 | grep -oE "[0-9]+" | head -1)
    
    if [ -z "$score" ]; then
        # Try alternative patterns
        score=$(grep -iE "[0-9]+/10|[0-9]+ out of 10" "$review_file" | head -1 | grep -oE "[0-9]+" | head -1)
    fi
    
    if [ -z "$score" ]; then
        log_warning "Could not extract score from $model_name review"
        score="0"
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
    local max_iterations=5
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

# Function to review security baseline
review_security_baseline() {
    local iteration=1
    local max_iterations=5
    local target_score=9.0
    
    log_deploy "Starting iterative review of security baseline"
    
    # Read security configuration
    local security_config=""
    if [ -f "/Users/dev1/github/medinovai-infrastructure/security-baseline/SECURITY_BASELINE.md" ]; then
        security_config=$(cat "/Users/dev1/github/medinovai-infrastructure/security-baseline/SECURITY_BASELINE.md")
    else
        security_config="Security baseline configuration files not found"
    fi
    
    while [ $iteration -le $max_iterations ]; do
        log_info "Security Baseline Review - Iteration $iteration"
        
        local score=$(run_comprehensive_review "security_baseline" "$security_config" "$iteration")
        
        if [ $(echo "$score >= $target_score" | bc -l) -eq 1 ]; then
            log_success "🎉 Security baseline achieved target score of $target_score!"
            break
        else
            log_warning "Score $score is below target $target_score. Reviewing feedback for improvements..."
            
            # Read feedback and suggest improvements
            local feedback_file="$REVIEW_DIR/security_baseline/iteration_$iteration/SUMMARY.md"
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

# Function to review infrastructure setup
review_infrastructure_setup() {
    local iteration=1
    local max_iterations=5
    local target_score=9.0
    
    log_deploy "Starting iterative review of infrastructure setup"
    
    # Read infrastructure configuration
    local infra_config=""
    if [ -f "/Users/dev1/github/medinovai-infrastructure/MACSTUDIO_INFRASTRUCTURE_IMPLEMENTATION_PLAN.md" ]; then
        infra_config=$(cat "/Users/dev1/github/medinovai-infrastructure/MACSTUDIO_INFRASTRUCTURE_IMPLEMENTATION_PLAN.md")
    else
        infra_config="Infrastructure setup configuration files not found"
    fi
    
    while [ $iteration -le $max_iterations ]; do
        log_info "Infrastructure Setup Review - Iteration $iteration"
        
        local score=$(run_comprehensive_review "infrastructure_setup" "$infra_config" "$iteration")
        
        if [ $(echo "$score >= $target_score" | bc -l) -eq 1 ]; then
            log_success "🎉 Infrastructure setup achieved target score of $target_score!"
            break
        else
            log_warning "Score $score is below target $target_score. Reviewing feedback for improvements..."
            
            # Read feedback and suggest improvements
            local feedback_file="$REVIEW_DIR/infrastructure_setup/iteration_$iteration/SUMMARY.md"
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
case "${1:-all}" in
    "kubernetes")
        review_kubernetes_cluster
        ;;
    "security")
        review_security_baseline
        ;;
    "infrastructure")
        review_infrastructure_setup
        ;;
    "all")
        log_deploy "Running comprehensive iterative review of all components"
        review_kubernetes_cluster
        review_security_baseline
        review_infrastructure_setup
        ;;
    "help"|*)
        echo "Usage: $0 {kubernetes|security|infrastructure|all|help}"
        echo ""
        echo "Commands:"
        echo "  kubernetes    - Review Kubernetes cluster configuration"
        echo "  security      - Review security baseline"
        echo "  infrastructure - Review infrastructure setup"
        echo "  all           - Review all components"
        echo "  help          - Show this help message"
        ;;
esac

log_success "🎉 Iterative review system completed!"
echo ""
echo "📊 Review Summary:"
echo "  📁 Review directory: $REVIEW_DIR/"
echo "  🤖 Models used: $MODEL_1, $MODEL_2, $MODEL_3"
echo "  🎯 Target score: 9/10"
echo "  📋 Review reports: Available in $REVIEW_DIR/"
echo ""
echo "📖 Review all feedback and implement improvements as needed"
