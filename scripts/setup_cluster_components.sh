#!/bin/bash

# MedinovAI Cluster Components Setup Script
# This script sets up all required cluster-side components for the BMAD implementation

set -euo pipefail

# Configuration
CLUSTER_NAMESPACE="medinovai-platform"
LOG_FILE="cluster_setup.log"
SETUP_DIR="cluster_setup"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
    echo "$(date): INFO: $1" >> "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
    echo "$(date): SUCCESS: $1" >> "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    echo "$(date): WARNING: $1" >> "$LOG_FILE"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    echo "$(date): ERROR: $1" >> "$LOG_FILE"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Check if helm is available
    if ! command -v helm &> /dev/null; then
        log_error "helm is not installed or not in PATH"
        exit 1
    fi
    
    # Check if we can connect to cluster
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Create namespace
create_namespace() {
    log_info "Creating namespace: $CLUSTER_NAMESPACE"
    
    if kubectl get namespace "$CLUSTER_NAMESPACE" &> /dev/null; then
        log_warning "Namespace $CLUSTER_NAMESPACE already exists"
    else
        kubectl create namespace "$CLUSTER_NAMESPACE"
        log_success "Namespace $CLUSTER_NAMESPACE created"
    fi
}

# Install Argo CD
install_argocd() {
    log_info "Installing Argo CD..."
    
    # Add Argo CD Helm repository
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update
    
    # Install Argo CD
    helm upgrade --install argocd argo/argo-cd \
        --namespace "$CLUSTER_NAMESPACE" \
        --set global.domain=argocd.medinovai.local \
        --set server.service.type=ClusterIP \
        --set server.ingress.enabled=true \
        --set server.ingress.hosts[0]=argocd.medinovai.local \
        --wait
    
    log_success "Argo CD installed"
}

# Install Argo CD ApplicationSet
install_argocd_applicationset() {
    log_info "Installing Argo CD ApplicationSet..."
    
    # Apply ApplicationSet CRD
    kubectl apply -f https://raw.githubusercontent.com/argoproj-labs/applicationset/v0.5.1/manifests/install.yaml
    
    # Apply the ApplicationSet configuration
    kubectl apply -f medinovai-infrastructure-standards/platform/addons/argocd-appset.yaml
    
    log_success "Argo CD ApplicationSet installed"
}

# Install External Secrets Operator
install_external_secrets() {
    log_info "Installing External Secrets Operator..."
    
    # Add External Secrets Helm repository
    helm repo add external-secrets https://charts.external-secrets.io
    helm repo update
    
    # Install External Secrets Operator
    helm upgrade --install external-secrets external-secrets/external-secrets \
        --namespace "$CLUSTER_NAMESPACE" \
        --wait
    
    log_success "External Secrets Operator installed"
}

# Install cert-manager
install_cert_manager() {
    log_info "Installing cert-manager..."
    
    # Add cert-manager Helm repository
    helm repo add jetstack https://charts.jetstack.io
    helm repo update
    
    # Install cert-manager
    helm upgrade --install cert-manager jetstack/cert-manager \
        --namespace "$CLUSTER_NAMESPACE" \
        --version v1.13.0 \
        --set installCRDs=true \
        --wait
    
    log_success "cert-manager installed"
}

# Install External DNS
install_external_dns() {
    log_info "Installing External DNS..."
    
    # Add External DNS Helm repository
    helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
    helm repo update
    
    # Install External DNS
    helm upgrade --install external-dns external-dns/external-dns \
        --namespace "$CLUSTER_NAMESPACE" \
        --set provider=aws \
        --set aws.region=us-east-1 \
        --set domainFilters[0]=medinovai.local \
        --wait
    
    log_success "External DNS installed"
}

# Install Envoy Gateway
install_envoy_gateway() {
    log_info "Installing Envoy Gateway..."
    
    # Add Envoy Gateway Helm repository
    helm repo add envoy-gateway https://envoyproxy.github.io/envoy-gateway
    helm repo update
    
    # Install Envoy Gateway
    helm upgrade --install envoy-gateway envoy-gateway/envoy-gateway \
        --namespace "$CLUSTER_NAMESPACE" \
        --wait
    
    log_success "Envoy Gateway installed"
}

# Install Kyverno
install_kyverno() {
    log_info "Installing Kyverno..."
    
    # Add Kyverno Helm repository
    helm repo add kyverno https://kyverno.github.io/kyverno/
    helm repo update
    
    # Install Kyverno
    helm upgrade --install kyverno kyverno/kyverno \
        --namespace "$CLUSTER_NAMESPACE" \
        --set replicaCount=2 \
        --wait
    
    log_success "Kyverno installed"
}

# Apply Kyverno policies
apply_kyverno_policies() {
    log_info "Applying Kyverno policies..."
    
    # Apply all Kyverno policies
    kubectl apply -f medinovai-infrastructure-standards/policies/kyverno/
    
    log_success "Kyverno policies applied"
}

# Install monitoring stack
install_monitoring_stack() {
    log_info "Installing monitoring stack..."
    
    # Add Prometheus Community Helm repository
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    
    # Install kube-prometheus-stack
    helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
        --namespace "$CLUSTER_NAMESPACE" \
        --values medinovai-infrastructure-standards/platform/charts/kube-prometheus-stack/values.yaml \
        --wait
    
    log_success "Monitoring stack installed"
}

# Install logging stack
install_logging_stack() {
    log_info "Installing logging stack..."
    
    # Add Grafana Helm repository
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update
    
    # Install Loki
    helm upgrade --install loki grafana/loki \
        --namespace "$CLUSTER_NAMESPACE" \
        --values medinovai-infrastructure-standards/platform/charts/loki/values.yaml \
        --wait
    
    log_success "Logging stack installed"
}

