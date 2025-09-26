#!/bin/bash

# Kubernetes Cluster Management Script
# Provides common cluster management operations

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

# Function to show cluster status
show_status() {
    log_info "Cluster Status:"
    echo ""
    echo "=== Nodes ==="
    kubectl get nodes -o wide
    echo ""
    echo "=== System Pods ==="
    kubectl get pods -n kube-system
    echo ""
    echo "=== Storage Classes ==="
    kubectl get storageclass
    echo ""
    echo "=== Services ==="
    kubectl get services -n kube-system
}

# Function to show cluster info
show_info() {
    log_info "Cluster Information:"
    kubectl cluster-info
    echo ""
    kubectl version --short
}

# Function to show resource usage
show_usage() {
    log_info "Resource Usage:"
    echo ""
    echo "=== Node Resources ==="
    kubectl top nodes
    echo ""
    echo "=== Pod Resources ==="
    kubectl top pods --all-namespaces
}

# Function to backup cluster
backup_cluster() {
    log_info "Backing up cluster configuration..."
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_DIR="cluster-backup-$TIMESTAMP"
    mkdir -p "$BACKUP_DIR"
    
    kubectl get all --all-namespaces -o yaml > "$BACKUP_DIR/all-resources.yaml"
    kubectl get configmaps --all-namespaces -o yaml > "$BACKUP_DIR/configmaps.yaml"
    kubectl get secrets --all-namespaces -o yaml > "$BACKUP_DIR/secrets.yaml"
    kubectl get pv -o yaml > "$BACKUP_DIR/persistent-volumes.yaml"
    kubectl get pvc --all-namespaces -o yaml > "$BACKUP_DIR/persistent-volume-claims.yaml"
    
    log_success "Cluster backup created in: $BACKUP_DIR"
}

# Function to clean up cluster
cleanup_cluster() {
    log_warning "This will delete the entire cluster. Are you sure? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        log_info "Deleting cluster..."
        k3d cluster delete medinovai-cluster
        log_success "Cluster deleted"
    else
        log_info "Cluster deletion cancelled"
    fi
}

# Main menu
case "${1:-status}" in
    "status")
        show_status
        ;;
    "info")
        show_info
        ;;
    "usage")
        show_usage
        ;;
    "backup")
        backup_cluster
        ;;
    "cleanup")
        cleanup_cluster
        ;;
    "help"|*)
        echo "Usage: $0 {status|info|usage|backup|cleanup|help}"
        echo ""
        echo "Commands:"
        echo "  status  - Show cluster status"
        echo "  info    - Show cluster information"
        echo "  usage   - Show resource usage"
        echo "  backup  - Backup cluster configuration"
        echo "  cleanup - Delete the cluster"
        echo "  help    - Show this help message"
        ;;
esac
