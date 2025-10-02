# 🔐 MEDINOVAI INFRASTRUCTURE - DASHBOARD CREDENTIALS

**Date**: October 2, 2025  
**Infrastructure Version**: 1.2.0 (with TLS)  
**⚠️ CONFIDENTIAL - DO NOT COMMIT TO PUBLIC REPOS**

---

## 🌐 PRIMARY DASHBOARDS

### 1. 📊 GRAFANA (Primary Monitoring Dashboard)
```
URL:      http://localhost:3000
          https://localhost/grafana/

Username: admin
Password: admin

Default Login: admin / admin
(You'll be prompted to change password on first login)

Features:
- System metrics (CPU, RAM, Disk)
- Service health monitoring
- Log aggregation (via Loki)
- Custom dashboards
- Alert configuration
```

**Quick Access**:
```bash
open http://localhost:3000
```

---

### 2. 📈 PROMETHEUS (Metrics & Queries)
```
URL:      http://localhost:9090
          https://localhost/prometheus/

Username: (none - no authentication)
Password: (none - no authentication)

Features:
- Raw metrics access
- PromQL queries
- Service discovery
- Alert rules
- Targets monitoring
```

**Quick Access**:
```bash
open http://localhost:9090
```

---

### 3. 🐰 RABBITMQ MANAGEMENT
```
URL:      http://localhost:15672
          https://localhost/rabbitmq/

Username: medinovai
Password: Check .env file (RABBITMQ_PASSWORD)
          Default: rabbitmq_secure_password

Features:
- Queue management
- Message rates
- Connection monitoring
- Virtual host configuration
- Exchange management
```

**Quick Access**:
```bash
open http://localhost:15672
```

---

### 4. 📦 MINIO CONSOLE (Object Storage)
```
URL:      http://localhost:9001
          https://localhost/minio/

Username: medinovai
Password: Check .env file (MINIO_ROOT_PASSWORD)
          Default: minio_secure_password

Features:
- Bucket management
- Object upload/download
- Access policies
- Storage metrics
- User management
```

**Quick Access**:
```bash
open http://localhost:9001
```

---

### 5. 🔐 KEYCLOAK (Identity Management)
```
URL:      http://localhost:8180
          https://localhost/keycloak/

Username: admin
Password: Check .env file (KEYCLOAK_ADMIN_PASSWORD)
          Default: keycloak_secure_password

Features:
- User management
- Role-based access control
- SSO configuration
- Client applications
- Identity providers
```

**Quick Access**:
```bash
open http://localhost:8180
```

---

### 6. 🔒 VAULT (Secrets Management)
```
URL:      http://localhost:8200

Token:    Check .env file (VAULT_TOKEN)
          Default: medinovai_vault_token

Features:
- Secret storage
- Dynamic secrets
- Encryption as a service
- PKI management
- Audit logging
```

**Quick Access**:
```bash
open http://localhost:8200
```

---

## 🗄️ DATABASE CONNECTIONS

### PostgreSQL (Main Database)
```
Host:     localhost
Port:     5432
Database: medinovai
Username: medinovai
Password: Check .env file (POSTGRES_PASSWORD)
          Default: medinovai_secure_password

SSL Mode: require (SSL is ENABLED)

Connection String:
postgresql://medinovai:medinovai_secure_password@localhost:5432/medinovai?sslmode=require

psql Command:
psql "postgresql://medinovai:medinovai_secure_password@localhost:5432/medinovai?sslmode=require"
```

---

### TimescaleDB (Time-Series Database)
```
Host:     localhost
Port:     5433
Database: medinovai_timeseries
Username: medinovai
Password: Check .env file (TIMESCALE_PASSWORD)
          Default: timescale_secure_password

SSL Mode: require (SSL is ENABLED)

Connection String:
postgresql://medinovai:timescale_secure_password@localhost:5433/medinovai_timeseries?sslmode=require
```

---

### MongoDB (Document Database)
```
Host:     localhost
Port:     27017
Username: admin
Password: Check .env file (MONGO_ROOT_PASSWORD)
          Default: mongo_secure_password

TLS:      ENABLED (requireTLS mode)

Connection String:
mongodb://admin:mongo_secure_password@localhost:27017/?tls=true&tlsCertificateKeyFile=/path/to/ssl/mongodb/server.pem&tlsCAFile=/path/to/ssl/ca/ca.crt

mongosh Command:
mongosh --tls \
  --tlsCertificateKeyFile ssl/mongodb/server.pem \
  --tlsCAFile ssl/ca/ca.crt \
  "mongodb://admin:mongo_secure_password@localhost:27017"
```

---

