#!/bin/bash

#####################################################################
# Cleanup Existing Deployment
# Remove all existing medinovai deployments for fresh install
#####################################################################

set -euo pipefail

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log_success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ $1"
}

log "Starting cleanup of existing deployments..."

# Delete all resources in medinovai namespace
log "Deleting all resources in medinovai namespace..."
kubectl delete all --all -n medinovai --force --grace-period=0 2>/dev/null || true
kubectl delete pvc --all -n medinovai --force --grace-period=0 2>/dev/null || true
kubectl delete configmaps --all -n medinovai 2>/dev/null || true
kubectl delete secrets --all -n medinovai 2>/dev/null || true

# Delete all resources in medinovai-module-dev namespace
log "Deleting all resources in medinovai-module-dev namespace..."
kubectl delete all --all -n medinovai-module-dev --force --grace-period=0 2>/dev/null || true

# Delete all resources in medinovai-restricted namespace
log "Deleting all resources in medinovai-restricted namespace..."
kubectl delete all --all -n medinovai-restricted --force --grace-period=0 2>/dev/null || true

# Delete all resources in default namespace with medinovai labels
log "Deleting medinovai resources in default namespace..."
kubectl delete all -l app.kubernetes.io/part-of=medinovai -n default --force --grace-period=0 2>/dev/null || true

# Wait for all pods to terminate
log "Waiting for all pods to terminate..."
for i in {1..30}; do
    if [ $(kubectl get pods -n medinovai 2>/dev/null | wc -l) -le 1 ]; then
        break
    fi
    sleep 2
done

log_success "Cleanup completed"

exit 0

