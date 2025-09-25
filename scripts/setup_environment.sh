#!/bin/bash

# MedinovAI Environment Setup Script
# This script sets up the complete environment for MedinovAI deployment

set -euo pipefail

# Configuration
MEDINOVAI_NAMESPACE="medinovai"
ISTIO_VERSION="1.20.0"
OLLAMA_MODELS=("llama3.1:8b" "llama3.1:70b" "codellama:7b" "mistral:7b" "gemma:7b")

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

log_setup() {
    echo -e "${PURPLE}🔧 $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    log_success "Docker is available"
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed"
        exit 1
    fi
    log_success "kubectl is available"
    
    # Check OrbStack
    if ! command -v orb &> /dev/null; then
        log_error "OrbStack is not installed"
        exit 1
    fi
    log_success "OrbStack is available"
    
    # Check Ollama
    if ! command -v ollama &> /dev/null; then
        log_error "Ollama is not installed"
        exit 1
    fi
    log_success "Ollama is available"
    
    # Check Helm
    if ! command -v helm &> /dev/null; then
        log_warning "Helm is not installed, installing..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi
    log_success "Helm is available"
}

# Setup Kubernetes cluster
setup_kubernetes() {
    log_setup "Setting up Kubernetes cluster..."
    
    # Start OrbStack
    log_info "Starting OrbStack..."
    orb start
    
    # Wait for cluster to be ready
    log_info "Waiting for Kubernetes cluster to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
    
    # Create MedinovAI namespace
    log_info "Creating MedinovAI namespace..."
    kubectl create namespace $MEDINOVAI_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    
    log_success "Kubernetes cluster setup completed"
}

# Install Istio
install_istio() {
    log_setup "Installing Istio service mesh..."
    
    # Download Istio
    log_info "Downloading Istio $ISTIO_VERSION..."
    curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_VERSION sh -
    cd istio-$ISTIO_VERSION
    
    # Install Istio
    log_info "Installing Istio..."
    bin/istioctl install --set values.defaultRevision=default -y
    
    # Enable sidecar injection for MedinovAI namespace
    log_info "Enabling sidecar injection for MedinovAI namespace..."
    kubectl label namespace $MEDINOVAI_NAMESPACE istio-injection=enabled
    
    # Cleanup
    cd ..
    rm -rf istio-$ISTIO_VERSION
    
    log_success "Istio installation completed"
}

# Setup Ollama models
setup_ollama() {
    log_setup "Setting up Ollama AI models..."
    
    # Start Ollama service
    log_info "Starting Ollama service..."
    ollama serve &
    OLLAMA_PID=$!
    
    # Wait for Ollama to be ready
    sleep 10
    
    # Pull models
    for model in "${OLLAMA_MODELS[@]}"; do
        log_info "Pulling model: $model"
        ollama pull "$model"
    done
    
    # Create Ollama service in Kubernetes
    log_info "Creating Ollama service in Kubernetes..."
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: ollama-service
  namespace: $MEDINOVAI_NAMESPACE
spec:
  selector:
    app: ollama
  ports:
  - name: http
    port: 11434
    targetPort: 11434
  type: ClusterIP
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ollama
  namespace: $MEDINOVAI_NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ollama
  template:
    metadata:
      labels:
        app: ollama
    spec:
      containers:
      - name: ollama
        image: ollama/ollama:latest
        ports:
        - containerPort: 11434
        env:
        - name: OLLAMA_HOST
          value: "0.0.0.0"
        resources:
          requests:
            memory: "8Gi"
            cpu: "2"
          limits:
            memory: "64Gi"
            cpu: "8"
        volumeMounts:
        - name: ollama-data
          mountPath: /root/.ollama
      volumes:
      - name: ollama-data
        hostPath:
          path: /tmp/ollama-data
          type: DirectoryOrCreate
EOF
    
    log_success "Ollama setup completed"
}

# Setup monitoring stack
setup_monitoring() {
    log_setup "Setting up monitoring stack..."
    
    # Add Helm repositories
    log_info "Adding Helm repositories..."
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo add loki https://grafana.github.io/helm-charts
    helm repo update
    
    # Install Prometheus
    log_info "Installing Prometheus..."
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
        --namespace $MEDINOVAI_NAMESPACE \
        --set grafana.adminPassword=admin \
        --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=10Gi \
        --set prometheus.prometheusSpec.retention=30d
    
    # Install Loki
    log_info "Installing Loki..."
    helm upgrade --install loki loki/loki-stack \
        --namespace $MEDINOVAI_NAMESPACE \
        --set loki.persistence.enabled=true \
        --set loki.persistence.size=50Gi
    
    # Install Tempo
    log_info "Installing Tempo..."
    helm upgrade --install tempo grafana/tempo \
        --namespace $MEDINOVAI_NAMESPACE \
        --set tempo.persistence.enabled=true \
        --set tempo.persistence.size=20Gi
    
    log_success "Monitoring stack setup completed"
}

