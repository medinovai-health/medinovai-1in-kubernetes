# 🏗️ DEFINITIVE MedinovAI Infrastructure Tech Stack

**Version**: 1.0.0  
**Date**: October 2, 2025  
**Status**: AUTHORITATIVE - SINGLE SOURCE OF TRUTH  
**Scope**: All 243+ MedinovAI Repositories  

---

## 🎯 MISSION STATEMENT

**THIS REPOSITORY (`medinovai-infrastructure`) IS THE SINGLE SOURCE OF TRUTH FOR ALL PLATFORM SOFTWARE AND INFRASTRUCTURE COMPONENTS.**

### Core Principles
1. **NO other repository** shall install infrastructure software (Istio, Docker, MongoDB, PostgreSQL, ELK, etc.)
2. **ALL infrastructure software** must be installed, configured, and validated by this repository
3. **EVERY software installation** must be validated with:
   - **Playwright**: End-to-end functional validation
   - **3 Best Ollama Models**: Configuration, security, and performance validation
4. **ZERO conflicts**: Centralized port management, version control, dependency resolution
5. **COMPREHENSIVE monitoring**: Health checks, metrics, logs, and alerts for all services

---

## 📊 REPOSITORY SCOPE

### Total Repositories Analyzed
- **GitHub MedinovAI Org**: 92 repositories (comprehensive_medinovai_repository_list.json)
- **MyOnsite Healthcare**: 17 repositories (all_myonsite_healthcare_repos.json)
- **Total Core Repos**: 109+ repositories
- **Extended Ecosystem**: 243+ repositories (including integrations, testing, documentation)

### Repository Categories
1. **Core Infrastructure** (1 repo): medinovai-infrastructure ← THIS REPO
2. **Core Platform** (3 repos): core-platform, api-gateway, authentication
3. **Security Services** (5 repos): security-services, compliance-services, audit-logging, authorization, encryption
4. **Data Services** (4 repos): data-services, data-officer, registry, analytics
5. **Healthcare Services** (15+ repos): clinical-services, patient-services, healthLLM, EDC, ETMF, CTMS
6. **Business Services** (8 repos): AutoMarketingPro, AutoBidPro, AutoSalesPro, ATS, QMS, Credentialing
7. **Integration Services** (20+ repos): FHIR, HL7, DICOM, EHR, pharmacy, laboratory
8. **AI/ML Services** (10+ repos): ai-engine, ml-models, nlp-service, computer-vision, diagnostic-ai
9. **Testing Services** (7 repos): testing-framework, qa-automation, performance-testing, security-testing
10. **Documentation** (6 repos): documentation, api-docs, user-guide, developer-guide

---

## 🔧 TIER 1: CONTAINER & ORCHESTRATION (CRITICAL)

### Docker & Container Runtime
| Software | Version | Purpose | Port(s) | Validation Models |
|----------|---------|---------|---------|-------------------|
| **Docker Desktop** | 28.4.0 | Container runtime | N/A | qwen2.5:72b, deepseek-coder:33b, llama3.1:70b |
| **OrbStack** | Latest | Alternative container runtime (Mac) | N/A | qwen2.5:72b, deepseek-coder:33b, llama3.1:70b |

### Kubernetes (k3d/k3s)
| Software | Version | Purpose | Port(s) | Validation Models |
|----------|---------|---------|---------|-------------------|
| **k3d** | v5.6.0 | Kubernetes in Docker | N/A | qwen2.5:72b, deepseek-coder:33b, llama3.1:70b |
| **k3s** | v1.31.5+k3s1 | Lightweight Kubernetes | 6443, 10250 | qwen2.5:72b, deepseek-coder:33b, llama3.1:70b |
| **kubectl** | v1.28.0+ | Kubernetes CLI | N/A | qwen2.5:72b, deepseek-coder:33b, llama3.1:70b |
| **Helm** | v3.12.0+ | Kubernetes package manager | N/A | qwen2.5:72b, deepseek-coder:33b, llama3.1:70b |

**Cluster Configuration:**
- **Name**: k3d-medinovai-cluster
- **Nodes**: 2 control-plane + 3 workers
- **Networking**: CoreDNS, Traefik ingress
- **Storage**: Local storage, emptyDir volumes

