#!/bin/bash

# MedinovAI Deployment Validation Script
# This script validates the complete deployment of all repositories

set -euo pipefail

# Configuration
MEDINOVAI_NAMESPACE="medinovai"
REPO_COUNT=120
VALIDATION_TIMEOUT=300

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

log_validate() {
    echo -e "${PURPLE}🔍 $1${NC}"
}

# Validation results
declare -A VALIDATION_RESULTS
TOTAL_VALIDATIONS=0
PASSED_VALIDATIONS=0
FAILED_VALIDATIONS=0

# Record validation result
record_validation() {
    local test_name="$1"
    local result="$2"
    local message="$3"
    
    VALIDATION_RESULTS["$test_name"]="$result"
    ((TOTAL_VALIDATIONS++))
    
    if [[ "$result" == "PASS" ]]; then
        ((PASSED_VALIDATIONS++))
        log_success "$test_name: $message"
    else
        ((FAILED_VALIDATIONS++))
        log_error "$test_name: $message"
    fi
}

# Validate Kubernetes cluster
validate_kubernetes_cluster() {
    log_validate "Validating Kubernetes cluster..."
    
    # Check cluster connectivity
    if kubectl cluster-info &>/dev/null; then
        record_validation "kubernetes-cluster" "PASS" "Cluster is accessible"
    else
        record_validation "kubernetes-cluster" "FAIL" "Cluster is not accessible"
        return 1
    fi
    
    # Check node status
    local ready_nodes
    ready_nodes=$(kubectl get nodes --no-headers | grep -c "Ready" || echo "0")
    if [[ $ready_nodes -gt 0 ]]; then
        record_validation "kubernetes-nodes" "PASS" "$ready_nodes nodes are ready"
    else
        record_validation "kubernetes-nodes" "FAIL" "No ready nodes found"
    fi
    
    # Check namespace
    if kubectl get namespace "$MEDINOVAI_NAMESPACE" &>/dev/null; then
        record_validation "medinovai-namespace" "PASS" "Namespace exists"
    else
        record_validation "medinovai-namespace" "FAIL" "Namespace does not exist"
    fi
}

# Validate Istio installation
validate_istio() {
    log_validate "Validating Istio installation..."
    
    # Check Istio installation
    if kubectl get pods -n istio-system &>/dev/null; then
        local istio_pods
        istio_pods=$(kubectl get pods -n istio-system --no-headers | grep -c "Running" || echo "0")
        if [[ $istio_pods -gt 0 ]]; then
            record_validation "istio-installation" "PASS" "$istio_pods Istio pods are running"
        else
            record_validation "istio-installation" "FAIL" "No Istio pods are running"
        fi
    else
        record_validation "istio-installation" "FAIL" "Istio namespace not found"
    fi
    
    # Check Istio gateway
    if kubectl get gateway -n "$MEDINOVAI_NAMESPACE" &>/dev/null; then
        record_validation "istio-gateway" "PASS" "Istio gateway is configured"
    else
        record_validation "istio-gateway" "FAIL" "Istio gateway is not configured"
    fi
}

