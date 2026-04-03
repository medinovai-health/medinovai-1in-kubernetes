#!/usr/bin/env bash
# MedinovAI Infrastructure Deployment Script with HashiCorp Vault
# This script deploys the entire infrastructure with secrets from Vault

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Configuration
VAULT_NAMESPACE="medinovai-vault"
INFRA_NAMESPACE="medinovai-services"
MONITORING_NAMESPACE="medinovai-monitoring"
DATA_NAMESPACE="medinovai-data"

echo "=========================================="
echo "  MedinovAI Infrastructure Deployment"
echo "  With HashiCorp Vault Integration"
echo "=========================================="
echo ""

# Step 1: Verify Prerequisites
log_info "Step 1: Verifying Prerequisites..."

if ! command -v kubectl &> /dev/null; then
    log_error "kubectl is required but not installed"
    exit 1
fi

if ! command -v helm &> /dev/null; then
    log_warn "helm not found. Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Check cluster connection
if ! kubectl cluster-info &> /dev/null; then
    log_error "Cannot connect to Kubernetes cluster"
    exit 1
fi
log_success "Connected to Kubernetes cluster"

# Step 2: Create Namespaces
log_info "Step 2: Creating Namespaces..."

kubectl create namespace ${VAULT_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace ${INFRA_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace ${MONITORING_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace ${DATA_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Label namespaces for Vault
kubectl label namespace ${VAULT_NAMESPACE} vault.hashicorp.com/enabled=true --overwrite
kubectl label namespace ${INFRA_NAMESPACE} vault.hashicorp.com/enabled=true --overwrite
kubectl label namespace ${MONITORING_NAMESPACE} vault.hashicorp.com/enabled=true --overwrite
kubectl label namespace ${DATA_NAMESPACE} vault.hashicorp.com/enabled=true --overwrite

log_success "Namespaces created"

# Step 3: Deploy Vault
log_info "Step 3: Deploying HashiCorp Vault..."

helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

# Check if Vault is already deployed
if ! helm list -n ${VAULT_NAMESPACE} | grep -q vault; then
    helm install vault hashicorp/vault \
        --namespace ${VAULT_NAMESPACE} \
        --set "server.dev.enabled=true" \
        --set "server.service.type=ClusterIP" \
        --set "injector.enabled=true" \
        --set "csi.enabled=true" \
        --wait --timeout 5m || {
        log_error "Vault deployment failed"
        exit 1
    }
else
    log_info "Vault already deployed, upgrading..."
    helm upgrade vault hashicorp/vault \
        --namespace ${VAULT_NAMESPACE} \
        --reuse-values \
        --wait --timeout 5m
fi

# Wait for Vault to be ready
log_info "Waiting for Vault to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=vault -n ${VAULT_NAMESPACE} --timeout=120s

log_success "Vault deployed and ready"

# Step 4: Initialize Vault (if not initialized)
log_info "Step 4: Initializing Vault..."

VAULT_STATUS=$(kubectl exec vault-0 -n ${VAULT_NAMESPACE} -- vault status 2>&1 || true)

if echo "$VAULT_STATUS" | grep -q "not initialized"; then
    log_info "Vault not initialized, initializing now..."
    
    # Initialize Vault
    INIT_OUTPUT=$(kubectl exec vault-0 -n ${VAULT_NAMESPACE} -- vault operator init -format=json -key-shares=1 -key-threshold=1)
    
    # Extract root token and unseal key
    ROOT_TOKEN=$(echo $INIT_OUTPUT | jq -r '.root_token')
    UNSEAL_KEY=$(echo $INIT_OUTPUT | jq -r '.unseal_keys_b64[0]')
    
    # Save to local file (in production, use proper secret management)
    echo "$INIT_OUTPUT" > ${ROOT_DIR}/.vault-init.json
    chmod 600 ${ROOT_DIR}/.vault-init.json
    
    log_warn "Vault initialized! Root token saved to .vault-init.json (PROTECT THIS FILE)"
    
    # Unseal Vault
    kubectl exec vault-0 -n ${VAULT_NAMESPACE} -- vault operator unseal "$UNSEAL_KEY"
    
    # Enable Kubernetes auth
    kubectl exec vault-0 -n ${VAULT_NAMESPACE} -- vault login "$ROOT_TOKEN"
    kubectl exec vault-0 -n ${VAULT_NAMESPACE} -- vault auth enable kubernetes || true
    
    # Configure Kubernetes auth
    kubectl exec vault-0 -n ${VAULT_NAMESPACE} -- vault write auth/kubernetes/config \
        token_reviewer_jwt="$(kubectl create token vault -n ${VAULT_NAMESPACE})" \
        kubernetes_host="$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')" \
        kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    
    # Create policy for infrastructure
    kubectl exec vault-0 -n ${VAULT_NAMESPACE} -- vault policy write medinovai-infrastructure - <<EOF
    path "secret/data/medinovai/*" {
      capabilities = ["create", "read", "update", "delete", "list"]
    }
    path "secret/metadata/medinovai/*" {
      capabilities = ["list", "read"]
    }
EOF
    
    # Create Kubernetes auth role
    kubectl exec vault-0 -n ${VAULT_NAMESPACE} -- vault write auth/kubernetes/role/medinovai-infrastructure \
        bound_service_account_names="*" \
        bound_service_account_namespaces="${INFRA_NAMESPACE},${MONITORING_NAMESPACE},${DATA_NAMESPACE}" \
        policies=medinovai-infrastructure \
        ttl=1h
    
    log_success "Vault initialized and configured"
else
    log_info "Vault already initialized"
    ROOT_TOKEN=$(cat ${ROOT_DIR}/.vault-init.json 2>/dev/null | jq -r '.root_token' || echo "")
fi

# Step 5: Seed Vault Secrets
log_info "Step 5: Seeding Vault Secrets..."

# Get root token
if [ -z "$ROOT_TOKEN" ]; then
    ROOT_TOKEN=$(cat ${ROOT_DIR}/.vault-init.json | jq -r '.root_token')
fi

# Seed all secrets
kubectl exec vault-0 -n ${VAULT_NAMESPACE} -- vault login "$ROOT_TOKEN" > /dev/null 2>&1

# Generate or use provided secrets
KEYCLOAK_ADMIN_PASS=$(openssl rand -base64 32)
SUPERADMIN_PASS="${SUPERADMIN_PASSWORD:-MedinovAI-Dev-2025!}"
GRAFANA_PASS=$(openssl rand -base64 24)
POSTGRES_PASS=$(openssl rand -base64 24)
REDIS_PASS=$(openssl rand -base64 24)
ELASTIC_PASS=$(openssl rand -base64 24)
JWT_SIGNING_KEY=$(openssl rand -base64 64)
ENCRYPTION_KEY=$(openssl rand -base64 32)

# Store in Vault
kubectl exec vault-0 -n ${VAULT_NAMESPACE} -- vault kv put secret/medinovai/infrastructure/security-service \
    keycloak_admin_password="$KEYCLOAK_ADMIN_PASS" \
    keycloak_client_secret="$(openssl rand -base64 32)" \
    superadmin_password="$SUPERADMIN_PASS"

kubectl exec vault-0 -n ${VAULT_NAMESPACE} -- vault kv put secret/medinovai/shared \
    jwt_signing_key="$JWT_SIGNING_KEY" \
    encryption_key="$ENCRYPTION_KEY"

kubectl exec vault-0 -n ${VAULT_NAMESPACE} -- vault kv put secret/medinovai/infrastructure/monitoring/grafana \
    admin_username="admin" \
    admin_password="$GRAFANA_PASS" \
    secret_key="$(openssl rand -base64 32)"

kubectl exec vault-0 -n ${VAULT_NAMESPACE} -- vault kv put secret/medinovai/infrastructure/database/postgres \
    username="postgres" \
    password="$POSTGRES_PASS" \
    database="medinovai"

kubectl exec vault-0 -n ${VAULT_NAMESPACE} -- vault kv put secret/medinovai/infrastructure/cache/redis \
    password="$REDIS_PASS"

kubectl exec vault-0 -n ${VAULT_NAMESPACE} -- vault kv put secret/medinovai/infrastructure/monitoring/elasticsearch \
    username="elastic" \
    password="$ELASTIC_PASS"

log_success "Vault secrets seeded"

# Save credentials to file (for reference)
cat > ${ROOT_DIR}/.credentials.env << EOF
# MedinovAI Infrastructure Credentials
# Generated on $(date)
# KEEP THIS FILE SECURE - DO NOT COMMIT TO GIT

# Keycloak
KEYCLOAK_ADMIN_PASSWORD=${KEYCLOAK_ADMIN_PASS}
KEYCLOAK_ADMIN_USERNAME=admin

# SuperAdmin
SUPERADMIN_USERNAME=superadmin
SUPERADMIN_PASSWORD=${SUPERADMIN_PASS}

# Grafana
GRAFANA_ADMIN_USERNAME=admin
GRAFANA_ADMIN_PASSWORD=${GRAFANA_PASS}

# PostgreSQL
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=${POSTGRES_PASS}

# Redis
REDIS_PASSWORD=${REDIS_PASS}

# Elasticsearch
ELASTIC_USERNAME=elastic
ELASTIC_PASSWORD=${ELASTIC_PASS}

# Vault
VAULT_ROOT_TOKEN=${ROOT_TOKEN}
EOF

chmod 600 ${ROOT_DIR}/.credentials.env
log_warn "Credentials saved to .credentials.env (DO NOT COMMIT THIS FILE)"

# Step 6: Deploy External Secrets Operator
log_info "Step 6: Deploying External Secrets Operator..."

helm repo add external-secrets https://charts.external-secrets.io
helm repo update

if ! helm list -n ${INFRA_NAMESPACE} | grep -q external-secrets; then
    helm install external-secrets external-secrets/external-secrets \
        --namespace ${INFRA_NAMESPACE} \
        --set installCRDs=true \
        --wait --timeout 5m
else
    log_info "External Secrets Operator already deployed"
fi

log_success "External Secrets Operator deployed"

# Step 7: Deploy Infrastructure Services
log_info "Step 7: Deploying Infrastructure Services..."

# Apply Vault configurations
kubectl apply -f ${ROOT_DIR}/infrastructure/vault/vault-secrets.yaml -n ${INFRA_NAMESPACE}

# Deploy core infrastructure
kubectl apply -k ${ROOT_DIR}/infrastructure/ --namespace ${INFRA_NAMESPACE}

log_success "Infrastructure services deployed"

# Step 8: Deploy Monitoring Stack
log_info "Step 8: Deploying Monitoring Stack..."

# Deploy Grafana with Vault secrets
cat <<EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: grafana-credentials
  namespace: ${MONITORING_NAMESPACE}
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend-cluster
    kind: ClusterSecretStore
  target:
    name: grafana-admin-credentials
  data:
    - secretKey: admin-user
      remoteRef:
        key: secret/medinovai/infrastructure/monitoring/grafana
        property: admin_username
    - secretKey: admin-password
      remoteRef:
        key: secret/medinovai/infrastructure/monitoring/grafana
        property: admin_password
EOF

# Deploy Grafana with dashboard ConfigMap
kubectl apply -f ${ROOT_DIR}/infrastructure/monitoring/grafana-deployment.yaml -n ${MONITORING_NAMESPACE} || {
    log_warn "Grafana deployment manifest not found, skipping..."
}

log_success "Monitoring stack deployed"

# Step 9: Run Deployment Seeder
log_info "Step 9: Running Deployment Seeder..."

# Wait for services to be ready
log_info "Waiting for services to be ready..."
kubectl wait --for=condition=ready pod -l app=security-service -n ${INFRA_NAMESPACE} --timeout=120s || true
kubectl wait --for=condition=ready pod -l app=registry -n ${INFRA_NAMESPACE} --timeout=120s || true

# Trigger seeding job
kubectl delete job deployment-seeder -n ${INFRA_NAMESPACE} --ignore-not-found=true
kubectl apply -f ${ROOT_DIR}/infrastructure/seeding/k8s-seed-job.yaml -n ${INFRA_NAMESPACE}

# Wait for seeding to complete
log_info "Waiting for seeding to complete..."
kubectl wait --for=condition=complete job/deployment-seeder -n ${INFRA_NAMESPACE} --timeout=300s || {
    log_warn "Seeding job did not complete in time, check logs with:"
    log_warn "kubectl logs job/deployment-seeder -n ${INFRA_NAMESPACE}"
}

log_success "Deployment seeding completed"

# Step 10: Summary
log_success "=========================================="
log_success "  Deployment Complete!"
log_success "=========================================="
echo ""
echo "Access URLs:"
echo "  medinovaiOS Portal: http://medinovaios.local (or port-forward from localhost)"
echo "  Grafana:           http://localhost:4250 (admin/${GRAFANA_PASS})"
echo "  Kibana:            http://localhost:4251"
echo "  Vault UI:          kubectl port-forward svc/vault -n ${VAULT_NAMESPACE} 8200:8200"
echo ""
echo "Credentials:"
echo "  SuperAdmin:        superadmin / ${SUPERADMIN_PASS}"
echo "  Keycloak Admin:    admin / ${KEYCLOAK_ADMIN_PASS}"
echo ""
echo "Important Files:"
echo "  Vault init data:   ${ROOT_DIR}/.vault-init.json"
echo "  Credentials:     ${ROOT_DIR}/.credentials.env"
echo ""
log_warn "IMPORTANT: Keep .vault-init.json and .credentials.env secure!"
log_warn "These files contain sensitive data and should NOT be committed to Git."
echo ""
log_success "=========================================="