---

## 🔧 TIER 2: SERVICE MESH & NETWORKING (CRITICAL)

### Service Mesh
| Software | Version | Purpose | Port(s) | Validation Models |
|----------|---------|---------|---------|-------------------|
| **Istio** | v1.27.1 | Service mesh, mTLS, traffic management | 15010-15017 | qwen2.5:72b, deepseek-coder:33b, llama3.1:70b |
| **istioctl** | v1.27.1 | Istio CLI | N/A | qwen2.5:72b, deepseek-coder:33b, llama3.1:70b |

**Istio Components:**
- **istiod**: Control plane
- **istio-ingressgateway**: External traffic entry point (80, 443)
- **istio-egressgateway**: External traffic exit point

### Load Balancing & API Gateway
| Software | Version | Purpose | Port(s) | Validation Models |
|----------|---------|---------|---------|-------------------|
| **Nginx** | nginx:alpine | API gateway, reverse proxy, load balancer | 80, 443, 8080 | qwen2.5:72b, llama3.1:70b, mixtral:8x22b |
| **Traefik** | v3.0 | Kubernetes ingress controller, dynamic routing | 80, 443 | qwen2.5:72b, llama3.1:70b, mixtral:8x22b |

---

## 🗄️ TIER 3: DATABASES & DATA STORES (CRITICAL)

### Relational Databases
| Software | Version | Purpose | Port | Resource Allocation | Validation Models |
|----------|---------|---------|------|---------------------|-------------------|
| **PostgreSQL** | 15-alpine | Primary relational DB (patient data, clinical records) | 5432 | 4 CPU, 16GB RAM | qwen2.5:72b, deepseek-coder:33b, llama3.1:70b |
| **TimescaleDB** | latest-pg15 | Time-series data (patient vitals, monitoring) | 5433 | 2 CPU, 8GB RAM | qwen2.5:72b, deepseek-coder:33b, llama3.1:70b |

**PostgreSQL Clients:**
- psycopg2-binary>=2.9.0
- SQLAlchemy>=2.0.0
- asyncpg (for async operations)

### NoSQL Databases
| Software | Version | Purpose | Port | Resource Allocation | Validation Models |
|----------|---------|---------|------|---------------------|-------------------|
| **MongoDB** | 7.0 | Document store (unstructured medical data, logs) | 27017 | 2 CPU, 8GB RAM | qwen2.5:72b, deepseek-coder:33b, llama3.1:70b |

**MongoDB Clients:**
- pymongo>=4.0.0
- motor (async MongoDB driver)

### Cache & Session Store
| Software | Version | Purpose | Port | Resource Allocation | Validation Models |
|----------|---------|---------|------|---------------------|-------------------|
| **Redis** | 7-alpine | Caching, session storage, real-time data | 6379 | 1 CPU, 4GB RAM | qwen2.5:72b, llama3.1:70b, mistral:7b |

**Redis Clients:**
- redis-py>=4.5.0
- aioredis (async Redis driver)

### Object Storage
| Software | Version | Purpose | Port(s) | Resource Allocation | Validation Models |
|----------|---------|---------|---------|---------------------|-------------------|
| **MinIO** | latest | S3-compatible object storage (DICOM images, PDFs, lab reports) | 9000 (API), 9001 (Console) | 2 CPU, 4GB RAM | qwen2.5:72b, deepseek-coder:33b, llama3.1:70b |

---

## 📡 TIER 4: MESSAGE QUEUES & STREAMING (CRITICAL)

### Event Streaming
| Software | Version | Purpose | Port | Resource Allocation | Validation Models |
|----------|---------|---------|------|---------------------|-------------------|
| **Apache Kafka** | confluentinc/cp-kafka:latest | Event streaming, async communication | 9092 | 4 CPU, 16GB RAM | qwen2.5:72b, deepseek-coder:33b, llama3.1:70b |
| **Zookeeper** | confluentinc/cp-zookeeper:latest | Kafka coordination | 2181 | Included with Kafka | qwen2.5:72b, deepseek-coder:33b, llama3.1:70b |

**Kafka Clients:**
- aiokafka>=0.8.0
- kafka-python>=2.0.0

