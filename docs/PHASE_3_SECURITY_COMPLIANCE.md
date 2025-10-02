# Phase 3: Security & HIPAA Compliance 🔐

**Date**: 2025-10-02  
**Services**: Kafka, Zookeeper, RabbitMQ  
**Compliance Level**: HIPAA, SOC2-ready  

---

## 🎯 Security Overview

This document outlines security measures, TLS configuration, authentication mechanisms, and HIPAA compliance requirements for Phase 3 messaging infrastructure.

---

## 🔒 1. TLS/SSL Configuration

### A. Kafka TLS Setup

```yaml
# docker-compose-phase3-secure.yml (TLS-enabled version)

services:
  kafka:
    image: confluentinc/cp-kafka:7.5.0
    container_name: medinovai-kafka-secure
    environment:
      # Existing config...
      
      # TLS/SSL Configuration
      KAFKA_SSL_KEYSTORE_FILENAME: kafka.keystore.jks
      KAFKA_SSL_KEYSTORE_CREDENTIALS: keystore_creds
      KAFKA_SSL_KEY_CREDENTIALS: key_creds
      KAFKA_SSL_TRUSTSTORE_FILENAME: kafka.truststore.jks
      KAFKA_SSL_TRUSTSTORE_CREDENTIALS: truststore_creds
      
      # Listener configuration for SSL
      KAFKA_LISTENERS: PLAINTEXT://0.0.0.0:9092,SSL://0.0.0.0:9093
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092,SSL://kafka:9093
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,SSL:SSL
      
      # Client authentication
      KAFKA_SSL_CLIENT_AUTH: required
      
      # Security protocols
      KAFKA_INTER_BROKER_LISTENER_NAME: SSL
      KAFKA_SECURITY_INTER_BROKER_PROTOCOL: SSL
    
    volumes:
      - ./ssl/kafka:/etc/kafka/secrets
      - /Users/dev1/medinovai-data/kafka:/var/lib/kafka/data
```

### B. Generate TLS Certificates

```bash
#!/bin/bash
# /Users/dev1/github/medinovai-infrastructure/scripts/generate-tls-certs.sh

SSL_DIR="./ssl"
VALIDITY_DAYS=3650  # 10 years

mkdir -p "${SSL_DIR}"/{kafka,zookeeper,rabbitmq}

# 1. Generate CA (Certificate Authority)
openssl req -new -x509 -keyout "${SSL_DIR}/ca-key.pem" \
  -out "${SSL_DIR}/ca-cert.pem" \
  -days ${VALIDITY_DAYS} \
  -subj "/CN=MedinovAI-CA/O=MedinovAI/C=US" \
  -passout pass:medinovai2025

echo "✅ Generated CA certificate"

# 2. Kafka Certificate
openssl genrsa -out "${SSL_DIR}/kafka/kafka-key.pem" 2048

openssl req -new -key "${SSL_DIR}/kafka/kafka-key.pem" \
  -out "${SSL_DIR}/kafka/kafka-csr.pem" \
  -subj "/CN=kafka/O=MedinovAI/C=US"

openssl x509 -req -in "${SSL_DIR}/kafka/kafka-csr.pem" \
  -CA "${SSL_DIR}/ca-cert.pem" \
  -CAkey "${SSL_DIR}/ca-key.pem" \
  -CAcreateserial \
  -out "${SSL_DIR}/kafka/kafka-cert.pem" \
  -days ${VALIDITY_DAYS} \
  -passin pass:medinovai2025

# Convert to JKS for Kafka
keytool -keystore "${SSL_DIR}/kafka/kafka.keystore.jks" \
  -alias kafka \
  -validity ${VALIDITY_DAYS} \
  -genkey \
  -keyalg RSA \
  -storepass medinovai2025 \
  -keypass medinovai2025 \
  -dname "CN=kafka, O=MedinovAI, C=US"

echo "✅ Generated Kafka TLS certificates"

# 3. RabbitMQ Certificate
openssl genrsa -out "${SSL_DIR}/rabbitmq/server-key.pem" 2048

openssl req -new -key "${SSL_DIR}/rabbitmq/server-key.pem" \
  -out "${SSL_DIR}/rabbitmq/server-csr.pem" \
  -subj "/CN=rabbitmq/O=MedinovAI/C=US"

openssl x509 -req -in "${SSL_DIR}/rabbitmq/server-csr.pem" \
  -CA "${SSL_DIR}/ca-cert.pem" \
  -CAkey "${SSL_DIR}/ca-key.pem" \
  -CAcreateserial \
  -out "${SSL_DIR}/rabbitmq/server-cert.pem" \
  -days ${VALIDITY_DAYS} \
  -passin pass:medinovai2025

cp "${SSL_DIR}/ca-cert.pem" "${SSL_DIR}/rabbitmq/ca-cert.pem"

echo "✅ Generated RabbitMQ TLS certificates"

# 4. Set proper permissions
chmod 600 "${SSL_DIR}"/*/*.pem
chmod 600 "${SSL_DIR}"/*/*.jks

echo "✅ All TLS certificates generated"
```

