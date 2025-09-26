#!/bin/bash

# MedinovAI Infrastructure Deployment Script
# Use this script to deploy any MedinovAI service to the production infrastructure

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

# Configuration
SERVICE_NAME="${1:-}"
NAMESPACE="medinovai"
CLUSTER="medinovai-cluster"

# Infrastructure endpoints
POSTGRESQL_URL="postgresql.medinovai.svc.cluster.local:5432"
REDIS_URL="redis.medinovai.svc.cluster.local:6379"
OLLAMA_URL="ollama.medinovai.svc.cluster.local:11434"
API_GATEWAY_URL="medinovai-api-gateway.medinovai.svc.cluster.local:8080"

# Usage function
usage() {
    echo "Usage: $0 <service-name> [options]"
    echo ""
    echo "Service Names:"
    echo "  medinovai-api              - Core API service"
    echo "  medinovai-auth             - Authentication service"
    echo "  medinovai-patient-service  - Patient management service"
    echo "  medinovai-dashboard        - Frontend dashboard"
    echo "  medinovai-analytics        - Analytics service"
    echo "  medinovai-notifications    - Notification service"
    echo "  medinovai-reports          - Reporting service"
    echo "  medinovai-integrations     - Integration service"
    echo "  medinovai-workflows        - Workflow service"
    echo "  medinovai-monitoring       - Monitoring service"
    echo ""
    echo "Options:"
    echo "  --dry-run                  - Show what would be deployed"
    echo "  --validate                 - Validate manifests only"
    echo "  --help                     - Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 medinovai-api"
    echo "  $0 medinovai-auth --dry-run"
    echo "  $0 medinovai-patient-service --validate"
}

# Validate service name
validate_service() {
    local valid_services=(
        "medinovai-api"
        "medinovai-auth"
        "medinovai-patient-service"
        "medinovai-dashboard"
        "medinovai-analytics"
        "medinovai-notifications"
        "medinovai-reports"
        "medinovai-integrations"
        "medinovai-workflows"
        "medinovai-monitoring"
    )
    
    for service in "${valid_services[@]}"; do
        if [ "$SERVICE_NAME" = "$service" ]; then
            return 0
        fi
    done
    
    log_error "Invalid service name: $SERVICE_NAME"
    echo ""
    usage
    exit 1
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Check if cluster is accessible
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot access Kubernetes cluster"
        exit 1
    fi
    
    # Check if namespace exists
    if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
        log_error "Namespace '$NAMESPACE' does not exist"
        exit 1
    fi
    
    # Check if required services are running
    local required_services=("postgresql" "redis" "medinovai-api-gateway")
    for service in "${required_services[@]}"; do
        if ! kubectl get service "$service" -n "$NAMESPACE" &> /dev/null; then
            log_warning "Required service '$service' is not running in namespace '$NAMESPACE'"
        fi
    done
    
    log_success "Prerequisites check completed"
}

# Generate environment variables
generate_env_vars() {
    local service="$1"
    
    cat << EOF
# Environment Variables for $service
DATABASE_URL=postgresql://postgres:medinovai123@$POSTGRESQL_URL/medinovai
REDIS_URL=redis://:medinovai123@$REDIS_URL
OLLAMA_BASE_URL=http://$OLLAMA_URL
API_GATEWAY_URL=http://$API_GATEWAY_URL
NAMESPACE=$NAMESPACE
SERVICE_NAME=$service
EOF
}

# Generate base deployment manifest
generate_deployment_manifest() {
    local service="$1"
    local image="${2:-$service:latest}"
    
    cat << EOF
# Deployment manifest for $service
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $service
  namespace: $NAMESPACE
  labels:
    app: $service
    component: healthcare-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: $service
  template:
    metadata:
      labels:
        app: $service
        component: healthcare-service
      annotations:
        sidecar.istio.io/inject: "false"
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      containers:
      - name: $service
        image: $image
        ports:
        - containerPort: 8080
          name: http
        env:
        - name: DATABASE_URL
          value: "postgresql://postgres:medinovai123@$POSTGRESQL_URL/medinovai"
        - name: REDIS_URL
          value: "redis://:medinovai123@$REDIS_URL"
        - name: OLLAMA_BASE_URL
          value: "http://$OLLAMA_URL"
        - name: API_GATEWAY_URL
          value: "http://$API_GATEWAY_URL"
        - name: NAMESPACE
          value: "$NAMESPACE"
        - name: SERVICE_NAME
          value: "$service"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
          seccompProfile:
            type: RuntimeDefault
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
EOF
}

# Generate service manifest
generate_service_manifest() {
    local service="$1"
    
    cat << EOF
# Service manifest for $service
apiVersion: v1
kind: Service
metadata:
  name: $service
  namespace: $NAMESPACE
  labels:
    app: $service
    component: healthcare-service
spec:
  selector:
    app: $service
  ports:
  - name: http
    port: 8080
    targetPort: 8080
    protocol: TCP
  type: ClusterIP
EOF
}