### Message Queue (Alternative)
| Software | Version | Purpose | Port(s) | Resource Allocation | Validation Models |
|----------|---------|---------|---------|---------------------|-------------------|
| **RabbitMQ** | 3-management-alpine | Alternative message queue (simpler pub/sub) | 5672 (AMQP), 15672 (Mgmt UI) | 2 CPU, 4GB RAM | qwen2.5:72b, llama3.1:70b, mistral:7b |

---

## 📊 TIER 5: MONITORING & OBSERVABILITY (CRITICAL)

### Metrics Collection & Storage
| Software | Version | Purpose | Port | Resource Allocation | Validation Models |
|----------|---------|---------|------|---------------------|-------------------|
| **Prometheus** | prom/prometheus:latest | Metrics collection, storage, alerting | 9090 | 2 CPU, 8GB RAM | qwen2.5:72b, deepseek-coder:33b, llama3.1:70b |
| **Alertmanager** | prom/alertmanager:latest | Alert routing, notification | 9093 | 1 CPU, 2GB RAM | qwen2.5:72b, llama3.1:70b, mistral:7b |

**Config Path:** `./prometheus-config/prometheus.yml`

### Visualization & Dashboards
| Software | Version | Purpose | Port | Resource Allocation | Validation Models |
|----------|---------|---------|------|---------------------|-------------------|
| **Grafana** | grafana/grafana:latest | Metrics visualization, dashboards | 3000 | 2 CPU, 4GB RAM | qwen2.5:72b, llama3.1:70b, mixtral:8x22b |
| **Apache Superset** | latest | Business intelligence, analytics | 8088 | 2 CPU, 4GB RAM | qwen2.5:72b, llama3.1:70b, mixtral:8x22b |

**Grafana Default Credentials:**
- Username: admin
- Password: medinovai123

### Log Aggregation & Analysis
| Software | Version | Purpose | Port | Resource Allocation | Validation Models |
|----------|---------|---------|------|---------------------|-------------------|
| **Loki** | grafana/loki:latest | Lightweight log aggregation (Grafana native) | 3100 | 1 CPU, 4GB RAM | qwen2.5:72b, deepseek-coder:33b, llama3.1:70b |
| **Promtail** | grafana/promtail:latest | Log shipping agent | N/A | 0.5 CPU, 1GB RAM | qwen2.5:72b, llama3.1:70b, mistral:7b |

**Config Path:** `./loki-config/loki.yaml`, `./promtail-config/promtail.yaml`

### ELK Stack (Alternative to Loki - Optional)
| Software | Version | Purpose | Port | Resource Allocation | Validation Models |
|----------|---------|---------|------|---------------------|-------------------|
| **Elasticsearch** | 8.x | Log aggregation, search | 9200 | 4 CPU, 16GB RAM | qwen2.5:72b, deepseek-coder:33b, llama3.1:70b |
| **Logstash** | 8.x | Log processing pipeline | 5044 | 2 CPU, 4GB RAM | qwen2.5:72b, deepseek-coder:33b, llama3.1:70b |
| **Kibana** | 8.x | Log visualization, analysis | 5601 | 2 CPU, 4GB RAM | qwen2.5:72b, llama3.1:70b, mixtral:8x22b |

---

## 🔐 TIER 6: SECURITY & SECRETS MANAGEMENT (CRITICAL)

### Identity & Access Management (IAM)
| Software | Version | Purpose | Port | Resource Allocation | Validation Models |
|----------|---------|---------|------|---------------------|-------------------|
| **Keycloak** | 24.0 | SSO, OAuth2, OIDC, identity management | 8080 | 2 CPU, 4GB RAM | qwen2.5:72b, deepseek-coder:33b, llama3.1:70b |

**Image:** `quay.io/keycloak/keycloak:24.0`

### Secrets Management
| Software | Version | Purpose | Port | Resource Allocation | Validation Models |
|----------|---------|---------|------|---------------------|-------------------|
| **HashiCorp Vault** | latest | Secrets management, encryption, HIPAA compliance | 8200 | 2 CPU, 4GB RAM | qwen2.5:72b, deepseek-coder:33b, llama3.1:70b |

**Vault Config Path:** `./vault-config/vault.hcl`

### Certificate Management
| Software | Version | Purpose | Port | Validation Models |
|----------|---------|---------|------|-------------------|
| **cert-manager** | v1.12.0+ | Kubernetes certificate management | N/A | qwen2.5:72b, deepseek-coder:33b, llama3.1:70b |

---

## 🤖 TIER 7: AI/ML INFRASTRUCTURE (CRITICAL)

### LLM Inference
| Software | Version | Purpose | Port | Resource Allocation | Validation Models |
|----------|---------|---------|------|---------------------|-------------------|
| **Ollama** | latest | Local LLM inference (67+ models) | 11434 | Native macOS (NOT Docker) | qwen2.5:72b, llama3.1:70b, mixtral:8x22b |

**Installed Models (67+):**
- qwen2.5:72b (Chief Architect)
- qwen2.5:32b (Senior Architect)
- qwen2.5:14b (Technical Lead)
- deepseek-coder:33b (Code Quality Expert)
- llama3.1:70b (Healthcare Specialist)
- mixtral:8x22b (Multi-perspective Validator)
- mistral:7b (Performance Optimizer)
- codellama:70b (Infrastructure as Code Expert)
- deepseek-r1:70b (Research & Analysis)
- ...and 58 more models

**Status:** ✅ Running natively on macOS (NOT containerized)

### ML Experiment Tracking
| Software | Version | Purpose | Port | Resource Allocation | Validation Models |
|----------|---------|---------|------|---------------------|-------------------|
| **MLflow** | latest | ML experiment tracking, model registry | 5000 | 2 CPU, 4GB RAM | qwen2.5:72b, deepseek-coder:33b, llama3.1:70b |

---

## 💾 TIER 8: BACKUP & DISASTER RECOVERY (IMPORTANT)

### Kubernetes Backup
| Software | Version | Purpose | Port | Validation Models |
|----------|---------|---------|------|-------------------|
| **Velero** | latest | Kubernetes cluster backup, restore | N/A | qwen2.5:72b, deepseek-coder:33b, llama3.1:70b |

### Database Backup
| Software | Version | Purpose | Port | Validation Models |
|----------|---------|---------|------|-------------------|
| **pgBackRest** | latest | PostgreSQL backup, point-in-time recovery | N/A | qwen2.5:72b, deepseek-coder:33b, llama3.1:70b |

---

## 🧪 TIER 9: TESTING & VALIDATION (CRITICAL)

### End-to-End Testing
| Software | Version | Purpose | Validation Models |
|----------|---------|---------|-------------------|
| **Playwright** | @playwright/test@latest | E2E testing, browser automation | qwen2.5:72b, deepseek-coder:33b, llama3.1:70b |

**Playwright Capabilities:**
- Web automation & form filling
- Screenshot capture & visual testing
- Performance monitoring (Web Vitals)
- Cross-browser testing (Chrome, Firefox, Safari, Edge)

**Validation Requirement:**
- **EVERY infrastructure software** must have a Playwright test
- Tests must validate: Installation, Configuration, Connectivity, Health, Performance

### Load Testing
| Software | Version | Purpose | Validation Models |
|----------|---------|---------|-------------------|
| **k6** | latest | Load testing, performance testing | qwen2.5:72b, llama3.1:70b, mistral:7b |
| **Locust** | latest | Distributed load testing | qwen2.5:72b, llama3.1:70b, mistral:7b |

---

## 📦 TIER 10: PYTHON DEPENDENCIES (INFRASTRUCTURE)

