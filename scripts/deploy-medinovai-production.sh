#!/bin/bash

# 🚀 MedinovAI Production Deployment Script
# Deploys only MedinovAI named repositories and referenced repositories

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PRODUCTION_REPOS_FILE="$PROJECT_ROOT/medinovai-production-repos.txt"
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

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites for MedinovAI production deployment..."
    
    # Check if kubectl is installed and configured
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    # Check if kubectl can connect to cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_error "kubectl cannot connect to cluster. Please configure kubectl."
        exit 1
    fi
    
    # Check if MedinovAI namespace exists
    if ! kubectl get namespace medinovai &> /dev/null; then
        print_warning "MedinovAI namespace not found. Creating it..."
        kubectl create namespace medinovai
    fi
    
    # Check if Istio is installed
    if ! kubectl get pods -n istio-system &> /dev/null; then
        print_warning "Istio not found in istio-system namespace. Please install Istio first."
    fi
    
    print_success "Prerequisites check completed"
}

# Function to read production repositories
read_production_repos() {
    local repos=()
    
    if [[ ! -f "$PRODUCTION_REPOS_FILE" ]]; then
        print_error "Production repositories file not found: $PRODUCTION_REPOS_FILE"
        exit 1
    fi
    
    # Read repositories from file, skipping comments and empty lines
    while IFS= read -r line; do
        # Skip comments and empty lines
        if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "${line// }" ]]; then
            continue
        fi
        
        # Remove any leading/trailing whitespace
        repo=$(echo "$line" | xargs)
        
        # Check if repository exists locally
        if [[ -d "/Users/dev1/github/$repo" ]]; then
            repos+=("$repo")
        else
            print_warning "Repository $repo not found locally, skipping..."
        fi
    done < "$PRODUCTION_REPOS_FILE"
    
    echo "${repos[@]}"
}

# Function to deploy repository
deploy_repository() {
    local repo="$1"
    local repo_path="/Users/dev1/github/$repo"
    
    print_status "Deploying $repo to production infrastructure..."
    
    if [[ ! -d "$repo_path" ]]; then
        print_error "Repository $repo not found at $repo_path"
        return 1
    fi
    
    cd "$repo_path"
    
    # Check if deployment directory exists
    if [[ ! -d "deployment" ]]; then
        print_warning "No deployment directory found for $repo. Skipping..."
        return 0
    fi
    
    # Check if deployment script exists
    if [[ -f "deployment/deploy-to-infrastructure.sh" ]]; then
        print_status "Running deployment script for $repo..."
        if ./deployment/deploy-to-infrastructure.sh "$repo"; then
            print_success "✅ $repo deployed successfully"
        else
            print_error "❌ Failed to deploy $repo"
            return 1
        fi
    else
        print_warning "No deployment script found for $repo. Checking for Kubernetes manifests..."
        
        # Check for Kubernetes manifests
        if [[ -d "deployment/k8s" ]]; then
            print_status "Applying Kubernetes manifests for $repo..."
            if kubectl apply -f deployment/k8s/ -n medinovai; then
                print_success "✅ $repo Kubernetes manifests applied successfully"
            else
                print_error "❌ Failed to apply Kubernetes manifests for $repo"
                return 1
            fi
        else
            print_warning "No Kubernetes manifests found for $repo. Skipping..."
        fi
    fi
    
    return 0
}

# Function to validate deployment
validate_deployment() {
    local repo="$1"
    
    print_status "Validating deployment for $repo..."
    
    # Check if pods are running
    if kubectl get pods -n medinovai -l app="$repo" &> /dev/null; then
        local pod_count=$(kubectl get pods -n medinovai -l app="$repo" --no-headers | wc -l)
        local running_count=$(kubectl get pods -n medinovai -l app="$repo" --no-headers | grep -c "Running" || true)
        
        if [[ $running_count -eq $pod_count ]] && [[ $pod_count -gt 0 ]]; then
            print_success "✅ $repo pods are running ($running_count/$pod_count)"
        else
            print_warning "⚠️  $repo pods not all running ($running_count/$pod_count)"
        fi
    else
        print_warning "⚠️  No pods found for $repo"
    fi
    
    # Check if service exists
    if kubectl get service "$repo" -n medinovai &> /dev/null; then
        print_success "✅ $repo service exists"
    else
        print_warning "⚠️  No service found for $repo"
    fi
}

