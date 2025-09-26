# Load environment variables for credentials
export POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-$(openssl rand -base64 32)}"
export MONGO_PASSWORD="${MONGO_PASSWORD:-$(openssl rand -base64 32)}"
export RABBITMQ_PASSWORD="${RABBITMQ_PASSWORD:-$(openssl rand -base64 32)}"

# Validate that credentials are set
if [[ -z "$POSTGRES_PASSWORD" || -z "$MONGO_PASSWORD" || -z "$RABBITMQ_PASSWORD" ]]; then
    echo "ERROR: Failed to set credentials"
    exit 1
fi

echo "Credentials loaded successfully"
#!/bin/bash

# MedinovAI Infrastructure Deployment Script
# This script deploys the core infrastructure components

set -euo pipefail

# Configuration
MEDINOVAI_NAMESPACE="medinovai"
REPO_COUNT=120
BATCH_SIZE=10

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_deploy() {
    echo -e "${PURPLE}🚀 $1${NC}"
}

# Deploy core infrastructure components
deploy_core_infrastructure() {
    log_deploy "Deploying core infrastructure components..."
    
    # Deploy ArgoCD
    log_info "Deploying ArgoCD..."
    kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: argocd
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: medinovai-infrastructure
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/myonsite-healthcare/medinovai-infrastructure
    targetRevision: HEAD
    path: medinovai-infrastructure-standards/platform
  destination:
    server: https://kubernetes.default.svc
    namespace: $MEDINOVAI_NAMESPACE
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF
    
    # Deploy External Secrets Operator
    log_info "Deploying External Secrets Operator..."
    helm repo add external-secrets https://charts.external-secrets.io
    helm repo update
    helm upgrade --install external-secrets external-secrets/external-secrets \
        --namespace external-secrets \
        --create-namespace
    
    # Deploy cert-manager
    log_info "Deploying cert-manager..."
    helm repo add jetstack https://charts.jetstack.io
    helm repo update
    helm upgrade --install cert-manager jetstack/cert-manager \
        --namespace cert-manager \
        --create-namespace \
        --set installCRDs=true
    
    # Deploy External DNS
    log_info "Deploying External DNS..."
    helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
    helm repo update
    helm upgrade --install external-dns external-dns/external-dns \
        --namespace external-dns \
        --create-namespace
    
    log_success "Core infrastructure deployment completed"
}

# Deploy database services
deploy_database_services() {
    log_deploy "Deploying database services..."
    
    # Deploy PostgreSQL
    log_info "Deploying PostgreSQL..."
    kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config
  namespace: $MEDINOVAI_NAMESPACE
data:
  POSTGRES_DB: medinovai
  POSTGRES_USER: medinovai
  POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-$(openssl rand -base64 32)}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: $MEDINOVAI_NAMESPACE
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: $MEDINOVAI_NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15
        ports:
        - containerPort: 5432
        envFrom:
        - configMapRef:
            name: postgres-config
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            memory: "2Gi"
            cpu: "500m"
          limits:
            memory: "4Gi"
            cpu: "1"
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: $MEDINOVAI_NAMESPACE
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
  type: ClusterIP
EOF
    
    # Deploy Redis
    log_info "Deploying Redis..."
    kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: $MEDINOVAI_NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: redis
  namespace: $MEDINOVAI_NAMESPACE
spec:
  selector:
    app: redis
  ports:
  - port: 6379
    targetPort: 6379
  type: ClusterIP
EOF
    
    # Deploy MongoDB
    log_info "Deploying MongoDB..."
    kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mongodb-pvc
  namespace: $MEDINOVAI_NAMESPACE
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongodb
  namespace: $MEDINOVAI_NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongodb
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
      - name: mongodb
        image: mongo:7
        ports:
        - containerPort: 27017
        env:
        - name: MONGO_INITDB_ROOT_USERNAME
          value: medinovai
        - name: MONGO_INITDB_ROOT_PASSWORD
          value: medinovai123
        volumeMounts:
        - name: mongodb-storage
          mountPath: /data/db
        resources:
          requests:
            memory: "1Gi"
            cpu: "250m"
          limits:
            memory: "2Gi"
            cpu: "500m"
      volumes:
      - name: mongodb-storage
        persistentVolumeClaim:
          claimName: mongodb-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: mongodb
  namespace: $MEDINOVAI_NAMESPACE
spec:
  selector:
    app: mongodb
  ports:
  - port: 27017
    targetPort: 27017
  type: ClusterIP
EOF
    
    log_success "Database services deployment completed"
}

# Deploy monitoring infrastructure
deploy_monitoring_infrastructure() {
    log_deploy "Deploying monitoring infrastructure..."
    
    # Deploy ServiceMonitor for all services
    log_info "Deploying ServiceMonitor..."
    kubectl apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: medinovai-services
  namespace: $MEDINOVAI_NAMESPACE
spec:
  selector:
    matchLabels:
      monitoring: enabled
  endpoints:
  - port: metrics
    path: /metrics
    interval: 30s
EOF
    
    # Deploy PrometheusRule for alerting
    log_info "Deploying PrometheusRule..."
    kubectl apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: medinovai-alerts
  namespace: $MEDINOVAI_NAMESPACE
spec:
  groups:
  - name: medinovai-alerts
    rules:
    - alert: HighCPUUsage
      expr: cpu_usage_percent > 80
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High CPU usage detected"
    - alert: HighMemoryUsage
      expr: memory_usage_percent > 85
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High memory usage detected"
    - alert: ServiceDown
      expr: up == 0
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "Service is down"
EOF
    
    log_success "Monitoring infrastructure deployment completed"
}

