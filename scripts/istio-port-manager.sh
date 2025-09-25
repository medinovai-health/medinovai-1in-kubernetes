#!/bin/bash

# MedinovAI Istio Port Management Script
# This script helps manage centralized port allocation and Istio configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Function to check if Istio is installed
check_istio() {
    print_header "Checking Istio Installation"
    
    if ! command -v istioctl &> /dev/null; then
        print_error "istioctl not found. Please ensure Istio is installed."
        exit 1
    fi
    
    if ! kubectl get pods -n istio-system | grep -q "Running"; then
        print_error "Istio pods are not running. Please check the installation."
        exit 1
    fi
    
    print_status "Istio is installed and running"
    istioctl version
}

# Function to show port registry
show_port_registry() {
    print_header "MedinovAI Port Registry"
    
    echo "Retrieving port configuration..."
    kubectl get configmap medinovai-port-registry -n istio-system -o yaml | grep -A 50 "port-mapping.yaml:" | sed 's/^[ ]*//' | tail -n +2
}

# Function to show service endpoints
show_service_endpoints() {
    print_header "Service Endpoints"
    
    echo "Retrieving service endpoint configuration..."
    kubectl get configmap medinovai-port-registry -n istio-system -o yaml | grep -A 100 "service-endpoints.yaml:" | sed 's/^[ ]*//' | tail -n +2
}

# Function to show Istio gateways
show_gateways() {
    print_header "Istio Gateways"
    
    kubectl get gateway -A
    echo ""
    kubectl get virtualservice -A
}

# Function to show ingress gateway status
show_ingress_status() {
    print_header "Istio Ingress Gateway Status"
    
    kubectl get svc -n istio-system istio-ingressgateway
    echo ""
    kubectl get pods -n istio-system -l app=istio-ingressgateway
}

# Function to test connectivity
test_connectivity() {
    print_header "Testing Connectivity"
    
    # Get the ingress gateway external IP
    EXTERNAL_IP=$(kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    
    if [ -z "$EXTERNAL_IP" ]; then
        print_warning "No external IP found for ingress gateway"
        EXTERNAL_IP=$(kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.spec.clusterIP}')
        print_status "Using cluster IP: $EXTERNAL_IP"
    else
        print_status "External IP: $EXTERNAL_IP"
    fi
    
    # Test HTTP connectivity
    print_status "Testing HTTP connectivity on port 80..."
    if curl -s --connect-timeout 5 http://$EXTERNAL_IP:80 > /dev/null; then
        print_status "✓ HTTP connectivity successful"
    else
        print_warning "✗ HTTP connectivity failed"
    fi
    
    # Test HTTPS connectivity
    print_status "Testing HTTPS connectivity on port 443..."
    if curl -s --connect-timeout 5 -k https://$EXTERNAL_IP:443 > /dev/null; then
        print_status "✓ HTTPS connectivity successful"
    else
        print_warning "✗ HTTPS connectivity failed"
    fi
}

# Function to add a new service to port registry
add_service() {
    local service_name=$1
    local namespace=$2
    local port=$3
    local protocol=${4:-http}
    local path=${5:-/}
    
    if [ -z "$service_name" ] || [ -z "$namespace" ] || [ -z "$port" ]; then
        print_error "Usage: add_service <service_name> <namespace> <port> [protocol] [path]"
        exit 1
    fi
    
    print_header "Adding Service to Port Registry"
    print_status "Service: $service_name"
    print_status "Namespace: $namespace"
    print_status "Port: $port"
    print_status "Protocol: $protocol"
    print_status "Path: $path"
    
    # This would require updating the ConfigMap
    print_warning "Manual update required for ConfigMap. Please edit istio-port-management.yaml and reapply."
}

# Function to show help
show_help() {
    echo "MedinovAI Istio Port Manager"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  check           Check Istio installation status"
    echo "  ports           Show port registry"
    echo "  endpoints       Show service endpoints"
    echo "  gateways        Show Istio gateways and virtual services"
    echo "  ingress         Show ingress gateway status"
    echo "  test            Test connectivity to ingress gateway"
    echo "  add <args>      Add a new service (requires manual ConfigMap update)"
    echo "  help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 check"
    echo "  $0 ports"
    echo "  $0 test"
}

# Main script logic
case "${1:-help}" in
    check)
        check_istio
        ;;
    ports)
        show_port_registry
        ;;
    endpoints)
        show_service_endpoints
        ;;
    gateways)
        show_gateways
        ;;
    ingress)
        show_ingress_status
        ;;
    test)
        test_connectivity
        ;;
    add)
        shift
        add_service "$@"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac







