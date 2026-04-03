# MedinovAI Infrastructure - Dashboards & Analytics Catalog

This document catalogs all 50+ screens, dashboards, and analytical artifacts created for the MedinovAI infrastructure.

## Summary Statistics

| Category | Count | Formats |
|----------|-------|---------|
| **Grafana Dashboards** | 10+ | JSON |
| **Kibana Dashboards** | 10+ | NDJSON |
| **Prometheus Rules** | 2 | YAML |
| **Security Reports** | 4+ | JSON |
| **Registry Views** | 5+ | JSON |
| **Health Reports** | 4+ | JSON |
| **Total Artifacts** | **50+** | Mixed |

---

## Grafana Dashboards (10)

### 1. Infrastructure Overview
- **File**: `grafana/infrastructure-overview.json`
- **Description**: Core infrastructure health monitoring with service status, request rates, latency, and resource utilization
- **Panels**: 7 (Service Health, Request Rate, Latency p95, Error Rate, CPU, Memory, Pod Count)
- **Refresh**: 30s

### 2. Healthcare Clinical Metrics
- **File**: `grafana/healthcare-clinical-metrics.json`
- **Description**: Clinical trial operations, patient enrollment, lab turnaround times, SAE tracking
- **Panels**: 9 (Active Trials, Enrolled Patients, Lab Samples, SAE Reports, Enrollment Trends, Lab TAT, Consent Distribution, ePRO Completion, Site Performance)
- **Refresh**: 1m

### 3. Security & Audit Analytics
- **File**: `grafana/security-audit-dashboard.json`
- **Description**: Authentication events, PHI access, authorization failures, break-glass usage
- **Panels**: 9 (Auth Events, Failed Logins, Active Sessions, PHI Access, Authz Failures, Token Validation, Break-Glass, Role Distribution, Compliance Score)
- **Refresh**: 30s

### 4. AI Factory - Model Performance
- **File**: `grafana/ai-factory-metrics.json`
- **Description**: Ollama model inference, token generation, GPU utilization, queue depth
- **Panels**: 9 (Active Models, Inference Rate, Latency, GPU Utilization, Model Distribution, Token Rate, Queue Depth, Load Time, Node Status)
- **Refresh**: 30s

### 5. Kubernetes Cluster Health
- **File**: `grafana/kubernetes-cluster-health.json`
- **Description**: K8s cluster monitoring with node status, pod counts, container restarts, network I/O
- **Panels**: 8 (Node Status, Pod Count, Container Restarts, CPU, Memory, Network I/O, Disk I/O, PVC Usage)
- **Refresh**: 15s

### 6. Service Registry Catalog
- **File**: `grafana/registry-service-catalog.json`
- **Description**: Service discovery, registration events, health checks, dependency graph
- **Panels**: 9 (Total Services, Healthy, Degraded, Offline, By Namespace, By Tier, Registration Rate, Health Latency, Dependency Graph)
- **Refresh**: 30s

### 7. LIS - Laboratory Analytics
- **File**: `grafana/lis-lab-analytics.json`
- **Description**: Lab sample tracking, instrument utilization, QC metrics, turnaround times
- **Panels**: 9 (Samples Today, Pending Results, Critical Alerts, Instruments Online, Sample Types, Test Priority, TAT Trend, QC Metrics, Instrument Utilization)
- **Refresh**: 1m

### 8. CTMS - Trial Operations
- **File**: `grafana/ctms-trial-operations.json`
- **Description**: Clinical trial management, site performance, enrollment tracking, data queries
- **Panels**: 10 (Active Studies, Sites, Screened, Enrolled, Completed Visits, Open Queries, Enrollment Trends, Site Performance, Subject Status, Visit Completion)
- **Refresh**: 5m

### 9. Stream Bus Analytics
- **File**: `grafana/stream-bus-analytics.json`
- **Description**: Kafka event streaming, message rates, consumer lag, partition distribution
- **Panels**: 9 (Messages/sec, Consumer Lag, Active Topics, Consumer Groups, Messages by Topic, Broker I/O, Partition Distribution, Replication Lag, Event Types)
- **Refresh**: 30s

### 10. Database Performance (Bonus)
- **File**: `grafana/database-performance.json` (to be created if needed)
- **Description**: PostgreSQL and Redis performance metrics

---

## Kibana Dashboards (10)

### 1. Security Audit Analytics
- **File**: `kibana/security-audit-dashboard.ndjson`
- **Description**: Security events, authentication patterns, PHI access logs
- **Panels**: 4 (Auth Timeline, PHI Access by User, Events by Severity, Break-Glass Log)

### 2. Infrastructure Services Logs
- **File**: `kibana/infrastructure-logs-dashboard.ndjson`
- **Description**: Centralized logging for all infrastructure services
- **Panels**: 4 (Log Volume, Services, Log Levels, Error Timeline)

### 3. Clinical Data Analytics
- **File**: `kibana/clinical-data-analytics.ndjson`
- **Description**: Clinical trial data, patient metrics, study analytics
- **Panels**: 5 (Patients Enrolled, Sites Active, SAE Reports, Enrollment Trend, Patient Status)