# Generate network policy manifest
generate_network_policy_manifest() {
    local service="$1"
    
    cat << EOF
# Network Policy for $service
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: $service-netpol
  namespace: $NAMESPACE
spec:
  podSelector:
    matchLabels:
      app: $service
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: medinovai-api-gateway
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: postgresql
    ports:
    - protocol: TCP
      port: 5432
  - to:
    - podSelector:
        matchLabels:
          app: redis
    ports:
    - protocol: TCP
      port: 6379
  - to: []
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
EOF
}

# Generate horizontal pod autoscaler manifest
generate_hpa_manifest() {
    local service="$1"
    
    cat << EOF
# Horizontal Pod Autoscaler for $service
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: $service-hpa
  namespace: $NAMESPACE
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: $service
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
EOF
}

# Deploy service
deploy_service() {
    local service="$1"
    local dry_run="${2:-false}"
    local validate_only="${3:-false}"
    
    log_deploy "Deploying $service to MedinovAI infrastructure..."
    
    # Create temporary directory for manifests
    local temp_dir=$(mktemp -d)
    local manifest_file="$temp_dir/$service-manifests.yaml"
    
    # Generate manifests
    {
        echo "# MedinovAI $service Deployment Manifests"
        echo "# Generated: $(date)"
        echo ""
        generate_deployment_manifest "$service"
        echo ""
        echo "---"
        echo ""
        generate_service_manifest "$service"
        echo ""
        echo "---"
        echo ""
        generate_network_policy_manifest "$service"
        echo ""
        echo "---"
        echo ""
        generate_hpa_manifest "$service"
    } > "$manifest_file"
    
    if [ "$validate_only" = "true" ]; then
        log_info "Validating manifests for $service..."
        kubectl apply --dry-run=client -f "$manifest_file"
        log_success "Manifests validation completed"
        rm -rf "$temp_dir"
        return 0
    fi
    
    if [ "$dry_run" = "true" ]; then
        log_info "Dry run - showing what would be deployed:"
        cat "$manifest_file"
        rm -rf "$temp_dir"
        return 0
    fi
    
    # Apply manifests
    log_info "Applying manifests for $service..."
    kubectl apply -f "$manifest_file"
    
    # Wait for deployment to be ready
    log_info "Waiting for $service deployment to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/$service -n $NAMESPACE
    
    # Check deployment status
    log_info "Checking deployment status..."
    kubectl get deployment $service -n $NAMESPACE
    kubectl get pods -l app=$service -n $NAMESPACE
    
    # Test health endpoint
    log_info "Testing health endpoint..."
    local pod_name=$(kubectl get pods -l app=$service -n $NAMESPACE -o jsonpath='{.items[0].metadata.name}')
    if [ -n "$pod_name" ]; then
        kubectl exec $pod_name -n $NAMESPACE -- curl -f http://localhost:8080/health || log_warning "Health check failed"
    fi
    
    log_success "$service deployed successfully!"
    
    # Cleanup
    rm -rf "$temp_dir"
}

# Main execution
main() {
    # Parse arguments
    local dry_run=false
    local validate_only=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                dry_run=true
                shift
                ;;
            --validate)
                validate_only=true
                shift
                ;;
            --help)
                usage
                exit 0
                ;;
            *)
                if [ -z "$SERVICE_NAME" ]; then
                    SERVICE_NAME="$1"
                fi
                shift
                ;;
        esac
    done
    
    # Validate service name
    if [ -z "$SERVICE_NAME" ]; then
        log_error "Service name is required"
        echo ""
        usage
        exit 1
    fi
    
    validate_service
    
    # Check prerequisites
    check_prerequisites
    
    # Deploy service
    deploy_service "$SERVICE_NAME" "$dry_run" "$validate_only"
    
    # Show environment variables
    log_info "Environment variables for $SERVICE_NAME:"
    generate_env_vars "$SERVICE_NAME"
    
    log_success "🎉 Deployment completed successfully!"
    echo ""
    echo "📊 Next Steps:"
    echo "  1. Verify service is running: kubectl get pods -l app=$SERVICE_NAME -n $NAMESPACE"
    echo "  2. Check service logs: kubectl logs -l app=$SERVICE_NAME -n $NAMESPACE"
    echo "  3. Test health endpoint: kubectl port-forward svc/$SERVICE_NAME 8080:8080 -n $NAMESPACE"
    echo "  4. Monitor metrics: kubectl get hpa $SERVICE_NAME-hpa -n $NAMESPACE"
    echo ""
    echo "🔗 Useful Commands:"
    echo "  kubectl get all -l app=$SERVICE_NAME -n $NAMESPACE"
    echo "  kubectl describe deployment $SERVICE_NAME -n $NAMESPACE"
    echo "  kubectl logs -f deployment/$SERVICE_NAME -n $NAMESPACE"
}

# Run main function
main "$@"
