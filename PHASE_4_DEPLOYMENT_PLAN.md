# Phase 4: Search & Analytics Deployment 🔍

**Date**: 2025-10-02  
**Services**: Elasticsearch / OpenSearch  
**Target**: 9.0/10 validation score  
**Methodology**: Deploy → Test → Validate → Iterate  

---

## 🎯 Objectives

Deploy production-ready search and analytics infrastructure for:
1. **Full-text search** - Patient records, clinical notes, documents
2. **Log aggregation** - Centralized logging from all services
3. **Analytics** - Healthcare data analysis, reporting
4. **Monitoring** - Observability and alerting

---

## 🏗️ Architecture

### Option A: Elasticsearch (Industry Standard)
```
┌────────────────────────────────────┐
│     Elasticsearch Cluster          │
│  ┌──────────┐  ┌──────────┐       │
│  │  Master  │  │  Master  │       │
│  │  Node 1  │──│  Node 2  │       │
│  └──────────┘  └──────────┘       │
│                                     │
│  ┌──────────┐  ┌──────────┐       │
│  │   Data   │  │   Data   │       │
│  │  Node 1  │──│  Node 2  │       │
│  └──────────┘  └──────────┘       │
│                                     │
│  ┌──────────┐                      │
│  │  Kibana  │                      │
│  │   UI     │                      │
│  └──────────┘                      │
└────────────────────────────────────┘
```

### Option B: OpenSearch (Open Source, HIPAA-friendly)
```
┌────────────────────────────────────┐
│      OpenSearch Cluster            │
│  ┌──────────┐  ┌──────────┐       │
│  │OpenSearch│  │OpenSearch│       │
│  │  Node 1  │──│  Node 2  │       │
│  └──────────┘  └──────────┘       │
│                                     │
│  ┌──────────┐                      │
│  │OpenSearch│                      │
│  │Dashboards│                      │
│  └──────────┘                      │
└────────────────────────────────────┘
```

**Decision**: Start with OpenSearch (better licensing for healthcare)

---

## 📦 Phase 4 Components

### 1. OpenSearch (Search Engine)
- Version: 2.11.0 (latest stable)
- Ports: 9200 (REST API), 9300 (transport)
- Use Cases:
  - Patient record search
  - Clinical note indexing
  - Audit log storage (HIPAA)

### 2. OpenSearch Dashboards (Visualization)
- Version: 2.11.0
- Port: 5601
- Features:
  - Log visualization
  - Analytics dashboards
  - Alerting rules

### 3. Logstash / Fluent Bit (Log Ingestion)
- Collect logs from all services
- Parse and enrich
- Forward to OpenSearch

---

## 🚀 Deployment Steps

### Microstep 1: Deploy OpenSearch (Single Node)
**Time**: 15-20 min
**Validation**: 3-model review

```bash
# Deploy
docker-compose -f docker-compose-phase4.yml up -d opensearch

# Test
curl -XGET https://localhost:9200 -u admin:admin --insecure

# Playwright tests
npx playwright test tests/infrastructure/phase4-opensearch.spec.ts
```

### Microstep 2: Deploy OpenSearch Dashboards
**Time**: 10-15 min
**Validation**: 3-model review

```bash
# Deploy
docker-compose -f docker-compose-phase4.yml up -d opensearch-dashboards

# Test UI
open http://localhost:5601

# Playwright tests
npx playwright test tests/infrastructure/phase4-dashboards.spec.ts
```

### Microstep 3: Configure Log Ingestion
**Time**: 20-30 min
**Validation**: 3-model review

```bash
# Deploy Fluent Bit
docker-compose -f docker-compose-phase4.yml up -d fluent-bit

# Verify log flow
curl -XGET https://localhost:9200/_cat/indices
```

### Microstep 4: Create Healthcare Indices
**Time**: 15-20 min
**Validation**: 3-model review

```bash
# Patient records index
# Audit logs index  
# Clinical notes index
```

---

## 🧪 Testing Strategy

### Playwright Tests (Per Microstep)
1. **OpenSearch Connectivity**
   - REST API accessible
   - Cluster health green
   - Authentication working

2. **Index Operations**
   - Create index
   - Insert documents
   - Search queries
   - Delete index

3. **Dashboards**
   - UI loads
   - Login works
   - Can create visualizations

4. **Log Ingestion**
   - Logs arriving from Kafka
   - Logs arriving from RabbitMQ
   - Parsing correct

### DR Testing
- Backup/restore OpenSearch indices
- Snapshot repository configuration
- Restoration procedure

---

## 📋 Multi-Model Validation (After Each Microstep)

### Validation Script
```python
# validate_phase4_microstep.py
models = ["qwen2.5:72b", "deepseek-coder:33b", "llama3.1:70b"]
target_score = 9.0

# Evaluate:
# - Deployment quality
# - Test coverage
# - HIPAA compliance
# - Production readiness
```

### If Score < 9.0
1. Review brutal feedback
2. Address critical gaps
3. Re-validate
4. Iterate until 9.0+

---

## 🔐 Security & Compliance

### HIPAA Requirements
- ✅ Encryption at rest (index encryption)
- ✅ Encryption in transit (TLS)
- ✅ Access control (authentication/authorization)
- ✅ Audit logging (all API calls logged)
- ✅ Data retention policies

### Security Configuration
```yaml
opensearch:
  environment:
    - OPENSEARCH_JAVA_OPTS=-Xms512m -Xmx512m
    - DISABLE_SECURITY_PLUGIN=false  # Enable security
    - OPENSEARCH_INITIAL_ADMIN_PASSWORD=MedinovAI_Secure_2025!
  security:
    - TLS enabled
    - Strong authentication
    - Role-based access control
```

---

## 💾 Backup & Recovery

### Snapshot Configuration
```bash
# Register snapshot repository
curl -XPUT "https://localhost:9200/_snapshot/medinovai_backups" \
  -H 'Content-Type: application/json' \
  -d '{
    "type": "fs",
    "settings": {
      "location": "/mnt/backups/opensearch"
    }
  }'

# Create snapshot
curl -XPUT "https://localhost:9200/_snapshot/medinovai_backups/snapshot_1"

# Restore snapshot
curl -XPOST "https://localhost:9200/_snapshot/medinovai_backups/snapshot_1/_restore"
```

---

## 📊 Success Criteria

### Per Microstep
- ✅ Service deployed and healthy
- ✅ Playwright tests passing (100%)
- ✅ 3-model validation ≥ 9.0/10
- ✅ DR procedures tested

### Overall Phase 4
- ✅ Full-text search working
- ✅ Logs aggregated from all services
- ✅ Dashboards operational
- ✅ Backup/restore validated
- ✅ HIPAA compliant
- ✅ Documentation complete

---

## 🚦 Let's Begin!

**First Microstep**: Deploy OpenSearch single node

**Expected Time**: 15-20 minutes
**Validation**: Immediate 3-model review

---

Ready to proceed? 🚀