### Core Dependencies (requirements.txt)
```txt
# HTTP & API clients
requests>=2.31.0
urllib3>=2.0.0

# Kubernetes & Container tools
kubernetes>=28.1.0
docker>=6.1.0

# Database connectors
sqlalchemy>=2.0.0
psycopg2-binary>=2.9.0
pymongo>=4.0.0
redis-py>=4.5.0

# Message Queue clients
aiokafka>=0.8.0
kafka-python>=2.0.0

# Monitoring & Metrics
prometheus-client>=0.17.0
grafana-api>=1.0.3
prometheus-api-client>=0.5.3

# Security & Cryptography
cryptography>=41.0.0
pyjwt>=2.8.0

# Testing
pytest>=7.4.0
pytest-cov>=4.1.0
pytest-asyncio>=0.21.0
playwright>=1.40.0

# Code Quality
black>=23.7.0
isort>=5.12.0
flake8>=6.0.0
pylint>=2.17.0
mypy>=1.5.0

# Infrastructure as Code
python-hcl2>=4.3.0

# Configuration & YAML
PyYAML>=6.0.1
python-dotenv>=1.0.0
jinja2>=3.1.0

# CLI & Utilities
click>=8.1.0
typer>=0.9.0
rich>=13.5.0
tqdm>=4.65.0

# Git operations
GitPython>=3.1.0

# Async support
aiohttp>=3.8.0
asyncio>=3.4.3

# Documentation
mkdocs>=1.5.0
mkdocs-material>=9.1.0
mkdocs-mermaid2-plugin>=1.1.0
```

**Full Path:** `/Users/dev1/github/medinovai-infrastructure/requirements.txt`

---

## 🎯 VALIDATION FRAMEWORK

### 3-Model Validation Strategy

**EVERY infrastructure software installation must be validated by 3 best-suited Ollama models:**

#### Model Selection Criteria
1. **qwen2.5:72b** - Always included for architecture & design review
2. **Model 2** - Selected based on domain (security, performance, healthcare, etc.)
3. **Model 3** - Selected based on technical area (code quality, infrastructure, etc.)

#### Domain-Specific Model Selection

| Domain | Best 3 Models |
|--------|---------------|
| **Databases** | qwen2.5:72b, deepseek-coder:33b, llama3.1:70b |
| **Security** | qwen2.5:72b, deepseek-coder:33b, llama3.1:70b |
| **Networking** | qwen2.5:72b, mixtral:8x22b, llama3.1:70b |
| **Monitoring** | qwen2.5:72b, llama3.1:70b, mistral:7b |
| **AI/ML** | qwen2.5:72b, llama3.1:70b, mixtral:8x22b |
| **Message Queues** | qwen2.5:72b, deepseek-coder:33b, llama3.1:70b |
| **Kubernetes** | qwen2.5:72b, deepseek-coder:33b, llama3.1:70b |

#### Validation Criteria (10/10 Scale)
1. **Configuration Quality** (2 points)
2. **Security Implementation** (2 points)
3. **Performance Optimization** (2 points)
4. **Best Practices Adherence** (2 points)
5. **Integration Quality** (2 points)

**Target Score:** 9.0/10 minimum from all 3 models (weighted consensus)

### Playwright Validation

**EVERY infrastructure software must have:**

1. **Installation Test**
   - Verify software is installed correctly
   - Check version matches expected

2. **Configuration Test**
   - Validate configuration files
   - Check environment variables
   - Verify connections to dependencies

3. **Health Check Test**
   - Verify service is running
   - Check health endpoints
   - Validate expected responses

4. **Performance Test**
   - Measure response times
   - Check resource usage
   - Validate throughput

5. **Integration Test**
   - Test connections to other services
   - Validate data flow
   - Check end-to-end scenarios

**Test Location:** `/Users/dev1/github/medinovai-infrastructure/playwright/tests/infrastructure/`

**Example Test Structure:**
```
playwright/tests/infrastructure/
├── databases/
│   ├── postgresql.spec.ts
│   ├── mongodb.spec.ts
│   ├── redis.spec.ts
│   └── timescaledb.spec.ts
├── monitoring/
│   ├── prometheus.spec.ts
│   ├── grafana.spec.ts
│   └── loki.spec.ts
├── kubernetes/
│   ├── cluster-health.spec.ts
│   └── istio-mesh.spec.ts
└── security/
    ├── keycloak.spec.ts
    └── vault.spec.ts
```

---

## 📈 RESOURCE ALLOCATION SUMMARY

### Current System Capacity
- **Mac Studio M3/M4 Ultra**
- **CPU**: 24 cores (32 available on M3 Ultra)
- **RAM**: 393GB allocated (512GB available on M3 Ultra)
- **GPU**: 80 cores (M3 Ultra)
- **Neural Engine**: 32 cores (M3 Ultra)

### Total Resource Allocation

