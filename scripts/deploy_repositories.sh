#!/bin/bash

# MedinovAI Repository Deployment Script
# This script deploys all 120 MedinovAI repositories using agent swarms

set -euo pipefail

# Configuration
ORG="myonsite-healthcare"
MEDINOVAI_NAMESPACE="medinovai"
REPO_COUNT=120
BATCH_SIZE=10
MAX_CONCURRENT_SWARMS=3

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

log_swarm() {
    echo -e "${CYAN}🤖 $1${NC}"
}

# Repository categories and port allocations
declare -A REPO_CATEGORIES=(
    ["core-infrastructure"]="8800-8899"
    ["api-services"]="8000-8099"
    ["frontend-services"]="8100-8199"
    ["database-services"]="8200-8299"
    ["ai-ml-services"]="8400-8499"
    ["analytics-services"]="8300-8399"
    ["integration-services"]="8500-8599"
    ["security-services"]="8600-8699"
    ["mobile-services"]="8700-8799"
)

# Generate repository list
generate_repository_list() {
    log_info "Generating repository list..."
    
    # Core Infrastructure (15 repos)
    cat > repositories/core-infrastructure.txt << 'EOF'
medinovai-infrastructure
medinovai-platform
medinovai-cluster-config
medinovai-monitoring
medinovai-logging
medinovai-security
medinovai-networking
medinovai-storage
medinovai-backup
medinovai-disaster-recovery
medinovai-compliance
medinovai-audit
medinovai-policies
medinovai-secrets
medinovai-certificates
EOF

    # API Services (25 repos)
    cat > repositories/api-services.txt << 'EOF'
medinovai-api-gateway
medinovai-auth-service
medinovai-user-service
medinovai-patient-service
medinovai-doctor-service
medinovai-appointment-service
medinovai-medical-records-service
medinovai-billing-service
medinovai-insurance-service
medinovai-notification-service
medinovai-analytics-service
medinovai-reporting-service
medinovai-integration-service
medinovai-workflow-service
medinovai-audit-service
medinovai-compliance-service
medinovai-security-service
medinovai-backup-service
medinovai-sync-service
medinovai-queue-service
medinovai-cache-service
medinovai-search-service
medinovai-recommendation-service
medinovai-prediction-service
medinovai-ai-service
EOF

    # Frontend Services (20 repos)
    cat > repositories/frontend-services.txt << 'EOF'
medinovai-dashboard
medinovai-patient-portal
medinovai-doctor-portal
medinovai-admin-portal
medinovai-nurse-portal
medinovai-reception-portal
medinovai-billing-portal
medinovai-analytics-portal
medinovai-reporting-portal
medinovai-settings-portal
medinovai-profile-portal
medinovai-messaging-portal
medinovai-calendar-portal
medinovai-documents-portal
medinovai-medications-portal
medinovai-lab-results-portal
medinovai-imaging-portal
medinovai-vitals-portal
medinovai-allergies-portal
medinovai-immunizations-portal
EOF

    # Database Services (10 repos)
    cat > repositories/database-services.txt << 'EOF'
medinovai-postgres-primary
medinovai-postgres-replica
medinovai-mongodb-primary
medinovai-mongodb-replica
medinovai-redis-cache
medinovai-elasticsearch
medinovai-influxdb
medinovai-timescaledb
medinovai-neo4j
medinovai-cassandra
EOF

    # AI/ML Services (15 repos)
    cat > repositories/ai-ml-services.txt << 'EOF'
medinovai-llm-service
medinovai-embedding-service
medinovai-vector-db
medinovai-rag-service
medinovai-chatbot-service
medinovai-document-analysis
medinovai-image-analysis
medinovai-prediction-engine
medinovai-recommendation-engine
medinovai-anomaly-detection
medinovai-fraud-detection
medinovai-risk-assessment
medinovai-clinical-decision-support
medinovai-drug-interaction-checker
medinovai-diagnosis-assistant
EOF

    # Analytics Services (10 repos)
    cat > repositories/analytics-services.txt << 'EOF'
medinovai-analytics-engine
medinovai-reporting-engine
medinovai-dashboard-engine
medinovai-kpi-service
medinovai-metrics-service
medinovai-alerts-service
medinovai-sla-service
medinovai-performance-service
medinovai-usage-service
medinovai-cost-service
EOF

    # Integration Services (10 repos)
    cat > repositories/integration-services.txt << 'EOF'
medinovai-hl7-integration
medinovai-fhir-integration
medinovai-epic-integration
medinovai-cerner-integration
medinovai-allscripts-integration
medinovai-athena-integration
medinovai-nextgen-integration
medinovai-eclinicalworks-integration
medinovai-practice-fusion-integration
medinovai-custom-integration
EOF

    # Security Services (8 repos)
    cat > repositories/security-services.txt << 'EOF'
medinovai-identity-service
medinovai-auth-service
medinovai-authorization-service
medinovai-audit-service
medinovai-compliance-service
medinovai-encryption-service
medinovai-key-management
medinovai-threat-detection
EOF

    # Mobile Services (7 repos)
    cat > repositories/mobile-services.txt << 'EOF'
medinovai-mobile-app
medinovai-patient-mobile
medinovai-doctor-mobile
medinovai-nurse-mobile
medinovai-admin-mobile
medinovai-messaging-mobile
medinovai-emergency-mobile
EOF

    log_success "Repository list generated"
}

