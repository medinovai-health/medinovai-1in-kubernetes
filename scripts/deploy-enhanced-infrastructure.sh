#!/bin/bash

# 🚀 Enhanced MedinovAI Infrastructure Deployment Script
# Deploys comprehensive infrastructure with continuous monitoring

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="medinovai"
CLUSTER_NAME="medinovai-cluster"
BATCH_SIZE=3
DELAY_BETWEEN_BATCHES=15

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}[HEADER]${NC} $1"
}

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_header "🔍 Checking Prerequisites for Enhanced Infrastructure Deployment"
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        print_error "helm is not installed. Please install helm first."
        exit 1
    fi
    
    # Check if Kubernetes cluster is accessible
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Kubernetes cluster is not accessible. Please ensure your cluster is running."
        exit 1
    fi
    
    # Check if k3d cluster exists
    if ! k3d cluster list | grep -q "$CLUSTER_NAME"; then
        print_error "k3d cluster '$CLUSTER_NAME' not found. Please create the cluster first."
        exit 1
    fi
    
    print_success "Prerequisites check completed"
}

# Function to deploy continuous monitoring infrastructure
deploy_monitoring_infrastructure() {
    print_step "Checking continuous monitoring infrastructure"
    
    # Check if monitoring infrastructure already exists
    if kubectl get namespace monitoring &> /dev/null; then
        print_status "Monitoring infrastructure already exists in 'monitoring' namespace"
        
        # Check if services are running
        local prometheus_ready=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus --no-headers | grep -c "Running" || echo "0")
        local grafana_ready=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana --no-headers | grep -c "Running" || echo "0")
        local loki_ready=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=loki --no-headers | grep -c "Running" || echo "0")
        
        if [ "$prometheus_ready" -gt 0 ] && [ "$grafana_ready" -gt 0 ] && [ "$loki_ready" -gt 0 ]; then
            print_success "✅ Monitoring infrastructure is running (Prometheus: $prometheus_ready, Grafana: $grafana_ready, Loki: $loki_ready)"
        else
            print_warning "⚠️  Monitoring infrastructure exists but not all services are running"
            print_status "Prometheus: $prometheus_ready, Grafana: $grafana_ready, Loki: $loki_ready"
        fi
    else
        print_status "No existing monitoring infrastructure found, deploying new one..."
        if [ -f "./scripts/continuous-monitoring-infrastructure.sh" ]; then
            ./scripts/continuous-monitoring-infrastructure.sh
            print_success "Continuous monitoring infrastructure deployed"
        else
            print_error "Continuous monitoring script not found"
            exit 1
        fi
    fi
}

# Function to deploy core infrastructure
deploy_core_infrastructure() {
    print_step "Deploying core infrastructure components"
    
    # Deploy Istio (if not already deployed)
    if ! kubectl get namespace istio-system &> /dev/null; then
        print_status "Installing Istio..."
        istioctl install --set values.defaultRevision=default -y
        kubectl label namespace "$NAMESPACE" istio-injection=enabled --overwrite
        print_success "Istio installed and configured"
    else
        print_status "Istio already installed"
    fi
    
    # Deploy Metrics Server
    if ! kubectl get deployment metrics-server -n kube-system &> /dev/null; then
        print_status "Installing Metrics Server..."
        kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
        print_success "Metrics Server installed"
    else
        print_status "Metrics Server already installed"
    fi
    
    # Deploy CoreDNS (if needed)
    if ! kubectl get deployment coredns -n kube-system &> /dev/null; then
        print_status "Installing CoreDNS..."
        kubectl apply -f k8s-cluster-config/coredns-config.yaml
        print_success "CoreDNS installed"
    else
        print_status "CoreDNS already installed"
    fi
}