# Validate monitoring stack
validate_monitoring() {
    log_validate "Validating monitoring stack..."
    
    # Check Prometheus
    if kubectl get pods -n "$MEDINOVAI_NAMESPACE" -l app.kubernetes.io/name=prometheus &>/dev/null; then
        local prometheus_pods
        prometheus_pods=$(kubectl get pods -n "$MEDINOVAI_NAMESPACE" -l app.kubernetes.io/name=prometheus --no-headers | grep -c "Running" || echo "0")
        if [[ $prometheus_pods -gt 0 ]]; then
            record_validation "prometheus" "PASS" "$prometheus_pods Prometheus pods are running"
        else
            record_validation "prometheus" "FAIL" "No Prometheus pods are running"
        fi
    else
        record_validation "prometheus" "FAIL" "Prometheus not found"
    fi
    
    # Check Grafana
    if kubectl get pods -n "$MEDINOVAI_NAMESPACE" -l app.kubernetes.io/name=grafana &>/dev/null; then
        local grafana_pods
        grafana_pods=$(kubectl get pods -n "$MEDINOVAI_NAMESPACE" -l app.kubernetes.io/name=grafana --no-headers | grep -c "Running" || echo "0")
        if [[ $grafana_pods -gt 0 ]]; then
            record_validation "grafana" "PASS" "$grafana_pods Grafana pods are running"
        else
            record_validation "grafana" "FAIL" "No Grafana pods are running"
        fi
    else
        record_validation "grafana" "FAIL" "Grafana not found"
    fi
    
    # Check Loki
    if kubectl get pods -n "$MEDINOVAI_NAMESPACE" -l app=loki &>/dev/null; then
        local loki_pods
        loki_pods=$(kubectl get pods -n "$MEDINOVAI_NAMESPACE" -l app=loki --no-headers | grep -c "Running" || echo "0")
        if [[ $loki_pods -gt 0 ]]; then
            record_validation "loki" "PASS" "$loki_pods Loki pods are running"
        else
            record_validation "loki" "FAIL" "No Loki pods are running"
        fi
    else
        record_validation "loki" "FAIL" "Loki not found"
    fi
}

# Validate database services
validate_database_services() {
    log_validate "Validating database services..."
    
    # Check PostgreSQL
    if kubectl get deployment postgres -n "$MEDINOVAI_NAMESPACE" &>/dev/null; then
        local postgres_ready
        postgres_ready=$(kubectl get deployment postgres -n "$MEDINOVAI_NAMESPACE" -o jsonpath='{.status.readyReplicas}' || echo "0")
        if [[ "$postgres_ready" == "1" ]]; then
            record_validation "postgres" "PASS" "PostgreSQL is ready"
        else
            record_validation "postgres" "FAIL" "PostgreSQL is not ready"
        fi
    else
        record_validation "postgres" "FAIL" "PostgreSQL deployment not found"
    fi
    
    # Check Redis
    if kubectl get deployment redis -n "$MEDINOVAI_NAMESPACE" &>/dev/null; then
        local redis_ready
        redis_ready=$(kubectl get deployment redis -n "$MEDINOVAI_NAMESPACE" -o jsonpath='{.status.readyReplicas}' || echo "0")
        if [[ "$redis_ready" == "1" ]]; then
            record_validation "redis" "PASS" "Redis is ready"
        else
            record_validation "redis" "FAIL" "Redis is not ready"
        fi
    else
        record_validation "redis" "FAIL" "Redis deployment not found"
    fi
    
    # Check MongoDB
    if kubectl get deployment mongodb -n "$MEDINOVAI_NAMESPACE" &>/dev/null; then
        local mongodb_ready
        mongodb_ready=$(kubectl get deployment mongodb -n "$MEDINOVAI_NAMESPACE" -o jsonpath='{.status.readyReplicas}' || echo "0")
        if [[ "$mongodb_ready" == "1" ]]; then
            record_validation "mongodb" "PASS" "MongoDB is ready"
        else
            record_validation "mongodb" "FAIL" "MongoDB is not ready"
        fi
    else
        record_validation "mongodb" "FAIL" "MongoDB deployment not found"
    fi
}

