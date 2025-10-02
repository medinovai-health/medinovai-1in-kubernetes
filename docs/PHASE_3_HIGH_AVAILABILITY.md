# Phase 3: High Availability & Multi-Node Configuration 🏗️

**Date**: 2025-10-02  
**Target**: Production-grade HA deployment  
**Services**: Kafka, Zookeeper, RabbitMQ  

---

## 🎯 Overview

This document outlines the high availability (HA) architecture for Phase 3 messaging services, designed for zero-downtime operations and automatic failover in production environments.

---

## 🏗️ 1. Architecture Overview

### Current (Development): Single-Node
```
┌─────────────────────────────────────┐
│   Mac Studio M3 Ultra (Local Dev)  │
│                                     │
│  ┌──────────┐  ┌──────────┐       │
│  │Zookeeper │  │  Kafka   │       │
│  │  (1)     │──│  (1)     │       │
│  └──────────┘  └──────────┘       │
│                                     │
│  ┌──────────┐                      │
│  │RabbitMQ  │                      │
│  │  (1)     │                      │
│  └──────────┘                      │
└─────────────────────────────────────┘

⚠️  Single point of failure
✅ Simple, fast development
```

### Target (Production): Multi-Node HA
```
┌─────────────────────────────────────────────────────────┐
│            Production Kubernetes Cluster                │
│                                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐            │
│  │Zookeeper │  │Zookeeper │  │Zookeeper │            │
│  │  Node 1  │──│  Node 2  │──│  Node 3  │            │
│  │ (Leader) │  │(Follower)│  │(Follower)│            │
│  └──────────┘  └──────────┘  └──────────┘            │
│        │              │              │                 │
│        └──────────────┴──────────────┘                 │
│                       │                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐            │
│  │  Kafka   │  │  Kafka   │  │  Kafka   │            │
│  │ Broker 1 │──│ Broker 2 │──│ Broker 3 │            │
│  │  (9092)  │  │  (9092)  │  │  (9092)  │            │
│  └──────────┘  └──────────┘  └──────────┘            │
│                                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐            │
│  │RabbitMQ  │  │RabbitMQ  │  │RabbitMQ  │            │
│  │  Node 1  │──│  Node 2  │──│  Node 3  │            │
│  │(Mirrored)│  │(Mirrored)│  │(Mirrored)│            │
│  └──────────┘  └──────────┘  └──────────┘            │
│                                                         │
│  ┌────────────────────────────────────────┐           │
│  │     Load Balancer / Service Mesh       │           │
│  │         (Istio / HAProxy)              │           │
│  └────────────────────────────────────────┘           │
└─────────────────────────────────────────────────────────┘

✅ Zero single point of failure
✅ Automatic failover
✅ Horizontal scalability
```

---

## 🦓 2. Zookeeper HA Ensemble

### A. 3-Node Zookeeper Configuration

```yaml
# k8s/zookeeper-statefulset.yaml

apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: zookeeper
  namespace: medinovai-messaging
spec:
  serviceName: zookeeper-headless
  replicas: 3
  selector:
    matchLabels:
      app: zookeeper
  template:
    metadata:
      labels:
        app: zookeeper
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchExpressions:
                  - key: app
                    operator: In
                    values:
                      - zookeeper
              topologyKey: kubernetes.io/hostname
      containers:
      - name: zookeeper
        image: confluentinc/cp-zookeeper:latest
        ports:
        - containerPort: 2181
          name: client
        - containerPort: 2888
          name: server
        - containerPort: 3888
          name: leader-election
        env:
        - name: ZOOKEEPER_SERVER_ID
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: ZOOKEEPER_SERVERS
          value: "zookeeper-0.zookeeper-headless.medinovai-messaging.svc.cluster.local:2888:3888;zookeeper-1.zookeeper-headless.medinovai-messaging.svc.cluster.local:2888:3888;zookeeper-2.zookeeper-headless.medinovai-messaging.svc.cluster.local:2888:3888"
        - name: ZOOKEEPER_TICK_TIME
          value: "2000"
        - name: ZOOKEEPER_INIT_LIMIT
          value: "10"
        - name: ZOOKEEPER_SYNC_LIMIT
          value: "5"
        - name: ZOOKEEPER_CLIENT_PORT
          value: "2181"
        volumeMounts:
        - name: datadir
          mountPath: /var/lib/zookeeper/data
        - name: logdir
          mountPath: /var/lib/zookeeper/log
        livenessProbe:
          exec:
            command:
            - /bin/bash
            - -c
            - echo ruok | nc 127.0.0.1 2181 | grep imok
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          exec:
            command:
            - /bin/bash
            - -c
            - echo ruok | nc 127.0.0.1 2181 | grep imok
          initialDelaySeconds: 10
          periodSeconds: 5
  volumeClaimTemplates:
  - metadata:
      name: datadir
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 10Gi
      storageClassName: fast-ssd
  - metadata:
      name: logdir
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 10Gi
      storageClassName: fast-ssd

---
apiVersion: v1
kind: Service
metadata:
  name: zookeeper-headless
  namespace: medinovai-messaging
spec:
  clusterIP: None
  ports:
  - port: 2181
    name: client
  - port: 2888
    name: server
  - port: 3888
    name: leader-election
  selector:
    app: zookeeper

---
apiVersion: v1
kind: Service
metadata:
  name: zookeeper
  namespace: medinovai-messaging
spec:
  type: ClusterIP
  ports:
  - port: 2181
    name: client
  selector:
    app: zookeeper
```