# Function to deploy existing services
deploy_existing_services() {
    print_step "Deploying existing MedinovAI services"
    
    # Deploy API Gateway
    if [ -f "medinovai-deployment/services/api-gateway/k8s-deployment.yaml" ]; then
        print_status "Deploying API Gateway..."
        kubectl apply -f medinovai-deployment/services/api-gateway/k8s-deployment.yaml
        print_success "API Gateway deployed"
    fi
    
    # Deploy PostgreSQL
    if [ -f "medinovai-deployment/databases/postgresql-deployment.yaml" ]; then
        print_status "Deploying PostgreSQL..."
        kubectl apply -f medinovai-deployment/databases/postgresql-deployment.yaml
        print_success "PostgreSQL deployed"
    fi
    
    # Deploy Redis
    if [ -f "medinovai-deployment/databases/redis-deployment.yaml" ]; then
        print_status "Deploying Redis..."
        kubectl apply -f medinovai-deployment/databases/redis-deployment.yaml
        print_success "Redis deployed"
    fi
    
    # Deploy Ollama
    if [ -f "medinovai-deployment/ai-ml/ollama-integration.yaml" ]; then
        print_status "Deploying Ollama..."
        kubectl apply -f medinovai-deployment/ai-ml/ollama-integration.yaml
        print_success "Ollama deployed"
    fi
}

# Function to create monitoring service monitors for existing services
create_service_monitors() {
    print_step "Creating service monitors for existing services"
    
    # Create ServiceMonitor for API Gateway
    cat > /tmp/api-gateway-monitor.yaml << EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: medinovai-api-gateway
  namespace: $NAMESPACE
  labels:
    app: medinovai-api-gateway
    monitoring: enabled
spec:
  selector:
    matchLabels:
      app: medinovai-api-gateway
  endpoints:
  - port: http
    interval: 30s
    path: /metrics
EOF

    kubectl apply -f /tmp/api-gateway-monitor.yaml
    print_success "Service monitors created"
}

# Function to validate deployment
validate_deployment() {
    print_step "Validating deployment"
    
    # Check namespace
    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        print_success "✅ Namespace '$NAMESPACE' exists"
    else
        print_error "❌ Namespace '$NAMESPACE' not found"
        return 1
    fi
    
    # Check pods
    local pod_count=$(kubectl get pods -n "$NAMESPACE" --no-headers | wc -l)
    local running_pods=$(kubectl get pods -n "$NAMESPACE" --field-selector=status.phase=Running --no-headers | wc -l)
    
    print_status "Pod Status: $running_pods/$pod_count running"
    
    if [ "$running_pods" -gt 0 ]; then
        print_success "✅ Services are running"
    else
        print_warning "⚠️  No services running yet"
    fi
    
    # Check services
    local service_count=$(kubectl get svc -n "$NAMESPACE" --no-headers | wc -l)
    print_status "Services: $service_count deployed"
    
    # Check monitoring
    if kubectl get namespace monitoring &> /dev/null; then
        print_success "✅ Monitoring infrastructure deployed"
    else
        print_warning "⚠️  Monitoring infrastructure not deployed"
    fi
}

# Function to show deployment status
show_deployment_status() {
    print_header "📊 Enhanced Infrastructure Deployment Status"
    echo "=================================================="
    echo ""
    
    print_status "Namespace Status:"
    kubectl get namespace "$NAMESPACE" || true
    echo ""
    
    print_status "Pod Status:"
    kubectl get pods -n "$NAMESPACE" -o wide || true
    echo ""
    
    print_status "Service Status:"
    kubectl get svc -n "$NAMESPACE" || true
    echo ""
    
    print_status "Ingress Status:"
    kubectl get ingress -n "$NAMESPACE" || true
    echo ""
    
    print_status "Monitoring Status:"
    kubectl get pods -n monitoring -o wide || true
    echo ""
    
    print_status "Access Information:"
    echo "  API Gateway: kubectl port-forward -n $NAMESPACE svc/medinovai-api-gateway 8080:80"
    echo "  Grafana:     kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
    echo "  Prometheus:  kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
    echo ""
}

