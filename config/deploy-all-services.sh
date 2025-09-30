#!/bin/bash

# Deploy All MedinovAI Services
# This script deploys all services across the distributed architecture

set -e

echo "🚀 Deploying all MedinovAI services..."
echo "Timestamp: $(date)"
echo "=========================================="

# Configuration
NAMESPACE="medinovai"
BASE_DIR="/Users/dev1/github"

# Create namespace if it doesn't exist
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Apply configurations
echo "📋 Applying service discovery configuration..."
kubectl apply -f service_discovery.yaml

echo "📋 Applying orchestration policies..."
kubectl apply -f orchestration_policies.yaml

echo "📋 Applying Istio service mesh configuration..."
kubectl apply -f istio-service-mesh.yaml

echo "📋 Applying monitoring configuration..."
kubectl apply -f monitoring-config.yaml

# Deploy services from each repository
repositories=(
    "medinovai-infrastructure"
    "medinovai-AI-standards"
    "medinovai-clinical-services"
    "medinovai-security-services"
    "medinovai-data-services"
    "medinovai-integration-services"
    "medinovai-patient-services"
    "medinovai-billing"
    "medinovai-compliance-services"
    "medinovai-ui-components"
    "medinovai-healthcare-utilities"
    "medinovai-business-services"
    "medinovai-research-services"
)

for repo in "${repositories[@]}"; do
    echo "🚀 Deploying services from $repo..."
    repo_path="$BASE_DIR/$repo"
    
    if [ -d "$repo_path" ]; then
        # Find and apply Kubernetes configurations
        find "$repo_path" -name "*.yaml" -o -name "*.yml" | while read -r config_file; do
            if grep -q "kind:" "$config_file"; then
                echo "   📋 Applying $config_file"
                kubectl apply -f "$config_file" -n $NAMESPACE
            fi
        done
    else
        echo "   ⚠️  Repository $repo not found at $repo_path"
    fi
done

echo "✅ All services deployed successfully!"
echo "🔍 Checking deployment status..."

kubectl get pods -n $NAMESPACE
kubectl get services -n $NAMESPACE
kubectl get virtualservices -n $NAMESPACE

echo "🎉 Deployment completed!"
