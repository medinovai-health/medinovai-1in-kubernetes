# MedinovAI LIS Infrastructure

DevOps infrastructure repository for the MedinovAI Laboratory Information System (LIS) platform.

## Overview

This repository contains all infrastructure-as-code (IaC) and DevOps configurations for deploying and managing the MedinovAI LIS platform in a healthcare-compliant manner.

## Repository Structure

```
medinovai-infrastructure/
├── kubernetes/
│   ├── base/                    # Base Kubernetes manifests
│   │   ├── namespace.yaml       # Namespace definitions with quotas
│   │   ├── configmap.yaml       # Application configurations
│   │   ├── secrets.yaml         # Secret templates (use external secrets in prod)
│   │   └── network-policy.yaml  # Zero-trust network policies
│   ├── overlays/                # Kustomize overlays per environment
│   └── helm-charts/
│       └── lis-api/             # LIS API Helm chart
│           ├── Chart.yaml
│           ├── values.yaml
│           └── templates/
├── terraform/
│   ├── modules/
│   │   ├── kubernetes-cluster/  # AKS/EKS/GKE module
│   │   ├── database/            # MySQL Flexible Server module
│   │   └── redis/               # Azure Cache for Redis module
│   └── environments/            # Per-environment configurations
├── docker/
│   ├── Dockerfile.lis-api       # Production-ready API Dockerfile
│   └── docker-compose.yml       # Local development environment
├── argocd/
│   ├── applications/            # ArgoCD Application definitions
│   │   ├── lis-platform.yaml
│   │   └── lis-services.yaml
│   └── applicationsets/         # Dynamic ApplicationSets
│       └── product-apps.yaml
├── monitoring/
│   ├── prometheus/              # Prometheus configuration
│   ├── grafana/                 # Grafana dashboards
│   └── alertmanager/            # Alert rules and routing
└── .github/
    └── workflows/
        ├── ci.yml               # Continuous Integration
        ├── cd.yml               # Continuous Deployment
        └── security-scan.yml    # Security scanning
```

## Prerequisites

- **Kubernetes**: v1.28+
- **Helm**: v3.13+
- **Terraform**: v1.5+
- **kubectl**: v1.28+
- **Azure CLI** (for Azure deployments)
- **ArgoCD**: v2.9+ (for GitOps)

## Quick Start

### Local Development

```bash
# Start local development environment
cd docker
docker-compose up -d

# Access services
# - API: http://localhost:8080
# - Grafana: http://localhost:3000 (admin/admin)
# - RabbitMQ Management: http://localhost:15672 (lis_app/rabbitmq_dev_password)
# - Kibana: http://localhost:5601
```

### Deploy to Kubernetes

```bash
# Deploy using Helm
helm upgrade --install lis-api kubernetes/helm-charts/lis-api \
  --namespace lis-platform \
  --create-namespace \
  -f kubernetes/helm-charts/lis-api/values.yaml \
  -f kubernetes/helm-charts/lis-api/values-production.yaml

# Or using ArgoCD
kubectl apply -f argocd/applications/lis-platform.yaml
```

### Provision Infrastructure

```bash
# Initialize Terraform
cd terraform/environments/production
terraform init

# Plan changes
terraform plan -var-file=vars/production.tfvars

# Apply changes
terraform apply -var-file=vars/production.tfvars
```

## Healthcare Compliance

This infrastructure is designed to meet healthcare compliance requirements:

### HIPAA Compliance

- **Access Control (164.312(a)(1))**: Network policies enforce zero-trust access
- **Audit Controls (164.312(b))**: Comprehensive logging and audit trails
- **Transmission Security (164.312(e)(1))**: TLS encryption for all traffic
- **Encryption (164.312(a)(2)(iv))**: Data encrypted at rest and in transit

### ISO 13485 Compliance

- **Document Control**: GitOps ensures version control
- **Traceability**: All changes tracked through git history
- **Change Management**: PR reviews and approval gates

## Security Features

1. **Zero-Trust Network Policies**: All traffic denied by default
2. **Pod Security Standards**: Non-root containers, read-only filesystems
3. **Secret Management**: External Secrets Operator integration
4. **Vulnerability Scanning**: Trivy, Checkov, TFSec in CI/CD
5. **HIPAA Compliance Checks**: Automated policy validation

## Monitoring & Alerting

### Dashboards

- **LIS Platform Dashboard**: Overall system health and SLOs
- **API Performance**: Request rates, latencies, error rates
- **Database Metrics**: Connection pools, query performance
- **Cache Metrics**: Hit ratios, memory utilization

### Alert Categories

1. **Critical/Patient Safety**: Immediate PagerDuty notification
2. **Service Availability**: Slack + email notification
3. **Performance Degradation**: Warning notifications
4. **Infrastructure Issues**: Team-specific routing

## CI/CD Pipelines

### Continuous Integration

- Kubernetes manifest validation (kubeval, helm lint)
- Terraform validation and formatting
- Security scanning (Trivy, Checkov, TFSec, KICS)
- Policy compliance (OPA/Conftest)
- Secret scanning (Gitleaks, TruffleHog)

### Continuous Deployment

- Automated staging deployments
- Manual production approvals
- ArgoCD GitOps synchronization
- Automated rollback on failures
- Health check verification

## Environment Configuration

| Environment | Namespace | Auto-Deploy | Approval |
|-------------|-----------|-------------|----------|
| Development | lis-development | Yes | No |
| Staging | lis-staging | Yes | No |
| Production | lis-platform | No | Required |

## Contributing

1. Create a feature branch from `develop`
2. Make changes and ensure CI passes
3. Create PR with comprehensive description
4. Obtain required approvals
5. Merge to `develop` (auto-deploys to staging)
6. After validation, merge to `main` (requires production approval)

## Troubleshooting

### Common Issues

**Pods not starting:**
```bash
kubectl describe pod <pod-name> -n lis-platform
kubectl logs <pod-name> -n lis-platform
```

**ArgoCD sync issues:**
```bash
argocd app get lis-platform
argocd app sync lis-platform --prune
```

**Terraform state issues:**
```bash
terraform state list
terraform state show <resource>
```

## Support

- **Documentation**: https://docs.medinovai.com/infrastructure
- **Issues**: Create GitHub issue with `infrastructure` label
- **Emergency**: Contact platform@medinovai.com

## License

Proprietary - MedinovAI Healthcare Systems
