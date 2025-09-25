#!/bin/bash

# MedinovAI Monitoring Setup Script
# This script sets up comprehensive monitoring for all deployed services

set -euo pipefail

# Configuration
MEDINOVAI_NAMESPACE="medinovai"
GRAFANA_ADMIN_PASSWORD="medinovai123"
PROMETHEUS_RETENTION="30d"
LOKI_RETENTION="7d"

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

log_monitor() {
    echo -e "${PURPLE}📊 $1${NC}"
}

# Setup Grafana dashboards
setup_grafana_dashboards() {
    log_monitor "Setting up Grafana dashboards..."
    
    # Create dashboard configmap
    kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboards
  namespace: $MEDINOVAI_NAMESPACE
data:
  medinovai-overview.json: |
    {
      "dashboard": {
        "id": null,
        "title": "MedinovAI Overview",
        "tags": ["medinovai"],
        "style": "dark",
        "timezone": "browser",
        "panels": [
          {
            "id": 1,
            "title": "System Overview",
            "type": "stat",
            "targets": [
              {
                "expr": "up{namespace=\"$MEDINOVAI_NAMESPACE\"}",
                "legendFormat": "Services Up"
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
                    {"color": "green", "value": 1}
                  ]
                }
              }
            },
            "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
          },
          {
            "id": 2,
            "title": "CPU Usage",
            "type": "graph",
            "targets": [
              {
                "expr": "rate(container_cpu_usage_seconds_total{namespace=\"$MEDINOVAI_NAMESPACE\"}[5m])",
                "legendFormat": "{{pod}}"
              }
            ],
            "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
          },
          {
            "id": 3,
            "title": "Memory Usage",
            "type": "graph",
            "targets": [
              {
                "expr": "container_memory_usage_bytes{namespace=\"$MEDINOVAI_NAMESPACE\"}",
                "legendFormat": "{{pod}}"
              }
            ],
            "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8}
          },
          {
            "id": 4,
            "title": "Network I/O",
            "type": "graph",
            "targets": [
              {
                "expr": "rate(container_network_receive_bytes_total{namespace=\"$MEDINOVAI_NAMESPACE\"}[5m])",
                "legendFormat": "{{pod}} RX"
              },
              {
                "expr": "rate(container_network_transmit_bytes_total{namespace=\"$MEDINOVAI_NAMESPACE\"}[5m])",
                "legendFormat": "{{pod}} TX"
              }
            ],
            "gridPos": {"h": 8, "w": 12, "x": 12, "y": 8}
          }
        ],
        "time": {
          "from": "now-1h",
          "to": "now"
        },
        "refresh": "30s"
      }
    }
  medinovai-services.json: |
    {
      "dashboard": {
        "id": null,
        "title": "MedinovAI Services",
        "tags": ["medinovai", "services"],
        "style": "dark",
        "timezone": "browser",
        "panels": [
          {
            "id": 1,
            "title": "Service Health",
            "type": "table",
            "targets": [
              {
                "expr": "up{namespace=\"$MEDINOVAI_NAMESPACE\"}",
                "format": "table",
                "instant": true
              }
            ],
            "gridPos": {"h": 8, "w": 24, "x": 0, "y": 0}
          },
          {
            "id": 2,
            "title": "Request Rate",
            "type": "graph",
            "targets": [
              {
                "expr": "rate(http_requests_total{namespace=\"$MEDINOVAI_NAMESPACE\"}[5m])",
                "legendFormat": "{{service}}"
              }
            ],
            "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8}
          },
          {
            "id": 3,
            "title": "Response Time",
            "type": "graph",
            "targets": [
              {
                "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{namespace=\"$MEDINOVAI_NAMESPACE\"}[5m]))",
                "legendFormat": "{{service}} 95th percentile"
              }
            ],
            "gridPos": {"h": 8, "w": 12, "x": 12, "y": 8}
          }
        ],
        "time": {
          "from": "now-1h",
          "to": "now"
        },
        "refresh": "30s"
      }
    }
  medinovai-ai-ml.json: |
    {
      "dashboard": {
        "id": null,
        "title": "MedinovAI AI/ML Services",
        "tags": ["medinovai", "ai-ml"],
        "style": "dark",
        "timezone": "browser",
        "panels": [
          {
            "id": 1,
            "title": "Ollama Models",
            "type": "stat",
            "targets": [
              {
                "expr": "ollama_models_loaded",
                "legendFormat": "Models Loaded"
              }
            ],
            "gridPos": {"h": 8, "w": 6, "x": 0, "y": 0}
          },
          {
            "id": 2,
            "title": "Model Inference Rate",
            "type": "graph",
            "targets": [
              {
                "expr": "rate(ollama_inference_requests_total[5m])",
                "legendFormat": "{{model}}"
              }
            ],
            "gridPos": {"h": 8, "w": 18, "x": 6, "y": 0}
          },
          {
            "id": 3,
            "title": "Vector Database Operations",
            "type": "graph",
            "targets": [
              {
                "expr": "rate(qdrant_operations_total[5m])",
                "legendFormat": "{{operation}}"
              }
            ],
            "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8}
          },
          {
            "id": 4,
            "title": "AI/ML Memory Usage",
            "type": "graph",
            "targets": [
              {
                "expr": "container_memory_usage_bytes{namespace=\"$MEDINOVAI_NAMESPACE\", pod=~\"ollama-.*|qdrant-.*\"}",
                "legendFormat": "{{pod}}"
              }
            ],
            "gridPos": {"h": 8, "w": 12, "x": 12, "y": 8}
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

    log_success "Grafana dashboards configured"
}

# Setup Prometheus rules
setup_prometheus_rules() {
    log_monitor "Setting up Prometheus alerting rules..."
    
    kubectl apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: medinovai-alerts
  namespace: $MEDINOVAI_NAMESPACE
spec:
  groups:
  - name: medinovai-system
    rules:
    - alert: MedinovAIServiceDown
      expr: up{namespace="$MEDINOVAI_NAMESPACE"} == 0
      for: 1m
      labels:
        severity: critical
        service: "{{ \$labels.job }}"
      annotations:
        summary: "MedinovAI service is down"
        description: "Service {{ \$labels.job }} has been down for more than 1 minute"
    
    - alert: MedinovAIHighCPU
      expr: rate(container_cpu_usage_seconds_total{namespace="$MEDINOVAI_NAMESPACE"}[5m]) > 0.8
      for: 5m
      labels:
        severity: warning
        service: "{{ \$labels.pod }}"
      annotations:
        summary: "MedinovAI service high CPU usage"
        description: "Service {{ \$labels.pod }} CPU usage is above 80% for more than 5 minutes"
    
    - alert: MedinovAIHighMemory
      expr: container_memory_usage_bytes{namespace="$MEDINOVAI_NAMESPACE"} / container_spec_memory_limit_bytes > 0.85
      for: 5m
      labels:
        severity: warning
        service: "{{ \$labels.pod }}"
      annotations:
        summary: "MedinovAI service high memory usage"
        description: "Service {{ \$labels.pod }} memory usage is above 85% for more than 5 minutes"
    
    - alert: MedinovAIPodCrashLooping
      expr: rate(kube_pod_container_status_restarts_total{namespace="$MEDINOVAI_NAMESPACE"}[15m]) > 0
      for: 5m
      labels:
        severity: critical
        service: "{{ \$labels.pod }}"
      annotations:
        summary: "MedinovAI pod is crash looping"
        description: "Pod {{ \$labels.pod }} is restarting frequently"
    
    - alert: MedinovAIDiskSpaceLow
      expr: (node_filesystem_avail_bytes{namespace="$MEDINOVAI_NAMESPACE"} / node_filesystem_size_bytes) < 0.1
      for: 5m
      labels:
        severity: warning
        node: "{{ \$labels.instance }}"
      annotations:
        summary: "MedinovAI node disk space low"
        description: "Node {{ \$labels.instance }} disk space is below 10%"
    
    - alert: MedinovAINetworkErrors
      expr: rate(container_network_receive_errors_total{namespace="$MEDINOVAI_NAMESPACE"}[5m]) > 0.1
      for: 5m
      labels:
        severity: warning
        service: "{{ \$labels.pod }}"
      annotations:
        summary: "MedinovAI service network errors"
        description: "Service {{ \$labels.pod }} has network receive errors"
  
  - name: medinovai-ai-ml
    rules:
    - alert: OllamaModelUnavailable
      expr: ollama_models_loaded == 0
      for: 2m
      labels:
        severity: critical
        service: "ollama"
      annotations:
        summary: "Ollama models are not loaded"
        description: "No Ollama models are currently loaded"
    
    - alert: OllamaHighLatency
      expr: histogram_quantile(0.95, rate(ollama_inference_duration_seconds_bucket[5m])) > 10
      for: 5m
      labels:
        severity: warning
        service: "ollama"
      annotations:
        summary: "Ollama inference latency is high"
        description: "Ollama 95th percentile inference latency is above 10 seconds"
    
    - alert: QdrantHighMemoryUsage
      expr: container_memory_usage_bytes{pod=~"qdrant-.*"} / container_spec_memory_limit_bytes > 0.9
      for: 5m
      labels:
        severity: warning
        service: "qdrant"
      annotations:
        summary: "Qdrant memory usage is high"
        description: "Qdrant memory usage is above 90%"
  
  - name: medinovai-database
    rules:
    - alert: DatabaseConnectionHigh
      expr: rate(database_connections_total{namespace="$MEDINOVAI_NAMESPACE"}[5m]) > 100
      for: 5m
      labels:
        severity: warning
        service: "{{ \$labels.database }}"
      annotations:
        summary: "Database connection rate is high"
        description: "Database {{ \$labels.database }} connection rate is above 100/sec"
    
    - alert: DatabaseSlowQueries
      expr: rate(database_slow_queries_total{namespace="$MEDINOVAI_NAMESPACE"}[5m]) > 1
      for: 5m
      labels:
        severity: warning
        service: "{{ \$labels.database }}"
      annotations:
        summary: "Database slow queries detected"
        description: "Database {{ \$labels.database }} has slow queries"
    
    - alert: RedisMemoryHigh
      expr: redis_memory_used_bytes / redis_memory_max_bytes > 0.9
      for: 5m
      labels:
        severity: warning
        service: "redis"
      annotations:
        summary: "Redis memory usage is high"
        description: "Redis memory usage is above 90%"
EOF

    log_success "Prometheus alerting rules configured"
}

# Setup Loki configuration
setup_loki_configuration() {
    log_monitor "Setting up Loki configuration..."
    
    kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: loki-config
  namespace: $MEDINOVAI_NAMESPACE
data:
  loki.yaml: |
    auth_enabled: false
    server:
      http_listen_port: 3100
      grpc_listen_port: 9096
    common:
      path_prefix: /loki
      storage:
        filesystem:
          chunks_directory: /loki/chunks
          rules_directory: /loki/rules
      replication_factor: 1
      ring:
        instance_addr: 127.0.0.1
        kvstore:
          store: inmemory
    query_scheduler:
      max_outstanding_requests_per_tenant: 2048
    schema_config:
      configs:
        - from: 2020-10-24
          store: boltdb-shipper
          object_store: filesystem
          schema: v11
          index:
            prefix: index_
            period: 24h
    storage_config:
      boltdb_shipper:
        active_index_directory: /loki/boltdb-shipper-active
        cache_location: /loki/boltdb-shipper-cache
        cache_ttl: 24h
        shared_store: filesystem
      filesystem:
        directory: /loki/chunks
    compactor:
      working_directory: /loki/boltdb-shipper-compactor
      shared_store: filesystem
    limits_config:
      reject_old_samples: true
      reject_old_samples_max_age: 168h
      max_cache_freshness_per_query: 10m
      split_queries_by_interval: 15m
      max_query_parallelism: 32
      max_streams_per_user: 0
      max_line_size: 256000
      max_entries_limit_per_query: 5000
      max_query_series: 1000
      max_query_lookback: 0s
      max_query_length: 721h
      max_query_parallelism: 32
      cardinality_limit: 100000
      max_streams_matchers_per_query: 1000
      max_concurrent_tail_requests: 10
      max_cache_freshness_per_query: 1m
      max_queriers_per_tenant: 0
      ruler:
        max_rules_per_rule_group: 0
        max_rule_groups_per_tenant: 0
    chunk_store_config:
      max_look_back_period: 0s
    table_manager:
      retention_deletes_enabled: true
      retention_period: $LOKI_RETENTION
    ruler:
      storage:
        type: local
        local:
          directory: /loki/rules
      rule_path: /loki/rules-temp
      alertmanager_url: http://localhost:9093
      ring:
        kvstore:
          store: inmemory
      enable_api: true
EOF

    log_success "Loki configuration completed"
}

# Setup Tempo configuration
setup_tempo_configuration() {
    log_monitor "Setting up Tempo configuration..."
    
    kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: tempo-config
  namespace: $MEDINOVAI_NAMESPACE
data:
  tempo.yaml: |
    server:
      http_listen_port: 3200
    distributor:
      receivers:
        jaeger:
          protocols:
            thrift_http:
            grpc:
            thrift_binary:
            thrift_compact:
        zipkin:
        otlp:
          protocols:
            grpc:
            http:
        opencensus:
    ingester:
      max_block_duration: 5m
    compactor:
      compaction:
        block_retention: 1h
    storage:
      trace:
        backend: local
        local:
          path: /var/tempo/traces
        pool:
          max_workers: 100
          queue_depth: 10000
    overrides:
      defaults:
        per_tenant_override_config: /etc/tempo/overrides.yaml
EOF

    log_success "Tempo configuration completed"
}

# Setup Jaeger configuration
setup_jaeger_configuration() {
    log_monitor "Setting up Jaeger configuration..."
    
    kubectl apply -f - <<EOF
apiVersion: jaegertracing.io/v1
kind: Jaeger
metadata:
  name: medinovai-jaeger
  namespace: $MEDINOVAI_NAMESPACE
spec:
  strategy: production
  collector:
    maxReplicas: 5
    resources:
      limits:
        cpu: 500m
        memory: 512Mi
      requests:
        cpu: 100m
        memory: 128Mi
  query:
    replicas: 2
    resources:
      limits:
        cpu: 200m
        memory: 256Mi
      requests:
        cpu: 100m
        memory: 128Mi
  storage:
    type: elasticsearch
    elasticsearch:
      nodeCount: 1
      resources:
        limits:
          cpu: 1000m
          memory: 1Gi
        requests:
          cpu: 500m
          memory: 512Mi
      storage:
        storageClassName: standard
        size: 10Gi
EOF

    log_success "Jaeger configuration completed"
}

# Setup ServiceMonitor for all services
setup_servicemonitors() {
    log_monitor "Setting up ServiceMonitors for all services..."
    
    # Create ServiceMonitor for MedinovAI services
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
    scrapeTimeout: 10s
  - port: health
    path: /health
    interval: 30s
    scrapeTimeout: 5s
EOF

    # Create ServiceMonitor for database services
    kubectl apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: medinovai-databases
  namespace: $MEDINOVAI_NAMESPACE
spec:
  selector:
    matchLabels:
      app: postgres
  endpoints:
  - port: postgres
    path: /metrics
    interval: 30s
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: medinovai-redis
  namespace: $MEDINOVAI_NAMESPACE
spec:
  selector:
    matchLabels:
      app: redis
  endpoints:
  - port: redis
    path: /metrics
    interval: 30s
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: medinovai-mongodb
  namespace: $MEDINOVAI_NAMESPACE
spec:
  selector:
    matchLabels:
      app: mongodb
  endpoints:
  - port: mongodb
    path: /metrics
    interval: 30s
EOF

    # Create ServiceMonitor for AI/ML services
    kubectl apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: medinovai-ollama
  namespace: $MEDINOVAI_NAMESPACE
spec:
  selector:
    matchLabels:
      app: ollama
  endpoints:
  - port: http
    path: /metrics
    interval: 30s
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: medinovai-qdrant
  namespace: $MEDINOVAI_NAMESPACE
spec:
  selector:
    matchLabels:
      app: qdrant
  endpoints:
  - port: http
    path: /metrics
    interval: 30s
EOF

    log_success "ServiceMonitors configured"
}

# Setup Grafana datasources
setup_grafana_datasources() {
    log_monitor "Setting up Grafana datasources..."
    
    kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-datasources
  namespace: $MEDINOVAI_NAMESPACE
data:
  datasources.yaml: |
    apiVersion: 1
    datasources:
    - name: Prometheus
      type: prometheus
      access: proxy
      url: http://prometheus-server:80
      isDefault: true
      editable: true
    - name: Loki
      type: loki
      access: proxy
      url: http://loki:3100
      editable: true
    - name: Tempo
      type: tempo
      access: proxy
      url: http://tempo:3200
      editable: true
    - name: Jaeger
      type: jaeger
      access: proxy
      url: http://medinovai-jaeger-query:16686
      editable: true
EOF

    log_success "Grafana datasources configured"
}

# Setup alerting
setup_alerting() {
    log_monitor "Setting up alerting configuration..."
    
    # Create Alertmanager configuration
    kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: alertmanager-config
  namespace: $MEDINOVAI_NAMESPACE
data:
  alertmanager.yml: |
    global:
      smtp_smarthost: 'localhost:587'
      smtp_from: 'alerts@medinovai.com'
    
    route:
      group_by: ['alertname']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 1h
      receiver: 'web.hook'
      routes:
      - match:
          severity: critical
        receiver: 'critical-alerts'
      - match:
          severity: warning
        receiver: 'warning-alerts'
    
    receivers:
    - name: 'web.hook'
      webhook_configs:
      - url: 'http://localhost:5001/'
    
    - name: 'critical-alerts'
      email_configs:
      - to: 'admin@medinovai.com'
        subject: 'CRITICAL: MedinovAI Alert'
        body: |
          Alert: {{ .GroupLabels.alertname }}
          Description: {{ .CommonAnnotations.description }}
          Severity: {{ .CommonLabels.severity }}
          Service: {{ .CommonLabels.service }}
    
    - name: 'warning-alerts'
      email_configs:
      - to: 'ops@medinovai.com'
        subject: 'WARNING: MedinovAI Alert'
        body: |
          Alert: {{ .GroupLabels.alertname }}
          Description: {{ .CommonAnnotations.description }}
          Severity: {{ .CommonLabels.severity }}
          Service: {{ .CommonLabels.service }}
EOF

    log_success "Alerting configuration completed"
}

# Setup log aggregation
setup_log_aggregation() {
    log_monitor "Setting up log aggregation..."
    
    # Create Fluentd configuration for log collection
    kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
  namespace: $MEDINOVAI_NAMESPACE
data:
  fluent.conf: |
    <source>
      @type tail
      path /var/log/containers/*.log
      pos_file /var/log/fluentd-containers.log.pos
      tag kubernetes.*
      format json
      time_key time
      time_format %Y-%m-%dT%H:%M:%S.%NZ
    </source>
    
    <filter kubernetes.**>
      @type kubernetes_metadata
    </filter>
    
    <match kubernetes.**>
      @type loki
      url http://loki:3100
      flush_interval 1s
      flush_at_shutdown true
      buffer_chunk_limit 1m
      <label>
        stream
        container_name
        namespace
        pod_name
      </label>
    </match>
EOF

    # Create Fluentd DaemonSet
    kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
  namespace: $MEDINOVAI_NAMESPACE
spec:
  selector:
    matchLabels:
      name: fluentd
  template:
    metadata:
      labels:
        name: fluentd
    spec:
      serviceAccountName: fluentd
      containers:
      - name: fluentd
        image: fluent/fluentd-kubernetes-daemonset:v1-debian-loki
        env:
        - name: FLUENT_LOKI_URL
          value: "http://loki:3100"
        - name: FLUENT_LOKI_USERNAME
          value: ""
        - name: FLUENT_LOKI_PASSWORD
          value: ""
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 200Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
        - name: fluentd-config
          mountPath: /fluentd/etc
      terminationGracePeriodSeconds: 30
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
      - name: fluentd-config
        configMap:
          name: fluentd-config
EOF

    log_success "Log aggregation configured"
}

# Main execution
main() {
    echo "📊 MedinovAI Monitoring Setup"
    echo "============================"
    echo "Namespace: $MEDINOVAI_NAMESPACE"
    echo "Grafana Admin Password: $GRAFANA_ADMIN_PASSWORD"
    echo "Prometheus Retention: $PROMETHEUS_RETENTION"
    echo "Loki Retention: $LOKI_RETENTION"
    echo "Date: $(date)"
    echo ""
    
    # Setup monitoring components
    setup_grafana_dashboards
    setup_prometheus_rules
    setup_loki_configuration
    setup_tempo_configuration
    setup_jaeger_configuration
    setup_servicemonitors
    setup_grafana_datasources
    setup_alerting
    setup_log_aggregation
    
    echo ""
    log_success "🎉 MedinovAI monitoring setup completed successfully!"
    echo ""
    echo "📊 Monitoring Components:"
    echo "  📈 Prometheus: Metrics collection and alerting"
    echo "  📊 Grafana: Dashboards and visualization"
    echo "  📝 Loki: Log aggregation and analysis"
    echo "  🔍 Tempo: Distributed tracing"
    echo "  🕵️  Jaeger: Trace analysis and debugging"
    echo "  🚨 Alertmanager: Alert routing and notification"
    echo "  📋 ServiceMonitors: Automatic service discovery"
    echo "  📊 Custom Dashboards: MedinovAI-specific monitoring"
    echo ""
    echo "🌐 Access URLs:"
    echo "  📊 Grafana: http://localhost:3000 (admin/$GRAFANA_ADMIN_PASSWORD)"
    echo "  📈 Prometheus: http://localhost:9090"
    echo "  🔍 Jaeger: http://localhost:16686"
    echo "  📝 Loki: http://localhost:3100"
    echo ""
    echo "🚀 Next Steps:"
    echo "  1. Access Grafana and import dashboards"
    echo "  2. Configure alert notifications"
    echo "  3. Set up log retention policies"
    echo "  4. Configure trace sampling"
    echo "  5. Test alerting rules"
}

# Run main function
main "$@"








