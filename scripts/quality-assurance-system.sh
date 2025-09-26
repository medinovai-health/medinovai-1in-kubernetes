#!/bin/bash

# Quality Assurance System with Top 3 Ollama Models
# Ensures quality at every step with honest, brutal reviews

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

log_qa() {
    echo -e "${PURPLE}🔍 $1${NC}"
}

log_review() {
    echo -e "${CYAN}📋 $1${NC}"
}

# Configuration
QA_DIR="/Users/dev1/github/medinovai-infrastructure/quality-assurance"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Top 3 models for quality assurance
MODEL_1="deepseek-r1-70b-analysis:latest"  # Best overall analysis
MODEL_2="qwen2.5:72b"                      # Excellent reasoning
MODEL_3="codellama:70b"                    # Best for code review

log_qa "Initializing Quality Assurance System with Top 3 Ollama Models"

# Create QA directory
mkdir -p "$QA_DIR"

# Function to run honest model review
run_honest_review() {
    local model_name="$1"
    local review_type="$2"
    local content="$3"
    local output_file="$4"
    
    log_review "Running honest review with $model_name for $review_type..."
    
    # Create brutally honest review prompt
    local prompt="You are an expert quality assurance engineer. Be BRUTALLY HONEST and UNCOMPROMISING in your review. Rate this $review_type from 1-10 and provide specific, actionable feedback.

CRITICAL REQUIREMENTS:
- Be brutally honest - no sugar coating
- Identify ALL issues, no matter how small
- Provide specific, actionable recommendations
- Rate harshly - only give 9-10 for truly exceptional work
- Focus on production readiness and enterprise standards

Content to review:
$content

Please respond with:
SCORE: [number from 1-10 - be harsh and honest]
CRITICAL_ISSUES: [list all critical issues that must be fixed]
HIGH_PRIORITY_ISSUES: [list high priority issues]
MEDIUM_PRIORITY_ISSUES: [list medium priority issues]
LOW_PRIORITY_ISSUES: [list low priority issues]
RECOMMENDATIONS: [specific actionable recommendations]
PRODUCTION_READY: [YES/NO - only YES if truly production ready]
NEXT_STEPS: [specific next steps to improve quality]"
    
    # Run the model review with timeout
    timeout 300 bash -c "echo '$prompt' | ollama run '$model_name'" > "$output_file" 2>&1 || {
        log_error "Review with $model_name timed out or failed"
        echo "SCORE: 0" > "$output_file"
        return 1
    }
    
    log_success "Honest review completed with $model_name"
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

# Function to check production readiness
check_production_ready() {
    local review_file="$1"
    local model_name="$2"
    
    local production_ready=$(grep -i "PRODUCTION_READY:" "$review_file" | head -1 | grep -i "yes" | wc -l)
    
    if [ "$production_ready" -gt 0 ]; then
        echo "YES"
    else
        echo "NO"
    fi
}

# Function to run comprehensive QA review
run_comprehensive_qa() {
    local review_type="$1"
    local content="$2"
    local iteration="$3"
    
    log_qa "Starting comprehensive QA review iteration $iteration for $review_type"
    
    local qa_dir="$QA_DIR/$review_type/iteration_$iteration"
    mkdir -p "$qa_dir"
    
    # Run reviews with all 3 models
    run_honest_review "$MODEL_1" "$review_type" "$content" "$qa_dir/model1_review.md"
    run_honest_review "$MODEL_2" "$review_type" "$content" "$qa_dir/model2_review.md"
    run_honest_review "$MODEL_3" "$review_type" "$content" "$qa_dir/model3_review.md"
    
    # Extract scores
    local score1=$(extract_score "$qa_dir/model1_review.md" "$MODEL_1")
    local score2=$(extract_score "$qa_dir/model2_review.md" "$MODEL_2")
    local score3=$(extract_score "$qa_dir/model3_review.md" "$MODEL_3")
    
    # Check production readiness
    local prod_ready1=$(check_production_ready "$qa_dir/model1_review.md" "$MODEL_1")
    local prod_ready2=$(check_production_ready "$qa_dir/model2_review.md" "$MODEL_2")
    local prod_ready3=$(check_production_ready "$qa_dir/model3_review.md" "$MODEL_3")
    
    # Calculate average score
    local avg_score=$(echo "scale=1; ($score1 + $score2 + $score3) / 3" | bc -l)
    
    # Determine overall production readiness
    local prod_ready_count=0
    [ "$prod_ready1" = "YES" ] && prod_ready_count=$((prod_ready_count + 1))
    [ "$prod_ready2" = "YES" ] && prod_ready_count=$((prod_ready_count + 1))
    [ "$prod_ready3" = "YES" ] && prod_ready_count=$((prod_ready_count + 1))
    
    local overall_prod_ready="NO"
    if [ $prod_ready_count -ge 2 ]; then
        overall_prod_ready="YES"
    fi
    
    # Create comprehensive QA report
    cat > "$qa_dir/QA_REPORT.md" << EOF
# Quality Assurance Report - Iteration $iteration
Generated: $(date)

## Review Type: $review_type

## Model Reviews:

### $MODEL_1
- **Score**: $score1/10
- **Production Ready**: $prod_ready1
- **Review File**: model1_review.md

### $MODEL_2
- **Score**: $score2/10
- **Production Ready**: $prod_ready2
- **Review File**: model2_review.md

### $MODEL_3
- **Score**: $score3/10
- **Production Ready**: $prod_ready3
- **Review File**: model3_review.md

## Overall Assessment:

### **Average Score: $avg_score/10**
### **Production Ready: $overall_prod_ready**
### **Consensus**: $prod_ready_count/3 models approve for production

## Quality Status:
$([ $(echo "$avg_score >= 9" | bc -l) -eq 1 ] && echo "✅ **EXCELLENT** - Meets high quality standards" || echo "❌ **NEEDS IMPROVEMENT** - Below quality standards")

## Production Readiness:
$([ "$overall_prod_ready" = "YES" ] && echo "✅ **PRODUCTION READY** - Approved by majority of models" || echo "❌ **NOT PRODUCTION READY** - Requires improvements")

## Next Steps:
$([ $(echo "$avg_score >= 9" | bc -l) -eq 1 ] && [ "$overall_prod_ready" = "YES" ] && echo "- Quality standards met - proceed to next phase" || echo "- Review individual model feedback and implement improvements")
EOF
    
    log_info "QA review completed - Average Score: $avg_score/10, Production Ready: $overall_prod_ready"
    
    # Return the average score
    echo "$avg_score"
}

# Function to QA current infrastructure
qa_current_infrastructure() {
    local iteration=1
    local max_iterations=3
    local target_score=9.0
    
    log_qa "Starting QA review of current infrastructure"
    
    # Gather current infrastructure status
    local infra_status=""
    infra_status+="## Kubernetes Cluster Status:\n"
    infra_status+="$(kubectl get nodes 2>/dev/null || echo 'Cluster not accessible')\n\n"
    infra_status+="## Pod Status:\n"
    infra_status+="$(kubectl get pods --all-namespaces 2>/dev/null | head -20 || echo 'Pods not accessible')\n\n"
    infra_status+="## Services Status:\n"
    infra_status+="$(kubectl get services --all-namespaces 2>/dev/null | head -20 || echo 'Services not accessible')\n\n"
    infra_status+="## Security Policies:\n"
    infra_status+="$(kubectl get networkpolicies,resourcequota,limitrange --all-namespaces 2>/dev/null || echo 'Security policies not accessible')\n\n"
    infra_status+="## Monitoring Status:\n"
    infra_status+="$(kubectl get pods -n monitoring 2>/dev/null || echo 'Monitoring not accessible')\n\n"
    infra_status+="## API Gateway Status:\n"
    infra_status+="$(kubectl get pods -n medinovai 2>/dev/null || echo 'API Gateway not accessible')\n\n"
    
    while [ $iteration -le $max_iterations ]; do
        log_info "Infrastructure QA Review - Iteration $iteration"
        
        local score=$(run_comprehensive_qa "infrastructure" "$infra_status" "$iteration")
        
        if [ $(echo "$score >= $target_score" | bc -l) -eq 1 ]; then
            log_success "🎉 Infrastructure achieved target quality score of $target_score!"
            break
        else
            log_warning "Score $score is below target $target_score. Reviewing feedback for improvements..."
            
            # Read feedback and suggest improvements
            local feedback_file="$QA_DIR/infrastructure/iteration_$iteration/QA_REPORT.md"
            if [ -f "$feedback_file" ]; then
                log_info "QA feedback available in: $feedback_file"
            fi
            
            iteration=$((iteration + 1))
        fi
    done
    
    if [ $iteration -gt $max_iterations ]; then
        log_warning "Maximum QA iterations reached. Final score: $score"
    fi
}

# Function to QA API Gateway
qa_api_gateway() {
    local iteration=1
    local max_iterations=3
    local target_score=9.0
    
    log_qa "Starting QA review of API Gateway"
    
    # Test API Gateway endpoints
    local api_status=""
    api_status+="## API Gateway Test Results:\n"
    
    # Test health endpoint
    local health_response=$(curl -s http://localhost:8080/health 2>/dev/null || echo 'Health endpoint not accessible')
    api_status+="Health Endpoint: $health_response\n\n"
    
    # Test patients endpoint
    local patients_response=$(curl -s http://localhost:8080/api/v1/patients 2>/dev/null || echo 'Patients endpoint not accessible')
    api_status+="Patients Endpoint: $patients_response\n\n"
    
    # Test FHIR endpoint
    local fhir_response=$(curl -s http://localhost:8080/api/v1/fhir/metadata 2>/dev/null || echo 'FHIR endpoint not accessible')
    api_status+="FHIR Endpoint: $fhir_response\n\n"
    
    # Test metrics endpoint
    local metrics_response=$(curl -s http://localhost:8080/metrics 2>/dev/null || echo 'Metrics endpoint not accessible')
    api_status+="Metrics Endpoint: $metrics_response\n\n"
    
    # Get pod status
    api_status+="## Pod Status:\n"
    api_status+="$(kubectl get pods -n medinovai 2>/dev/null || echo 'Pods not accessible')\n\n"
    
    # Get service status
    api_status+="## Service Status:\n"
    api_status+="$(kubectl get service -n medinovai 2>/dev/null || echo 'Service not accessible')\n\n"
    
    while [ $iteration -le $max_iterations ]; do
        log_info "API Gateway QA Review - Iteration $iteration"
        
        local score=$(run_comprehensive_qa "api_gateway" "$api_status" "$iteration")
        
        if [ $(echo "$score >= $target_score" | bc -l) -eq 1 ]; then
            log_success "🎉 API Gateway achieved target quality score of $target_score!"
            break
        else
            log_warning "Score $score is below target $target_score. Reviewing feedback for improvements..."
            
            # Read feedback and suggest improvements
            local feedback_file="$QA_DIR/api_gateway/iteration_$iteration/QA_REPORT.md"
            if [ -f "$feedback_file" ]; then
                log_info "QA feedback available in: $feedback_file"
            fi
            
            iteration=$((iteration + 1))
        fi
    done
    
    if [ $iteration -gt $max_iterations ]; then
        log_warning "Maximum QA iterations reached. Final score: $score"
    fi
}

# Main execution
case "${1:-all}" in
    "infrastructure")
        qa_current_infrastructure
        ;;
    "api")
        qa_api_gateway
        ;;
    "all")
        log_qa "Running comprehensive QA review of all components"
        qa_current_infrastructure
        qa_api_gateway
        ;;
    "help"|*)
        echo "Usage: $0 {infrastructure|api|all|help}"
        echo ""
        echo "Commands:"
        echo "  infrastructure - QA review of Kubernetes infrastructure"
        echo "  api           - QA review of API Gateway"
        echo "  all           - QA review of all components"
        echo "  help          - Show this help message"
        ;;
esac

log_success "🎉 Quality assurance system completed!"
echo ""
echo "📊 QA Summary:"
echo "  📁 QA directory: $QA_DIR/"
echo "  🤖 Models used: $MODEL_1, $MODEL_2, $MODEL_3"
echo "  🎯 Target score: 9/10"
echo "  📋 QA reports: Available in $QA_DIR/"
echo ""
echo "📖 Review all QA feedback and implement improvements as needed"
