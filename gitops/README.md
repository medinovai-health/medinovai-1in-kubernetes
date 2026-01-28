# MedinovAI GitOps Infrastructure

This directory contains the GitOps configuration for deploying all MedinovAI healthcare products using ArgoCD.

## Directory Structure

```
gitops/
├── apps/                          # Application definitions
│   ├── lis-platform/              # Laboratory Information System
│   │   └── application.yaml       # ArgoCD Application manifests
│   ├── mobile-phlebotomy/         # Mobile specimen collection
│   │   └── application.yaml
│   ├── ctms/                      # Clinical Trial Management System
│   │   └── application.yaml
│   └── billing/                   # Revenue Cycle Management
│       └── application.yaml
├── clusters/                      # Environment configurations
│   ├── production/                # Production cluster config
│   │   └── config.yaml
│   ├── staging/                   # Staging cluster config
│   │   └── config.yaml
│   └── development/               # Development cluster config
│       └── config.yaml
├── infrastructure/                # Shared infrastructure components
│   ├── sealed-secrets.yaml        # Encrypted secrets management
│   ├── external-secrets.yaml      # External secrets sync (AWS, Vault)
│   ├── cert-manager.yaml          # TLS certificate automation
│   └── ingress-nginx.yaml         # Ingress controller with WAF
└── base/                          # Shared templates and automation
    ├── preview-environments.yaml  # PR preview ApplicationSet
    ├── canary-rollout.yaml        # Progressive delivery config
    ├── sync-policy.yaml           # Sync policies and RBAC
    └── notification-config.yaml   # Deployment notifications
```

## Healthcare Compliance

All configurations in this repository are designed for healthcare compliance:

| Standard | Implementation |
|----------|----------------|
| **HIPAA** | TLS 1.2+, encryption at rest, audit logging, access controls |
| **HITRUST** | Security controls mapped to HITRUST CSF |
| **SOC 2** | Type II controls for security, availability, confidentiality |
| **PCI-DSS** | Payment processing isolation, tokenization (billing only) |
| **21 CFR Part 11** | Audit trails, electronic signatures (CTMS only) |

## Quick Start

### Prerequisites

1. ArgoCD installed in `argocd` namespace
2. Kubernetes cluster access
3. GitHub access token configured

### Deploy Infrastructure

```bash
# Apply infrastructure components (in order)
kubectl apply -f infrastructure/cert-manager.yaml
kubectl apply -f infrastructure/ingress-nginx.yaml
kubectl apply -f infrastructure/sealed-secrets.yaml
kubectl apply -f infrastructure/external-secrets.yaml
```

### Deploy Applications

```bash
# Deploy all product applications
kubectl apply -f apps/lis-platform/application.yaml
kubectl apply -f apps/mobile-phlebotomy/application.yaml
kubectl apply -f apps/ctms/application.yaml
kubectl apply -f apps/billing/application.yaml
```

### Enable Preview Environments

```bash
# Enable PR preview environments
kubectl apply -f base/preview-environments.yaml
```

## Environments

### Production
- **Cluster**: `https://kubernetes.default.svc`
- **Sync Policy**: Manual sync, no auto-prune, self-heal enabled
- **Sync Windows**: Mon-Thu 6AM-10PM ET
- **Deployments**: Canary with manual approval at 50%

### Staging
- **Cluster**: `https://staging.k8s.medinovai.com`
- **Sync Policy**: Auto-sync, auto-prune, self-heal enabled
- **Sync Windows**: 24/7
- **Deployments**: Auto-promote canary

### Development
- **Cluster**: `https://dev.k8s.medinovai.com`
- **Sync Policy**: Auto-sync, auto-prune, self-heal enabled
- **Sync Windows**: 24/7
- **Deployments**: Immediate rollout

## Deployment Strategies

### Canary Rollout (Production APIs)

Healthcare-safe progressive delivery:

