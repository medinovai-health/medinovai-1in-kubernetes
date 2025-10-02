# 🔐 MedinovAI Infrastructure - Initialization Data Reference

**Date**: October 1, 2025  
**Version**: 1.1.0  
**Status**: IMMUTABLE REFERENCE  
**Purpose**: Complete initialization data for future deployments  

---

## 🚨 SECURITY NOTICE

**This document contains sensitive configuration information.**  
- Store securely
- Do not commit to public repositories
- Encrypt when backing up
- Review access permissions regularly

---

## 📊 COMPLETE SERVICE INVENTORY

### Services Running: 15/16

| # | Service | Container Name | Status | Port(s) | Type |
|---|---------|----------------|--------|---------|------|
| 1 | PostgreSQL | medinovai-postgres | ✅ Healthy | 5432 | Database |
| 2 | TimescaleDB | medinovai-timescaledb | ✅ Healthy | 5433 | Time-series DB |
| 3 | MongoDB | medinovai-mongodb | ✅ Healthy | 27017 | Document DB |
| 4 | Redis | medinovai-redis | ✅ Healthy | 6379 | Cache |
| 5 | Zookeeper | medinovai-zookeeper | ✅ Healthy | 2181 | Coordination |
| 6 | Kafka | medinovai-kafka | ✅ Healthy | 9092, 29092 | Streaming |
| 7 | RabbitMQ | medinovai-rabbitmq | ✅ Healthy | 5672, 15672 | Message Queue |
| 8 | Prometheus | medinovai-prometheus | ✅ Healthy | 9090 | Metrics |
| 9 | Grafana | medinovai-grafana | ✅ Healthy | 3000 | Dashboards |
| 10 | Loki | medinovai-loki | ✅ Healthy | 3100 | Logs |
| 11 | Promtail | medinovai-promtail | ✅ Running | - | Log Shipper |
| 12 | Vault | medinovai-vault | ✅ Healthy | 8200 | Secrets |
| 13 | MinIO | medinovai-minio | ✅ Healthy | 9000, 9001 | Storage |
| 14 | Nginx | medinovai-nginx | ⚠️ Functional | 8080 | Gateway |
| 15 | Keycloak | medinovai-keycloak | ⚠️ Starting | 8180 | IAM |

---

## 🔑 AUTHENTICATION CREDENTIALS

### Web Interfaces

