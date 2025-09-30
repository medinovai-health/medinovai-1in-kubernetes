#!/bin/bash

# Health Check for All MedinovAI Services
# This script performs comprehensive health checks across all services

set -e

echo "🏥 Performing health checks on all MedinovAI services..."
echo "Timestamp: $(date)"
echo "=========================================="

# Configuration
NAMESPACE="medinovai"
BASE_DIR="/Users/dev1/github"

# Function to check service health
check_service_health() {
    local service_name=$1
    local service_url=$2
    
    echo "🔍 Checking $service_name..."
    
    if curl -s -f "$service_url/health" > /dev/null; then
        echo "   ✅ $service_name is healthy"
        return 0
    else
        echo "   ❌ $service_name is unhealthy"
        return 1
    fi
}

# Function to check Kubernetes resources
check_k8s_resources() {
    echo "🔍 Checking Kubernetes resources..."
    
    # Check pods
    echo "   📋 Pod status:"
    kubectl get pods -n $NAMESPACE --no-headers | while read -r line; do
        pod_name=$(echo $line | awk '{print $1}')
        status=$(echo $line | awk '{print $3}')
        if [ "$status" = "Running" ]; then
            echo "     ✅ $pod_name: $status"
        else
            echo "     ❌ $pod_name: $status"
        fi
    done
    
    # Check services
    echo "   📋 Service status:"
    kubectl get services -n $NAMESPACE --no-headers | while read -r line; do
        service_name=$(echo $line | awk '{print $1}')
        endpoints=$(echo $line | awk '{print $2}')
        echo "     📡 $service_name: $endpoints"
    done
}

# Function to check service discovery
check_service_discovery() {
    echo "🔍 Checking service discovery..."
    
    # Check if service discovery is working
    if kubectl get configmap medinovai-service-discovery -n $NAMESPACE > /dev/null 2>&1; then
        echo "   ✅ Service discovery configuration found"
    else
        echo "   ❌ Service discovery configuration missing"
    fi
    
    # Check if orchestration policies are applied
    if kubectl get configmap medinovai-orchestration-policies -n $NAMESPACE > /dev/null 2>&1; then
        echo "   ✅ Orchestration policies applied"
    else
        echo "   ❌ Orchestration policies missing"
    fi
}

# Function to check Istio service mesh
check_istio_mesh() {
    echo "🔍 Checking Istio service mesh..."
    
    # Check virtual services
    if kubectl get virtualservice medinovai-services -n $NAMESPACE > /dev/null 2>&1; then
        echo "   ✅ Virtual service configured"
    else
        echo "   ❌ Virtual service missing"
    fi
    
    # Check destination rules
    if kubectl get destinationrule medinovai-services -n $NAMESPACE > /dev/null 2>&1; then
        echo "   ✅ Destination rules configured"
    else
        echo "   ❌ Destination rules missing"
    fi
}

# Function to check monitoring
check_monitoring() {
    echo "🔍 Checking monitoring setup..."
    
    # Check Prometheus
    if kubectl get pods -n $NAMESPACE | grep prometheus > /dev/null; then
        echo "   ✅ Prometheus is running"
    else
        echo "   ❌ Prometheus is not running"
    fi
    
    # Check Grafana
    if kubectl get pods -n $NAMESPACE | grep grafana > /dev/null; then
        echo "   ✅ Grafana is running"
    else
        echo "   ❌ Grafana is not running"
    fi
}

# Main health check execution
echo "🏥 Starting comprehensive health check..."

check_k8s_resources
check_service_discovery
check_istio_mesh
check_monitoring

echo "✅ Health check completed!"
echo "📊 Summary:"
echo "   - Kubernetes resources: Checked"
echo "   - Service discovery: Checked"
echo "   - Istio service mesh: Checked"
echo "   - Monitoring: Checked"

echo "🎉 All health checks completed!"