# Validate AI/ML services
validate_ai_ml_services() {
    log_validate "Validating AI/ML services..."
    
    # Check Ollama
    if kubectl get deployment ollama -n "$MEDINOVAI_NAMESPACE" &>/dev/null; then
        local ollama_ready
        ollama_ready=$(kubectl get deployment ollama -n "$MEDINOVAI_NAMESPACE" -o jsonpath='{.status.readyReplicas}' || echo "0")
        if [[ "$ollama_ready" == "1" ]]; then
            record_validation "ollama" "PASS" "Ollama is ready"
        else
            record_validation "ollama" "FAIL" "Ollama is not ready"
        fi
    else
        record_validation "ollama" "FAIL" "Ollama deployment not found"
    fi
    
    # Check Qdrant
    if kubectl get deployment qdrant -n "$MEDINOVAI_NAMESPACE" &>/dev/null; then
        local qdrant_ready
        qdrant_ready=$(kubectl get deployment qdrant -n "$MEDINOVAI_NAMESPACE" -o jsonpath='{.status.readyReplicas}' || echo "0")
        if [[ "$qdrant_ready" == "1" ]]; then
            record_validation "qdrant" "PASS" "Qdrant is ready"
        else
            record_validation "qdrant" "FAIL" "Qdrant is not ready"
        fi
    else
        record_validation "qdrant" "FAIL" "Qdrant deployment not found"
    fi
}

# Validate repository deployments
validate_repository_deployments() {
    log_validate "Validating repository deployments..."
    
    # Get all deployments in MedinovAI namespace
    local deployments
    deployments=$(kubectl get deployments -n "$MEDINOVAI_NAMESPACE" --no-headers | wc -l || echo "0")
    
    if [[ $deployments -gt 0 ]]; then
        record_validation "repository-deployments" "PASS" "$deployments deployments found"
        
        # Check deployment readiness
        local ready_deployments
        ready_deployments=$(kubectl get deployments -n "$MEDINOVAI_NAMESPACE" --no-headers | awk '$2==$4 {print $1}' | wc -l || echo "0")
        
        if [[ $ready_deployments -gt 0 ]]; then
            record_validation "deployment-readiness" "PASS" "$ready_deployments deployments are ready"
        else
            record_validation "deployment-readiness" "FAIL" "No deployments are ready"
        fi
    else
        record_validation "repository-deployments" "FAIL" "No deployments found"
    fi
    
    # Check pods status
    local total_pods
    total_pods=$(kubectl get pods -n "$MEDINOVAI_NAMESPACE" --no-headers | wc -l || echo "0")
    
    if [[ $total_pods -gt 0 ]]; then
        local running_pods
        running_pods=$(kubectl get pods -n "$MEDINOVAI_NAMESPACE" --no-headers | grep -c "Running" || echo "0")
        
        if [[ $running_pods -gt 0 ]]; then
            record_validation "pod-status" "PASS" "$running_pods/$total_pods pods are running"
        else
            record_validation "pod-status" "FAIL" "No pods are running"
        fi
    else
        record_validation "pod-status" "FAIL" "No pods found"
    fi
}

# Validate services
validate_services() {
    log_validate "Validating services..."
    
    # Get all services in MedinovAI namespace
    local services
    services=$(kubectl get services -n "$MEDINOVAI_NAMESPACE" --no-headers | wc -l || echo "0")
    
    if [[ $services -gt 0 ]]; then
        record_validation "services" "PASS" "$services services found"
    else
        record_validation "services" "FAIL" "No services found"
    fi
    
    # Check service endpoints
    local services_with_endpoints
    services_with_endpoints=$(kubectl get services -n "$MEDINOVAI_NAMESPACE" --no-headers | while read -r name type cluster_ip external_ip ports age; do
        if kubectl get endpoints "$name" -n "$MEDINOVAI_NAMESPACE" &>/dev/null; then
            local endpoint_count
            endpoint_count=$(kubectl get endpoints "$name" -n "$MEDINOVAI_NAMESPACE" -o jsonpath='{.subsets[0].addresses[*].ip}' | wc -w || echo "0")
            if [[ $endpoint_count -gt 0 ]]; then
                echo "$name"
            fi
        fi
    done | wc -l || echo "0")
    
    if [[ $services_with_endpoints -gt 0 ]]; then
        record_validation "service-endpoints" "PASS" "$services_with_endpoints services have endpoints"
    else
        record_validation "service-endpoints" "FAIL" "No services have endpoints"
    fi
}

