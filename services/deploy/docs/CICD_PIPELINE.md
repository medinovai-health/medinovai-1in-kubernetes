# CI/CD Pipeline Architecture

## Overview

MedinovAI uses a multi-stage CI/CD pipeline with approval gates, canary deployments, and automated rollback. All pipelines are defined as GitHub Actions workflows in `.github/workflows/`.

## Pipeline Inventory

| Workflow | File | Trigger | Purpose |
|----------|------|---------|---------|
| CI | `ci.yml` | Push/PR to main, develop | Validate configs, Terraform, K8s, tests, security |
| Deploy Staging | `deploy-staging.yml` | Merge to develop | Build, push, deploy to staging, smoke test |
| Deploy Production | `deploy-production.yml` | Release tag v* | Approval gate, canary, monitor, promote/rollback |
| Infra Plan | `infra-plan.yml` | PR touching infra/ | Terraform plan, post as PR comment |
| Security Scan | `security-scan.yml` | Daily + PR | Secret scan, dependency audit, container scan |
| Drift Detection | `drift-detection.yml` | Daily 03:00 UTC | Detect IaC drift across environments |
| Nightly Health | `nightly-health.yml` | Daily 04:00 UTC | Full health audit, cert check, backup verify |

## Production Deploy Flow

```
Release Tag (v1.2.3)
  │
  ├── Pre-flight Checks
  │   ├── Deploy window validation (Mon-Thu 09:00-16:00)
  │   ├── Staging health verification
  │   └── Open incident check
  │
  ├── Build & Security Scan
  │   ├── Docker image build
  │   ├── Trivy container scan
  │   ├── Snyk dependency audit
  │   └── SBOM generation
  │
  ├── APPROVAL GATE ← Eng lead + on-call
  │   │               (Governance board for clinical AI)
  │   │
  │   ├── Canary Deploy (5% traffic)
  │   │   └── Monitor 10 minutes
  │   │       ├── Error rate vs baseline
  │   │       ├── Latency percentiles
  │   │       └── 5xx count
  │   │
  │   ├── [Pass] → Promote to 100%
  │   └── [Fail] → Auto-rollback + Incident
  │
  ├── Post-Deploy Verification
  │   ├── Health endpoint check
  │   ├── Smoke tests
  │   └── Monitoring verification
  │
  └── Notify (#eng, #exec)
```

## Branching Strategy

- `main` — Production-ready code. Protected. Requires PR + approval.
- `develop` — Integration branch. Auto-deploys to staging.
- `feature/*` — Feature branches. PR to develop.
- `hotfix/*` — Emergency fixes. PR to main (bypass develop).

## Deployment Strategies

### Canary (Production Default)

1. Deploy new version to 5% of pods
2. Route 5% of traffic to canary
3. Monitor for 10 minutes
4. If error rate < baseline + 1%: promote to 100%
5. If error rate >= baseline + 1%: auto-rollback

### Rolling Update (Staging Default)

1. Update pods one at a time
2. Health-check each pod before proceeding
3. Rollback if any pod fails health check

### Blue-Green (Optional)

1. Deploy to inactive environment
2. Run full test suite
3. Switch traffic atomically
4. Keep old environment for instant rollback

## Rollback

### Automatic Rollback Triggers

- Canary error rate exceeds threshold
- Post-deploy health check fails
- Pod crash loop detected (>= 3 restarts)

### Manual Rollback

```bash
make rollback SVC=api-gateway ENV=production
```

## Deploy Windows

| Day | Hours (Local) | Approval Required |
|-----|---------------|-------------------|
| Mon-Thu | 09:00-16:00 | Standard (eng lead + on-call) |
| Friday | 09:00-14:00 | Eng lead explicit approval |
| Friday 14:00+ | N/A | Blocked except emergency |
| Weekend | N/A | CTO approval required |

## Metrics

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| Deploy Frequency | 2-5/week | < 1/week |
| Lead Time (commit → prod) | < 4 hours | > 24 hours |
| Change Failure Rate | < 5% | > 10% |
| MTTR | < 30 minutes | > 2 hours |
| Rollback Rate | < 10% | > 20% |
