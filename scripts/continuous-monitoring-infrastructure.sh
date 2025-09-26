#!/bin/bash

# 🔍 Continuous Monitoring Infrastructure Deployment Script
# Deploys comprehensive monitoring infrastructure for MedinovAI deployment tracking

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="medinovai-monitoring"
CLUSTER_NAME="medinovai-cluster"
MONITORING_VERSION="v0.68.0"
GRAFANA_VERSION="6.63.0"
PROMETHEUS_VERSION="25.8.0"
ALERTMANAGER_VERSION="v0.25.0"

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

print_header() {
    echo -e "${PURPLE}[HEADER]${NC} $1"
}

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_header "🔍 Checking Prerequisites for Continuous Monitoring Infrastructure"
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        print_error "helm is not installed. Please install helm first."
        exit 1
    fi
    
    # Check if Kubernetes cluster is accessible
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Kubernetes cluster is not accessible. Please ensure your cluster is running."
        exit 1
    fi
    
    # Check if k3d cluster exists
    if ! k3d cluster list | grep -q "$CLUSTER_NAME"; then
        print_error "k3d cluster '$CLUSTER_NAME' not found. Please create the cluster first."
        exit 1
    fi
    
    print_success "Prerequisites check completed"
}

# Function to create monitoring namespace
create_monitoring_namespace() {
    print_step "Creating monitoring namespace"
    
    if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
        print_status "Creating namespace '$NAMESPACE'..."
        kubectl create namespace "$NAMESPACE"
        print_success "Namespace '$NAMESPACE' created"
    else
        print_status "Namespace '$NAMESPACE' already exists"
    fi
    
    # Label namespace for monitoring
    kubectl label namespace "$NAMESPACE" monitoring=enabled --overwrite
    kubectl label namespace "$NAMESPACE" istio-injection=enabled --overwrite
}

# Function to add Prometheus Helm repository
setup_helm_repositories() {
    print_step "Setting up Helm repositories"
    
    # Add Prometheus Community Helm repository
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    
    # Update Helm repositories
    helm repo update
    
    print_success "Helm repositories configured"
}

# Function to deploy Prometheus
deploy_prometheus() {
    print_step "Deploying Prometheus"
    
    # Create Prometheus values file
    cat > /tmp/prometheus-values.yaml << EOF
server:
  persistentVolume:
    enabled: false
  resources:
    requests:
      cpu: 200m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 512Mi

alertmanager:
  enabled: true
  persistentVolume:
    enabled: false
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 200m
      memory: 256Mi

pushgateway:
  enabled: true
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 100m
      memory: 128Mi

nodeExporter:
  enabled: true

kubeStateMetrics:
  enabled: true

serviceMonitor:
  enabled: true

ruleSelector:
  matchLabels:
    app: prometheus

alerting:
  alertmanagers:
    - namespace: $NAMESPACE
      name: prometheus-alertmanager
      port: 9093

additionalScrapeConfigs:
  - job_name: 'medinovai-services'
    kubernetes_sd_configs:
      - role: endpoints
        namespaces:
          names:
            - medinovai
    relabel_configs:
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: \$1:\$2
        target_label: __address__
      - action: labelmap
        regex: __meta_kubernetes_service_label_(.+)
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: kubernetes_namespace
      - source_labels: [__meta_kubernetes_service_name]
        action: replace
        target_label: kubernetes_name
EOF

    # Deploy Prometheus
    helm upgrade --install prometheus prometheus-community/prometheus \
        --namespace "$NAMESPACE" \
        --values /tmp/prometheus-values.yaml \
        --wait --timeout=10m
    
    print_success "Prometheus deployed successfully"
}

# Function to deploy Grafana
deploy_grafana() {
    print_step "Deploying Grafana"
    
    # Create Grafana values file
    cat > /tmp/grafana-values.yaml << EOF
persistence:
  enabled: false

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 200m
    memory: 256Mi

service:
  type: ClusterIP
  port: 3000

ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: istio
    istio.ingressgateway: medinovai-gateway
  hosts:
    - grafana.medinovai.local
  tls:
    - secretName: grafana-tls
      hosts:
        - grafana.medinovai.local

adminPassword: admin123

datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
      - name: Prometheus
        type: prometheus
        url: http://prometheus-server:80
        access: proxy
        isDefault: true
      - name: Loki
        type: loki
        url: http://loki:3100
        access: proxy

dashboardProviders:
  dashboardproviders.yaml:
    apiVersion: 1
    providers:
      - name: 'default'
        orgId: 1
        folder: ''
        type: file
        disableDeletion: false
        editable: true
        options:
          path: /var/lib/grafana/dashboards/default

dashboards:
  default:
    medinovai-overview:
      gnetId: 1860
      revision: 27
      datasource: Prometheus
    kubernetes-cluster:
      gnetId: 7249
      revision: 1
      datasource: Prometheus
    kubernetes-pods:
      gnetId: 6417
      revision: 1
      datasource: Prometheus
EOF

    # Deploy Grafana
    helm upgrade --install grafana grafana/grafana \
        --namespace "$NAMESPACE" \
        --values /tmp/grafana-values.yaml \
        --wait --timeout=10m
    
    print_success "Grafana deployed successfully"
}