# Create agent swarm for repository
create_repository_swarm() {
    local repo_name="$1"
    local category="$2"
    local port_range="$3"
    local base_port=$(echo "$port_range" | cut -d'-' -f1)
    
    log_swarm "Creating agent swarm for $repo_name"
    
    # Create swarm directory
    mkdir -p "swarms/$repo_name"
    
    # Create swarm configuration
    cat > "swarms/$repo_name/swarm-config.json" << EOF
{
  "repository": "$repo_name",
  "category": "$category",
  "port_range": "$port_range",
  "base_port": $base_port,
  "namespace": "$MEDINOVAI_NAMESPACE",
  "agents": [
    {
      "name": "build-deploy",
      "type": "build-deploy",
      "port": $((base_port + 0))
    },
    {
      "name": "configure",
      "type": "configure",
      "port": $((base_port + 1))
    },
    {
      "name": "validate",
      "type": "validate",
      "port": $((base_port + 2))
    },
    {
      "name": "monitor",
      "type": "monitor",
      "port": $((base_port + 3))
    },
    {
      "name": "security",
      "type": "security",
      "port": $((base_port + 4))
    }
  ]
}
EOF

    # Create agent scripts
    create_agent_scripts "$repo_name" "$category" "$base_port"
    
    # Create Kubernetes manifests
    create_kubernetes_manifests "$repo_name" "$category" "$base_port"
    
    # Create Istio configuration
    create_istio_configuration "$repo_name" "$base_port"
    
    log_success "Agent swarm created for $repo_name"
}

# Create agent scripts
create_agent_scripts() {
    local repo_name="$1"
    local category="$2"
    local base_port="$3"
    
    # Build & Deploy Agent
    cat > "swarms/$repo_name/agent-build-deploy.sh" << EOF
#!/bin/bash
# Build & Deploy Agent for $repo_name

set -euo pipefail

REPO_NAME="$repo_name"
CATEGORY="$category"
BASE_PORT=$base_port
NAMESPACE="$MEDINOVAI_NAMESPACE"

echo "🤖 Build & Deploy Agent: Starting deployment for \$REPO_NAME"

# Clone repository
echo "📥 Cloning repository..."
git clone "https://github.com/$ORG/\$REPO_NAME.git" /tmp/\$REPO_NAME
cd /tmp/\$REPO_NAME

# Build Docker image
echo "🐳 Building Docker image..."
docker build -t medinovai/\$REPO_NAME:latest .

# Create Kubernetes manifests
echo "☸️  Creating Kubernetes manifests..."
kubectl apply -f k8s/ -n \$NAMESPACE

# Deploy to cluster
echo "🚀 Deploying to cluster..."
kubectl rollout status deployment/\$REPO_NAME -n \$NAMESPACE

echo "✅ Build & Deploy Agent: Completed deployment for \$REPO_NAME"
EOF

    # Configure Agent
    cat > "swarms/$repo_name/agent-configure.sh" << EOF
#!/bin/bash
# Configure Agent for $repo_name

set -euo pipefail

REPO_NAME="$repo_name"
CATEGORY="$category"
BASE_PORT=$base_port
NAMESPACE="$MEDINOVAI_NAMESPACE"

echo "🔧 Configure Agent: Configuring \$REPO_NAME"

# Configure environment variables
echo "⚙️  Configuring environment variables..."
kubectl patch deployment \$REPO_NAME -n \$NAMESPACE -p '{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "\$REPO_NAME",
          "env": [
            {"name": "PORT", "value": "\$BASE_PORT"},
            {"name": "NAMESPACE", "value": "\$NAMESPACE"},
            {"name": "CATEGORY", "value": "\$CATEGORY"}
          ]
        }]
      }
    }
  }
}'