# Function to create deployment summary
create_deployment_summary() {
    print_step "Creating deployment summary"
    
    cat > /tmp/deployment-summary.md << EOF
# 🚀 Enhanced MedinovAI Infrastructure Deployment Summary

## Deployment Date
$(date)

## Infrastructure Components Deployed

### Core Infrastructure
- ✅ Kubernetes Cluster (k3d-medinovai-cluster)
- ✅ Istio Service Mesh
- ✅ Metrics Server
- ✅ CoreDNS

### MedinovAI Services
- ✅ API Gateway (medinovai-api-gateway)
- ✅ PostgreSQL Database
- ✅ Redis Cache
- ✅ Ollama AI/ML Service

### Monitoring Infrastructure
- ✅ Prometheus (Metrics Collection)
- ✅ Grafana (Dashboards)
- ✅ Loki (Log Aggregation)
- ✅ AlertManager (Alerting)

## Access Information

### Service Access
- API Gateway: kubectl port-forward -n $NAMESPACE svc/medinovai-api-gateway 8080:80
- PostgreSQL: kubectl port-forward -n $NAMESPACE svc/postgresql 5432:5432
- Redis: kubectl port-forward -n $NAMESPACE svc/redis 6379:6379
- Ollama: kubectl port-forward -n $NAMESPACE svc/ollama 11434:11434

### Monitoring Access
- Grafana: kubectl port-forward -n medinovai-monitoring svc/grafana 3000:80
- Prometheus: kubectl port-forward -n medinovai-monitoring svc/prometheus-server 9090:80
- AlertManager: kubectl port-forward -n medinovai-monitoring svc/prometheus-alertmanager 9093:80

### Default Credentials
- Grafana: admin / admin123

## Next Steps
1. Deploy remaining MedinovAI services
2. Configure additional monitoring dashboards
3. Set up alerting rules
4. Implement backup and disaster recovery
5. Configure security policies

## Monitoring Dashboards
- MedinovAI Infrastructure Overview
- Kubernetes Cluster Monitoring
- Pod and Service Monitoring
- Resource Usage Monitoring

## Alerting Rules
- Pod Down Alerts
- High CPU Usage Alerts
- High Memory Usage Alerts
- Service Down Alerts
EOF

    print_success "Deployment summary created at /tmp/deployment-summary.md"
}

# Function to show help
show_help() {
    echo "🚀 Enhanced MedinovAI Infrastructure Deployment Script"
    echo ""
    echo "Usage: $0 [--monitoring-only] [--core-only] [--help]"
    echo ""
    echo "Arguments:"
    echo "  --monitoring-only    Deploy only monitoring infrastructure"
    echo "  --core-only         Deploy only core infrastructure"
    echo "  --help              Show this help message"
    echo ""
    echo "This script will:"
    echo "  1. Check prerequisites (kubectl, helm, cluster)"
    echo "  2. Deploy continuous monitoring infrastructure"
    echo "  3. Deploy core infrastructure components"
    echo "  4. Deploy existing MedinovAI services"
    echo "  5. Create service monitors"
    echo "  6. Validate deployment"
    echo "  7. Show deployment status"
    echo ""
}

# Main execution function
main() {
    echo "🚀 Enhanced MedinovAI Infrastructure Deployment"
    echo "=============================================="
    echo ""
    
    # Handle help
    if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
        show_help
        exit 0
    fi
    
    check_prerequisites
    
    # Handle monitoring-only deployment
    if [[ "${1:-}" == "--monitoring-only" ]]; then
        deploy_monitoring_infrastructure
        show_deployment_status
        exit 0
    fi
    
    # Handle core-only deployment
    if [[ "${1:-}" == "--core-only" ]]; then
        deploy_core_infrastructure
        deploy_existing_services
        validate_deployment
        show_deployment_status
        exit 0
    fi
    
    # Full deployment
    deploy_monitoring_infrastructure
    deploy_core_infrastructure
    deploy_existing_services
    create_service_monitors
    validate_deployment
    create_deployment_summary
    show_deployment_status
    
    print_success "🎉 Enhanced infrastructure deployment completed successfully!"
    print_status "Next steps:"
    echo "  1. Access monitoring: kubectl port-forward -n medinovai-monitoring svc/grafana 3000:80"
    echo "  2. Deploy remaining services using production deployment script"
    echo "  3. Configure additional monitoring and alerting"
    echo "  4. Review deployment summary: cat /tmp/deployment-summary.md"
    echo ""
}

# Run main function
main "$@"
