#!/bin/bash

# MedinovAI Master Deployment Script
# This script orchestrates the complete deployment of the MedinovAI suite

set -euo pipefail

# Configuration
MEDINOVAI_NAMESPACE="medinovai"
REPO_COUNT=120
DEPLOYMENT_LOG="deployment-$(date +%Y%m%d-%H%M%S).log"

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
    echo -e "${BLUE}ℹ️  $1${NC}" | tee -a "$DEPLOYMENT_LOG"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "$DEPLOYMENT_LOG"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "$DEPLOYMENT_LOG"
}

log_error() {
    echo -e "${RED}❌ $1${NC}" | tee -a "$DEPLOYMENT_LOG"
}

log_deploy() {
    echo -e "${PURPLE}🚀 $1${NC}" | tee -a "$DEPLOYMENT_LOG"
}

log_phase() {
    echo -e "${CYAN}🎯 $1${NC}" | tee -a "$DEPLOYMENT_LOG"
}

# Deployment phases
PHASE_1="Environment Setup"
PHASE_2="Infrastructure Deployment"
PHASE_3="Repository Deployment"
PHASE_4="Validation"
PHASE_5="Monitoring Setup"

# Phase execution times
PHASE_1_TIME=30
PHASE_2_TIME=60
PHASE_3_TIME=240
PHASE_4_TIME=60
PHASE_5_TIME=30

# Total deployment time
TOTAL_TIME=$((PHASE_1_TIME + PHASE_2_TIME + PHASE_3_TIME + PHASE_4_TIME + PHASE_5_TIME))

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if scripts exist
    local scripts=("setup_environment.sh" "deploy_infrastructure.sh" "deploy_repositories.sh" "validate_deployment.sh" "setup_monitoring.sh")
    
    for script in "${scripts[@]}"; do
        if [[ ! -f "scripts/$script" ]]; then
            log_error "Required script not found: scripts/$script"
            exit 1
        fi
        
        if [[ ! -x "scripts/$script" ]]; then
            log_warning "Making script executable: scripts/$script"
            chmod +x "scripts/$script"
        fi
    done
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed"
        exit 1
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    
    # Check Helm
    if ! command -v helm &> /dev/null; then
        log_error "Helm is not installed"
        exit 1
    fi
    
    log_success "All prerequisites met"
}

# Execute phase with error handling
execute_phase() {
    local phase_name="$1"
    local script_name="$2"
    local estimated_time="$3"
    
    log_phase "Starting $phase_name (Estimated time: ${estimated_time} minutes)"
    
    local start_time=$(date +%s)
    
    if [[ -f "scripts/$script_name" ]]; then
        log_info "Executing: ./scripts/$script_name"
        
        if ./scripts/"$script_name" 2>&1 | tee -a "$DEPLOYMENT_LOG"; then
            local end_time=$(date +%s)
            local actual_time=$((end_time - start_time))
            local actual_minutes=$((actual_time / 60))
            
            log_success "$phase_name completed successfully in ${actual_minutes} minutes"
            return 0
        else
            local end_time=$(date +%s)
            local actual_time=$((end_time - start_time))
            local actual_minutes=$((actual_time / 60))
            
            log_error "$phase_name failed after ${actual_minutes} minutes"
            return 1
        fi
    else
        log_error "Script not found: scripts/$script_name"
        return 1
    fi
}