# Install tracing stack
install_tracing_stack() {
    log_info "Installing tracing stack..."
    
    # Add Grafana Helm repository (already added)
    
    # Install Tempo
    helm upgrade --install tempo grafana/tempo \
        --namespace "$CLUSTER_NAMESPACE" \
        --values medinovai-infrastructure-standards/platform/charts/tempo/values.yaml \
        --wait
    
    # Install OpenTelemetry Operator
    helm upgrade --install opentelemetry-operator medinovai-infrastructure-standards/platform/charts/opentelemetry-operator/ \
        --namespace "$CLUSTER_NAMESPACE" \
        --wait
    
    log_success "Tracing stack installed"
}

# Configure Pod Security Standards
configure_pod_security() {
    log_info "Configuring Pod Security Standards..."
    
    # Label namespaces with Pod Security Standards
    kubectl label namespace default pod-security.kubernetes.io/enforce=restricted --overwrite
    kubectl label namespace default pod-security.kubernetes.io/audit=restricted --overwrite
    kubectl label namespace default pod-security.kubernetes.io/warn=restricted --overwrite
    
    kubectl label namespace "$CLUSTER_NAMESPACE" pod-security.kubernetes.io/enforce=restricted --overwrite
    kubectl label namespace "$CLUSTER_NAMESPACE" pod-security.kubernetes.io/audit=restricted --overwrite
    kubectl label namespace "$CLUSTER_NAMESPACE" pod-security.kubernetes.io/warn=restricted --overwrite
    
    log_success "Pod Security Standards configured"
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."
    
    # Check if all pods are running
    local failed_pods=0
    
    for component in argocd external-secrets cert-manager external-dns envoy-gateway kyverno kube-prometheus-stack loki tempo; do
        if kubectl get pods -n "$CLUSTER_NAMESPACE" -l "app.kubernetes.io/name=$component" --field-selector=status.phase!=Running | grep -q "$component"; then
            log_warning "Some $component pods are not running"
            ((failed_pods++))
        else
            log_success "$component is running"
        fi
    done
    
    if [[ $failed_pods -gt 0 ]]; then
        log_warning "$failed_pods components have issues"
        return 1
    fi
    
    log_success "All components are running successfully"
}

# Generate setup report
generate_setup_report() {
    log_info "Generating setup report..."
    
    local report_file="cluster_setup_report.md"
    
    cat > "$report_file" << EOF
# MedinovAI Cluster Setup Report

**Date:** $(date)
**Cluster:** $(kubectl config current-context)
**Namespace:** $CLUSTER_NAMESPACE

## Installed Components

### Core Platform
- ✅ Argo CD - GitOps deployment
- ✅ Argo CD ApplicationSet - Multi-app management
- ✅ External Secrets Operator - Secret management
- ✅ cert-manager - TLS certificate management
- ✅ External DNS - DNS record management
- ✅ Envoy Gateway - Ingress controller

### Security & Policies
- ✅ Kyverno - Policy enforcement
- ✅ Pod Security Standards - Pod-level security

### Observability
- ✅ Prometheus & Grafana - Monitoring
- ✅ Loki - Log aggregation
- ✅ Tempo - Distributed tracing
- ✅ OpenTelemetry Operator - Telemetry collection

## Verification Status

EOF

    # Add component status
    for component in argocd external-secrets cert-manager external-dns envoy-gateway kyverno kube-prometheus-stack loki tempo; do
        local status=$(kubectl get pods -n "$CLUSTER_NAMESPACE" -l "app.kubernetes.io/name=$component" --no-headers | wc -l)
        echo "- $component: $status pods" >> "$report_file"
    done
    
    cat >> "$report_file" << EOF

## Next Steps

1. Configure External Secrets with cloud provider
2. Set up DNS provider credentials for External DNS
3. Configure cert-manager with Let's Encrypt
4. Apply application-specific configurations
5. Begin Bootstrap phase of BMAD implementation

## Access Information

- **Argo CD UI:** https://argocd.medinovai.local
- **Grafana:** https://grafana.medinovai.local
- **Prometheus:** https://prometheus.medinovai.local

## Troubleshooting

If any components are not running, check:
1. Resource availability
2. Network connectivity
3. Storage requirements
4. Configuration values

Use \`kubectl get pods -n $CLUSTER_NAMESPACE\` to check pod status.
EOF

    log_success "Setup report generated: $report_file"
}

# Main execution
main() {
    echo "🏗️  MedinovAI Cluster Components Setup"
    echo "======================================"
    echo "Cluster: $(kubectl config current-context)"
    echo "Namespace: $CLUSTER_NAMESPACE"
    echo "Date: $(date)"
    echo ""
    
    # Initialize log file
    echo "MedinovAI Cluster Setup Log" > "$LOG_FILE"
    echo "Date: $(date)" >> "$LOG_FILE"
    echo "========================================" >> "$LOG_FILE"
    
    # Check prerequisites
    check_prerequisites
    
    # Create namespace
    create_namespace
    
    # Install components
    install_argocd
    install_argocd_applicationset
    install_external_secrets
    install_cert_manager
    install_external_dns
    install_envoy_gateway
    install_kyverno
    apply_kyverno_policies
    install_monitoring_stack
    install_logging_stack
    install_tracing_stack
    
    # Configure security
    configure_pod_security
    
    # Verify installation
    if verify_installation; then
        log_success "🎉 Cluster setup complete!"
        generate_setup_report
    else
        log_error "❌ Cluster setup completed with issues"
        log_warning "Check the log file for details: $LOG_FILE"
        exit 1
    fi
}

# Run main function
main "$@"