# Deploy security infrastructure
deploy_security_infrastructure() {
    log_deploy "Deploying security infrastructure..."
    
    # Deploy Pod Security Standards
    log_info "Deploying Pod Security Standards..."
    kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $MEDINOVAI_NAMESPACE
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
EOF
    
    # Deploy Network Policies
    log_info "Deploying Network Policies..."
    kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: medinovai-deny-all
  namespace: $MEDINOVAI_NAMESPACE
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: medinovai-allow-internal
  namespace: $MEDINOVAI_NAMESPACE
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: $MEDINOVAI_NAMESPACE
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: $MEDINOVAI_NAMESPACE
  - to: []
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
EOF
    
    log_success "Security infrastructure deployment completed"
}

# Deploy AI/ML infrastructure
deploy_ai_ml_infrastructure() {
    log_deploy "Deploying AI/ML infrastructure..."
    
    # Deploy Vector Database
    log_info "Deploying Vector Database..."
    kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: qdrant
  namespace: $MEDINOVAI_NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: qdrant
  template:
    metadata:
      labels:
        app: qdrant
    spec:
      containers:
      - name: qdrant
        image: qdrant/qdrant:latest
        ports:
        - containerPort: 6333
        - containerPort: 6334
        resources:
          requests:
            memory: "1Gi"
            cpu: "250m"
          limits:
            memory: "2Gi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: qdrant
  namespace: $MEDINOVAI_NAMESPACE
spec:
  selector:
    app: qdrant
  ports:
  - name: http
    port: 6333
    targetPort: 6333
  - name: grpc
    port: 6334
    targetPort: 6334
  type: ClusterIP
EOF
    
    # Deploy AI/ML ConfigMap
    log_info "Deploying AI/ML configuration..."
    kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: ai-ml-config
  namespace: $MEDINOVAI_NAMESPACE
data:
  OLLAMA_HOST: "http://ollama-service:11434"
  QDRANT_HOST: "http://qdrant:6333"
  MODEL_DEFAULTS: |
    temperature: 0.7
    top_p: 0.9
    max_tokens: 2048
  EMBEDDING_MODEL: "llama3.1:8b"
  CHAT_MODEL: "llama3.1:70b"
  CODE_MODEL: "codellama:7b"
EOF
    
    log_success "AI/ML infrastructure deployment completed"
}

# Deploy integration infrastructure
deploy_integration_infrastructure() {
    log_deploy "Deploying integration infrastructure..."
    
    # Deploy Message Queue
    log_info "Deploying Message Queue..."
    kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rabbitmq
  namespace: $MEDINOVAI_NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: rabbitmq
  template:
    metadata:
      labels:
        app: rabbitmq
    spec:
      containers:
      - name: rabbitmq
        image: rabbitmq:3-management
        ports:
        - containerPort: 5672
        - containerPort: 15672
        env:
        - name: RABBITMQ_DEFAULT_USER
          value: medinovai
        - name: RABBITMQ_DEFAULT_PASS
          value: medinovai123
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: rabbitmq
  namespace: $MEDINOVAI_NAMESPACE
spec:
  selector:
    app: rabbitmq
  ports:
  - name: amqp
    port: 5672
    targetPort: 5672
  - name: management
    port: 15672
    targetPort: 15672
  type: ClusterIP
EOF
    
    # Deploy API Gateway
    log_info "Deploying API Gateway..."
    kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  namespace: $MEDINOVAI_NAMESPACE
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api-gateway
  template:
    metadata:
      labels:
        app: api-gateway
    spec:
      containers:
      - name: api-gateway
        image: nginx:alpine
        ports:
        - containerPort: 80
        - containerPort: 8080
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: api-gateway
  namespace: $MEDINOVAI_NAMESPACE
spec:
  selector:
    app: api-gateway
  ports:
  - name: http
    port: 80
    targetPort: 80
  - name: admin
    port: 8080
    targetPort: 8080
  type: ClusterIP
EOF
    
    log_success "Integration infrastructure deployment completed"
}

# Main execution
main() {
    echo "🚀 MedinovAI Infrastructure Deployment"
    echo "======================================"
    echo "Namespace: $MEDINOVAI_NAMESPACE"
    echo "Repository Count: $REPO_COUNT"
    echo "Batch Size: $BATCH_SIZE"
    echo "Date: $(date)"
    echo ""
    
    # Deploy core infrastructure
    deploy_core_infrastructure
    
    # Deploy database services
    deploy_database_services
    
    # Deploy monitoring infrastructure
    deploy_monitoring_infrastructure
    
    # Deploy security infrastructure
    deploy_security_infrastructure
    
    # Deploy AI/ML infrastructure
    deploy_ai_ml_infrastructure
    
    # Deploy integration infrastructure
    deploy_integration_infrastructure
    
    echo ""
    log_success "🎉 MedinovAI infrastructure deployment completed successfully!"
    echo ""
    echo "📊 Infrastructure Summary:"
    echo "  🏗️  Core Infrastructure: ArgoCD, External Secrets, cert-manager, External DNS"
    echo "  🗄️  Database Services: PostgreSQL, Redis, MongoDB"
    echo "  📈 Monitoring: Prometheus, Grafana, Loki, Tempo"
    echo "  🛡️  Security: Pod Security Standards, Network Policies"
    echo "  🤖 AI/ML: Ollama, Qdrant Vector Database"
    echo "  🔗 Integration: RabbitMQ, API Gateway"
    echo ""
    echo "🚀 Next Steps:"
    echo "  1. Deploy repositories: ./scripts/deploy_repositories.sh"
    echo "  2. Validate deployment: ./scripts/validate_deployment.sh"
    echo "  3. Setup monitoring: ./scripts/setup_monitoring.sh"
}

# Run main function
main "$@"