### Redis (Cache)
```
Host:     localhost
Port:     6379
Password: Check .env file (REDIS_PASSWORD)
          Default: redis_secure_password

TLS:      ENABLED (port 6379 is TLS)

redis-cli Command:
redis-cli --tls \
  --cert ssl/redis/server.crt \
  --key ssl/redis/server.key \
  --cacert ssl/ca/ca.crt \
  -a redis_secure_password
```

---

## 📋 QUICK ACCESS COMMANDS

### Open All Dashboards at Once
```bash
# macOS
open http://localhost:3000 \
     http://localhost:9090 \
     http://localhost:15672 \
     http://localhost:9001 \
     http://localhost:8180

# Linux
xdg-open http://localhost:3000 &
xdg-open http://localhost:9090 &
xdg-open http://localhost:15672 &
xdg-open http://localhost:9001 &
xdg-open http://localhost:8180 &
```

### Check All Service Status
```bash
./check-all-services.sh
```

### View Docker Services
```bash
docker ps --filter "name=medinovai"
```

---

## 🔒 SECURITY NOTES

### ⚠️ IMPORTANT - PRODUCTION DEPLOYMENT
**Before deploying to production:**

1. **Change ALL default passwords**
2. **Generate new SSL certificates** (or use Let's Encrypt)
3. **Enable authentication** on Prometheus (currently open)
4. **Configure firewall rules** (restrict port access)
5. **Setup VPN access** (don't expose directly to internet)
6. **Enable audit logging** on all services
7. **Implement IP whitelisting**

### Current Security Status
- ✅ TLS/SSL enabled on all databases
- ✅ HTTPS configured on Nginx
- ✅ Strong cipher suites configured
- ✅ Certificate-based authentication
- ⚠️ Default passwords in use (CHANGE THESE!)
- ⚠️ Self-signed certificates (OK for dev, use CA for prod)

---

## 📁 CREDENTIAL MANAGEMENT

### Where Credentials Are Stored
1. **Docker Compose File**: `docker-compose-final-infrastructure-tls.yml`
2. **Environment File**: `.env` or `.env.production`
3. **Vault**: For production secrets
4. **This Document**: For reference

### Rotating Credentials
```bash
# Generate new password
openssl rand -base64 32

# Update in docker-compose file
# Restart affected service
docker compose restart [service-name]
```

---

## 🆘 TROUBLESHOOTING

### Can't Login to Grafana
```bash
# Reset Grafana admin password
docker exec -it medinovai-grafana-tls grafana-cli admin reset-admin-password newpassword
```

### Can't Connect to Database
```bash
# Check if service is running
docker ps | grep medinovai-postgres

# Check logs
docker logs medinovai-postgres-tls

# Test connection
psql "postgresql://medinovai:password@localhost:5432/medinovai?sslmode=require" -c "SELECT 1;"
```

### Forgot Vault Token
```bash
# Check docker logs for dev token
docker logs medinovai-vault-tls | grep "Root Token"
```

---

## 📊 DEFAULT CREDENTIALS SUMMARY

| Service | Username | Default Password | Port | TLS |
|---------|----------|------------------|------|-----|
| Grafana | admin | admin | 3000 | ✅ |
| Prometheus | (none) | (none) | 9090 | ✅ |
| RabbitMQ | medinovai | rabbitmq_secure_password | 15672 | ✅ |
| MinIO | medinovai | minio_secure_password | 9001 | ✅ |
| Keycloak | admin | keycloak_secure_password | 8180 | ✅ |
| PostgreSQL | medinovai | medinovai_secure_password | 5432 | ✅ |
| TimescaleDB | medinovai | timescale_secure_password | 5433 | ✅ |
| MongoDB | admin | mongo_secure_password | 27017 | ✅ |
| Redis | (none) | redis_secure_password | 6379 | ✅ |

---

## 🎯 FIRST TIME SETUP

### 1. Login to Grafana
```bash
open http://localhost:3000
# Login: admin / admin
# Change password when prompted
```

### 2. Configure Grafana Datasources
- Prometheus: Already configured via provisioning
- Loki: Already configured via provisioning

### 3. Import Dashboards
- Browse to Dashboards → Import
- Popular Dashboard IDs:
  - 893: Docker monitoring
  - 1860: Node Exporter Full
  - 7362: PostgreSQL Database
  - 2583: MongoDB

### 4. Setup Alerts (Coming in Phase 2)
- Navigate to Alerting → Alert Rules
- Configure notification channels

---

**Status**: ✅ ALL CREDENTIALS DOCUMENTED  
**Last Updated**: October 2, 2025  
**Infrastructure Version**: 1.2.0 (TLS Enabled)  

⚠️ **KEEP THIS FILE SECURE - Contains sensitive information!**