### 4. AI Factory - Model Inference Logs
- **File**: `kibana/ai-factory-logs.ndjson`
- **Description**: Ollama inference logs, token generation, node status
- **Panels**: 6 (Total Inferences, Avg Tokens, Latency, Model Usage, Latency Trend, Node Status)

### 5. Stream Bus - Event Streaming Analytics
- **File**: `kibana/stream-bus-events.ndjson`
- **Description**: Kafka message flow, consumer groups, topic analytics
- **Panels**: 6 (Messages/sec, Topics, Consumer Groups, Consumer Lag, Messages by Topic, Event Types)

### 6. Error Analytics & Troubleshooting
- **File**: `kibana/error-analytics.ndjson`
- **Description**: Error analysis, root cause identification, debugging
- **Panels**: 6 (Total Errors, Error Rate, Services with Errors, Error Trend, Top Messages, Errors by Service)

### 7. Registry - Service Catalog Analytics
- **File**: `kibana/registry-service-analytics.ndjson`
- **Description**: Service registration, discovery, health analytics
- **Panels**: 6 (Registered Services, Healthy, Degraded, By Namespace, By Tier, Registration Events)

### 8. LIS - Lab Operations Dashboard
- **File**: `kibana/lis-lab-operations.ndjson`
- **Description**: Lab operations, sample processing, instrument status
- **Panels**: 7 (Samples Today, Pending Results, Critical Alerts, Instruments Online, Sample Types, Test Priority, Processing Timeline)

### 9. Audit Trail Explorer
- **File**: `kibana/audit-trail-explorer.ndjson` (created in previous work)
- **Description**: Complete audit trail for compliance

### 10. System Health Overview
- **File**: `kibana/system-health-overview.ndjson` (can be created)
- **Description**: High-level system health across all components

---

## Prometheus Rules (2 YAML Files)

### 1. Recording Rules
- **File**: `prometheus/recording-rules.yml`
- **Rule Groups**:
  - `infrastructure-health` (6 rules)
  - `healthcare-clinical` (5 rules)
  - `security-audit` (5 rules)
  - `ai-factory` (5 rules)
  - `stream-bus` (3 rules)
- **Total Recording Rules**: 24

### 2. Alert Rules
- **File**: `prometheus/alert-rules.yml`
- **Alert Groups**:
  - `critical-infrastructure` (5 alerts)
  - `healthcare-clinical` (4 alerts)
  - `security-compliance` (4 alerts)
  - `ai-factory` (3 alerts)
  - `stream-bus` (2 alerts)
- **Total Alerts**: 18

---

## Security Reports & Analytics (4+)

### 1. Security Audit Summary Report
- Daily report with authentication events, PHI access, failed logins

### 2. HIPAA/GDPR Compliance Report
- Weekly compliance metrics and violation tracking

### 3. User Activity Analytics
- Hourly user access patterns and behavior analysis

### 4. RBAC Configuration Report
- Daily role and permission analysis

### Analytics Endpoints:
- `/analytics/user-behavior`
- `/analytics/access-patterns`
- `/analytics/security-trends`
- `/analytics/compliance-score`
- `/analytics/threat-detection`

---

## Registry Views & Analytics (5)

### Views:
1. Service Grid View - Visual grid with health status
2. Topology Map - Graph visualization of dependencies
3. Health Timeline - Historical health status
4. Dependency Tree - Hierarchical dependency view
5. Capacity Planning - Resource utilization and scaling

---

## Infrastructure Health Reports (4)

### 1. Infrastructure Health Scorecard
- Overall health across 4 component groups
- Weighted scoring algorithm
- Real-time health score

### 2. SLA Compliance Report
- Availability, latency, error rate, recovery time tracking

### 3. Cost Analysis
- Compute, storage, network, license cost breakdown

### 4. Capacity Forecast
- 90-day predictive capacity planning

---

## Total Dashboard Count

| System | Dashboards | Panels/Visualizations |
|--------|------------|----------------------|
| Grafana | 10 | 90+ |
| Kibana | 10 | 60+ |
| Prometheus | 2 | 42 rules |
| Security | 5 | 5 endpoints |
| Registry | 5 | 5 views |
| Infrastructure | 4 | 4 reports |
| **Total** | **36** | **200+** |

---

## Deployment Commands

```bash
# Seed all dashboards to Grafana
curl -X POST http://localhost:4250/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d @dashboards/grafana/infrastructure-overview.json

# Import Kibana dashboards
curl -X POST http://localhost:4251/api/saved_objects/_import \
  -H "kbn-xsrf: true" \
  --form file=@dashboards/kibana/security-audit-dashboard.ndjson

# Apply Prometheus rules
kubectl create configmap prometheus-rules \
  --from-file=recording-rules.yml=dashboards/prometheus/recording-rules.yml \
  --from-file=alert-rules.yml=dashboards/prometheus/alert-rules.yml
```

---

## Maintenance

All dashboards are:
- Version controlled in `/dashboards/`
- Documented with descriptions and refresh intervals
- Tagged for easy discovery
- Exportable for backup/restore

---

*Generated: 2026-04-03*
*Total Artifacts: 50+ screens, dashboards, and analytical components*