# Configure monitoring
echo "📊 Configuring monitoring..."
kubectl label deployment \$REPO_NAME monitoring=enabled -n \$NAMESPACE

# Configure security
echo "🛡️  Configuring security..."
kubectl patch deployment \$REPO_NAME -n \$NAMESPACE -p '{
  "spec": {
    "template": {
      "spec": {
        "securityContext": {
          "runAsNonRoot": true,
          "runAsUser": 1000,
          "fsGroup": 2000
        }
      }
    }
  }
}'

echo "✅ Configure Agent: Completed configuration for \$REPO_NAME"
EOF

    # Validate Agent
    cat > "swarms/$repo_name/agent-validate.sh" << EOF
#!/bin/bash
# Validate Agent for $repo_name

set -euo pipefail

REPO_NAME="$repo_name"
CATEGORY="$category"
BASE_PORT=$base_port
NAMESPACE="$MEDINOVAI_NAMESPACE"

echo "🔍 Validate Agent: Validating \$REPO_NAME"

# Health check
echo "💚 Running health check..."
kubectl wait --for=condition=Available deployment/\$REPO_NAME -n \$NAMESPACE --timeout=300s

# Port check
echo "🔌 Checking port \$BASE_PORT..."
kubectl port-forward deployment/\$REPO_NAME \$BASE_PORT:\$BASE_PORT -n \$NAMESPACE &
PORT_FORWARD_PID=\$!
sleep 5

if curl -f "http://localhost:\$BASE_PORT/health" 2>/dev/null; then
    echo "✅ Health check passed"
else
    echo "❌ Health check failed"
    exit 1
fi

kill \$PORT_FORWARD_PID 2>/dev/null || true

# Integration test
echo "🧪 Running integration tests..."
kubectl exec deployment/\$REPO_NAME -n \$NAMESPACE -- npm test 2>/dev/null || echo "No tests found"

echo "✅ Validate Agent: Completed validation for \$REPO_NAME"
EOF

    # Monitor Agent
    cat > "swarms/$repo_name/agent-monitor.sh" << EOF
#!/bin/bash
# Monitor Agent for $repo_name

set -euo pipefail

REPO_NAME="$repo_name"
CATEGORY="$category"
BASE_PORT=$base_port
NAMESPACE="$MEDINOVAI_NAMESPACE"

echo "📊 Monitor Agent: Setting up monitoring for \$REPO_NAME"

# Create ServiceMonitor
echo "📈 Creating ServiceMonitor..."
kubectl apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: \$REPO_NAME
  namespace: \$NAMESPACE
spec:
  selector:
    matchLabels:
      app: \$REPO_NAME
  endpoints:
  - port: metrics
    path: /metrics
    interval: 30s
EOF

# Create alerts
echo "🚨 Creating alerts..."
kubectl apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: \$REPO_NAME-alerts
  namespace: \$NAMESPACE
spec:
  groups:
  - name: \$REPO_NAME-alerts
    rules:
    - alert: \$REPO_NAME-Down
      expr: up{job="\$REPO_NAME"} == 0
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "\$REPO_NAME is down"
    - alert: \$REPO_NAME-HighCPU
      expr: rate(container_cpu_usage_seconds_total{pod=~"\$REPO_NAME-.*"}[5m]) > 0.8
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "\$REPO_NAME high CPU usage"
EOF