# Generate deployment summary
generate_deployment_summary() {
    local end_time=$(date)
    local start_time=$(head -n 1 "$DEPLOYMENT_LOG" | grep -o '[0-9][0-9]:[0-9][0-9]:[0-9][0-9]' || echo "Unknown")
    
    log_info "Generating deployment summary..."
    
    cat > "deployment-summary-$(date +%Y%m%d-%H%M%S).md" << EOF
# MedinovAI Deployment Summary

## Deployment Information
- **Start Time:** $start_time
- **End Time:** $end_time
- **Namespace:** $MEDINOVAI_NAMESPACE
- **Repository Count:** $REPO_COUNT
- **Deployment Log:** $DEPLOYMENT_LOG

## Phase Results
EOF

    # Add phase results from log
    if grep -q "✅.*completed successfully" "$DEPLOYMENT_LOG"; then
        echo "✅ All phases completed successfully" >> "deployment-summary-$(date +%Y%m%d-%H%M%S).md"
    else
        echo "❌ Some phases failed" >> "deployment-summary-$(date +%Y%m%d-%H%M%S).md"
    fi
    
    cat >> "deployment-summary-$(date +%Y%m%d-%H%M%S).md" << EOF

## System Status
\`\`\`bash
# Check pod status
kubectl get pods -n $MEDINOVAI_NAMESPACE

# Check services
kubectl get services -n $MEDINOVAI_NAMESPACE

# Check deployments
kubectl get deployments -n $MEDINOVAI_NAMESPACE

# Check ingress
kubectl get ingress -n $MEDINOVAI_NAMESPACE
\`\`\`

## Access URLs
- **Grafana:** http://localhost:3000 (admin/medinovai123)
- **Prometheus:** http://localhost:9090
- **Jaeger:** http://localhost:16686
- **Loki:** http://localhost:3100

## Next Steps
1. Verify all services are running
2. Access monitoring dashboards
3. Configure alerting notifications
4. Run performance tests
5. Setup backup and recovery

## Troubleshooting
If issues are encountered:
1. Check pod logs: \`kubectl logs -n $MEDINOVAI_NAMESPACE <pod-name>\`
2. Check events: \`kubectl get events -n $MEDINOVAI_NAMESPACE\`
3. Check resource usage: \`kubectl top pods -n $MEDINOVAI_NAMESPACE\`
4. Review deployment log: \`cat $DEPLOYMENT_LOG\`
EOF

    log_success "Deployment summary generated"
}

# Main deployment execution
main() {
    echo "🚀 MedinovAI Master Deployment"
    echo "============================="
    echo "Namespace: $MEDINOVAI_NAMESPACE"
    echo "Repository Count: $REPO_COUNT"
    echo "Estimated Total Time: $((TOTAL_TIME / 60)) hours $((TOTAL_TIME % 60)) minutes"
    echo "Deployment Log: $DEPLOYMENT_LOG"
    echo "Date: $(date)"
    echo ""
    
    # Initialize deployment log
    echo "MedinovAI Deployment Started: $(date)" > "$DEPLOYMENT_LOG"
    echo "Namespace: $MEDINOVAI_NAMESPACE" >> "$DEPLOYMENT_LOG"
    echo "Repository Count: $REPO_COUNT" >> "$DEPLOYMENT_LOG"
    echo "========================================" >> "$DEPLOYMENT_LOG"
    echo "" >> "$DEPLOYMENT_LOG"
    
    # Check prerequisites
    check_prerequisites
    
    # Phase 1: Environment Setup
    if execute_phase "$PHASE_1" "setup_environment.sh" "$PHASE_1_TIME"; then
        log_success "Phase 1 completed successfully"
    else
        log_error "Phase 1 failed. Stopping deployment."
        exit 1
    fi
    
    # Phase 2: Infrastructure Deployment
    if execute_phase "$PHASE_2" "deploy_infrastructure.sh" "$PHASE_2_TIME"; then
        log_success "Phase 2 completed successfully"
    else
        log_error "Phase 2 failed. Stopping deployment."
        exit 1
    fi
    
    # Phase 3: Repository Deployment
    if execute_phase "$PHASE_3" "deploy_repositories.sh" "$PHASE_3_TIME"; then
        log_success "Phase 3 completed successfully"
    else
        log_error "Phase 3 failed. Stopping deployment."
        exit 1
    fi
    
    # Phase 4: Validation
    if execute_phase "$PHASE_4" "validate_deployment.sh" "$PHASE_4_TIME"; then
        log_success "Phase 4 completed successfully"
    else
        log_error "Phase 4 failed. Stopping deployment."
        exit 1
    fi
    
    # Phase 5: Monitoring Setup
    if execute_phase "$PHASE_5" "setup_monitoring.sh" "$PHASE_5_TIME"; then
        log_success "Phase 5 completed successfully"
    else
        log_error "Phase 5 failed. Stopping deployment."
        exit 1
    fi
    
    # Generate deployment summary
    generate_deployment_summary
    
    echo ""
    log_success "🎉 MedinovAI deployment completed successfully!"
    echo ""
    echo "📊 Deployment Summary:"
    echo "  🏗️  Environment: Setup and configured"
    echo "  🏗️  Infrastructure: Deployed and running"
    echo "  🚀 Repositories: $REPO_COUNT repositories deployed"
    echo "  🔍 Validation: All checks passed"
    echo "  📊 Monitoring: Complete observability stack"
    echo ""
    echo "🌐 Access URLs:"
    echo "  📊 Grafana: http://localhost:3000 (admin/medinovai123)"
    echo "  📈 Prometheus: http://localhost:9090"
    echo "  🔍 Jaeger: http://localhost:16686"
    echo "  📝 Loki: http://localhost:3100"
    echo ""
    echo "📋 Next Steps:"
    echo "  1. Verify all services: kubectl get pods -n $MEDINOVAI_NAMESPACE"
    echo "  2. Access monitoring dashboards"
    echo "  3. Configure alerting notifications"
    echo "  4. Run performance tests"
    echo "  5. Setup backup and recovery"
    echo ""
    echo "📄 Documentation:"
    echo "  📋 Deployment Log: $DEPLOYMENT_LOG"
    echo "  📊 Summary Report: deployment-summary-*.md"
    echo "  📖 Plan Document: ANTHROPIC_CTO_DEPLOYMENT_PLAN.md"
}

# Handle script interruption
trap 'log_error "Deployment interrupted by user"; exit 1' INT TERM

# Run main function
main "$@"