# Setup security policies
setup_security() {
    log_setup "Setting up security policies..."
    
    # Install Kyverno
    log_info "Installing Kyverno..."
    helm repo add kyverno https://kyverno.github.io/kyverno/
    helm repo update
    helm upgrade --install kyverno kyverno/kyverno \
        --namespace kyverno \
        --create-namespace
    
    # Apply security policies
    log_info "Applying security policies..."
    kubectl apply -f - <<EOF
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: medinovai-security-policy
spec:
  validationFailureAction: enforce
  background: true
  rules:
  - name: require-security-context
    match:
      any:
      - resources:
          kinds:
          - Pod
    validate:
      message: "Security context is required"
      pattern:
        spec:
          securityContext:
            runAsNonRoot: true
            runAsUser: 1000
            fsGroup: 2000
            seccompProfile:
              type: RuntimeDefault
EOF
    
    # Apply network policies
    log_info "Applying network policies..."
    kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: medinovai-network-policy
  namespace: $MEDINOVAI_NAMESPACE
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: $MEDINOVAI_NAMESPACE
    - namespaceSelector:
        matchLabels:
          name: istio-system
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: $MEDINOVAI_NAMESPACE
    - namespaceSelector:
        matchLabels:
          name: kube-system
  - to: []
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
EOF
    
    log_success "Security policies setup completed"
}

# Setup Istio gateway
setup_istio_gateway() {
    log_setup "Setting up Istio gateway..."
    
    # Install Istio gateway
    log_info "Installing Istio gateway..."
    kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: medinovai-gateway
  namespace: $MEDINOVAI_NAMESPACE
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*.medinovai.local"
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: medinovai-tls
    hosts:
    - "*.medinovai.local"
EOF
    
    log_success "Istio gateway setup completed"
}

# Setup port allocation
setup_port_allocation() {
    log_setup "Setting up port allocation..."
    
    # Create port allocation configmap
    log_info "Creating port allocation configuration..."
    kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: medinovai-port-allocation
  namespace: $MEDINOVAI_NAMESPACE
data:
  port-ranges.yaml: |
    api-services: 8000-8099
    frontend-services: 8100-8199
    database-services: 8200-8299
    analytics-services: 8300-8399
    ai-ml-services: 8400-8499
    integration-services: 8500-8599
    security-services: 8600-8699
    mobile-services: 8700-8799
    infrastructure-services: 8800-8899
    reserved: 8900-8999
  per-repository-ports.yaml: |
    primary-service: base + 0
    health-check: base + 1
    metrics: base + 2
    debug: base + 3
    admin: base + 4
EOF
    
    log_success "Port allocation setup completed"
}

# Main execution
main() {
    echo "🔧 MedinovAI Environment Setup"
    echo "=============================="
    echo "Namespace: $MEDINOVAI_NAMESPACE"
    echo "Istio Version: $ISTIO_VERSION"
    echo "Ollama Models: ${OLLAMA_MODELS[*]}"
    echo "Date: $(date)"
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Setup Kubernetes
    setup_kubernetes
    
    # Install Istio
    install_istio
    
    # Setup Ollama
    setup_ollama
    
    # Setup monitoring
    setup_monitoring
    
    # Setup security
    setup_security
    
    # Setup Istio gateway
    setup_istio_gateway
    
    # Setup port allocation
    setup_port_allocation
    
    echo ""
    log_success "🎉 MedinovAI environment setup completed successfully!"
    echo ""
    echo "📊 Environment Summary:"
    echo "  ☸️  Kubernetes: Ready"
    echo "  🌐 Istio: Installed and configured"
    echo "  🤖 Ollama: Models loaded and service running"
    echo "  📈 Monitoring: Prometheus, Grafana, Loki, Tempo"
    echo "  🛡️  Security: Kyverno policies and network policies"
    echo "  🔧 Port Allocation: Configured (8000-8999)"
    echo ""
    echo "🚀 Next Steps:"
    echo "  1. Deploy infrastructure: ./scripts/deploy_infrastructure.sh"
    echo "  2. Deploy repositories: ./scripts/deploy_repositories.sh"
    echo "  3. Validate deployment: ./scripts/validate_deployment.sh"
}

# Run main function
main "$@"








