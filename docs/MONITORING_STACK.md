# Monitoring & Observability Architecture

## Four-Layer Monitoring

| Layer | What It Monitors | Tools | Alert Channel |
|-------|-----------------|-------|---------------|
| Infrastructure | CPU, memory, disk, network, IaC drift, cost | CloudWatch, Terraform | P2-P3 |
| Platform | Cluster health, node pressure, pod restarts, HPA | Prometheus, Grafana | P2-P3 |
| Application | Request latency, error rates, traces, logs | OpenTelemetry, Jaeger, Loki | P1-P3 |
| AI/ML | Inference latency, prediction drift, bias, cost | Custom metrics, model registry | P1-P3 |

## Alert Severity & Routing

| Severity | Channel | Response SLA | Examples |
|----------|---------|-------------|----------|
| P1 Critical | PagerDuty (page) | 15 min | Production down, data breach, patient safety |
| P2 High | PagerDuty + Slack #incidents | 1 hour | Service degraded, error spike, cert < 7 days |
| P3 Medium | Slack #eng | 4 hours | IaC drift, cost anomaly, non-critical test fail |
| P4 Low | Slack #ops-digest | Next business day | Dependency update, cost optimization opportunity |

## Dashboards

### Platform Overview

- All services health status (green/yellow/red)
- Deployment history (last 30 days)
- Cluster utilization (CPU, memory, storage)
- Monthly cost and trend

### Service Detail (per service)

- Request rate (requests/second)
- Latency percentiles (p50, p90, p95, p99)
- Error rate (4xx, 5xx)
- Pod count and HPA status
- Resource utilization per pod

### AI Model Health

- Inference latency by model
- Prediction distribution (detect drift)
- Bias scores across demographics
- Token cost per model
- Model version and deployment status

### Deploy Pipeline

- Deploy frequency per week
- Lead time (commit to production)
- Change failure rate
- Mean time to recovery (MTTR)
- Rollback count and reasons

### Cost Center

- Daily and monthly cost by service
- Cost trend (7-day, 30-day, 90-day)
- Cost anomaly alerts
- Resource utilization vs provisioned
- Optimization recommendations

### Security Posture

- Vulnerability count by severity (critical, high, medium, low)
- Secret scan results
- Certificate expiry timeline
- RBAC audit summary
- Failed authentication attempts

## Key Metrics

### Golden Signals (per service)

| Signal | Metric | Alert Threshold |
|--------|--------|-----------------|
| Latency | p95 response time | > 2s (API), > 5s (AI inference) |
| Traffic | Requests per second | Anomaly detection (> 3 std dev) |
| Errors | 5xx rate | > 1% of requests |
| Saturation | CPU utilization | > 80% for > 5 minutes |

### SLOs

| Service | Availability | Latency (p99) |
|---------|-------------|----------------|
| API Gateway | 99.95% | < 500ms |
| Auth Service | 99.99% | < 200ms |
| Clinical Engine | 99.95% | < 2s |
| AI Inference | 99.9% | < 5s |
| Data Pipeline | 99.9% | < 10s (batch) |

## Stack Components

### Prometheus

- Scrape interval: 15s (services), 60s (infrastructure)
- Retention: 15 days local, long-term via Thanos/Cortex
- Service discovery: Kubernetes annotations
- Recording rules for pre-computed aggregations

### Grafana

- Version: Latest stable
- Authentication: SSO via auth-service
- Provisioning: Dashboards-as-code from this repo
- Datasources: Prometheus (metrics), Loki (logs), Jaeger (traces)

### Alertmanager

- Deduplication: 5-minute group window
- Inhibition: Suppress low-priority during P1 incidents
- Silences: Manual silence management via Grafana UI
- Routing: By severity label to appropriate channel

### Loki

- Log retention: 30 days (staging), 90 days (production)
- Collection: Promtail DaemonSet on all nodes
- Labels: namespace, service, pod, container, level
- Queries: LogQL in Grafana