### B. Zookeeper Quorum Configuration

```properties
# zoo.cfg (generated for each node)

# Node 1
server.1=zookeeper-0:2888:3888
server.2=zookeeper-1:2888:3888
server.3=zookeeper-2:2888:3888

# Quorum settings
tickTime=2000
initLimit=10
syncLimit=5
dataDir=/var/lib/zookeeper/data
clientPort=2181

# 4-letter word commands
4lw.commands.whitelist=stat,ruok,conf,isro

# Enable JMX for monitoring
jmx.port=9999
```

### C. Zookeeper Health Monitoring

```bash
#!/bin/bash
# Monitor Zookeeper cluster health

check_zk_health() {
  local node=$1
  local port=2181
  
  # Check if leader or follower
  mode=$(echo stat | nc $node $port | grep Mode | awk '{print $2}')
  
  # Check if part of quorum
  echo ruok | nc $node $port
  
  echo "$node: $mode"
}

check_zk_health "zookeeper-0.zookeeper-headless" 
check_zk_health "zookeeper-1.zookeeper-headless"
check_zk_health "zookeeper-2.zookeeper-headless"
```

---

## ☕ 3. Kafka HA Cluster

### A. 3-Broker Kafka Configuration

```yaml
# k8s/kafka-statefulset.yaml

apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: kafka
  namespace: medinovai-messaging
spec:
  serviceName: kafka-headless
  replicas: 3
  selector:
    matchLabels:
      app: kafka
  template:
    metadata:
      labels:
        app: kafka
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchExpressions:
                  - key: app
                    operator: In
                    values:
                      - kafka
              topologyKey: kubernetes.io/hostname
      containers:
      - name: kafka
        image: confluentinc/cp-kafka:7.5.0
        ports:
        - containerPort: 9092
          name: plaintext
        - containerPort: 9093
          name: ssl
        env:
        - name: KAFKA_BROKER_ID
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: KAFKA_ZOOKEEPER_CONNECT
          value: "zookeeper-0.zookeeper-headless:2181,zookeeper-1.zookeeper-headless:2181,zookeeper-2.zookeeper-headless:2181"
        - name: KAFKA_LISTENERS
          value: "PLAINTEXT://0.0.0.0:9092"
        - name: KAFKA_ADVERTISED_LISTENERS
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
          value: "PLAINTEXT://$(status.podIP):9092"
        
        # HA Configuration
        - name: KAFKA_DEFAULT_REPLICATION_FACTOR
          value: "3"  # Replicate to all brokers
        - name: KAFKA_MIN_INSYNC_REPLICAS
          value: "2"  # At least 2 replicas must acknowledge
        - name: KAFKA_UNCLEAN_LEADER_ELECTION_ENABLE
          value: "false"  # Prevent data loss
        - name: KAFKA_AUTO_CREATE_TOPICS_ENABLE
          value: "false"  # Control topic creation
        
        # Performance
        - name: KAFKA_NUM_NETWORK_THREADS
          value: "8"
        - name: KAFKA_NUM_IO_THREADS
          value: "16"
        - name: KAFKA_SOCKET_SEND_BUFFER_BYTES
          value: "102400"
        - name: KAFKA_SOCKET_RECEIVE_BUFFER_BYTES
          value: "102400"
        
        # Retention
        - name: KAFKA_LOG_RETENTION_HOURS
          value: "168"  # 7 days
        - name: KAFKA_LOG_SEGMENT_BYTES
          value: "1073741824"  # 1GB
        
        resources:
          requests:
            memory: "8Gi"
            cpu: "2"
          limits:
            memory: "16Gi"
            cpu: "4"
        
        volumeMounts:
        - name: datadir
          mountPath: /var/lib/kafka/data
        
        livenessProbe:
          exec:
            command:
            - /bin/bash
            - -c
            - kafka-broker-api-versions --bootstrap-server=localhost:9092
          initialDelaySeconds: 60
          periodSeconds: 30
        
        readinessProbe:
          exec:
            command:
            - /bin/bash
            - -c
            - kafka-broker-api-versions --bootstrap-server=localhost:9092
          initialDelaySeconds: 30
          periodSeconds: 10
  
  volumeClaimTemplates:
  - metadata:
      name: datadir
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 100Gi
      storageClassName: fast-ssd

---
apiVersion: v1
kind: Service
metadata:
  name: kafka-headless
  namespace: medinovai-messaging
spec:
  clusterIP: None
  ports:
  - port: 9092
    name: plaintext
  selector:
    app: kafka

---
apiVersion: v1
kind: Service
metadata:
  name: kafka
  namespace: medinovai-messaging
spec:
  type: ClusterIP
  ports:
  - port: 9092
    name: plaintext
  selector:
    app: kafka
```

