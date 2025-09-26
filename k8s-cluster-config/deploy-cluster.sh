#!/bin/bash

# Kubernetes Cluster Deployment Script
# Deploys the k3d cluster with all configurations

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_deploy() {
    echo -e "${PURPLE}🚀 $1${NC}"
}

log_deploy "Deploying Kubernetes Cluster"

# Check if cluster already exists
if k3d cluster list | grep -q "medinovai-cluster"; then
    log_warning "Cluster medinovai-cluster already exists. Deleting..."
    k3d cluster delete medinovai-cluster
fi

# Create the cluster
log_info "Creating k3d cluster..."
k3d cluster create --config k3d-config.yaml

# Wait for cluster to be ready
log_info "Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Deploy storage configuration
log_info "Deploying storage configuration..."
kubectl apply -f storage-config.yaml

# Deploy networking configuration
log_info "Deploying networking configuration..."
kubectl apply -f networking-config.yaml

# Deploy metrics server
log_info "Deploying metrics server..."
kubectl apply -f metrics-server.yaml

# Wait for components to be ready
log_info "Waiting for components to be ready..."
kubectl wait --for=condition=Ready pods --all -n kube-system --timeout=300s

# Verify cluster status
log_info "Verifying cluster status..."
kubectl get nodes
kubectl get pods -n kube-system

log_success "🎉 Kubernetes cluster deployed successfully!"

echo ""
echo "📊 Cluster Summary:"
echo "  🏗️  Cluster Name: medinovai-cluster"
echo "  🖥️  Nodes: 2 servers + 3 agents"
echo "  🌐 Load Balancer: Ports 80, 443, 8080, 30000-30100"
echo "  💾 Storage: Local path provisioner"
echo "  🌐 Networking: CoreDNS"
echo "  📊 Metrics: Metrics server"
echo "  🔍 Audit: Audit logging enabled"
echo ""
echo "🔧 Next Steps:"
echo "  1. Verify cluster connectivity: kubectl cluster-info"
echo "  2. Deploy Istio service mesh"
echo "  3. Deploy monitoring stack"
echo "  4. Deploy security baseline"