```
Step 1: 1% traffic   → 5 min pause  → Analysis
Step 2: 5% traffic   → 10 min pause → Analysis + DB health
Step 3: 10% traffic  → 15 min pause → Analysis + Functional tests
Step 4: 25% traffic  → 20 min pause → Analysis
Step 5: 50% traffic  → MANUAL APPROVAL REQUIRED
Step 6: 75% traffic  → 30 min pause → Analysis
Step 7: 100% traffic → Complete
```

Analysis metrics:
- Success rate ≥ 99.5%
- P99 latency ≤ 500ms
- Error rate ≤ 0.1%
- No critical alerts

### Blue-Green (Background Workers)

Zero-downtime deployments for worker services:
- Full preview environment validation
- Manual promotion
- 5-minute graceful shutdown period

## Secrets Management

### Sealed Secrets
For secrets that need to be stored in Git:

```bash
# Seal a secret
kubeseal --controller-name=sealed-secrets-controller \
         --controller-namespace=kube-system \
         < secret.yaml > sealed-secret.yaml
```

### External Secrets
For secrets from AWS Secrets Manager/Parameter Store:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-credentials
spec:
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  data:
    - secretKey: DB_PASSWORD
      remoteRef:
        key: medinovai/lis-platform/database
        property: password
```

## RBAC Roles

| Role | Permissions | Groups |
|------|-------------|--------|
| `admin` | Full access | platform-team, sre-team |
| `deployer` | Sync, view, logs | developers |
| `prod-deployer` | Production sync only | release-managers |
| `readonly` | View only | qa-team |

## Notifications

Deployment events are sent to:

| Event | Channels |
|-------|----------|
| Deployment Success | Slack: #medinovai-deployments |
| Deployment Failed | Slack: #medinovai-alerts, PagerDuty |
| Health Degraded | Slack: #medinovai-alerts, PagerDuty |
| PR Preview Ready | GitHub Status, Slack: #medinovai-preview |
| Canary Failed | Slack: #medinovai-alerts, PagerDuty (Critical) |

## Sync Waves

Infrastructure components are deployed in order using sync waves:

| Wave | Components |
|------|------------|
| -10 | cert-manager |
| -8 | ingress-nginx |
| -6 | argo-rollouts |
| -5 | sealed-secrets, external-secrets |
| -3 | namespaces, network policies |
| 0 | core applications |
| 5 | secondary services |
| 10 | monitoring, logging |

## Troubleshooting

### Application Out of Sync

```bash
# Check sync status
argocd app get <app-name>

# View diff
argocd app diff <app-name>

# Force sync
argocd app sync <app-name> --force
```

### Canary Stuck

```bash
# Check rollout status
kubectl argo rollouts get rollout <rollout-name> -n <namespace>

# Promote canary manually
kubectl argo rollouts promote <rollout-name> -n <namespace>

# Abort and rollback
kubectl argo rollouts abort <rollout-name> -n <namespace>
```

### Secret Not Syncing

```bash
# Check external secret status
kubectl get externalsecret <name> -n <namespace> -o yaml

# Check secret store connection
kubectl get secretstore -n <namespace>
```

## Maintenance

### Certificate Renewal
Cert-manager automatically renews certificates 30 days before expiry.

### Sealed Secrets Key Rotation
Key rotation happens automatically every 30 days. Backup keys are stored in S3.

### ArgoCD Upgrades
1. Update `targetRevision` in `infrastructure/` manifests
2. Apply to staging first
3. Validate for 24 hours
4. Apply to production

## Support

- **Documentation**: https://docs.medinovai.com/gitops
- **ArgoCD UI**: https://argocd.medinovai.com
- **Slack**: #platform-support
- **PagerDuty**: medinovai-oncall

## Contributing

1. Create feature branch from `main`
2. Make changes to GitOps configs
3. Open PR with `preview` label for automatic preview environment
4. Get approval from platform team
5. Merge to `main` (auto-deploys to staging)
6. Create release for production deployment