| Category | CPU Cores | RAM (GB) |
|----------|-----------|----------|
| **Databases** | 9 | 36 |
| **Message Queues** | 6 | 20 |
| **Monitoring** | 5 | 18 |
| **Security** | 4 | 8 |
| **Kubernetes** | 2 | 16 |
| **Services** | 4 | 20 |
| **System Reserve** | 2 | 8 |
| **TOTAL** | **32** | **126** |

**Status:** ✅ Within capacity (32 CPU, 126GB RAM used of 32 CPU, 512GB RAM available)

---

## 🚀 DEPLOYMENT SEQUENCE

### Phase 1: Foundation (Tier 1-2)
1. Docker/OrbStack
2. Kubernetes (k3d/k3s)
3. Istio Service Mesh
4. Traefik/Nginx

**Validation:** Playwright + (qwen2.5:72b, deepseek-coder:33b, llama3.1:70b)

### Phase 2: Data Layer (Tier 3)
1. PostgreSQL
2. Redis
3. MongoDB
4. TimescaleDB
5. MinIO

**Validation:** Playwright + (qwen2.5:72b, deepseek-coder:33b, llama3.1:70b)

### Phase 3: Event Streaming (Tier 4)
1. Zookeeper
2. Kafka
3. RabbitMQ (optional)

**Validation:** Playwright + (qwen2.5:72b, deepseek-coder:33b, llama3.1:70b)

### Phase 4: Monitoring (Tier 5)
1. Prometheus + Alertmanager
2. Grafana
3. Loki + Promtail

**Validation:** Playwright + (qwen2.5:72b, llama3.1:70b, mistral:7b)

### Phase 5: Security (Tier 6)
1. Keycloak
2. HashiCorp Vault
3. cert-manager

**Validation:** Playwright + (qwen2.5:72b, deepseek-coder:33b, llama3.1:70b)

### Phase 6: AI/ML (Tier 7)
1. Ollama (native - already running)
2. MLflow

**Validation:** Playwright + (qwen2.5:72b, llama3.1:70b, mixtral:8x22b)

### Phase 7: Backup & DR (Tier 8)
1. Velero
2. pgBackRest

**Validation:** Playwright + (qwen2.5:72b, deepseek-coder:33b, llama3.1:70b)

---

## 🎯 CONTINUOUS HEALTH MONITORING

### Health Check Requirements

**EVERY infrastructure software must expose:**

1. **Health Endpoint**
   - HTTP/HTTPS endpoint returning health status
   - Example: `/health`, `/healthz`, `/api/health`
   - Response: 200 OK when healthy

2. **Metrics Endpoint**
   - Prometheus-compatible metrics endpoint
   - Example: `/metrics`
   - Scraped by Prometheus every 30s

3. **Readiness Probe**
   - Kubernetes readiness probe
   - Indicates when service is ready to accept traffic

4. **Liveness Probe**
   - Kubernetes liveness probe
   - Indicates when service needs restart

### Monitoring Dashboard

**Grafana Dashboard Requirements:**
- Overview dashboard showing all infrastructure services
- Individual dashboards for each tier
- Alert panels for critical issues
- Performance metrics (CPU, RAM, disk, network)
- Custom metrics per service

**Dashboard Location:** `/Users/dev1/github/medinovai-infrastructure/grafana-provisioning/dashboards/`

---

## 📝 PORT ALLOCATION REGISTRY

### Reserved Port Ranges
- **80-999**: Reserved for HTTP/HTTPS services
- **1000-7999**: Reserved for system services
- **8000-8999**: Reserved for MedinovAI application services
- **9000-9999**: Reserved for monitoring & infrastructure services
- **10000-19999**: Reserved for databases & data stores
- **20000+**: Available for future expansion

### Current Port Allocations

#### System Ports
| Service | Port(s) | Protocol |
|---------|---------|----------|
| HTTP | 80 | TCP |
| HTTPS | 443 | TCP |
| Kubernetes API | 6443 | TCP |
| Kubernetes Kubelet | 10250 | TCP |