### B. Topic Configuration for HA

```bash
#!/bin/bash
# Create topics with HA settings

# Patient vitals stream - critical data
kafka-topics --bootstrap-server kafka:9092 \
  --create --topic patient-vitals-stream \
  --partitions 9 \
  --replication-factor 3 \
  --config min.insync.replicas=2 \
  --config unclean.leader.election.enable=false \
  --config retention.ms=604800000  # 7 days

# Clinical events - high throughput
kafka-topics --bootstrap-server kafka:9092 \
  --create --topic clinical-events \
  --partitions 12 \
  --replication-factor 3 \
  --config min.insync.replicas=2

# Audit logs - long retention
kafka-topics --bootstrap-server kafka:9092 \
  --create --topic audit-logs \
  --partitions 6 \
  --replication-factor 3 \
  --config min.insync.replicas=2 \
  --config retention.ms=220752000000  # 7 years (HIPAA)
```

### C. Producer Configuration for HA

```java
// Java producer configuration
Properties props = new Properties();
props.put("bootstrap.servers", "kafka-0:9092,kafka-1:9092,kafka-2:9092");
props.put("acks", "all");  // Wait for all replicas
props.put("retries", Integer.MAX_VALUE);
props.put("max.in.flight.requests.per.connection", 1);
props.put("enable.idempotence", true);  // Exactly-once semantics
props.put("compression.type", "lz4");
```

---

## 🐰 4. RabbitMQ HA Cluster

### A. 3-Node RabbitMQ Configuration

```yaml
# k8s/rabbitmq-statefulset.yaml

apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: rabbitmq
  namespace: medinovai-messaging
spec:
  serviceName: rabbitmq-headless
  replicas: 3
  selector:
    matchLabels:
      app: rabbitmq
  template:
    metadata:
      labels:
        app: rabbitmq
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchExpressions:
                  - key: app
                    operator: In
                    values:
                      - rabbitmq
              topologyKey: kubernetes.io/hostname
      
      initContainers:
      - name: copy-rabbitmq-config
        image: busybox
        command: ['sh', '-c', 'cp /configmap/* /etc/rabbitmq']
        volumeMounts:
        - name: configmap
          mountPath: /configmap
        - name: config
          mountPath: /etc/rabbitmq
      
      containers:
      - name: rabbitmq
        image: rabbitmq:3-management-alpine
        ports:
        - containerPort: 5672
          name: amqp
        - containerPort: 15672
          name: management
        - containerPort: 4369
          name: epmd
        - containerPort: 25672
          name: clustering
        
        env:
        - name: RABBITMQ_DEFAULT_USER
          valueFrom:
            secretKeyRef:
              name: rabbitmq-secret
              key: username
        - name: RABBITMQ_DEFAULT_PASS
          valueFrom:
            secretKeyRef:
              name: rabbitmq-secret
              key: password
        - name: RABBITMQ_ERLANG_COOKIE
          valueFrom:
            secretKeyRef:
              name: rabbitmq-secret
              key: erlang-cookie
        - name: MY_POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: RABBITMQ_USE_LONGNAME
          value: "true"
        - name: RABBITMQ_NODENAME
          value: "rabbit@$(MY_POD_NAME).rabbitmq-headless.medinovai-messaging.svc.cluster.local"
        - name: K8S_SERVICE_NAME
          value: "rabbitmq-headless"
        - name: K8S_HOSTNAME_SUFFIX
          value: ".rabbitmq-headless.medinovai-messaging.svc.cluster.local"
        
        resources:
          requests:
            memory: "2Gi"
            cpu: "1"
          limits:
            memory: "4Gi"
            cpu: "2"
        
        volumeMounts:
        - name: config
          mountPath: /etc/rabbitmq
        - name: datadir
          mountPath: /var/lib/rabbitmq
        
        livenessProbe:
          exec:
            command:
            - rabbitmq-diagnostics
            - ping
          initialDelaySeconds: 60
          periodSeconds: 30
        
        readinessProbe:
          exec:
            command:
            - rabbitmq-diagnostics
            - check_port_connectivity
          initialDelaySeconds: 20
          periodSeconds: 10
      
      volumes:
      - name: configmap
        configMap:
          name: rabbitmq-config
      - name: config
        emptyDir: {}
  
  volumeClaimTemplates:
  - metadata:
      name: datadir
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 20Gi
      storageClassName: fast-ssd

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: rabbitmq-config
  namespace: medinovai-messaging
data:
  enabled_plugins: |
    [rabbitmq_management,rabbitmq_peer_discovery_k8s,rabbitmq_shovel,rabbitmq_shovel_management].
  
  rabbitmq.conf: |
    cluster_formation.peer_discovery_backend = rabbit_peer_discovery_k8s
    cluster_formation.k8s.host = kubernetes.default.svc.cluster.local
    cluster_formation.k8s.address_type = hostname
    cluster_formation.node_cleanup.interval = 10
    cluster_formation.node_cleanup.only_log_warning = true
    cluster_partition_handling = autoheal
    
    # Queue mirroring policy
    queue_master_locator = min-masters
    
    # Performance
    channel_max = 2048
    heartbeat = 60
    
    # TLS
    listeners.ssl.default = 5671
    ssl_options.cacertfile = /etc/rabbitmq/ssl/ca-cert.pem
    ssl_options.certfile = /etc/rabbitmq/ssl/server-cert.pem
    ssl_options.keyfile = /etc/rabbitmq/ssl/server-key.pem
    ssl_options.verify = verify_peer
    ssl_options.fail_if_no_peer_cert = false

---
apiVersion: v1
kind: Service
metadata:
  name: rabbitmq-headless
  namespace: medinovai-messaging
spec:
  clusterIP: None
  ports:
  - port: 5672
    name: amqp
  - port: 4369
    name: epmd
  - port: 25672
    name: clustering
  selector:
    app: rabbitmq

---
apiVersion: v1
kind: Service
metadata:
  name: rabbitmq
  namespace: medinovai-messaging
spec:
  type: LoadBalancer
  ports:
  - port: 5672
    name: amqp
  - port: 15672
    name: management
  selector:
    app: rabbitmq
```

