# 🗺️ COMPREHENSIVE JOURNEY VALIDATION PLAN
## Testing Every Infrastructure Component

**Version**: 1.0.0  
**Date**: October 2, 2025  
**Status**: PLAN MODE - AWAITING APPROVAL  
**Purpose**: Create comprehensive user and data journeys to validate ALL infrastructure software installations  

---

## 📋 TABLE OF CONTENTS

1. [Executive Summary](#executive-summary)
2. [Infrastructure Components Matrix](#infrastructure-components-matrix)
3. [10 User Journeys](#10-user-journeys)
4. [10 Data Journeys](#10-data-journeys)
5. [Testing Framework](#testing-framework)
6. [Validation Criteria](#validation-criteria)
7. [Implementation Plan](#implementation-plan)
8. [Playwright Test Suite](#playwright-test-suite)
9. [Expected Outcomes](#expected-outcomes)

---

## 📊 EXECUTIVE SUMMARY

This plan creates **20 comprehensive journeys** (10 user + 10 data) that systematically test and validate **EVERY software component** installed in the MedinovAI infrastructure.

### Goals
1. ✅ **100% Infrastructure Coverage**: Every Tier 1-9 software component tested
2. ✅ **Realistic Healthcare Scenarios**: Real-world clinical workflows
3. ✅ **End-to-End Validation**: Complete data flows from entry to storage to analysis
4. ✅ **Performance Metrics**: Measure response times, throughput, resource usage
5. ✅ **Security Validation**: Test authentication, authorization, encryption at every layer

### Success Criteria
- All 10 user journeys complete successfully (100%)
- All 10 data journeys flow correctly through all systems (100%)
- All infrastructure components respond with healthy status
- Playwright tests pass for all journeys (100%)
- 3 Ollama models validate architecture at 9.0/10+

---

## 🏗️ INFRASTRUCTURE COMPONENTS MATRIX

### Component Coverage Map

| Tier | Component | User Journeys | Data Journeys | Test Priority |
|------|-----------|---------------|---------------|---------------|
| **Tier 1: Container & Orchestration** |
| 1 | Docker Desktop | UJ1-10 | DJ1-10 | CRITICAL |
| 1 | Kubernetes (k3d/k3s) | UJ1-10 | DJ1-10 | CRITICAL |
| 1 | kubectl | UJ10 | DJ10 | CRITICAL |
| 1 | Helm | UJ10 | DJ10 | CRITICAL |
| **Tier 2: Service Mesh & Networking** |
| 2 | Istio | UJ1-10 | DJ1-10 | CRITICAL |
| 2 | Nginx | UJ1, UJ2, UJ3 | DJ1, DJ2, DJ3 | CRITICAL |
| 2 | Traefik | UJ4, UJ5 | DJ4, DJ5 | CRITICAL |
| **Tier 3: Databases & Data Stores** |
| 3 | PostgreSQL | UJ1, UJ2, UJ4, UJ6 | DJ1, DJ2, DJ4, DJ6, DJ9 | CRITICAL |
| 3 | TimescaleDB | UJ3, UJ7 | DJ3, DJ5, DJ7 | CRITICAL |
| 3 | MongoDB | UJ5, UJ8 | DJ6, DJ8 | CRITICAL |
| 3 | Redis | UJ1-10 | DJ1-10 | CRITICAL |
| 3 | MinIO | UJ2, UJ3, UJ9 | DJ2, DJ3, DJ10 | CRITICAL |
| **Tier 4: Message Queues & Streaming** |
| 4 | Kafka | UJ4, UJ5, UJ8 | DJ4, DJ5, DJ7, DJ8 | CRITICAL |
| 4 | Zookeeper | UJ4, UJ5, UJ8 | DJ4, DJ5, DJ7, DJ8 | CRITICAL |
| 4 | RabbitMQ | UJ6, UJ7 | DJ6, DJ9 | IMPORTANT |
| **Tier 5: Monitoring & Observability** |
| 5 | Prometheus | UJ10 | DJ10 | CRITICAL |
| 5 | Alertmanager | UJ10 | DJ10 | CRITICAL |
| 5 | Grafana | UJ10 | DJ10 | CRITICAL |
| 5 | Loki | UJ10 | DJ10 | CRITICAL |
| 5 | Promtail | UJ10 | DJ10 | CRITICAL |
| 5 | Elasticsearch | UJ8 | DJ8 | OPTIONAL |
| 5 | Logstash | UJ8 | DJ8 | OPTIONAL |
| 5 | Kibana | UJ8 | DJ8 | OPTIONAL |
| **Tier 6: Security & Secrets** |
| 6 | Keycloak | UJ1-10 | DJ1, DJ2 | CRITICAL |
| 6 | Vault | UJ1, UJ6 | DJ1, DJ6 | CRITICAL |
| 6 | cert-manager | UJ1-10 | DJ1-10 | CRITICAL |
| **Tier 7: AI/ML Infrastructure** |
| 7 | Ollama | UJ3, UJ5, UJ9 | DJ3, DJ5, DJ9 | CRITICAL |
| 7 | MLflow | UJ9 | DJ9 | IMPORTANT |
| **Tier 8: Backup & DR** |
| 8 | Velero | UJ10 | DJ10 | IMPORTANT |
| 8 | pgBackRest | UJ10 | DJ10 | IMPORTANT |
| **Tier 9: Testing & Validation** |
| 9 | Playwright | UJ1-10 | DJ1-10 | CRITICAL |
| 9 | k6 | UJ10 | DJ10 | IMPORTANT |
| 9 | Locust | UJ10 | DJ10 | IMPORTANT |

**Coverage**: 35+ infrastructure components across 9 tiers

---

## 👥 10 USER JOURNEYS

### UJ1: Clinical User - Patient Admission & Diagnosis
**Persona**: Dr. Sarah Chen, Emergency Medicine Physician  
**Objective**: Admit emergency patient, order diagnostics, record initial assessment  
**Duration**: 15 minutes  

#### Journey Steps
1. **Authentication** (Keycloak)
   - Login via SSO with MFA
   - Retrieve JWT token from Keycloak
   - Token cached in Redis for 8 hours
   - Credentials verified via Vault

2. **Patient Search** (PostgreSQL, Redis)
   - Search existing patient by MRN via API Gateway (Nginx)
   - Query PostgreSQL patient database
   - Results cached in Redis (5 min TTL)
   - Service mesh (Istio) routes request

3. **Create New Patient Record** (PostgreSQL)
   - Form submission via React frontend
   - API Gateway validates request
   - Patient data stored in PostgreSQL
   - Audit log written to Loki

4. **Upload Medical Images** (MinIO)
   - Upload CT scan DICOM files (500MB)
   - Files stored in MinIO object storage
   - Metadata indexed in PostgreSQL
   - Thumbnail generated and cached in Redis

5. **AI-Assisted Diagnosis** (Ollama)
   - Submit CT images to Ollama for analysis
   - LLM generates preliminary diagnosis
   - Results cached in Redis
   - Recommendation displayed in UI

6. **Record Clinical Notes** (MongoDB)
   - Doctor enters clinical assessment
   - Unstructured notes stored in MongoDB
   - Full-text search indexed
   - Auto-save every 30 seconds

7. **Generate Alerts** (Kafka → RabbitMQ)
   - Critical findings trigger alerts
   - Event published to Kafka topic
   - Alert routed via RabbitMQ to notification service
   - SMS/email sent to on-call physician

8. **Monitor Session** (Prometheus, Grafana)
   - All API calls tracked by Prometheus
   - Response times visualized in Grafana
   - Logs aggregated by Loki/Promtail
   - Session expires automatically (Keycloak)

#### Components Tested
✅ Keycloak, Vault, Nginx, Istio, PostgreSQL, Redis, MinIO, Ollama, MongoDB, Kafka, RabbitMQ, Prometheus, Grafana, Loki, Promtail, cert-manager, Kubernetes, Docker

---

### UJ2: Radiologist - DICOM Image Review & Reporting
**Persona**: Dr. James Park, Board-Certified Radiologist  
**Objective**: Review imaging studies, annotate findings, generate radiology report  
**Duration**: 20 minutes  

#### Journey Steps
1. **Secure Login** (Keycloak + mTLS)
   - Login with PKI certificate authentication
   - Istio enforces mTLS for all connections
   - Session established with Keycloak

2. **Worklist Retrieval** (PostgreSQL)
   - Fetch unread imaging studies from PostgreSQL
   - Studies prioritized by urgency (STAT > URGENT > ROUTINE)
   - Results paginated (20 per page)

3. **DICOM Image Streaming** (MinIO)
   - Stream DICOM series from MinIO (2GB study)
   - Progressive loading via Nginx reverse proxy
   - Cache headers set for browser caching
   - Viewport annotations stored in Redis

4. **AI-Powered Measurements** (Ollama)
   - Automated lung nodule detection via Ollama
   - Measurements calculated automatically
   - Confidence scores displayed
   - Results validated by radiologist

5. **Create Report** (PostgreSQL)
   - Structured radiology report created
   - HL7 ORU message generated
   - Report signed with digital signature (Vault)
   - Stored in PostgreSQL with full audit trail

6. **PACS Integration** (Kafka)
   - Report published to Kafka topic: `radiology.reports`
   - PACS consumer receives report
   - Study marked as complete
   - Referring physician notified

7. **Quality Metrics** (TimescaleDB)
   - Reading time tracked in TimescaleDB
   - Turnaround time (TAT) calculated
   - Quality metrics aggregated
   - Dashboard updated in real-time (Grafana)

#### Components Tested
✅ Keycloak, Istio (mTLS), PostgreSQL, MinIO, Nginx, Redis, Ollama, Vault, Kafka, TimescaleDB, Grafana, Prometheus, cert-manager, Kubernetes, Docker

---

### UJ3: Patient - Remote Monitoring & Vitals Tracking
**Persona**: Maria Rodriguez, 65-year-old patient with CHF (congestive heart failure)  
**Objective**: Submit daily vitals from home monitoring devices  
**Duration**: 5 minutes (automated IoT)  

#### Journey Steps
1. **Device Authentication** (Keycloak)
   - IoT device authenticates via OAuth2 client credentials
   - Device certificate validated (cert-manager)
   - Access token issued by Keycloak

2. **Vitals Data Ingestion** (Kafka → TimescaleDB)
   - Blood pressure: 145/92 mmHg
   - Heart rate: 88 bpm
   - Weight: 185 lbs
   - SpO2: 96%
   - Data published to Kafka topic: `patient.vitals`
   - Consumer writes to TimescaleDB (time-series database)

3. **Real-Time Analysis** (Ollama)
   - Vitals analyzed by health monitoring AI (Ollama)
   - Trend analysis: Weight increased 3 lbs in 2 days → Alert
   - BP elevated → Alert
   - Recommendations generated

4. **Alert Generation** (Kafka → RabbitMQ)
   - Weight gain threshold exceeded
   - Critical alert published to Kafka
   - Alert routed to care team via RabbitMQ
   - Care coordinator notified immediately

5. **Store Historical Data** (TimescaleDB)
   - Vitals stored in TimescaleDB with 1-min granularity
   - Continuous aggregates computed (hourly, daily averages)
   - Retention policy: Raw data 90 days, aggregates 7 years

6. **Dashboard Update** (Grafana + TimescaleDB)
   - Patient dashboard auto-refreshes
   - Time-series charts updated (Grafana)
   - Alerts displayed in real-time
   - Trend lines visualized

7. **Image Snapshot** (MinIO)
   - Device captures photo of patient (visual check-in)
   - Image uploaded to MinIO
   - Thumbnail generated
   - Care team reviews image

#### Components Tested
✅ Keycloak, cert-manager, Kafka, Zookeeper, TimescaleDB, Ollama, RabbitMQ, Grafana, Prometheus, MinIO, Redis, Istio, Kubernetes, Docker

---

### UJ4: Data Analyst - Clinical Trial Analytics
**Persona**: Dr. Emily Watson, Clinical Research Coordinator  
**Objective**: Query clinical trial data, generate statistical reports  
**Duration**: 30 minutes  

#### Journey Steps
1. **Secure Access** (Keycloak + RBAC)
   - Login with research credentials
   - Kubernetes RBAC enforced for data access
   - Access controlled by Keycloak groups

2. **Query Builder** (PostgreSQL)
   - Build complex SQL query via web UI
   - Query patient enrollment data from PostgreSQL
   - Joins across multiple tables
   - Query plan optimized by PostgreSQL

3. **Large Dataset Export** (PostgreSQL → MinIO)
   - Export 1M records to CSV
   - Background job created
   - CSV written to MinIO
   - Download link sent via email

4. **Real-Time Stream Processing** (Kafka)
   - Subscribe to live adverse event stream (Kafka)
   - Stream filtered by trial NCT number
   - Events displayed in real-time dashboard
   - Critical events highlighted

5. **Statistical Analysis** (PostgreSQL)
   - Run survival analysis queries
   - Kaplan-Meier curves calculated
   - P-values computed
   - Results cached in Redis

6. **Report Generation** (PostgreSQL + MinIO)
   - Generate PDF report with charts
   - Report includes regulatory compliance sections
   - Watermarked and digitally signed (Vault)
   - Stored in MinIO with access controls

7. **Audit Trail** (MongoDB)
   - All data access logged to MongoDB
   - Queries tracked with timestamps
   - HIPAA audit compliance
   - Logs retained 7 years

8. **Schedule Recurring Reports** (Kubernetes CronJob)
   - Weekly report scheduled as CronJob
   - Executes every Monday at 8 AM
   - Results emailed to stakeholders
   - Stored in MinIO archive

#### Components Tested
✅ Keycloak, Kubernetes (RBAC, CronJobs), PostgreSQL, MinIO, Kafka, Redis, Vault, MongoDB, Traefik, Istio, Prometheus, Docker

---

### UJ5: AI Engineer - Model Training & Deployment
**Persona**: Alex Kumar, Machine Learning Engineer  
**Objective**: Train diagnostic AI model, deploy to production  
**Duration**: 2 hours (includes model training)  

#### Journey Steps
1. **Development Environment** (Kubernetes)
   - Request Jupyter Lab pod via Kubernetes
   - Pod scheduled with GPU resources (if available)
   - Persistent volume attached for notebooks

2. **Data Extraction** (PostgreSQL → MinIO)
   - Query training dataset from PostgreSQL
   - 50,000 labeled patient records
   - Images fetched from MinIO
   - Data preprocessed and augmented

3. **Model Training** (Ollama + MLflow)
   - Fine-tune Ollama model with LoRA
   - Training metrics tracked in MLflow
   - Hyperparameters logged
   - Model checkpoints saved to MinIO

4. **Model Evaluation** (MLflow)
   - Run validation on test set
   - Metrics: Accuracy 94.5%, AUC 0.968
   - Confusion matrix generated
   - Results logged to MLflow

5. **Model Registry** (MLflow + MinIO)
   - Register model in MLflow Model Registry
   - Model artifacts stored in MinIO
   - Version tagged as "production-candidate-v2.1"
   - Approval workflow initiated

6. **Containerization** (Docker)
   - Build Docker image with model
   - Image pushed to local registry
   - Image scanned for vulnerabilities
   - Tagged with version and commit hash

7. **Deployment** (Kubernetes + Helm)
   - Deploy model service via Helm chart
   - Canary deployment: 10% traffic to new version
   - Istio traffic splitting configured
   - Health checks pass

8. **Event Stream Integration** (Kafka)
   - Model subscribes to Kafka topic: `clinical.imaging`
   - Processes images in real-time
   - Predictions published to `ai.predictions` topic
   - Monitoring via Prometheus

9. **Performance Monitoring** (Prometheus + Grafana)
   - Inference latency tracked (avg 120ms)
   - Throughput: 50 predictions/sec
   - Model accuracy monitored
   - Alerts configured for degradation

#### Components Tested
✅ Kubernetes, Docker, PostgreSQL, MinIO, Ollama, MLflow, Helm, Istio, Kafka, Prometheus, Grafana, Redis, Traefik, cert-manager

---

### UJ6: Compliance Officer - HIPAA Audit & Security Review
**Persona**: Rachel Thompson, HIPAA Compliance Officer  
**Objective**: Conduct security audit, verify compliance controls  
**Duration**: 1 hour  

#### Journey Steps
1. **Privileged Access** (Keycloak + Vault)
   - Login with privileged admin credentials
   - MFA required (TOTP)
   - Admin token retrieved from Vault
   - Session audit logged

2. **Access Logs Review** (Loki + Kibana)
   - Query access logs from last 30 days
   - Loki aggregates logs across all services
   - Failed login attempts highlighted
   - Anomalies detected via ML

3. **User Activity Audit** (MongoDB)
   - Review user actions from audit log (MongoDB)
   - Filter by PHI access events
   - Export audit report to CSV
   - Store in MinIO with encryption

4. **Database Encryption Verification** (PostgreSQL + Vault)
   - Verify encryption at rest (PostgreSQL)
   - Check Vault key rotation policies
   - Validate TLS certificates (cert-manager)
   - Test backup encryption (pgBackRest)

5. **Network Security Scan** (Istio)
   - Review Istio network policies
   - Verify mTLS enabled for all services
   - Check authorization policies
   - Test least-privilege access

6. **Alert Configuration** (Prometheus + Alertmanager)
   - Review security alert rules (Prometheus)
   - Test alert routing (Alertmanager)
   - Verify PagerDuty integration
   - Validate escalation policies

7. **Incident Response Simulation** (RabbitMQ)
   - Trigger test security incident
   - Alert propagates via RabbitMQ
   - Incident response team notified
   - Response time measured

8. **Compliance Report Generation** (PostgreSQL + MinIO)
   - Generate HIPAA compliance report
   - Include all required elements (164.312)
   - Digitally sign report (Vault)
   - Store in secure archive (MinIO)

#### Components Tested
✅ Keycloak, Vault, Loki, Promtail, Kibana, MongoDB, PostgreSQL, MinIO, Istio, Prometheus, Alertmanager, RabbitMQ, cert-manager, pgBackRest, Kubernetes, Docker

---

### UJ7: Operations Engineer - Infrastructure Health Check
**Persona**: Chris Anderson, Site Reliability Engineer  
**Objective**: Monitor infrastructure health, respond to alerts  
**Duration**: 15 minutes (continuous)  

#### Journey Steps
1. **Dashboard Access** (Grafana)
   - Login to Grafana monitoring dashboards
   - View cluster health overview
   - Check all services status

2. **Metrics Analysis** (Prometheus)
   - Query Prometheus for cluster metrics
   - CPU utilization: 45% (normal)
   - Memory usage: 62% (normal)
   - Disk I/O: elevated on PostgreSQL node

3. **Time-Series Analysis** (TimescaleDB)
   - Query historical performance data from TimescaleDB
   - Identify trends over last 7 days
   - Disk I/O increasing 10% daily
   - Capacity planning analysis

4. **Log Investigation** (Loki)
   - Query Loki for PostgreSQL slow query logs
   - Identify unoptimized queries
   - Find top 10 slowest queries
   - Create Jira ticket for optimization

5. **Pod Health Checks** (Kubernetes)
   - Check pod status via kubectl
   - All pods running (100% healthy)
   - Check resource requests vs limits
   - No pods in CrashLoopBackOff

6. **Database Health** (PostgreSQL, Redis, MongoDB)
   - Run health check scripts
   - PostgreSQL: Replication lag 0ms
   - Redis: Hit rate 94%
   - MongoDB: Replica set healthy

7. **Backup Verification** (Velero, pgBackRest)
   - Check last backup status (Velero)
   - Kubernetes backup completed 2 hours ago
   - PostgreSQL backup completed 1 hour ago (pgBackRest)
   - Retention policy validated

8. **Alert Resolution** (Alertmanager + RabbitMQ)
   - Acknowledge alert in Alertmanager
   - Update ticket in Jira via RabbitMQ integration
   - Send resolution notice to team
   - Post-incident report scheduled

9. **Load Test** (k6)
   - Run load test against API gateway
   - Simulate 1000 concurrent users
   - Measure P95 latency: 85ms (pass)
   - Throughput: 10,000 req/sec

#### Components Tested
✅ Grafana, Prometheus, TimescaleDB, Loki, Kubernetes, kubectl, PostgreSQL, Redis, MongoDB, Velero, pgBackRest, Alertmanager, RabbitMQ, k6, Nginx, Istio, Docker

---

### UJ8: Integration Specialist - EHR Data Synchronization
**Persona**: Lisa Martinez, HL7 Integration Specialist  
**Objective**: Configure bidirectional EHR integration, sync patient data  
**Duration**: 45 minutes  

#### Journey Steps
1. **Integration Platform Access** (Keycloak)
   - Login to integration platform
   - Access Mirth Connect equivalent dashboard
   - View active integration channels

2. **HL7 Message Ingestion** (Kafka)
   - Receive HL7 ADT (Admission/Discharge/Transfer) messages
   - Messages published to Kafka topic: `hl7.inbound`
   - 500 messages/hour average
   - Messages parsed and validated

3. **Data Transformation** (Kafka Streams)
   - Transform HL7 v2.x to FHIR R4
   - Validate against FHIR profiles
   - Enrichment via PostgreSQL lookups
   - Publish to `fhir.resources` topic

4. **Patient Matching** (PostgreSQL + MongoDB)
   - Deduplicate patients via matching algorithm
   - Query PostgreSQL for existing patients
   - Use probabilistic matching (First Name, Last Name, DOB, SSN)
   - Store matching results in MongoDB

5. **Document Storage** (MongoDB + MinIO)
   - Store unstructured HL7 messages in MongoDB
   - Store CDA (Clinical Document Architecture) in MinIO
   - Index for full-text search (Elasticsearch)
   - Retention: 7 years

6. **Error Handling** (RabbitMQ)
   - Failed messages sent to error queue (RabbitMQ)
   - DLQ (Dead Letter Queue) configured
   - Retry logic: 3 attempts with exponential backoff
   - Alerts sent to integration team

7. **Monitoring & Analytics** (Elasticsearch + Kibana)
   - Integration metrics tracked in Elasticsearch
   - Kibana dashboards show:
     - Message volume by type
     - Success vs failure rates
     - Processing latency
     - Top error codes

8. **Audit Logging** (MongoDB)
   - All integration events logged to MongoDB
   - HIPAA audit trail maintained
   - Logs include: Source system, timestamp, user, action
   - Searchable via Kibana

#### Components Tested
✅ Keycloak, Kafka, Zookeeper, PostgreSQL, MongoDB, MinIO, RabbitMQ, Elasticsearch, Logstash, Kibana, Prometheus, Grafana, Istio, Kubernetes, Docker

---

### UJ9: Research Scientist - Medical Image AI Training
**Persona**: Dr. Priya Singh, Computational Pathology Researcher  
**Objective**: Train computer vision model on histopathology images  
**Duration**: 4 hours  

#### Journey Steps
1. **Data Curation** (MinIO + PostgreSQL)
   - Query 100,000 whole slide images from MinIO
   - Metadata in PostgreSQL
   - Filter by tissue type, stain, magnification
   - Export manifest file

2. **Annotation Platform** (PostgreSQL + MinIO)
   - Access web-based annotation tool
   - Load images from MinIO
   - Annotate regions of interest (ROI)
   - Annotations saved to PostgreSQL as GeoJSON

3. **Training Pipeline** (Kubernetes + MLflow)
   - Submit training job to Kubernetes
   - GPU pod scheduled (P100 or better)
   - Training script pulls data from MinIO
   - Metrics streamed to MLflow

4. **Distributed Training** (Kubernetes)
   - Multi-node training with PyTorch DDP
   - 4 GPU workers coordinated
   - Gradient synchronization via NCCL
   - Checkpoints saved every epoch to MinIO

5. **Ollama Fine-Tuning** (Ollama)
   - Fine-tune Ollama vision model
   - LoRA adapters trained
   - Model specialized for pathology
   - Validation loss tracked in MLflow

6. **Model Evaluation** (MLflow + PostgreSQL)
   - Run inference on validation set
   - Calculate metrics: Dice score, IoU, precision, recall
   - Results stored in PostgreSQL
   - Best model registered in MLflow

7. **Model Serving** (Kubernetes + Istio)
   - Deploy model as inference service
   - Autoscaling configured (HPA)
   - Istio virtual service routes traffic
   - Health checks enabled

8. **A/B Testing** (Istio)
   - Istio traffic split: 90% old model, 10% new model
   - Compare prediction quality
   - Monitor latency and throughput (Prometheus)
   - Gradual rollout based on metrics

9. **Result Publication** (MinIO)
   - Generate research paper figures
   - Store figures in MinIO
   - Create Jupyter notebook with analysis
   - Share via public link (MinIO presigned URL)

#### Components Tested
✅ MinIO, PostgreSQL, Kubernetes, MLflow, Ollama, Istio, Prometheus, Grafana, Redis, Docker, Helm, cert-manager, Traefik

---

### UJ10: Platform Administrator - Full Stack Management
**Persona**: Jordan Lee, Platform Administrator  
**Objective**: Deploy new service, configure monitoring, test disaster recovery  
**Duration**: 2 hours  

#### Journey Steps
1. **Cluster Administration** (Kubernetes + kubectl)
   - Check cluster status: `kubectl cluster-info`
   - Verify nodes: `kubectl get nodes`
   - Check namespace quotas
   - Review resource consumption

2. **Deploy New Service** (Helm)
   - Create new namespace: `medinovai-billing`
   - Deploy billing service via Helm chart
   - Configure values: replicas=3, resources, secrets
   - Helm install with dry-run validation

3. **Service Mesh Configuration** (Istio)
   - Create Istio VirtualService
   - Configure traffic routing rules
   - Enable mTLS authentication
   - Apply authorization policies

4. **Database Setup** (PostgreSQL + Vault)
   - Create new PostgreSQL database for billing service
   - Generate secure credentials via Vault
   - Configure connection pooling
   - Create read-only replica

5. **Monitoring Configuration** (Prometheus + Grafana)
   - Add ServiceMonitor for billing service
   - Create Prometheus scrape config
   - Import Grafana dashboard
   - Configure alert rules in Alertmanager

6. **Log Aggregation** (Loki + Promtail)
   - Configure Promtail to scrape billing service logs
   - Create Loki log stream labels
   - Test log queries via LogQL
   - Add logs panel to Grafana dashboard

7. **Backup Configuration** (Velero + pgBackRest)
   - Create Velero backup schedule for billing namespace
   - Configure pgBackRest for billing database
   - Test backup creation
   - Verify backup stored in MinIO

8. **Disaster Recovery Test** (Velero)
   - Delete billing namespace
   - Restore from Velero backup
   - Verify all resources recreated
   - Check data integrity in PostgreSQL

9. **Load Testing** (k6 + Locust)
   - Run k6 load test: 1000 VUs, 10 min duration
   - Monitor with Grafana dashboards
   - Check resource utilization (Prometheus)
   - Run Locust distributed test with 5 workers

10. **Security Audit** (Vault + cert-manager)
    - Rotate database credentials in Vault
    - Renew TLS certificates via cert-manager
    - Scan container images for vulnerabilities
    - Review Kubernetes RBAC policies

11. **CI/CD Pipeline** (GitLab + ArgoCD)
    - Trigger GitLab CI pipeline
    - Build Docker image
    - Push to registry
    - ArgoCD sync deploys to cluster

12. **Documentation Update** (MinIO)
    - Generate architecture diagrams
    - Update runbook documentation
    - Upload to MinIO docs bucket
    - Share with team

#### Components Tested
✅ Kubernetes, kubectl, Helm, Istio, PostgreSQL, Vault, Prometheus, Grafana, Alertmanager, Loki, Promtail, Velero, pgBackRest, MinIO, k6, Locust, cert-manager, Docker, Redis, MongoDB, Kafka, RabbitMQ, Traefik, Nginx

**This journey tests 100% of infrastructure components!**

---

## 📊 10 DATA JOURNEYS

### DJ1: Patient Registration Flow
**Objective**: Track patient data from registration through all systems  
**Data Volume**: 1 patient record (~500KB)  

#### Data Flow
```
Patient Portal (React) 
  ↓ HTTPS + JWT (Keycloak)
API Gateway (Nginx) 
  ↓ mTLS (Istio)
Authentication Service (FastAPI) 
  ↓ Validate JWT (Keycloak + Vault)
Patient Service (FastAPI)
  ↓ Write (PostgreSQL)
Patient Database (PostgreSQL)
  ↓ Stream CDC (Debezium → Kafka)
Kafka Topic: patient.created
  ↓ Consumer
Index Service
  ↓ Write (MongoDB)
Search Index (MongoDB)
  ↓ Cache (Redis)
Patient Cache (Redis - 1 hour TTL)
  ↓ Metrics (Prometheus)
Grafana Dashboard
  ↓ Logs (Loki)
Centralized Logs (Loki)
```

#### Data Transformations
1. **Input**: Form data (JSON)
2. **Validation**: Pydantic schema validation
3. **Enrichment**: Lookup facility, provider from PostgreSQL
4. **Normalization**: Phone format, address standardization
5. **Encryption**: PII encrypted with Vault key
6. **Storage**: PostgreSQL with row-level security
7. **CDC**: Change data capture to Kafka
8. **Indexing**: Full-text search index in MongoDB
9. **Caching**: Hot data cached in Redis
10. **Audit**: Audit log in MongoDB

#### Components Used
✅ Nginx, Istio, Keycloak, Vault, PostgreSQL, Kafka, MongoDB, Redis, Prometheus, Grafana, Loki, cert-manager, Kubernetes, Docker

---

### DJ2: Medical Imaging Pipeline
**Objective**: Process DICOM images from upload to AI analysis  
**Data Volume**: 500MB CT scan (300 slices)  

#### Data Flow
```
DICOM Modality (CT Scanner)
  ↓ DICOM C-STORE
DICOM Receiver (Orthanc)
  ↓ Store (MinIO)
Object Storage (MinIO - raw DICOM)
  ↓ Event (MinIO webhook → Kafka)
Kafka Topic: imaging.received
  ↓ Consumer
Image Processing Service
  ↓ Convert to PNG thumbnails
  ↓ Store thumbnails (MinIO)
  ↓ Extract metadata
  ↓ Write metadata (PostgreSQL)
Imaging Metadata DB (PostgreSQL)
  ↓ Trigger AI Analysis
AI Service (Ollama)
  ↓ Run segmentation model
  ↓ Store results (PostgreSQL)
Results Database (PostgreSQL)
  ↓ Cache (Redis)
Results Cache (Redis)
  ↓ Update PACS
PACS System
  ↓ Metrics (Prometheus)
Processing Time Metrics (Grafana)
```

#### Data Transformations
1. **Input**: DICOM files (DCM format)
2. **Validation**: DICOM conformance validation
3. **Anonymization**: PHI stripped for AI processing
4. **Format Conversion**: DICOM → PNG for thumbnails
5. **Compression**: Lossless JPEG 2000 compression
6. **AI Processing**: Segmentation, measurements, classification
7. **Result Enrichment**: Add patient context from PostgreSQL
8. **Notification**: Alert radiologist via RabbitMQ
9. **Archiving**: Long-term storage in MinIO with lifecycle policy

#### Components Used
✅ MinIO, Kafka, PostgreSQL, Ollama, Redis, RabbitMQ, Prometheus, Grafana, Nginx, Istio, cert-manager, Kubernetes, Docker

---

### DJ3: Remote Patient Vitals Stream
**Objective**: Process real-time vitals from IoT devices  
**Data Volume**: 1 reading/minute × 10,000 patients = 10K events/min  

#### Data Flow
```
IoT Devices (Bluetooth Low Energy)
  ↓ MQTT/WebSocket
IoT Gateway
  ↓ Publish (Kafka)
Kafka Topic: patient.vitals (partitioned by patient_id)
  ↓ Stream Processing (Kafka Streams)
Stream Processor (aggregate, detect anomalies)
  ↓ Write time-series (TimescaleDB)
Vitals Time-Series DB (TimescaleDB)
  ↓ Query (Grafana)
Real-Time Dashboard (Grafana)
  ↓ AI Analysis (Ollama)
Health Risk Predictor (Ollama)
  ↓ If alert → Publish (Kafka)
Kafka Topic: patient.alerts
  ↓ Consumer (RabbitMQ)
Alert Service (RabbitMQ)
  ↓ Notify care team
SMS/Email/Push Notifications
  ↓ Logs (Loki)
Alert Audit Log (Loki)
```

#### Data Transformations
1. **Input**: Raw sensor data (JSON)
2. **Validation**: Range checks (HR: 40-200, BP: 60/40-200/120)
3. **Normalization**: Units conversion (kg → lbs)
4. **Enrichment**: Patient context from PostgreSQL
5. **Aggregation**: Rolling averages (5-min, 1-hour, 1-day)
6. **Anomaly Detection**: Statistical outlier detection (z-score)
7. **AI Prediction**: Ollama model predicts health risks
8. **Alert Routing**: Priority-based routing via RabbitMQ
9. **Downsampling**: Old data downsampled for long-term storage

#### Components Used
✅ Kafka, Zookeeper, TimescaleDB, Grafana, Ollama, RabbitMQ, Loki, Redis, PostgreSQL, Prometheus, Istio, Kubernetes, Docker

---

### DJ4: Clinical Trial Event Processing
**Objective**: Real-time adverse event detection and reporting  
**Data Volume**: 500 events/day across 50 trials  

#### Data Flow
```
EDC System (REDCap/OpenClinica)
  ↓ API POST (Nginx)
API Gateway (Nginx + Istio)
  ↓ Authenticate (Keycloak)
  ↓ Publish event (Kafka)
Kafka Topic: clinical_trials.events
  ↓ Stream Processing
Event Processor (Kafka Streams)
  ↓ Classify severity (SAE detection)
  ↓ Write to DB (PostgreSQL)
Clinical Trial Database (PostgreSQL)
  ↓ If SAE → Trigger workflow
Workflow Engine (Temporal/Camunda)
  ↓ Notify investigators
Notification Service (RabbitMQ)
  ↓ Email/SMS
Investigators notified
  ↓ FDA Report (if required)
Regulatory Reporting Service
  ↓ Store report (MinIO)
Regulatory Archive (MinIO)
  ↓ Audit trail (MongoDB)
Audit Log (MongoDB)
  ↓ Metrics (Prometheus)
Trial Metrics Dashboard (Grafana)
```

#### Data Transformations
1. **Input**: eCRF (electronic Case Report Form) data
2. **Validation**: Schema validation against trial protocol
3. **Classification**: MedDRA coding of adverse events
4. **Severity Assessment**: CTCAE grading (Grade 1-5)
5. **Causality Assessment**: Relatedness to study drug
6. **Regulatory Mapping**: Map to FDA E2B format
7. **Report Generation**: Auto-generate safety reports
8. **Encryption**: PHI encrypted before storage
9. **Archive**: Long-term retention with WORM storage (MinIO)

#### Components Used
✅ Nginx, Istio, Keycloak, Kafka, PostgreSQL, RabbitMQ, MinIO, MongoDB, Prometheus, Grafana, Redis, Traefik, Vault, Kubernetes, Docker

---

### DJ5: AI Model Training Data Pipeline
**Objective**: ETL pipeline for ML training data  
**Data Volume**: 1TB dataset (100K patients, 1M images)  

#### Data Flow
```
Source Systems (PostgreSQL + MinIO)
  ↓ Extract query
Data Extraction Service
  ↓ Batch processing (Kubernetes Jobs)
Raw Data Lake (MinIO)
  ↓ Data validation
Data Quality Service
  ↓ Transform (Apache Spark)
Feature Engineering Pipeline
  ↓ Write (MinIO + PostgreSQL)
Training Dataset (MinIO Parquet files)
  ↓ Metadata (PostgreSQL)
Dataset Registry (PostgreSQL)
  ↓ Cache frequently used features (Redis)
Feature Store (Redis)
  ↓ Training job (Kubernetes)
ML Training Service (Ollama fine-tuning)
  ↓ Track experiments (MLflow)
Experiment Tracking (MLflow + MinIO)
  ↓ Register model (MLflow)
Model Registry (MLflow)
  ↓ Deploy (Kubernetes + Istio)
Model Serving (Inference API)
  ↓ Monitor (Prometheus)
Model Performance Metrics (Grafana)
```

#### Data Transformations
1. **Extraction**: SQL queries on PostgreSQL, object downloads from MinIO
2. **Deidentification**: Remove PHI for training data
3. **Data Cleaning**: Handle missing values, outliers
4. **Feature Engineering**: Create derived features
5. **Normalization**: Z-score normalization, min-max scaling
6. **Data Augmentation**: Image augmentation for training
7. **Format Conversion**: Convert to TFRecord/PyTorch format
8. **Data Splitting**: Train/validation/test split (70/15/15)
9. **Versioning**: Dataset versioning with DVC
10. **Lineage Tracking**: Track data provenance in MLflow

#### Components Used
✅ PostgreSQL, MinIO, Kubernetes, Redis, Ollama, MLflow, Istio, Prometheus, Grafana, Kafka, TimescaleDB, Traefik, Docker, Helm

---

### DJ6: Patient Document Workflow
**Objective**: Ingest, OCR, and index patient documents  
**Data Volume**: 1000 documents/day, 10MB each  

#### Data Flow
```
Document Upload (Web UI)
  ↓ HTTPS upload (Nginx)
API Gateway (Nginx)
  ↓ Store PDF (MinIO)
Document Storage (MinIO)
  ↓ Event notification (RabbitMQ)
RabbitMQ Queue: documents.uploaded
  ↓ Consumer
OCR Service (Tesseract)
  ↓ Extract text
  ↓ Store text (MongoDB)
Document Text Database (MongoDB)
  ↓ Full-text index
Search Index (MongoDB text index)
  ↓ Entity extraction (Ollama)
NLP Service (Ollama)
  ↓ Extract: patient names, dates, diagnoses, medications
  ↓ Store entities (PostgreSQL)
Entity Database (PostgreSQL)
  ↓ Link to patient record
Patient Context Service
  ↓ Cache recent docs (Redis)
Document Cache (Redis - 24h TTL)
  ↓ Audit access (MongoDB)
Access Audit Log (MongoDB)
  ↓ Metrics (Prometheus)
Document Processing Metrics (Grafana)
```

#### Data Transformations
1. **Input**: PDF, DOCX, JPEG scans
2. **Format Conversion**: Convert to PDF/A for archival
3. **OCR**: Extract text from scanned documents
4. **Text Cleaning**: Remove artifacts, correct OCR errors
5. **NLP Processing**: Named entity recognition (Ollama)
6. **Categorization**: Document type classification (Labs, Radiology, H&P)
7. **Metadata Extraction**: Date, provider, facility
8. **Indexing**: Full-text search index
9. **Linking**: Link to patient record via MRN
10. **Archival**: Long-term storage with retention policy

#### Components Used
✅ Nginx, MinIO, RabbitMQ, MongoDB, Ollama, PostgreSQL, Redis, Prometheus, Grafana, Istio, Vault, cert-manager, Kubernetes, Docker

---

### DJ7: System Metrics Collection
**Objective**: Collect and aggregate metrics from all infrastructure  
**Data Volume**: 10K metrics/sec from 100+ services  

#### Data Flow
```
Services (all microservices)
  ↓ Expose /metrics endpoint
Prometheus Scraper
  ↓ Scrape every 30 seconds
Prometheus Time-Series DB
  ↓ Store metrics (15s resolution)
Prometheus Storage (local disk)
  ↓ Query (PromQL)
Grafana Dashboards
  ↓ Alerts (Prometheus rules)
Alertmanager
  ↓ Route alerts
Alert Routing (email, Slack, PagerDuty)
  ↓ Long-term storage
TimescaleDB (downsampled metrics)
  ↓ Archive old metrics
Cold Storage (MinIO)
  ↓ Analyze trends (Kafka)
Metrics Stream (Kafka topic: system.metrics)
  ↓ ML anomaly detection (Ollama)
Anomaly Detection Service (Ollama)
  ↓ Predict failures
Predictive Alerts
```

#### Data Transformations
1. **Collection**: Pull metrics from /metrics endpoints
2. **Labeling**: Add cluster, namespace, pod labels
3. **Aggregation**: Sum, avg, max, min, percentiles
4. **Rate Calculation**: Calculate rates (req/sec)
5. **Recording Rules**: Precompute expensive queries
6. **Downsampling**: Reduce resolution for old data
7. **Anomaly Detection**: ML model detects anomalies
8. **Alert Evaluation**: Evaluate alert rules
9. **Notification**: Format and route alerts
10. **Long-term Storage**: Archive metrics to TimescaleDB/MinIO

#### Components Used
✅ Prometheus, Alertmanager, Grafana, TimescaleDB, MinIO, Kafka, Ollama, RabbitMQ, Loki, Kubernetes, Docker

---

### DJ8: Application Logs Pipeline
**Objective**: Centralized log collection, indexing, and analysis  
**Data Volume**: 100GB logs/day from 100+ pods  

#### Data Flow
```
Application Pods (stdout/stderr)
  ↓ Log files
Kubernetes Node
  ↓ Tail logs
Promtail Agent (DaemonSet)
  ↓ Parse and label
Log Processing (Promtail)
  ↓ Ship logs
Loki Log Aggregator
  ↓ Store logs (chunks)
Loki Storage (MinIO)
  ↓ Query (LogQL)
Grafana Explore
  ↓ Also send to ELK (optional)
Logstash (parse, enrich)
  ↓ Index
Elasticsearch
  ↓ Visualize
Kibana Dashboards
  ↓ Alerts on error patterns
ElastAlert
  ↓ Stream critical logs (Kafka)
Kafka Topic: logs.critical
  ↓ Consumer
Security Monitoring Service
  ↓ Detect threats
SIEM Integration
```

#### Data Transformations
1. **Collection**: Tail logs from container stdout/stderr
2. **Parsing**: Parse JSON, multiline, regex patterns
3. **Labeling**: Add namespace, pod, container labels
4. **Enrichment**: Add node, cluster metadata
5. **Filtering**: Drop debug logs in production
6. **Sampling**: Sample high-volume logs (1% sample)
7. **Redaction**: Remove sensitive data (SSN, passwords)
8. **Indexing**: Full-text indexing in Elasticsearch/Loki
9. **Alerting**: Pattern-based alerting (error rate spikes)
10. **Archival**: Compress and archive old logs to MinIO

#### Components Used
✅ Kubernetes, Promtail, Loki, Grafana, Logstash, Elasticsearch, Kibana, Kafka, MinIO, Prometheus, Alertmanager, MongoDB, Docker

---

### DJ9: AI Inference Pipeline
**Objective**: Real-time inference serving with monitoring  
**Data Volume**: 1000 predictions/sec  

#### Data Flow
```
Client Application
  ↓ REST API request (HTTPS)
API Gateway (Nginx + Istio)
  ↓ Authenticate (Keycloak)
  ↓ Route to inference service
Inference Service (FastAPI)
  ↓ Check cache (Redis)
Prediction Cache (Redis)
  ↓ If miss → Call Ollama
Ollama Inference Engine
  ↓ Load model from MinIO
Model Storage (MinIO)
  ↓ Run inference (GPU)
Prediction Result
  ↓ Cache result (Redis)
  ↓ Store in DB (PostgreSQL)
Predictions Database (PostgreSQL)
  ↓ Track experiment (MLflow)
MLflow Tracking
  ↓ Publish metrics (Prometheus)
Inference Metrics (latency, throughput)
  ↓ Log predictions (Loki)
Prediction Logs (Loki)
  ↓ Monitor with Grafana
Real-Time Monitoring Dashboard
```

#### Data Transformations
1. **Input**: Request payload (JSON, image, text)
2. **Preprocessing**: Resize images, tokenize text
3. **Normalization**: Apply training-time normalization
4. **Inference**: Model prediction (Ollama)
5. **Post-processing**: Convert logits to probabilities
6. **Confidence Scoring**: Calculate prediction confidence
7. **Result Formatting**: Format response as JSON
8. **Caching**: Cache predictions for repeated requests
9. **Logging**: Log input/output for auditing
10. **Metrics**: Track latency, throughput, error rate

#### Components Used
✅ Nginx, Istio, Keycloak, Redis, Ollama, MinIO, PostgreSQL, MLflow, Prometheus, Grafana, Loki, cert-manager, Kubernetes, Docker

---

### DJ10: Disaster Recovery Test
**Objective**: Backup and restore entire platform  
**Data Volume**: 5TB total (DBs + object storage)  

#### Data Flow
```
Production Databases
  ↓ pg_dump / mongodump / redis-cli bgsave
Database Backups
  ↓ Compress (gzip)
  ↓ Encrypt (Vault keys)
Encrypted Backup Files
  ↓ Upload (pgBackRest / MinIO)
Backup Storage (MinIO - backup bucket)
  ↓ Backup Kubernetes (Velero)
Velero Backup
  ↓ Store in MinIO
Kubernetes Backup (MinIO)
  ↓ Test restore (new namespace)
Restore Test Environment
  ↓ Restore PostgreSQL
pgBackRest Restore
  ↓ Verify data integrity
Data Validation
  ↓ Restore Kubernetes resources
Velero Restore
  ↓ Verify pods running
Health Checks
  ↓ Run smoke tests (Playwright)
Automated Test Suite
  ↓ Generate DR report
Disaster Recovery Report (MinIO)
  ↓ Metrics (Prometheus)
Backup Success Rate Dashboard
```

#### Data Transformations
1. **Backup**: Logical dump of databases
2. **Compression**: gzip compression (ratio: 5:1)
3. **Encryption**: AES-256 encryption with Vault keys
4. **Splitting**: Split large backups into chunks
5. **Checksumming**: Calculate SHA256 checksums
6. **Upload**: Multi-part upload to MinIO
7. **Verification**: Verify backup integrity
8. **Restore**: Decompress and decrypt
9. **Validation**: Compare checksums
10. **Testing**: Run automated tests to verify functionality

#### Components Used
✅ PostgreSQL, MongoDB, Redis, MinIO, pgBackRest, Velero, Vault, Prometheus, Grafana, Playwright, Kubernetes, kubectl, Helm, Loki, Alertmanager, Docker

**This journey tests backup/DR for all components!**

---

## 🧪 TESTING FRAMEWORK

### Playwright Test Suite Structure

```
/Users/dev1/github/medinovai-infrastructure/playwright/tests/
├── user-journeys/
│   ├── uj01-patient-admission.spec.ts
│   ├── uj02-radiology-workflow.spec.ts
│   ├── uj03-remote-monitoring.spec.ts
│   ├── uj04-clinical-trial-analytics.spec.ts
│   ├── uj05-ai-model-training.spec.ts
│   ├── uj06-compliance-audit.spec.ts
│   ├── uj07-infrastructure-health.spec.ts
│   ├── uj08-ehr-integration.spec.ts
│   ├── uj09-medical-image-ai.spec.ts
│   └── uj10-platform-admin.spec.ts
├── data-journeys/
│   ├── dj01-patient-registration-flow.spec.ts
│   ├── dj02-medical-imaging-pipeline.spec.ts
│   ├── dj03-remote-vitals-stream.spec.ts
│   ├── dj04-clinical-trial-events.spec.ts
│   ├── dj05-ml-training-pipeline.spec.ts
│   ├── dj06-document-workflow.spec.ts
│   ├── dj07-metrics-collection.spec.ts
│   ├── dj08-logs-pipeline.spec.ts
│   ├── dj09-ai-inference.spec.ts
│   └── dj10-disaster-recovery.spec.ts
├── infrastructure/
│   ├── tier1-containers.spec.ts
│   ├── tier2-networking.spec.ts
│   ├── tier3-databases.spec.ts
│   ├── tier4-messaging.spec.ts
│   ├── tier5-monitoring.spec.ts
│   ├── tier6-security.spec.ts
│   ├── tier7-ai-ml.spec.ts
│   ├── tier8-backup.spec.ts
│   └── tier9-testing.spec.ts
└── integration/
    ├── end-to-end-flow.spec.ts
    ├── performance-benchmarks.spec.ts
    └── security-validation.spec.ts
```

### Test Execution Strategy

#### Phase 1: Infrastructure Component Tests (1 hour)
- Test each tier independently
- Verify health endpoints
- Validate connectivity
- Check resource allocation

**Command**:
```bash
npx playwright test infrastructure/ --workers=9
```

#### Phase 2: Data Journey Tests (2 hours)
- Run data journey tests sequentially
- Validate data at each step
- Check data integrity
- Measure latency

**Command**:
```bash
npx playwright test data-journeys/ --workers=1
```

#### Phase 3: User Journey Tests (3 hours)
- Run user journey tests
- Simulate real user interactions
- Capture screenshots
- Record videos for failures

**Command**:
```bash
npx playwright test user-journeys/ --workers=3
```

#### Phase 4: Integration Tests (1 hour)
- End-to-end cross-journey tests
- Performance benchmarks
- Security validation

**Command**:
```bash
npx playwright test integration/ --workers=1
```

**Total Test Time**: ~7 hours

---

## ✅ VALIDATION CRITERIA

### Infrastructure Health Checks

| Component | Health Check | Expected Result | Failure Threshold |
|-----------|--------------|-----------------|-------------------|
| **Docker** | `docker info` | Running | 0% |
| **Kubernetes** | `kubectl get nodes` | All Ready | 0 not ready |
| **Istio** | `istioctl analyze` | No issues | 0 errors |
| **PostgreSQL** | `SELECT 1` | Returns 1 | Connection failed |
| **Redis** | `PING` | PONG | Connection timeout |
| **MongoDB** | `db.runCommand({ping: 1})` | ok: 1 | Connection failed |
| **MinIO** | `mc admin info` | Online | Offline |
| **Kafka** | `kafka-topics --list` | Lists topics | Timeout |
| **Prometheus** | `curl :9090/-/healthy` | HTTP 200 | Non-200 |
| **Grafana** | `curl :3000/api/health` | HTTP 200 | Non-200 |
| **Loki** | `curl :3100/ready` | HTTP 200 | Non-200 |
| **Keycloak** | `curl :8080/health` | HTTP 200 | Non-200 |
| **Vault** | `vault status` | Initialized | Sealed |
| **Ollama** | `curl :11434/api/tags` | HTTP 200 | Non-200 |
| **MLflow** | `curl :5000/health` | HTTP 200 | Non-200 |

### Performance Metrics

| Metric | Target | Warning | Critical |
|--------|--------|---------|----------|
| **API Latency (P95)** | < 100ms | > 200ms | > 500ms |
| **Database Query Time (P95)** | < 50ms | > 100ms | > 200ms |
| **Cache Hit Rate** | > 90% | < 70% | < 50% |
| **Message Queue Lag** | < 1000 | > 10K | > 100K |
| **Pod Restart Rate** | 0/hour | > 1/hour | > 5/hour |
| **Error Rate** | < 0.1% | > 1% | > 5% |
| **Resource Utilization (CPU)** | 40-70% | > 80% | > 90% |
| **Resource Utilization (RAM)** | 50-80% | > 85% | > 95% |
| **Disk I/O Wait** | < 10% | > 20% | > 50% |

### Data Integrity Checks

| Journey | Validation | Method |
|---------|------------|--------|
| **DJ1** | Patient record complete | SQL query |
| **DJ2** | Image metadata matches | Compare checksums |
| **DJ3** | Vitals data points count | Count rows |
| **DJ4** | Events processed = events received | Compare counts |
| **DJ5** | Training dataset valid | Validate schema |
| **DJ6** | OCR accuracy > 95% | Sample validation |
| **DJ7** | No missing metrics | Check gaps |
| **DJ8** | Log entries match | Count validation |
| **DJ9** | Prediction accuracy | Compare to ground truth |
| **DJ10** | Restore matches original | Checksum comparison |

---

## 📋 IMPLEMENTATION PLAN

### Phase 1: Test Development (Week 1)
**Duration**: 5 days  
**Team**: 2 QA Engineers + 1 Platform Engineer  

#### Day 1-2: Infrastructure Tests
- Write Playwright tests for Tier 1-9 components
- Create health check scripts
- Set up test fixtures
- Configure test data

#### Day 3-4: Data Journey Tests
- Implement DJ1-DJ5 tests
- Implement DJ6-DJ10 tests
- Add data validation logic
- Set up test database

#### Day 5: User Journey Tests
- Implement UJ1-UJ5 tests
- Implement UJ6-UJ10 tests
- Add screenshot capture
- Configure video recording

### Phase 2: Test Execution (Week 2)
**Duration**: 5 days  
**Team**: 3 QA Engineers  

#### Day 1: Infrastructure Validation
- Run Tier 1-9 component tests
- Document failures
- Fix infrastructure issues
- Re-run tests

#### Day 2-3: Data Journey Validation
- Run DJ1-DJ10 tests
- Validate data at each step
- Check data integrity
- Fix data flow issues

#### Day 4-5: User Journey Validation
- Run UJ1-UJ10 tests
- Review screenshots/videos
- Fix UI/API issues
- Re-run failed tests

### Phase 3: Ollama Validation (Week 3)
**Duration**: 3 days  
**Team**: 1 AI Engineer  

#### Day 1: Model Selection
- Select 3 best Ollama models per domain
- Prepare validation prompts
- Set up evaluation framework

#### Day 2: Architecture Validation
- Run qwen2.5:72b review
- Run deepseek-coder:33b review
- Run llama3.1:70b review
- Collect scores

#### Day 3: Iteration
- Address issues < 9/10
- Re-run validations
- Achieve 9/10+ consensus

### Phase 4: Documentation (Week 3)
**Duration**: 2 days  
**Team**: 1 Technical Writer  

#### Day 1: Test Documentation
- Document test setup
- Write test execution guide
- Create troubleshooting guide

#### Day 2: Journey Documentation
- Document user journeys
- Document data journeys
- Create architecture diagrams

---

## 🎯 EXPECTED OUTCOMES

### Success Metrics
- ✅ **100% Infrastructure Coverage**: All 35+ components tested
- ✅ **100% Test Pass Rate**: All Playwright tests passing
- ✅ **9.0/10+ Validation Score**: Ollama models consensus
- ✅ **< 1% Error Rate**: Production-ready reliability
- ✅ **Complete Documentation**: All journeys documented

### Deliverables
1. **Playwright Test Suite**: 30+ test files covering all journeys
2. **Test Execution Report**: HTML report with screenshots/videos
3. **Infrastructure Health Dashboard**: Grafana dashboard showing all components
4. **Validation Report**: 3-model Ollama validation results
5. **Journey Documentation**: Detailed documentation of all 20 journeys
6. **Architecture Diagrams**: Visual representation of data flows
7. **Runbook**: Operational runbook for infrastructure management

### Timeline
- **Week 1**: Test development (5 days)
- **Week 2**: Test execution and fixes (5 days)
- **Week 3**: Validation and documentation (5 days)
- **Total**: 15 business days (3 weeks)

### Resource Requirements
- **Personnel**: 2 QA Engineers, 1 Platform Engineer, 1 AI Engineer, 1 Technical Writer
- **Compute**: Full infrastructure running (32 CPU, 400GB RAM)
- **Time**: ~200 hours total effort

---

## 📝 NEXT STEPS

### Immediate Actions
1. **Review this plan** with stakeholders
2. **Approve scope and timeline**
3. **Allocate resources** (team members)
4. **Create GitHub project** for tracking
5. **Schedule kickoff meeting**

### User Approval Required
**This plan is ready for review. Please type "ACT" to begin implementation.**

---

**STATUS**: 🟡 AWAITING USER APPROVAL  
**MODE**: PLAN  
**QUALITY TARGET**: 9/10 from 3 Ollama Models per domain  
**ESTIMATED TIME**: 3 weeks (15 business days)  
**RISK LEVEL**: Low  

---

*This comprehensive plan ensures EVERY infrastructure component is tested through realistic healthcare workflows, providing end-to-end validation of the entire MedinovAI platform.*