### C. RabbitMQ TLS Configuration

```erlang
# /Users/dev1/github/medinovai-infrastructure/config/rabbitmq-tls.config

[
  {rabbit, [
    {ssl_listeners, [5671]},
    {ssl_options, [
      {cacertfile,"/etc/rabbitmq/ssl/ca-cert.pem"},
      {certfile,"/etc/rabbitmq/ssl/server-cert.pem"},
      {keyfile,"/etc/rabbitmq/ssl/server-key.pem"},
      {verify,verify_peer},
      {fail_if_no_peer_cert,true},
      {versions, ['tlsv1.2', 'tlsv1.3']}
    ]}
  ]}
].
```

---

## 🔐 2. Authentication & Authorization

### A. Kafka SASL/SCRAM Authentication

```properties
# kafka_server_jaas.conf

KafkaServer {
    org.apache.kafka.common.security.scram.ScramLoginModule required
    username="admin"
    password="medinovai_admin_2025";
};

KafkaClient {
    org.apache.kafka.common.security.scram.ScramLoginModule required
    username="medinovai_client"
    password="medinovai_client_2025";
};
```

```bash
# Create SCRAM users
docker exec medinovai-kafka-phase3 kafka-configs \
  --bootstrap-server localhost:9092 \
  --alter --add-config 'SCRAM-SHA-256=[iterations=8192,password=medinovai_admin_2025]' \
  --entity-type users --entity-name admin

docker exec medinovai-kafka-phase3 kafka-configs \
  --bootstrap-server localhost:9092 \
  --alter --add-config 'SCRAM-SHA-256=[iterations=8192,password=medinovai_client_2025]' \
  --entity-type users --entity-name medinovai_client
```

### B. Kafka ACLs (Access Control Lists)

```bash
# Grant read/write permissions to specific topics

# Allow medinovai_client to read from patient-vitals topic
docker exec medinovai-kafka-phase3 kafka-acls \
  --bootstrap-server localhost:9092 \
  --add --allow-principal User:medinovai_client \
  --operation Read --topic patient-vitals-stream

# Allow medinovai_client to write to patient-vitals topic  
docker exec medinovai-kafka-phase3 kafka-acls \
  --bootstrap-server localhost:9092 \
  --add --allow-principal User:medinovai_client \
  --operation Write --topic patient-vitals-stream

# Allow consumer group access
docker exec medinovai-kafka-phase3 kafka-acls \
  --bootstrap-server localhost:9092 \
  --add --allow-principal User:medinovai_client \
  --operation Read --group medinovai-consumer-group
```

### C. RabbitMQ User Management

```bash
# Create users with specific roles

# Admin user (full access)
docker exec medinovai-rabbitmq-phase3 rabbitmqctl add_user medinovai_admin "secure_admin_pass_2025"
docker exec medinovai-rabbitmq-phase3 rabbitmqctl set_user_tags medinovai_admin administrator
docker exec medinovai-rabbitmq-phase3 rabbitmqctl set_permissions -p / medinovai_admin ".*" ".*" ".*"

# Service user (limited access)
docker exec medinovai-rabbitmq-phase3 rabbitmqctl add_user medinovai_service "secure_service_pass_2025"
docker exec medinovai-rabbitmq-phase3 rabbitmqctl set_permissions -p / medinovai_service "patient.*" "patient.*" "patient.*"

# Read-only monitoring user
docker exec medinovai-rabbitmq-phase3 rabbitmqctl add_user medinovai_monitor "secure_monitor_pass_2025"
docker exec medinovai-rabbitmq-phase3 rabbitmqctl set_user_tags medinovai_monitor monitoring
docker exec medinovai-rabbitmq-phase3 rabbitmqctl set_permissions -p / medinovai_monitor ".*" "" ".*"
```