### B. Queue Mirroring Policy

```bash
# Set HA policy for all queues
rabbitmqctl set_policy ha-all "^" \
  '{"ha-mode":"all","ha-sync-mode":"automatic"}' \
  --apply-to queues

# Priority queues with quorum
rabbitmqctl set_policy ha-priority "^priority\." \
  '{"ha-mode":"exactly","ha-params":2,"ha-sync-mode":"automatic"}' \
  --apply-to queues --priority 1
```

---

## 🔄 5. Failover & Recovery

### A. Automated Failover Testing

```bash
#!/bin/bash
# Simulate node failure and test failover

# Test Kafka failover
echo "Testing Kafka failover..."
kubectl delete pod kafka-0 -n medinovai-messaging
sleep 30
# Verify leadership election
kubectl exec kafka-1 -n medinovai-messaging -- kafka-topics --list

# Test RabbitMQ failover
echo "Testing RabbitMQ failover..."
kubectl delete pod rabbitmq-0 -n medinovai-messaging
sleep 30
# Verify cluster status
kubectl exec rabbitmq-1 -n medinovai-messaging -- rabbitmqctl cluster_status

echo "✅ Failover tests complete"
```

### B. Recovery Time Objectives

| Service | RTO (Recovery Time) | RPO (Data Loss) |
|---------|---------------------|-----------------|
| Zookeeper | < 30 seconds | 0 (no data loss) |
| Kafka | < 2 minutes | 0 (with min.insync.replicas=2) |
| RabbitMQ | < 1 minute | 0 (with mirrored queues) |

---

## 📊 6. Monitoring & Alerting

### A. Key HA Metrics

```yaml
# Prometheus alerting rules

groups:
- name: messaging_ha
  rules:
  - alert: KafkaUnderReplicatedPartitions
    expr: kafka_server_replicamanager_underreplicatedpartitions > 0
    for: 5m
    annotations:
      summary: "Kafka has under-replicated partitions"
  
  - alert: ZookeeperQuorumLost
    expr: zookeeper_quorum_size < 2
    for: 1m
    annotations:
      summary: "Zookeeper quorum lost"
  
  - alert: RabbitMQNodeDown
    expr: rabbitmq_cluster_nodes_running < 2
    for: 2m
    annotations:
      summary: "RabbitMQ node down in cluster"
```

---

## ✅ HA Implementation Checklist

- [ ] Deploy 3-node Zookeeper ensemble
- [ ] Deploy 3-node Kafka cluster
- [ ] Deploy 3-node RabbitMQ cluster
- [ ] Configure replication policies
- [ ] Set up automated failover testing
- [ ] Configure monitoring & alerting
- [ ] Document runbooks for failure scenarios
- [ ] Test disaster recovery procedures

---

**Status**: Documented for production deployment  
**Current**: Single-node (development)  
**Next**: Deploy HA configuration in staging environment

