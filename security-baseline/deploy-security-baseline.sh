#!/bin/bash

# Security Baseline Deployment Script
# Deploys all security policies and configurations

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

log_deploy "Deploying Security Baseline to Kubernetes Cluster"

# Check if kubectl is available
if ! command -v kubectl >/dev/null 2>&1; then
    log_error "kubectl is not available. Please install kubectl first."
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info >/dev/null 2>&1; then
    log_error "Kubernetes cluster is not accessible. Please check your cluster connection."
    exit 1
fi

# Deploy security policies
log_info "Deploying Pod Security Standards..."
kubectl apply -f pod-security-standards.yaml

log_info "Deploying Network Policies..."
kubectl apply -f network-policies.yaml

log_info "Deploying RBAC Configuration..."
kubectl apply -f rbac-config.yaml

log_info "Deploying Secrets..."
kubectl apply -f secrets.yaml

log_info "Deploying External Secrets Configuration..."
kubectl apply -f external-secrets.yaml

log_info "Deploying Security Monitoring..."
kubectl apply -f falco-config.yaml

log_info "Deploying Compliance Configuration..."
kubectl apply -f hipaa-compliance.yaml
kubectl apply -f gdpr-compliance.yaml

log_info "Deploying Security Testing..."
kubectl apply -f security-scanning.yaml

log_success "🎉 Security baseline deployed successfully!"

echo ""
echo "📊 Security Baseline Summary:"
echo "  🛡️  Pod Security Standards: Deployed"
echo "  🌐 Network Policies: Deployed"
echo "  🔐 RBAC Configuration: Deployed"
echo "  🔑 Secrets Management: Deployed"
echo "  📊 Security Monitoring: Deployed"
echo "  📋 Compliance Configuration: Deployed"
echo "  🔍 Security Testing: Deployed"
echo ""
echo "🔧 Next Steps:"
echo "  1. Verify all security policies are active"
echo "  2. Test network policies"
echo "  3. Validate RBAC permissions"
echo "  4. Configure external secrets management"
echo "  5. Set up security monitoring alerts"
echo "  6. Run security scans"
echo ""
echo "📖 Review security documentation: SECURITY_BASELINE.md"
