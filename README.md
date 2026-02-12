# MedinovAI Infrastructure

[![HIPAA Compliant](https://img.shields.io/badge/HIPAA-Compliant-green.svg)](./SECURITY.md)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28+-blue.svg)](https://kubernetes.io/)
[![Terraform](https://img.shields.io/badge/Terraform-1.5+-purple.svg)](https://terraform.io/)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](./LICENSE)

DevOps infrastructure repository for the MedinovAI Laboratory Information System (LIS) platform. Part of the myonsite-healthcare ecosystem.

---

## Overview

This repository contains all infrastructure-as-code (IaC) and DevOps configurations for deploying and managing the MedinovAI LIS platform in a healthcare-compliant manner. It provides Kubernetes manifests, Terraform modules, ArgoCD GitOps definitions, Docker configurations, and comprehensive monitoring for secure, scalable deployments.

**Key capabilities:**
- **GitOps** – ArgoCD-driven continuous deployment
- **Multi-cloud** – Terraform modules for AKS/EKS/GKE
- **Healthcare compliance** – HIPAA, FDA 21 CFR Part 11, SOC 2
- **Zero-trust networking** – Network policies and RBAC

---

## Architecture

```
+----------------------------------------------------+
|                  GitHub Repository                   |
|           (medinovai-infrastructure)                |
+------------------------+----------------------------+
                         | CI/CD (GitHub Actions)
                         v
+------------------------+----------------------------+
|            Container Registry (ACR)                  |
+------------------------+----------------------------+
                         | Deployment
                         v
+------------------------+----------------------------+
|         Kubernetes Cluster (AKS)                     |
|  +------------------+   +----------------------+    |
|  |   ArgoCD         +-->+   LIS Services       |    |
|  |   (GitOps)       |   |   (API, Workers)     |    |
|  +------------------+   +----------------------+    |
+----------------------------------------------------+
```

**Technology Stack:**
- **Orchestration:** Kubernetes (Azure Kubernetes Service)
- **IaC:** Terraform, Kustomize, Helm
- **CI/CD:** GitHub Actions
- **GitOps:** ArgoCD
- **Containerization:** Docker
- **Monitoring:** Prometheus, Grafana, Alertmanager

---

## Getting Started

### Prerequisites

- **Kubernetes**: v1.28+
- **Helm**: v3.13+
- **Terraform**: v1.5+
- **kubectl**: v1.28+
- **Azure CLI** (for Azure deployments)
- **ArgoCD**: v2.9+ (for GitOps)

### Local Development

```bash
# Start local development environment
cd docker
docker-compose up -d

# Access services
# - API: http://localhost:8080
# - Grafana: http://localhost:3000 (admin/admin)
# - RabbitMQ: http://localhost:15672
# - Kibana: http://localhost:5601
```

### Deploy to Kubernetes

```bash
# Deploy using Helm
helm upgrade --install lis-api kubernetes/helm-charts/lis-api   --namespace lis-platform   --create-namespace   -f kubernetes/helm-charts/lis-api/values.yaml

# Or using ArgoCD
kubectl apply -f argocd/applications/lis-platform.yaml
```

### Provision Infrastructure

```bash
cd terraform/environments/production
terraform init
terraform plan -var-file=vars/production.tfvars
terraform apply -var-file=vars/production.tfvars
```

---

## API Reference

This repository does not directly expose APIs. It deploys services that do. API contracts for deployed services are summarized in [docs/API_CONTRACTS.md](./docs/API_CONTRACTS.md). See [openapi.yaml](./openapi.yaml) for API specifications.

---

## Development

### Repository Structure

```
medinovai-infrastructure/
├── kubernetes/          # Base manifests, overlays, Helm charts
├── terraform/           # Cloud resource modules (K8s, DB, Redis)
├── argocd/              # ArgoCD applications and ApplicationSets
├── docker/              # Dockerfiles and docker-compose
├── gitops/              # GitOps base configs (clusters, apps)
├── monitoring/          # Prometheus, Grafana, Alertmanager
├── security/            # Compliance, policies, scanning
└── docs/                # Architecture and API documentation
```

### Environment Configuration

| Environment | Namespace       | Auto-Deploy | Approval   |
|-------------|-----------------|-------------|------------|
| Development | lis-development | Yes         | No         |
| Staging     | lis-staging     | Yes         | No         |
| Production  | lis-platform    | No          | Required   |

---

## Deployment

Deployments are automated via GitOps with ArgoCD:

1. **Push to main** → CI builds and pushes images
2. **ArgoCD sync** → Detects manifest changes
3. **Auto-deploy** → Staging deploys automatically
4. **Production** → Requires manual approval gate

**Rollback:**
```bash
argocd app sync lis-platform --revision <previous-sync-rev> --prune
```

---

## Security & Compliance

### HIPAA Technical Safeguards

| Control            | Implementation                                  |
|--------------------|--------------------------------------------------|
| Access Control     | Zero-trust network policies, RBAC                |
| Audit Controls     | Comprehensive logging and audit trails           |
| Transmission       | TLS encryption for all traffic                   |
| Encryption         | Data encrypted at rest and in transit            |

### Security Features

1. **Zero-Trust Network Policies** – Deny-by-default
2. **Pod Security Standards** – Non-root, read-only filesystems
3. **Secret Management** – External Secrets Operator
4. **Vulnerability Scanning** – Trivy, Checkov, TFSec in CI/CD
5. **Compliance** – FDA 21 CFR 11, SOC 2 controls

See [SECURITY.md](./SECURITY.md) and [security/](./security/) for details.

---

## Contributing

1. Create a feature branch from `main` or `develop`
2. Make changes and ensure CI passes
3. Create PR with comprehensive description
4. Obtain required approvals
5. Merge to `develop` (auto-deploys to staging)
6. For production, merge to `main` (approval required)

See [CONTRIBUTING.md](./CONTRIBUTING.md) for full guidelines.

---

## License

Proprietary – MedinovAI Healthcare Systems / myonsite-healthcare. All rights reserved.