#### Infrastructure Ports
| Service | Port(s) | Protocol |
|---------|---------|----------|
| Traefik | 80, 443 | TCP |
| Nginx | 80, 443, 8080 | TCP |
| Prometheus | 9090 | TCP |
| Alertmanager | 9093 | TCP |
| Grafana | 3000 | TCP |
| Loki | 3100 | TCP |
| Elasticsearch | 9200 | TCP |
| Kibana | 5601 | TCP |
| Logstash | 5044 | TCP |

#### Database Ports
| Service | Port | Protocol |
|---------|------|----------|
| PostgreSQL | 5432 | TCP |
| TimescaleDB | 5433 | TCP |
| MongoDB | 27017 | TCP |
| Redis | 6379 | TCP |
| MinIO API | 9000 | TCP |
| MinIO Console | 9001 | TCP |

#### Message Queue Ports
| Service | Port(s) | Protocol |
|---------|---------|----------|
| Kafka | 9092 | TCP |
| Zookeeper | 2181 | TCP |
| RabbitMQ AMQP | 5672 | TCP |
| RabbitMQ Management | 15672 | TCP |

#### Security Ports
| Service | Port | Protocol |
|---------|------|----------|
| Keycloak | 8080 | TCP |
| Vault | 8200 | TCP |

#### AI/ML Ports
| Service | Port | Protocol |
|---------|------|----------|
| Ollama | 11434 | TCP |
| MLflow | 5000 | TCP |

#### Istio Ports
| Service | Port(s) | Protocol |
|---------|---------|----------|
| Istio Pilot | 15010-15017 | TCP |
| Istio Ingress | 80, 443 | TCP |

---

## 🔒 SECURITY REQUIREMENTS

### Mandatory Security Measures

**EVERY infrastructure software must implement:**

1. **Network Isolation**
   - Kubernetes network policies
   - Service mesh mTLS encryption
   - Firewall rules

2. **Access Control**
   - RBAC (Role-Based Access Control)
   - Service accounts with least privilege
   - API authentication & authorization

3. **Secrets Management**
   - NO hardcoded secrets in code or configs
   - Secrets stored in HashiCorp Vault or Kubernetes secrets
   - Encrypted at rest and in transit

4. **Audit Logging**
   - All access logged to centralized system
   - Logs stored for 7+ years (HIPAA compliance)
   - Tamper-proof log storage

5. **Security Scanning**
   - Container image scanning (Trivy, Clair)
   - Vulnerability scanning
   - Compliance scanning (HIPAA, SOC2)

6. **Encryption**
   - TLS 1.3 for all external communications
   - mTLS for all internal service-to-service communications
   - Data encryption at rest (AES-256)

---

## 📋 COMPLIANCE REQUIREMENTS

### HIPAA Compliance

**Infrastructure components must support:**
- Audit controls (164.312(b))
- Integrity controls (164.312(c)(1))
- Person or entity authentication (164.312(d))
- Transmission security (164.312(e))

### SOC 2 Type II

**Infrastructure must demonstrate:**
- Security
- Availability
- Processing integrity
- Confidentiality
- Privacy

---

## 🎓 DOCUMENTATION REQUIREMENTS

### Required Documentation (Per Software)

1. **Installation Guide**
   - Prerequisites
   - Installation steps
   - Configuration options
   - Troubleshooting

2. **Configuration Guide**
   - Configuration files
   - Environment variables
   - Secrets management
   - Performance tuning

3. **Operations Guide**
   - Health checks
   - Monitoring & alerts
   - Backup & restore
   - Disaster recovery

4. **Security Guide**
   - Authentication & authorization
   - Network policies
   - Encryption
   - Audit logging

5. **Integration Guide**
   - API documentation
   - Client libraries
   - Connection examples
   - Best practices

**Documentation Location:** `/Users/dev1/github/medinovai-infrastructure/docs/infrastructure/<software-name>/`

---

## 🔄 VERSION CONTROL & UPDATES

### Semantic Versioning

**ALL infrastructure software versions must use semantic versioning:**
- MAJOR.MINOR.PATCH (e.g., 1.27.1)
- MAJOR: Breaking changes
- MINOR: New features, backwards compatible
- PATCH: Bug fixes, backwards compatible

### Update Policy

1. **Critical Security Updates**
   - Applied within 24 hours
   - Tested in dev/staging first
   - Rollback plan required