# Function to deploy Loki
deploy_loki() {
    print_step "Deploying Loki"
    
    # Create Loki values file
    cat > /tmp/loki-values.yaml << EOF
loki:
  persistence:
    enabled: false
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 200m
      memory: 256Mi

promtail:
  enabled: true
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 100m
      memory: 128Mi

service:
  type: ClusterIP
  port: 3100
EOF

    # Deploy Loki
    helm upgrade --install loki grafana/loki-stack \
        --namespace "$NAMESPACE" \
        --values /tmp/loki-values.yaml \
        --wait --timeout=10m
    
    print_success "Loki deployed successfully"
}

# Function to deploy AlertManager
deploy_alertmanager() {
    print_step "Deploying AlertManager"
    
    # Create AlertManager configuration
    cat > /tmp/alertmanager-config.yaml << EOF
global:
  smtp_smarthost: 'localhost:587'
  smtp_from: 'alerts@medinovai.com'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'

receivers:
  - name: 'web.hook'
    webhook_configs:
      - url: 'http://localhost:5001/'

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']
EOF

    # Create AlertManager ConfigMap
    kubectl create configmap alertmanager-config \
        --from-file=alertmanager.yml=/tmp/alertmanager-config.yaml \
        --namespace "$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    print_success "AlertManager configured"
}

# Function to create monitoring dashboards
create_monitoring_dashboards() {
    print_step "Creating monitoring dashboards"
    
    # Create MedinovAI specific dashboard
    cat > /tmp/medinovai-dashboard.json << EOF
{
  "dashboard": {
    "id": null,
    "title": "MedinovAI Infrastructure Overview",
    "tags": ["medinovai", "infrastructure"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Pod Status",
        "type": "stat",
        "targets": [
          {
            "expr": "count(kube_pod_status_phase{namespace=\"medinovai\"})",
            "legendFormat": "Total Pods"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "thresholds": {
              "steps": [
                {"color": "red", "value": 0},
                {"color": "yellow", "value": 10},
                {"color": "green", "value": 20}
              ]
            }
          }
        }
      },
      {
        "id": 2,
        "title": "CPU Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(container_cpu_usage_seconds_total{namespace=\"medinovai\"}[5m])",
            "legendFormat": "{{pod}}"
          }
        ]
      },
      {
        "id": 3,
        "title": "Memory Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "container_memory_usage_bytes{namespace=\"medinovai\"}",
            "legendFormat": "{{pod}}"
          }
        ]
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "30s"
  }
}
EOF

    # Apply dashboard
    kubectl create configmap medinovai-dashboard \
        --from-file=medinovai-dashboard.json \
        --namespace "$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    print_success "Monitoring dashboards created"
}

# Function to create monitoring alerts
create_monitoring_alerts() {
    print_step "Creating monitoring alerts"
    
    # Create PrometheusRule for MedinovAI alerts
    cat > /tmp/medinovai-alerts.yaml << EOF
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: medinovai-alerts
  namespace: $NAMESPACE
  labels:
    app: prometheus
spec:
  groups:
  - name: medinovai.rules
    rules:
    - alert: MedinovAIPodDown
      expr: kube_pod_status_phase{namespace="medinovai", phase!="Running"} > 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "MedinovAI pod is down"
        description: "Pod {{ \$labels.pod }} in namespace {{ \$labels.namespace }} is not running"
    
    - alert: MedinovAIHighCPU
      expr: rate(container_cpu_usage_seconds_total{namespace="medinovai"}[5m]) > 0.8
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High CPU usage in MedinovAI"
        description: "Pod {{ \$labels.pod }} has high CPU usage: {{ \$value }}"
    
    - alert: MedinovAIHighMemory
      expr: container_memory_usage_bytes{namespace="medinovai"} / container_spec_memory_limit_bytes > 0.8
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High memory usage in MedinovAI"
        description: "Pod {{ \$labels.pod }} has high memory usage: {{ \$value }}"
    
    - alert: MedinovAIServiceDown
      expr: up{job=~"medinovai-.*"} == 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "MedinovAI service is down"
        description: "Service {{ \$labels.job }} is not responding"
EOF

    # Apply alerts
    kubectl apply -f /tmp/medinovai-alerts.yaml
    
    print_success "Monitoring alerts created"
}