# Function to process batch
process_batch() {
    local batch_num="$1"
    shift
    local repos=("$@")
    
    print_status "Processing batch $batch_num (${#repos[@]} repositories)..."
    
    local success_count=0
    local failure_count=0
    
    for repo in "${repos[@]}"; do
        if deploy_repository "$repo"; then
            success_count=$((success_count + 1))
            # Validate deployment
            validate_deployment "$repo"
        else
            failure_count=$((failure_count + 1))
        fi
    done
    
    print_status "Batch $batch_num completed: $success_count successful, $failure_count failed"
    
    if [[ $failure_count -gt 0 ]]; then
        return 1
    fi
    
    return 0
}

# Function to show deployment status
show_deployment_status() {
    print_status "MedinovAI Production Deployment Status"
    echo "============================================="
    echo ""
    
    # Show namespace status
    print_status "Namespace Status:"
    kubectl get namespace medinovai -o wide 2>/dev/null || print_warning "MedinovAI namespace not found"
    echo ""
    
    # Show all pods in medinovai namespace
    print_status "Pod Status:"
    kubectl get pods -n medinovai -o wide 2>/dev/null || print_warning "No pods found in medinovai namespace"
    echo ""
    
    # Show all services in medinovai namespace
    print_status "Service Status:"
    kubectl get services -n medinovai -o wide 2>/dev/null || print_warning "No services found in medinovai namespace"
    echo ""
    
    # Show ingress status
    print_status "Ingress Status:"
    kubectl get ingress -n medinovai -o wide 2>/dev/null || print_warning "No ingress found in medinovai namespace"
    echo ""
}

# Function to show help
show_help() {
    echo "🚀 MedinovAI Production Deployment Script"
    echo ""
    echo "Usage: $0 [--status] [--help]"
    echo ""
    echo "Arguments:"
    echo "  --status        Show current deployment status"
    echo "  --help          Show this help message"
    echo ""
    echo "This script will:"
    echo "  1. Check prerequisites (kubectl, cluster, namespace)"
    echo "  2. Read MedinovAI production repositories list"
    echo "  3. Deploy each repository to production infrastructure"
    echo "  4. Validate deployments"
    echo "  5. Show deployment status"
    echo ""
    echo "Production repositories are defined in: $PRODUCTION_REPOS_FILE"
    echo ""
}

# Main execution
main() {
    echo "🚀 MedinovAI Production Deployment"
    echo "=================================="
    echo ""
    
    # Handle help
    if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
        show_help
        exit 0
    fi
    
    # Handle status
    if [[ "${1:-}" == "--status" ]]; then
        show_deployment_status
        exit 0
    fi
    
    check_prerequisites
    
    # Read production repositories
    print_status "Reading MedinovAI production repositories..."
    repos=($(read_production_repos))
    
    if [[ ${#repos[@]} -eq 0 ]]; then
        print_error "No production repositories found"
        exit 1
    fi
    
    print_status "Found ${#repos[@]} MedinovAI production repositories"
    echo ""
    
    local total_success=0
    local total_failure=0
    local batch_num=1
    
    # Process repositories in batches
    for ((i=0; i<${#repos[@]}; i+=BATCH_SIZE)); do
        local batch=()
        for ((j=i; j<i+BATCH_SIZE && j<${#repos[@]}; j++)); do
            batch+=("${repos[j]}")
        done
        
        if process_batch "$batch_num" "${batch[@]}"; then
            total_success=$((total_success + ${#batch[@]}))
        else
            total_failure=$((total_failure + ${#batch[@]}))
        fi
        
        batch_num=$((batch_num + 1))
        
        # Delay between batches (except for the last batch)
        if [[ $i -lt $((${#repos[@]} - BATCH_SIZE)) ]]; then
            print_status "Waiting $DELAY_BETWEEN_BATCHES seconds before next batch..."
            sleep "$DELAY_BETWEEN_BATCHES"
        fi
    done
    
    echo ""
    print_status "MedinovAI production deployment completed!"
    print_success "✅ $total_success repositories deployed successfully"
    if [[ $total_failure -gt 0 ]]; then
        print_error "❌ $total_failure repositories failed to deploy"
    fi
    
    echo ""
    show_deployment_status
    
    echo ""
    print_status "Next steps:"
    echo "  1. Monitor deployment status: $0 --status"
    echo "  2. Check logs: kubectl logs -n medinovai -l app=<service-name>"
    echo "  3. Test services: kubectl port-forward -n medinovai svc/<service-name> <port>"
    echo "  4. Access Grafana: kubectl port-forward -n medinovai svc/grafana 3000:3000"
    echo ""
}

# Run main function
main "$@"
