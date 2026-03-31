# Disaster Recovery Plan

## Overview

This document defines the disaster recovery (DR) procedures for the MedinovAI platform. The goal is to ensure business continuity with minimal data loss and downtime.

## Recovery Objectives

| Component | RPO (Data Loss) | RTO (Downtime) |
|-----------|-----------------|----------------|
| Database (PostgreSQL) | 5 minutes | 30 minutes |
| Object Storage (S3/GCS) | Near-zero | 15 minutes |
| Kubernetes State | Near-zero (GitOps) | 45 minutes |
| Secrets | Near-zero | 15 minutes |
| DNS Failover | N/A | 60 seconds (TTL) |
| Full Platform | 5 minutes | 60 minutes |

## DR Strategy by Component

### Database

- **Primary mechanism**: Cross-region read replica (continuous async replication)
- **Backup**: Automated daily snapshots + transaction log backups every 5 minutes
- **Failover**: Promote read replica to primary (automated or manual)
- **Testing**: Monthly restore test from snapshot

### Object Storage

- **Primary mechanism**: Cross-region replication (S3 CRR / GCS dual-region)
- **Versioning**: Enabled with 30-day retention for all buckets
- **Failover**: Update application config to point to replica region

### Kubernetes

- **Primary mechanism**: GitOps — all manifests in this repository
- **Failover**: Apply manifests to DR cluster in alternate region
- **State**: etcd snapshots stored in object storage (cross-region replicated)

### Secrets

- **Primary mechanism**: Secrets Manager replication to DR region
- **Failover**: Applications use region-aware secret references

## Incident Severity Classification

| Severity | Description | Example | Response |
|----------|-------------|---------|----------|
| DR-1 | Full region failure | Cloud region outage | Full DR failover |
| DR-2 | Partial service failure | Single AZ outage, database failure | Targeted recovery |
| DR-3 | Data corruption | Accidental deletion, ransomware | Point-in-time restore |

## DR Failover Procedure (DR-1: Full Region Failure)

### Step 1: Detect & Classify (0-5 minutes)

- Health checks detect failure (automated)
- On-call engineer confirms scope
- Classify as DR-1, DR-2, or DR-3

### Step 2: Approval (5-10 minutes)

- **Auto-failover** (if enabled): Proceeds automatically after 5-minute confirmation window
- **Manual approval**: CTO + Eng lead approve failover
- **Communication**: Notify all stakeholders via backup communication channel

### Step 3: Database Failover (10-20 minutes)

```bash
# Promote DR read replica to primary
aws rds promote-read-replica \
  --db-instance-identifier medinovai-production-dr-replica

# Update connection strings in secrets
aws secretsmanager update-secret \
  --secret-id medinovai/production/database/endpoint \
  --secret-string "new-primary-endpoint.rds.amazonaws.com"
```

### Step 4: DNS Failover (20-25 minutes)

- Route53 health check detects primary region is down
- Automatic DNS failover to DR region (60s TTL)
- Verify DNS propagation

### Step 5: Service Recovery (25-45 minutes)

```bash
# Apply K8s manifests to DR cluster
kubectl config use-context medinovai-dr-cluster
cd infra/kubernetes
kustomize build overlays/production-dr | kubectl apply -f -

# Wait for rollouts
kubectl rollout status deployment --all -n medinovai-services --timeout=600s
```

### Step 6: Verification (45-60 minutes)

- Run smoke tests against DR environment
- Verify all services healthy
- Confirm monitoring is receiving data
- Check data consistency

### Step 7: Communication

- Notify stakeholders: "Platform recovered in DR region"
- Update status page
- Begin root cause analysis on primary region

## DR Failback (Return to Primary)

After primary region is restored:

1. Verify primary region is fully healthy
2. Resync data from DR to primary
3. Run full test suite against primary
4. Schedule maintenance window for failback
5. Switch DNS back to primary
6. Monitor for 24 hours before decommissioning DR active state

## DR Testing Schedule

| Test | Frequency | Duration | Scope |
|------|-----------|----------|-------|
| Backup restore test | Monthly | 2 hours | Restore latest snapshot to test instance |
| Database failover | Quarterly | 4 hours | Promote replica, verify applications |
| Full DR failover | Semi-annually | 8 hours | Complete region failover and back |
| Tabletop exercise | Quarterly | 2 hours | Walk through DR scenarios with team |

## Contacts

| Role | Responsibility |
|------|---------------|
| On-call Engineer | First responder, initial assessment |
| Eng Lead | Approve DR-2 failover, coordinate recovery |
| CTO | Approve DR-1 failover, executive communication |
| DBA | Database recovery and data consistency |
| Security Lead | Assess security implications, credential rotation |