# Function to create monitoring service monitors
create_service_monitors() {
    print_step "Creating service monitors"
    
    # Create ServiceMonitor for MedinovAI services
    cat > /tmp/medinovai-service-monitor.yaml << EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: medinovai-services
  namespace: $NAMESPACE
  labels:
    app: prometheus
spec:
  selector:
    matchLabels:
      monitoring: enabled
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
  namespaceSelector:
    matchNames:
    - medinovai
EOF

    # Apply ServiceMonitor
    kubectl apply -f /tmp/medinovai-service-monitor.yaml
    
    print_success "Service monitors created"
}

# Function to validate monitoring deployment
validate_monitoring_deployment() {
    print_step "Validating monitoring deployment"
    
    # Check Prometheus
    if kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=prometheus | grep -q "Running"; then
        print_success "✅ Prometheus is running"
    else
        print_error "❌ Prometheus is not running"
        return 1
    fi
    
    # Check Grafana
    if kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=grafana | grep -q "Running"; then
        print_success "✅ Grafana is running"
    else
        print_error "❌ Grafana is not running"
        return 1
    fi
    
    # Check Loki
    if kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=loki | grep -q "Running"; then
        print_success "✅ Loki is running"
    else
        print_error "❌ Loki is not running"
        return 1
    fi
    
    # Check AlertManager
    if kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=alertmanager | grep -q "Running"; then
        print_success "✅ AlertManager is running"
    else
        print_error "❌ AlertManager is not running"
        return 1
    fi
    
    print_success "Monitoring deployment validation completed"
}

# Function to show monitoring access information
show_monitoring_access() {
    print_header "📊 Monitoring Access Information"
    
    echo ""
    print_status "Monitoring Services Status:"
    kubectl get pods -n "$NAMESPACE" -o wide
    
    echo ""
    print_status "Monitoring Services:"
    kubectl get svc -n "$NAMESPACE"
    
    echo ""
    print_status "Access URLs (via port-forward):"
    echo "  Grafana:     kubectl port-forward -n $NAMESPACE svc/grafana 3000:80"
    echo "  Prometheus:  kubectl port-forward -n $NAMESPACE svc/prometheus-server 9090:80"
    echo "  AlertManager: kubectl port-forward -n $NAMESPACE svc/prometheus-alertmanager 9093:80"
    echo "  Loki:        kubectl port-forward -n $NAMESPACE svc/loki 3100:3100"
    
    echo ""
    print_status "Default Credentials:"
    echo "  Grafana: admin / admin123"
    
    echo ""
    print_status "Monitoring Dashboards:"
    echo "  - MedinovAI Infrastructure Overview"
    echo "  - Kubernetes Cluster Monitoring"
    echo "  - Pod and Service Monitoring"
    echo "  - Resource Usage Monitoring"
    
    echo ""
    print_status "Alerting Rules:"
    echo "  - Pod Down Alerts"
    echo "  - High CPU Usage Alerts"
    echo "  - High Memory Usage Alerts"
    echo "  - Service Down Alerts"
}

# Function to create monitoring cleanup script
create_monitoring_cleanup() {
    print_step "Creating monitoring cleanup script"
    
    cat > /tmp/cleanup-monitoring.sh << 'EOF'
#!/bin/bash
# Cleanup script for monitoring infrastructure

NAMESPACE="medinovai-monitoring"

echo "Cleaning up monitoring infrastructure..."

# Delete Helm releases
helm uninstall prometheus -n $NAMESPACE || true
helm uninstall grafana -n $NAMESPACE || true
helm uninstall loki -n $NAMESPACE || true

# Delete namespace
kubectl delete namespace $NAMESPACE || true

echo "Monitoring cleanup completed"
EOF

    chmod +x /tmp/cleanup-monitoring.sh
    print_success "Cleanup script created at /tmp/cleanup-monitoring.sh"
}

# Main execution function
main() {
    print_header "🚀 MedinovAI Continuous Monitoring Infrastructure Deployment"
    echo "================================================================"
    echo ""
    
    check_prerequisites
    create_monitoring_namespace
    setup_helm_repositories
    deploy_prometheus
    deploy_grafana
    deploy_loki
    deploy_alertmanager
    create_monitoring_dashboards
    create_monitoring_alerts
    create_service_monitors
    validate_monitoring_deployment
    create_monitoring_cleanup
    show_monitoring_access
    
    echo ""
    print_success "🎉 Continuous monitoring infrastructure deployed successfully!"
    print_status "Next steps:"
    echo "  1. Access Grafana: kubectl port-forward -n $NAMESPACE svc/grafana 3000:80"
    echo "  2. Access Prometheus: kubectl port-forward -n $NAMESPACE svc/prometheus-server 9090:80"
    echo "  3. Configure additional dashboards and alerts as needed"
    echo "  4. Monitor deployment progress in real-time"
    echo ""
}

# Run main function
main "$@"