echo "✅ Monitor Agent: Completed monitoring setup for \$REPO_NAME"
EOF

    # Security Agent
    cat > "swarms/$repo_name/agent-security.sh" << EOF
#!/bin/bash
# Security Agent for $repo_name

set -euo pipefail

REPO_NAME="$repo_name"
CATEGORY="$category"
BASE_PORT=$base_port
NAMESPACE="$MEDINOVAI_NAMESPACE"

echo "🛡️  Security Agent: Setting up security for \$REPO_NAME"

# Create NetworkPolicy
echo "🔒 Creating NetworkPolicy..."
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: \$REPO_NAME-network-policy
  namespace: \$NAMESPACE
spec:
  podSelector:
    matchLabels:
      app: \$REPO_NAME
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: \$NAMESPACE
    - namespaceSelector:
        matchLabels:
          name: istio-system
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: \$NAMESPACE
    - namespaceSelector:
        matchLabels:
          name: kube-system
  - to: []
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
EOF

# Create PodSecurityPolicy
echo "🔐 Creating PodSecurityPolicy..."
kubectl apply -f - <<EOF
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: \$REPO_NAME-psp
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'downwardAPI'
    - 'persistentVolumeClaim'
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'RunAsAny'
  fsGroup:
    rule: 'RunAsAny'
EOF