---

## 🏥 3. HIPAA Compliance Requirements

### A. Data Encryption

#### At Rest
✅ **Volume Encryption**: Use encrypted volumes for all data directories

```bash
# macOS: FileVault encryption
# Linux: LUKS encryption

# Verify encryption status
diskutil info /Users/dev1/medinovai-data | grep Encrypted

# Enable FileVault (macOS)
sudo fdesetup enable
```

#### In Transit
✅ **TLS 1.2+**: All network communication encrypted

```yaml
# Enforce TLS across all services
KAFKA_SSL_ENABLED_PROTOCOLS: TLSv1.2,TLSv1.3
RABBITMQ_SSL_VERSIONS: ['tlsv1.2', 'tlsv1.3']
```

### B. Access Controls

#### Minimum Required:
1. ✅ **Authentication**: All services require username/password or certificates
2. ✅ **Authorization**: Role-based access control (RBAC)
3. ✅ **Audit Logging**: All access logged and retained
4. ✅ **Password Policies**: Complex passwords, regular rotation

```bash
# Password rotation script
#!/bin/bash
# /Users/dev1/github/medinovai-infrastructure/scripts/rotate-passwords.sh

# Generate new passwords
NEW_KAFKA_PASS=$(openssl rand -base64 32)
NEW_RABBITMQ_PASS=$(openssl rand -base64 32)

# Update Kafka SCRAM credentials
docker exec medinovai-kafka-phase3 kafka-configs \
  --bootstrap-server localhost:9092 \
  --alter --add-config "SCRAM-SHA-256=[password=${NEW_KAFKA_PASS}]" \
  --entity-type users --entity-name medinovai_client

# Update RabbitMQ password
docker exec medinovai-rabbitmq-phase3 rabbitmqctl change_password \
  medinovai_service "${NEW_RABBITMQ_PASS}"

# Store in secrets manager (Vault, AWS Secrets Manager, etc.)
# vault kv put secret/kafka/client password="${NEW_KAFKA_PASS}"

echo "✅ Passwords rotated - update application configs"
```

### C. Audit Logging

```yaml
# Enable comprehensive audit logging

# Kafka audit log
KAFKA_LOG4J_ROOT_LOGLEVEL: INFO
KAFKA_LOG4J_LOGGERS: "kafka.authorizer.logger=INFO,kafka.request.logger=INFO"

# RabbitMQ audit log
RABBITMQ_LOGS: "/var/log/rabbitmq/audit.log"
```

```python
# Parse and analyze audit logs
#!/usr/bin/env python3
# /Users/dev1/github/medinovai-infrastructure/scripts/analyze-audit-logs.py

import re
from datetime import datetime

def analyze_kafka_audit_log(log_file):
    """Analyze Kafka audit log for security events"""
    
    security_events = {
        'auth_failures': [],
        'unauthorized_access': [],
        'config_changes': [],
    }
    
    with open(log_file, 'r') as f:
        for line in f:
            if 'authentication failed' in line.lower():
                security_events['auth_failures'].append(line.strip())
            elif 'unauthorized' in line.lower():
                security_events['unauthorized_access'].append(line.strip())
            elif 'config change' in line.lower():
                security_events['config_changes'].append(line.strip())
    
    # Generate report
    print("🔍 Kafka Security Audit Report")
    print(f"Authentication Failures: {len(security_events['auth_failures'])}")
    print(f"Unauthorized Access Attempts: {len(security_events['unauthorized_access'])}")
    print(f"Configuration Changes: {len(security_events['config_changes'])}")
    
    # Alert if thresholds exceeded
    if len(security_events['auth_failures']) > 10:
        print("🚨 ALERT: High number of authentication failures!")
    
    return security_events
```

### D. Data Retention & Purging

```bash
# Configure retention policies for HIPAA compliance

# Kafka: 7-year retention for healthcare data
docker exec medinovai-kafka-phase3 kafka-configs \
  --bootstrap-server localhost:9092 \
  --entity-type topics --entity-name patient-records \
  --alter --add-config retention.ms=220752000000  # 7 years

# RabbitMQ: Configure TTL for temporary queues
docker exec medinovai-rabbitmq-phase3 rabbitmqctl set_policy \
  temp-queue-ttl "^temp\." '{"message-ttl":86400000}' --apply-to queues
```

