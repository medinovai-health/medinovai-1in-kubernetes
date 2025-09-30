#!/bin/bash
# Enhanced MedinovAI Infrastructure Deployment

set -e

echo "🚀 Enhanced MedinovAI Infrastructure Deployment"

# Apply corrected Istio configuration
echo "🔧 Applying Istio configuration..."
kubectl apply -f k8s/istio/medinovai-gateway-corrected.yaml

# Deploy placeholder services
echo "📦 Deploying services..."
kubectl apply -f /Users/dev1/github/medinovai-clinical-services/k8s/deployment.yaml
kubectl apply -f /Users/dev1/github/medinovai-data-services/k8s/deployment.yaml
kubectl apply -f /Users/dev1/github/medinovai-patient-services/k8s/deployment.yaml

# Deploy monorepo modules
echo "🏢 Deploying monorepo modules..."
kubectl apply -f k8s/monorepo/researchsuite-cds-deployment.yaml
kubectl apply -f k8s/monorepo/researchsuite-istio-config.yaml

# Check status
echo "📊 Deployment status:"
kubectl get pods -n medinovai

echo "✅ Deployment completed!"