2. **Minor Updates**
   - Applied monthly
   - Validated by 3 Ollama models
   - Tested with Playwright

3. **Major Updates**
   - Applied quarterly
   - Full validation cycle
   - Extended testing period (2-4 weeks)

### Change Management

**EVERY infrastructure change must:**
1. Create a change request (GitHub Issue)
2. Get approval from 3 Ollama models (9/10+ score)
3. Pass all Playwright tests
4. Have rollback plan documented
5. Be deployed during maintenance window

---

## 📊 SUCCESS METRICS

### Deployment Success Criteria

**Infrastructure is considered successfully deployed when:**

1. ✅ All Tier 1-7 services are running
2. ✅ All health checks pass
3. ✅ All Playwright tests pass (100%)
4. ✅ All 3 Ollama models score 9.0/10+
5. ✅ All monitoring dashboards active
6. ✅ All alerts configured
7. ✅ All documentation complete
8. ✅ Disaster recovery tested
9. ✅ Security audit passed
10. ✅ HIPAA compliance validated

### Key Performance Indicators (KPIs)

| KPI | Target | Current |
|-----|--------|---------|
| **System Uptime** | 99.9% | TBD |
| **Average Response Time** | < 100ms | TBD |
| **Deployment Success Rate** | 100% | TBD |
| **Test Pass Rate** | 100% | TBD |
| **Model Validation Score** | 9.0/10+ | TBD |
| **Security Incidents** | 0 | 0 |
| **Compliance Violations** | 0 | 0 |

---

## 🚨 CRITICAL REMINDERS

### 🔴 ABSOLUTE RULES

1. **NO other repository** shall install ANY infrastructure software listed in this document
2. **ALL infrastructure software** must be installed by this repository ONLY
3. **EVERY infrastructure software** must be validated by:
   - ✅ Playwright (E2E tests)
   - ✅ 3 Best Ollama Models (9/10+ score)
4. **ZERO exceptions** - these rules apply to ALL 243+ repositories
5. **COMPREHENSIVE health monitoring** - all services must expose health/metrics endpoints
6. **HIPAA & SOC2 compliance** - all infrastructure must meet regulatory requirements

### 📌 ENFORCEMENT

- This document is the **SINGLE SOURCE OF TRUTH**
- All PRs touching infrastructure must reference this document
- All new infrastructure additions require:
  1. Update to this document
  2. Playwright tests
  3. 3-model validation (9/10+ score)
  4. Security audit
  5. Documentation

---

## 📞 CONTACTS & RESOURCES

### Key Documents
- **This Document**: `/Users/dev1/github/medinovai-infrastructure/docs/DEFINITIVE_MEDINOVAI_TECH_STACK.md`
- **Infrastructure Catalog**: `/Users/dev1/github/medinovai-infrastructure/docs/MEDINOVAI_INFRASTRUCTURE_CATALOG.md`
- **Deployment Guide**: `/Users/dev1/github/medinovai-infrastructure/INFRASTRUCTURE_DEPLOYMENT_GUIDE.md`
- **Istio Setup**: `/Users/dev1/github/medinovai-infrastructure/ISTIO_SETUP_GUIDE.md`

### Repository
- **GitHub**: https://github.com/medinovai/medinovai-infrastructure
- **GitLab**: https://git.myonsitehealthcare.com/medinovai/medinovai-infrastructure

---

## 📝 CHANGELOG

### v1.0.0 (October 2, 2025)
- ✅ Initial definitive tech stack document
- ✅ Comprehensive software inventory (Tiers 1-10)
- ✅ 3-model validation framework
- ✅ Playwright testing requirements
- ✅ Complete port allocation registry
- ✅ Security & compliance requirements
- ✅ Resource allocation summary
- ✅ Health monitoring framework

---

**STATUS**: ✅ AUTHORITATIVE - READY FOR IMPLEMENTATION  
**VERSION**: 1.0.0  
**LAST UPDATED**: October 2, 2025  
**NEXT REVIEW**: January 2, 2026 (Quarterly)  

---

**THIS DOCUMENT IS THE SINGLE SOURCE OF TRUTH FOR ALL MEDINOVAI INFRASTRUCTURE SOFTWARE.**