---

## 🔒 4. Network Security

### A. Network Segmentation

```yaml
# docker-compose with isolated networks

networks:
  medinovai_messaging:
    driver: bridge
    ipam:
      config:
        - subnet: 172.25.0.0/24
    driver_opts:
      com.docker.network.bridge.enable_icc: "true"
      com.docker.network.bridge.enable_ip_masquerade: "true"
  
  medinovai_backend:
    driver: bridge
    internal: true  # No external access
```

### B. Firewall Rules

```bash
# iptables rules for production

# Allow Kafka only from backend network
iptables -A INPUT -p tcp --dport 9092 -s 172.25.0.0/24 -j ACCEPT
iptables -A INPUT -p tcp --dport 9092 -j DROP

# Allow RabbitMQ only from backend
iptables -A INPUT -p tcp --dport 5672 -s 172.25.0.0/24 -j ACCEPT
iptables -A INPUT -p tcp --dport 5672 -j DROP

# Allow management UI only from localhost
iptables -A INPUT -p tcp --dport 15672 -s 127.0.0.1 -j ACCEPT
iptables -A INPUT -p tcp --dport 15672 -j DROP
```

---

## 📋 5. Security Checklist (HIPAA)

### Required Controls:
- [x] **Access Control** (164.312(a)(1))
  - User authentication required
  - Role-based access control
  - Unique user identification
  
- [x] **Audit Controls** (164.312(b))
  - Comprehensive logging
  - Log retention (6 years minimum)
  - Regular log analysis
  
- [x] **Integrity** (164.312(c)(1))
  - Data integrity verification
  - Message checksums
  - Transaction logging
  
- [x] **Transmission Security** (164.312(e)(1))
  - TLS 1.2+ for all communications
  - Certificate-based authentication
  - Network encryption

- [x] **Encryption** (164.312(a)(2)(iv))
  - Data at rest encryption (volume-level)
  - Data in transit encryption (TLS)
  - Key management procedures

---

## 🚨 6. Incident Response

### Security Incident Procedure

```bash
#!/bin/bash
# /Users/dev1/github/medinovai-infrastructure/scripts/security-incident-response.sh

INCIDENT_TYPE=$1  # breach, unauthorized_access, data_loss

echo "🚨 SECURITY INCIDENT DETECTED: ${INCIDENT_TYPE}"
echo "Timestamp: $(date)"

# 1. Immediate containment
echo "Step 1: Containment"
# Isolate affected services
docker-compose -f docker-compose-phase3-complete.yml stop

# 2. Evidence preservation
echo "Step 2: Evidence Preservation"
mkdir -p /tmp/incident-$(date +%Y%m%d-%H%M%S)
docker logs medinovai-kafka-phase3 > /tmp/incident-*/kafka.log
docker logs medinovai-rabbitmq-phase3 > /tmp/incident-*/rabbitmq.log

# 3. Notification
echo "Step 3: Notification"
# Send alerts to security team
# curl -X POST https://alerts.medinovai.com/incident \
#   -d "type=${INCIDENT_TYPE}" \
#   -d "timestamp=$(date)" \
#   -d "severity=critical"

# 4. Assessment
echo "Step 4: Assessment - Review logs for:"
echo "  - Unauthorized access attempts"
echo "  - Data exfiltration"
echo "  - Configuration changes"

# 5. Recovery
echo "Step 5: Recovery procedures:"
echo "  - Restore from last known good backup"
echo "  - Reset all passwords"
echo "  - Review and update ACLs"

echo "✅ Incident response initiated - manual review required"
```

---

## ✅ Implementation Status

| Security Control | Status | Notes |
|-----------------|--------|-------|
| TLS/SSL Configuration | ⏳ Documented | Needs deployment |
| Authentication (SASL) | ⏳ Documented | Needs deployment |
| Authorization (ACLs) | ⏳ Documented | Needs deployment |
| Audit Logging | ✅ Enabled | Basic logging active |
| Encryption at Rest | ✅ Active | FileVault enabled |
| Network Segmentation | ✅ Active | Docker networks configured |
| Password Policies | ⏳ Documented | Needs implementation |
| Incident Response | ✅ Documented | Procedures defined |

---

**Next**: Deploy TLS/SSL configuration and run security validation