# Validate network policies
validate_network_policies() {
    log_validate "Validating network policies..."
    
    # Check network policies
    local network_policies
    network_policies=$(kubectl get networkpolicies -n "$MEDINOVAI_NAMESPACE" --no-headers | wc -l || echo "0")
    
    if [[ $network_policies -gt 0 ]]; then
        record_validation "network-policies" "PASS" "$network_policies network policies found"
    else
        record_validation "network-policies" "FAIL" "No network policies found"
    fi
}

# Validate security policies
validate_security_policies() {
    log_validate "Validating security policies..."
    
    # Check Kyverno
    if kubectl get pods -n kyverno &>/dev/null; then
        local kyverno_pods
        kyverno_pods=$(kubectl get pods -n kyverno --no-headers | grep -c "Running" || echo "0")
        if [[ $kyverno_pods -gt 0 ]]; then
            record_validation "kyverno" "PASS" "$kyverno_pods Kyverno pods are running"
        else
            record_validation "kyverno" "FAIL" "No Kyverno pods are running"
        fi
    else
        record_validation "kyverno" "FAIL" "Kyverno not found"
    fi
    
    # Check Pod Security Standards
    local pss_enforced
    pss_enforced=$(kubectl get namespace "$MEDINOVAI_NAMESPACE" -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' || echo "")
    
    if [[ "$pss_enforced" == "restricted" ]]; then
        record_validation "pod-security-standards" "PASS" "Pod Security Standards are enforced"
    else
        record_validation "pod-security-standards" "FAIL" "Pod Security Standards are not enforced"
    fi
}

# Validate port allocation
validate_port_allocation() {
    log_validate "Validating port allocation..."
    
    # Check port allocation configmap
    if kubectl get configmap medinovai-port-allocation -n "$MEDINOVAI_NAMESPACE" &>/dev/null; then
        record_validation "port-allocation-config" "PASS" "Port allocation configuration found"
    else
        record_validation "port-allocation-config" "FAIL" "Port allocation configuration not found"
    fi
    
    # Check for port conflicts
    local port_conflicts
    port_conflicts=$(kubectl get services -n "$MEDINOVAI_NAMESPACE" -o jsonpath='{.items[*].spec.ports[*].port}' | tr ' ' '\n' | sort | uniq -d | wc -l || echo "0")
    
    if [[ $port_conflicts -eq 0 ]]; then
        record_validation "port-conflicts" "PASS" "No port conflicts detected"
    else
        record_validation "port-conflicts" "FAIL" "$port_conflicts port conflicts detected"
    fi
}

# Validate resource usage
validate_resource_usage() {
    log_validate "Validating resource usage..."
    
    # Check node resource usage
    local node_count
    node_count=$(kubectl get nodes --no-headers | wc -l || echo "0")
    
    if [[ $node_count -gt 0 ]]; then
        record_validation "node-count" "PASS" "$node_count nodes available"
        
        # Check memory usage
        local memory_usage
        memory_usage=$(kubectl top nodes --no-headers 2>/dev/null | awk '{sum+=$3} END {print sum}' || echo "0")
        
        if [[ $memory_usage -lt 80 ]]; then
            record_validation "memory-usage" "PASS" "Memory usage is within limits"
        else
            record_validation "memory-usage" "WARN" "Memory usage is high: ${memory_usage}%"
        fi
        
        # Check CPU usage
        local cpu_usage
        cpu_usage=$(kubectl top nodes --no-headers 2>/dev/null | awk '{sum+=$2} END {print sum}' || echo "0")
        
        if [[ $cpu_usage -lt 80 ]]; then
            record_validation "cpu-usage" "PASS" "CPU usage is within limits"
        else
            record_validation "cpu-usage" "WARN" "CPU usage is high: ${cpu_usage}%"
        fi
    else
        record_validation "node-count" "FAIL" "No nodes available"
    fi
}

# Generate validation report
generate_validation_report() {
    log_info "Generating validation report..."
    
    local report_file="validation-report-$(date +%Y%m%d-%H%M%S).json"
    
    cat > "$report_file" << EOF
{
  "validation_summary": {
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "namespace": "$MEDINOVAI_NAMESPACE",
    "total_validations": $TOTAL_VALIDATIONS,
    "passed_validations": $PASSED_VALIDATIONS,
    "failed_validations": $FAILED_VALIDATIONS,
    "success_rate": $(echo "scale=2; $PASSED_VALIDATIONS * 100 / $TOTAL_VALIDATIONS" | bc -l),
    "status": "$(if [[ $FAILED_VALIDATIONS -eq 0 ]]; then echo "PASS"; else echo "FAIL"; fi)"
  },
  "validation_results": {
EOF

    local first=true
    for test_name in "${!VALIDATION_RESULTS[@]}"; do
        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo "," >> "$report_file"
        fi
        echo "    \"$test_name\": \"${VALIDATION_RESULTS[$test_name]}\"" >> "$report_file"
    done

    cat >> "$report_file" << EOF
  },
  "recommendations": [
EOF

    # Add recommendations based on failed validations
    if [[ $FAILED_VALIDATIONS -gt 0 ]]; then
        echo "    \"Review failed validations and address issues\"," >> "$report_file"
        echo "    \"Check pod logs for error details\"," >> "$report_file"
        echo "    \"Verify resource availability\"," >> "$report_file"
        echo "    \"Ensure all dependencies are properly configured\"" >> "$report_file"
    else
        echo "    \"All validations passed successfully\"," >> "$report_file"
        echo "    \"Deployment is ready for production use\"," >> "$report_file"
        echo "    \"Monitor system performance and resource usage\"," >> "$report_file"
        echo "    \"Set up alerting for critical metrics\"" >> "$report_file"
    fi

    cat >> "$report_file" << EOF
  ]
}
EOF

    log_success "Validation report generated: $report_file"
}

# Main execution
main() {
    echo "🔍 MedinovAI Deployment Validation"
    echo "=================================="
    echo "Namespace: $MEDINOVAI_NAMESPACE"
    echo "Repository Count: $REPO_COUNT"
    echo "Validation Timeout: ${VALIDATION_TIMEOUT}s"
    echo "Date: $(date)"
    echo ""
    
    # Run all validations
    validate_kubernetes_cluster
    validate_istio
    validate_monitoring
    validate_database_services
    validate_ai_ml_services
    validate_repository_deployments
    validate_services
    validate_network_policies
    validate_security_policies
    validate_port_allocation
    validate_resource_usage
    
    # Generate report
    generate_validation_report
    
    echo ""
    echo "📊 Validation Summary:"
    echo "  🔍 Total Validations: $TOTAL_VALIDATIONS"
    echo "  ✅ Passed: $PASSED_VALIDATIONS"
    echo "  ❌ Failed: $FAILED_VALIDATIONS"
    echo "  📈 Success Rate: $(echo "scale=1; $PASSED_VALIDATIONS * 100 / $TOTAL_VALIDATIONS" | bc -l)%"
    echo ""
    
    if [[ $FAILED_VALIDATIONS -eq 0 ]]; then
        log_success "🎉 All validations passed! Deployment is successful."
        echo ""
        echo "🚀 Next Steps:"
        echo "  1. Setup monitoring: ./scripts/setup_monitoring.sh"
        echo "  2. Configure alerting"
        echo "  3. Run performance tests"
        echo "  4. Setup backup and recovery"
        exit 0
    else
        log_error "❌ Some validations failed. Please review and fix issues."
        echo ""
        echo "🔧 Troubleshooting:"
        echo "  1. Check pod logs: kubectl logs -n $MEDINOVAI_NAMESPACE"
        echo "  2. Check pod status: kubectl get pods -n $MEDINOVAI_NAMESPACE"
        echo "  3. Check events: kubectl get events -n $MEDINOVAI_NAMESPACE"
        echo "  4. Review validation report for details"
        exit 1
    fi
}

# Run main function
main "$@"








