#!/bin/bash

#####################################################################
# Bootstrap Infrastructure
# Deploy core infrastructure components
#####################################################################

set -euo pipefail

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log_success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ $1"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ $1"
}

log "Bootstrapping core infrastructure..."

# Ensure namespaces exist
log "Creating namespaces..."
kubectl create namespace medinovai --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace istio-system --dry-run=client -o yaml | kubectl apply -f -

# Label namespace for Istio injection
kubectl label namespace medinovai istio-injection=enabled --overwrite

log_success "Namespaces created"

# Add Helm repositories
log "Adding Helm repositories..."
helm repo add bitnami https://charts.bitnami.com/bitnami 2>/dev/null || true
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || true
helm repo update

log_success "Helm repositories added"

# Deploy PostgreSQL
log "Deploying PostgreSQL..."
helm upgrade --install postgresql bitnami/postgresql \
  --namespace medinovai \
  --set auth.database=medinovai \
  --set auth.username=medinovai \
  --set auth.password=medinovai123 \
  --set primary.persistence.size=10Gi \
  --wait --timeout=10m || log_error "PostgreSQL deployment failed"

log_success "PostgreSQL deployed"

# Deploy Redis
log "Deploying Redis..."
helm upgrade --install redis bitnami/redis \
  --namespace medinovai \
  --set auth.password=medinovai123 \
  --set master.persistence.size=5Gi \
  --wait --timeout=10m || log_error "Redis deployment failed"

log_success "Redis deployed"

# Deploy Prometheus & Grafana
log "Deploying Prometheus & Grafana..."
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.adminPassword=medinovai123 \
  --set grafana.ingress.enabled=false \
  --set prometheus.ingress.enabled=false \
  --wait --timeout=10m || log_error "Prometheus deployment failed"

log_success "Prometheus & Grafana deployed"

# Wait for all pods to be ready
log "Waiting for all infrastructure pods to be ready..."
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/instance=postgresql \
  -n medinovai --timeout=300s

kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/instance=redis \
  -n medinovai --timeout=300s

log_success "All infrastructure components are ready"

# Display connection information
log ""
log "Infrastructure Connection Details:"
log "  PostgreSQL: postgresql.medinovai.svc.cluster.local:5432"
log "    Database: medinovai"
log "    Username: medinovai"
log "    Password: medinovai123"
log ""
log "  Redis: redis-master.medinovai.svc.cluster.local:6379"
log "    Password: medinovai123"
log ""
log "  Grafana: http://prometheus-grafana.monitoring.svc.cluster.local:80"
log "    Username: admin"
log "    Password: medinovai123"
log ""

log_success "Infrastructure bootstrap completed"

exit 0