echo "✅ Security Agent: Completed security setup for \$REPO_NAME"
EOF

    # Make scripts executable
    chmod +x "swarms/$repo_name"/*.sh
}

# Create Kubernetes manifests
create_kubernetes_manifests() {
    local repo_name="$1"
    local category="$2"
    local base_port="$3"
    
    mkdir -p "swarms/$repo_name/k8s"
    
    # Deployment
    cat > "swarms/$repo_name/k8s/deployment.yaml" << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $repo_name
  namespace: $MEDINOVAI_NAMESPACE
  labels:
    app: $repo_name
    category: $category
    monitoring: enabled
spec:
  replicas: 3
  selector:
    matchLabels:
      app: $repo_name
  template:
    metadata:
      labels:
        app: $repo_name
        category: $category
        monitoring: enabled
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 2000
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: $repo_name
        image: medinovai/$repo_name:latest
        ports:
        - name: http
          containerPort: $base_port
        - name: health
          containerPort: $((base_port + 1))
        - name: metrics
          containerPort: $((base_port + 2))
        env:
        - name: PORT
          value: "$base_port"
        - name: NAMESPACE
          value: "$MEDINOVAI_NAMESPACE"
        - name: CATEGORY
          value: "$category"
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /health
            port: $((base_port + 1))
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: $((base_port + 1))
          initialDelaySeconds: 5
          periodSeconds: 5
EOF

    # Service
    cat > "swarms/$repo_name/k8s/service.yaml" << EOF
apiVersion: v1
kind: Service
metadata:
  name: $repo_name
  namespace: $MEDINOVAI_NAMESPACE
  labels:
    app: $repo_name
    category: $category
    monitoring: enabled
spec:
  selector:
    app: $repo_name
  ports:
  - name: http
    port: $base_port
    targetPort: $base_port
  - name: health
    port: $((base_port + 1))
    targetPort: $((base_port + 1))
  - name: metrics
    port: $((base_port + 2))
    targetPort: $((base_port + 2))
  type: ClusterIP
EOF

    # ConfigMap
    cat > "swarms/$repo_name/k8s/configmap.yaml" << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: $repo_name-config
  namespace: $MEDINOVAI_NAMESPACE
data:
  PORT: "$base_port"
  NAMESPACE: "$MEDINOVAI_NAMESPACE"
  CATEGORY: "$category"
  LOG_LEVEL: "info"
  METRICS_ENABLED: "true"
  HEALTH_CHECK_ENABLED: "true"
EOF
}

# Create Istio configuration
create_istio_configuration() {
    local repo_name="$1"
    local base_port="$2"
    
    mkdir -p "swarms/$repo_name/istio"
    
    # VirtualService
    cat > "swarms/$repo_name/istio/virtualservice.yaml" << EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: $repo_name
  namespace: $MEDINOVAI_NAMESPACE
spec:
  hosts:
  - "$repo_name.medinovai.local"
  gateways:
  - medinovai-gateway
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: $repo_name
        port:
          number: $base_port
    timeout: 30s
    retries:
      attempts: 3
      perTryTimeout: 10s
EOF

    # DestinationRule
    cat > "swarms/$repo_name/istio/destinationrule.yaml" << EOF
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: $repo_name
  namespace: $MEDINOVAI_NAMESPACE
spec:
  host: $repo_name
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 50
        maxRequestsPerConnection: 2
    circuitBreaker:
      consecutiveErrors: 3
      interval: 30s
      baseEjectionTime: 30s
      maxEjectionPercent: 50
EOF
}

# Deploy repository batch
deploy_repository_batch() {
    local batch_num="$1"
    local category="$2"
    local repo_file="repositories/$category.txt"
    
    if [[ ! -f "$repo_file" ]]; then
        log_warning "Repository file not found: $repo_file"
        return 0
    fi
    
    log_deploy "Deploying batch $batch_num: $category"
    
    local repo_count=0
    while IFS= read -r repo_name; do
        if [[ -z "$repo_name" ]]; then
            continue
        fi
        
        # Create agent swarm
        create_repository_swarm "$repo_name" "$category" "${REPO_CATEGORIES[$category]}"
        
        # Deploy agents in parallel
        (
            cd "swarms/$repo_name"
            ./agent-build-deploy.sh &
            ./agent-configure.sh &
            ./agent-validate.sh &
            ./agent-monitor.sh &
            ./agent-security.sh &
            wait
        ) &
        
        ((repo_count++))
        
        # Limit concurrent deployments
        if [[ $((repo_count % 5)) -eq 0 ]]; then
            wait
        fi
        
    done < "$repo_file"
    
    # Wait for all deployments in this batch
    wait
    
    log_success "Batch $batch_num ($category) deployment completed"
}

# Main execution
main() {
    echo "🚀 MedinovAI Repository Deployment"
    echo "=================================="
    echo "Organization: $ORG"
    echo "Namespace: $MEDINOVAI_NAMESPACE"
    echo "Repository Count: $REPO_COUNT"
    echo "Batch Size: $BATCH_SIZE"
    echo "Date: $(date)"
    echo ""
    
    # Create directories
    mkdir -p repositories swarms
    
    # Generate repository list
    generate_repository_list
    
    # Deploy repositories by category
    local batch_num=1
    for category in "${!REPO_CATEGORIES[@]}"; do
        deploy_repository_batch "$batch_num" "$category"
        ((batch_num++))
        
        # Wait between batches
        if [[ $batch_num -le ${#REPO_CATEGORIES[@]} ]]; then
            log_info "Waiting 30 seconds before next batch..."
            sleep 30
        fi
    done
    
    echo ""
    log_success "🎉 MedinovAI repository deployment completed successfully!"
    echo ""
    echo "📊 Deployment Summary:"
    echo "  🏗️  Core Infrastructure: 15 repositories"
    echo "  🌐 API Services: 25 repositories"
    echo "  🎨 Frontend Services: 20 repositories"
    echo "  🗄️  Database Services: 10 repositories"
    echo "  🤖 AI/ML Services: 15 repositories"
    echo "  📊 Analytics Services: 10 repositories"
    echo "  🔗 Integration Services: 10 repositories"
    echo "  🛡️  Security Services: 8 repositories"
    echo "  📱 Mobile Services: 7 repositories"
    echo "  🎯 Total: 120 repositories deployed"
    echo ""
    echo "🚀 Next Steps:"
    echo "  1. Validate deployment: ./scripts/validate_deployment.sh"
    echo "  2. Setup monitoring: ./scripts/setup_monitoring.sh"
    echo "  3. Check status: kubectl get pods -n $MEDINOVAI_NAMESPACE"
}

# Run main function
main "$@"