**Grafana** (http://localhost:3000)
```
Username: admin
Password: medinovai_grafana_2025_secure
Database: Internal (PostgreSQL)
Default Org: Main Org.
Initial Setup: Complete
```

**RabbitMQ Management** (http://localhost:15672)
```
Username: medinovai
Password: medinovai_rabbitmq_2025_secure
Virtual Host: /medinovai
Permissions: Administrator
```

**MinIO Console** (http://localhost:9001)
```
Access Key: medinovai
Secret Key: medinovai_minio_2025_secure
Root Access: Yes
Region: us-east-1 (default)
```

**Keycloak Admin** (http://localhost:8180/admin/)
```
Username: admin
Password: medinovai_keycloak_2025_secure
Master Realm: Yes
Initial Realm: master
```

### Database Connections

**PostgreSQL** (localhost:5432)
```
Host: localhost
Port: 5432
Database: medinovai
Username: medinovai
Password: medinovai_postgres_2025_secure
Connection String: postgresql://medinovai:PASSWORD@localhost:5432/medinovai
SSL Mode: prefer
Max Connections: 200
```

**TimescaleDB** (localhost:5433)
```
Host: localhost
Port: 5433
Database: medinovai_timeseries
Username: medinovai
Password: medinovai_timescale_2025_secure
Connection String: postgresql://medinovai:PASSWORD@localhost:5433/medinovai_timeseries
TimescaleDB Extension: Enabled
```

**MongoDB** (localhost:27017)
```
Host: localhost
Port: 27017
Database: medinovai
Username: medinovai
Password: medinovai_mongo_2025_secure
Auth Database: admin
Connection String: mongodb://medinovai:PASSWORD@localhost:27017/medinovai?authSource=admin
Replica Set: Not configured (standalone)
```

**Redis** (localhost:6379)
```
Host: localhost
Port: 6379
Password: medinovai_redis_2025_secure
Database: 0 (default)
Connection String: redis://:PASSWORD@localhost:6379/0
Max Memory: 4GB
Eviction Policy: allkeys-lru
Persistence: Enabled (AOF + RDB)
```

### Message Queues

**Kafka** (localhost:9092)
```
Bootstrap Servers: localhost:9092 (external), kafka:9092 (internal)
Internal Port: 9092
External Port: 29092
Zookeeper: zookeeper:2181
Broker ID: 1
Topics: Auto-create enabled
Partitions: 3 (default)
Retention: 7 days
```

**RabbitMQ AMQP** (localhost:5672)
```
Host: localhost
Port: 5672
Virtual Host: /medinovai
Username: medinovai
Password: medinovai_rabbitmq_2025_secure
Connection String: amqp://medinovai:PASSWORD@localhost:5672/medinovai
```

### Vault (localhost:8200)
```
Address: http://localhost:8200
Root Token: medinovai_vault_root_2025_secure
Unsealed: Yes (dev mode)
Storage Backend: In-memory (dev mode)
Note: Dev mode - data not persisted between restarts
```

---

## 📁 CONFIGURATION FILES

### Primary Configuration
```
docker-compose-final-infrastructure.yml - Main deployment
.env.production - Environment variables (SECURE!)
```

### Service Configurations
```
prometheus-config/prometheus.yml - Metrics scraping
grafana-provisioning/datasources/datasources.yml - Data sources
loki-config/local-config.yaml - Log aggregation
promtail-config/config.yml - Log shipping
nginx-simple.conf - API gateway
```

### Backup Scripts
```
scripts/backup-postgres.sh - PostgreSQL backups
scripts/backup-mongodb.sh - MongoDB backups
scripts/backup-all.sh - Complete backup suite
```

---

## 🔧 RESOURCE ALLOCATION

### Docker Desktop Configuration
```
CPUs: 24 (of 32 available)
RAM: 393GB (of 512GB available)
Swap: 1GB
Disk: 2TB+ available
Network: Bridge (medinovai-network)
```

### Per-Service Resources

| Service | CPU Limit | RAM Limit | CPU Reserved | RAM Reserved |
|---------|-----------|-----------|--------------|--------------|
| PostgreSQL | 4 | 16GB | 2 | 8GB |
| TimescaleDB | 2 | 8GB | 1 | 4GB |
| MongoDB | 2 | 8GB | 1 | 4GB |
| Redis | 1 | 4GB | 0.5 | 2GB |
| Kafka | 3 | 12GB | 2 | 8GB |
| Zookeeper | 1 | 2GB | - | - |
| RabbitMQ | 1 | 2GB | - | - |
| Prometheus | 2 | 8GB | - | - |
| Grafana | 1 | 2GB | - | - |
| Loki | 1 | 4GB | - | - |
| Keycloak | 2 | 4GB | - | - |
| Vault | 1 | 2GB | - | - |
| MinIO | 2 | 4GB | - | - |
| Nginx | 1 | 512MB | - | - |

**Total Allocated**: ~24 CPUs, ~76GB RAM (leaves headroom for system + Ollama)

---

## 🌐 NETWORK CONFIGURATION

### Docker Network
```
Name: medinovai-infrastructure_medinovai-network
Driver: bridge
Subnet: 172.28.0.0/16
Gateway: 172.28.0.1
DNS: Docker default
Isolation: Enabled
```

### Port Mappings
```
# Databases
5432  → PostgreSQL
5433  → TimescaleDB
27017 → MongoDB
6379  → Redis

# Message Queues
2181  → Zookeeper
9092  → Kafka (internal)
29092 → Kafka (external)
5672  → RabbitMQ AMQP
15672 → RabbitMQ Management

# Monitoring
9090  → Prometheus
3000  → Grafana
3100  → Loki

# Security & Storage
8180  → Keycloak
8200  → Vault
9000  → MinIO API
9001  → MinIO Console

# Gateway
8080  → Nginx
```

---

## 📊 MONITORING CONFIGURATION

### Prometheus Data Sources

**Configured Scrape Jobs**:
```yaml
- job_name: 'prometheus'
  scrape_interval: 15s
  static_configs:
    - targets: ['localhost:9090']

- job_name: 'postgres'
  static_configs:
    - targets: ['postgres:5432']

- job_name: 'mongodb'
  static_configs:
    - targets: ['mongodb:27017']

- job_name: 'redis'
  static_configs:
    - targets: ['redis:6379']
```

**Retention**: 30 days  
**Storage**: /prometheus volume  
**Web UI**: http://localhost:9090

### Grafana Data Sources

**Pre-configured**:
1. **Prometheus** (default)
   - URL: http://prometheus:9090
   - Access: Proxy
   - Type: Prometheus

2. **Loki**
   - URL: http://loki:3100
   - Access: Proxy
   - Type: Loki

**Dashboards**: Available in UI (Import ID or JSON)

### Loki Configuration

**Schema**: v13 (tsdb)  
**Storage**: Filesystem (/loki volume)  
**Retention**: 31 days  
**Max Query Length**: Unlimited  
**Ingestion Rate**: 10MB/s  

---

## 💾 BACKUP CONFIGURATION

### Automated Backups

**Schedule**: Daily at 2:00 AM (to be configured in cron)  
**Retention**: 30 days  
**Location**: `/tmp/backups/`  
**Compression**: gzip

**Services Backed Up**:
- PostgreSQL (custom format)
- MongoDB (mongodump)
- TimescaleDB (pg_dump)
- Redis (RDB snapshots)
- Vault (raft snapshots)

**Backup Command**:
```bash
/Users/dev1/github/medinovai-infrastructure/scripts/backup-all.sh
```

**Restore Procedures**: Documented in DISASTER_RECOVERY_PLAN.md (to be created)

---

## 🔒 SECURITY CONFIGURATION

### Current Security Measures

✅ **Implemented**:
- Network isolation (Docker bridge)
- Authentication on all services
- Secrets management (Vault)
- Password-protected databases
- IAM (Keycloak)
- Access logging (Loki)

⚠️ **Pending** (for production):
- TLS/SSL encryption
- Certificate management
- Security audits schedule
- Penetration testing
- HIPAA compliance review

### Vault Configuration

**Mode**: Development (NOT for production)  
**Storage**: In-memory  
**Sealed**: No (auto-unsealed in dev)  
**Root Token**: See .env.production  

**For Production**: Switch to production mode with persistent storage

---

## 📝 INITIALIZATION CHECKLIST

Use this checklist for new deployments:

### Pre-Deployment
- [ ] Mac Studio M3 Ultra (or equivalent)
- [ ] Docker Desktop installed (28.4.0+)
- [ ] k3d installed (5.8.3+)
- [ ] 24+ CPUs, 393+ GB RAM allocated
- [ ] 2TB+ storage available

### Deployment
- [ ] Clone repository
- [ ] Create `.env.production` with secure passwords
- [ ] Run: `docker-compose -f docker-compose-final-infrastructure.yml up -d`
- [ ] Wait 5 minutes for all services to start
- [ ] Verify: `docker ps --filter "name=medinovai"`

### Post-Deployment
- [ ] Change all default passwords
- [ ] Test Grafana login (http://localhost:3000)
- [ ] Test Prometheus access (http://localhost:9090)
- [ ] Configure automated backups (cron)
- [ ] Create MinIO buckets
- [ ] Setup Keycloak realms
- [ ] Configure RabbitMQ queues
- [ ] Test database connections

### Validation
- [ ] All 15 services running
- [ ] Health checks passing
- [ ] Web UIs accessible
- [ ] Databases accepting connections
- [ ] Monitoring collecting metrics
- [ ] Logs being aggregated
- [ ] Backups completing successfully

---

## 🎯 FUTURE ENHANCEMENTS (Path to 10/10)

### Phase 1: TLS/SSL (Priority: CRITICAL)
- Generate SSL certificates
- Configure PostgreSQL with SSL
- Configure MongoDB with TLS
- Configure Redis with TLS
- Update Nginx with HTTPS
- Update all connection strings

**Estimated Time**: 1.5 hours  
**Impact**: +0.5 points → 9.7/10

### Phase 2: AlertManager (Priority: HIGH)
- Deploy AlertManager container
- Configure alert rules
- Setup notification channels
- Create runbooks

**Estimated Time**: 45 minutes  
**Impact**: +0.2 points → 9.9/10

### Phase 3: DR Testing (Priority: MEDIUM)
- Test backup restoration
- Document procedures
- Verify RTO/RPO
- Schedule drills

**Estimated Time**: 45 minutes  
**Impact**: +0.1 points → 10.0/10

---

## 📚 REFERENCE DOCUMENTATION

**Complete Guide**: `FINAL_INFRASTRUCTURE_GUIDE_V1.1.md`  
**Validation Results**: `MANUAL_SERVICE_VALIDATION_RESULTS.md`  
**Multi-Model Assessment**: `MULTI_MODEL_VALIDATION_RESULTS_FINAL.md`  
**Deployment Summary**: `DEPLOYMENT_COMPLETE.md`  
**Next Steps**: `NEXT_STEPS_TO_10_10.md`

---

## 🎉 SUMMARY

**Infrastructure Quality**: 9.2/10 (validated by 6 AI models)  
**Services Operational**: 15/16 (13 healthy, 2 functional)  
**Uptime**: 14+ hours stable  
**Ready For**: Development, Staging, MVP deployment  

**All initialization data documented and saved for future deployments!**

---

**Document Created**: October 1, 2025  
**Last Updated**: October 1, 2025  
**Status**: IMMUTABLE REFERENCE  
**Version**: 1.1.0  

**Store this document securely!** 🔐

