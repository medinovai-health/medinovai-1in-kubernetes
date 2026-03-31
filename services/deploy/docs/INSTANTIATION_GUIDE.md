# MedinovAI Platform — Greenfield Instantiation Guide

## Overview

This guide walks you through standing up a complete MedinovAI environment from a bare cloud account. The `instantiate.sh` script automates all 15 steps, but this document explains each one for understanding, customization, and troubleshooting.

## Prerequisites

Before starting, ensure you have:

1. **Cloud account** with admin or PowerUser-level access (AWS, GCP, or Azure)
2. **Domain name** configured in your DNS provider (optional but recommended)
3. **All required tools** installed (run `make prerequisites` to verify):
   - Terraform 1.7+, kubectl 1.29+, Helm 3.14+, Docker 25+
   - jq 1.7+, Node.js 22+, Python 3.11+, GitHub CLI
   - Cloud CLI (aws, gcloud, or az)

## Quick Start

```bash
# 1. Verify prerequisites
make prerequisites

# 2. Initialize cloud account (creates state backend)
bash scripts/bootstrap/init-cloud-account.sh --cloud aws --region us-east-1

# 3. Full instantiation
bash scripts/bootstrap/instantiate.sh \
  --cloud aws \
  --region us-east-1 \
  --environment production \
  --domain app.medinovai.com \
  --org-name "Your Health System"
```

## Step-by-Step Breakdown

### Step 1: Prerequisites Check (10s)

Verifies all required CLI tools are installed with minimum versions. Fails fast if anything is missing.

**Troubleshooting**: Run `bash scripts/bootstrap/prerequisites.sh` to see exactly what's missing.

### Step 2: Cloud Account Bootstrap (1m)

Creates the Terraform state backend:

| Cloud | State Backend | Lock Mechanism |
|-------|--------------|----------------|
| AWS | S3 bucket (versioned, encrypted, private) | DynamoDB table |
| GCP | GCS bucket (versioned) | GCS object locking |
| Azure | Azure Storage container (versioned) | Azure blob leasing |

Also creates bootstrap IAM roles/service accounts for Terraform.

**Idempotent**: Safe to re-run. Skips resources that already exist.

### Step 3: Networking (3m)

Provisions the network foundation:

- **VPC** with /16 CIDR block
- **Subnets**: Public (load balancers), Private (application), Data (databases)
- **NAT Gateways** for outbound internet from private subnets
- **Security Groups** with default deny-all + explicit allow rules
- **VPC Flow Logs** for network auditing (production only)

### Step 4: DNS & Certificates (2m)

- Creates a hosted zone for your domain
- Requests SSL/TLS certificates (ACM on AWS, managed certs on GCP)
- Certificates are auto-renewed by the cloud provider

**Skip if**: No domain provided (`--domain` omitted)

### Step 5: Secrets Infrastructure (1m)

- Creates KMS encryption keys for data-at-rest encryption
- Initializes the secret management service
- Configures automatic rotation policies

### Step 6: Seed Initial Secrets (30s)

Generates and stores initial secrets:

- Database master password
- Redis authentication password
- JWT signing secret
- Internal API keys
- Encryption keys

**Security note**: These should be rotated within 90 days of initial setup.

### Step 7: Databases (10m)

Provisions data stores:

| Component | Dev | Staging | Production |
|-----------|-----|---------|------------|
| PostgreSQL | db.t3.medium, single AZ | db.r6g.large, single AZ | db.r6g.xlarge, multi-AZ + read replica |
| Redis | cache.t3.micro | cache.r6g.large | cache.r6g.xlarge, cluster mode |
| Backups | 1 day retention | 7 day retention | 30 day + cross-region |

**Slow step**: RDS provisioning takes ~8-10 minutes.

### Step 8: Database Migrations (2m)

- Runs schema creation DDL
- Seeds reference/lookup data
- Creates required database users with least-privilege permissions

### Step 9: Compute Cluster (12m)

Provisions the Kubernetes cluster:

| Component | Dev | Staging | Production |
|-----------|-----|---------|------------|
| Node groups | 1-3 nodes | 2-5 nodes | 3-20 nodes (autoscaled) |
| Instance type | m6i.large | m6i.xlarge | m6i.xlarge |
| GPU nodes | 0 | 1 | 2-8 (autoscaled) |
| GPU type | — | g5.xlarge | g5.xlarge |

**Slowest step**: EKS/GKE cluster creation takes ~10-12 minutes.

### Step 10: Base K8s Resources (1m)

Applies foundational Kubernetes resources:

- Namespaces: `medinovai-system`, `medinovai-services`, `medinovai-data`, `medinovai-ai`, `medinovai-monitoring`
- RBAC: Service-specific ServiceAccounts with least privilege
- Network Policies: Default deny-all with explicit allow rules
- Resource Quotas: Per-namespace CPU/memory limits
- Priority Classes: critical, high, normal, batch

### Step 11: Monitoring Stack (3m)

Deploys the observability stack:

- **Prometheus** — metrics collection with auto-discovery
- **Grafana** — pre-configured dashboards
- **Alertmanager** — alert routing (PagerDuty, Slack)
- **Loki** — log aggregation

### Step 12: MedinovAI Services (5m)

Deploys services in dependency order:

1. `auth-service` (no service dependencies)
2. `notification-service` (no service dependencies)
3. `data-pipeline` (depends: auth-service)
4. `clinical-engine` (depends: auth-service, data-pipeline)
5. `ai-inference` (depends: auth-service, data-pipeline)
6. `api-gateway` (depends: all backend services)

Each service is health-checked before proceeding to the next.

### Step 13: Ingress & TLS (2m)

- Deploys nginx-ingress controller
- Configures cert-manager for automatic TLS certificate management
- Creates ingress rules routing external traffic to services

### Step 14: Smoke Tests (2m)

Verifies the platform is operational:

- All service health endpoints return 200
- Authentication flow works end-to-end
- Key API endpoints respond with valid data
- AI inference endpoint processes a test request
- Monitoring stack is receiving metrics

### Step 15: Atlas Gateway (1m)

- Installs Atlas CLI
- Deploys gateway configuration
- Registers deploy agents (platform, eng, security, data, ai-ml)
- Registers monitoring cron jobs

## Resuming from Failure

If instantiation fails at any step, re-run with `--resume`:

```bash
bash scripts/bootstrap/instantiate.sh --resume \
  --cloud aws --region us-east-1 --environment production
```

The script checkpoints after each step and skips completed steps on resume.

## Customization

### Environment Sizing

Edit `infra/terraform/environments/<env>/terraform.tfvars` to customize:

```hcl
node_instance_types = ["m6i.2xlarge"]
min_nodes           = 5
max_nodes           = 30
db_instance_class   = "db.r6g.2xlarge"
```

### Adding Services

1. Create a service manifest in `services/registry/<service>.manifest.json`
2. Create K8s manifests in `infra/kubernetes/services/<service>/`
3. Add the service to the deploy order in `scripts/deploy/deploy_all.sh`

## Post-Instantiation

After successful instantiation:

1. **Verify health**: `make health`
2. **Access Grafana**: `kubectl port-forward svc/grafana -n medinovai-monitoring 3000:3000`
3. **Start Atlas**: `make start`
4. **Run compliance check**: `make validate-compliance`
5. **Set up alerting**: Update PagerDuty/Slack tokens in Alertmanager config
