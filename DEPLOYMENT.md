# DEPLOYMENT.md
# Sprint 10: Deployment Runbook for medinovai-1in-kubernetes
# (c) 2025 DescartesBio — Empowering human will for cure.

## Overview

This document describes the CI/CD pipeline and deployment procedures for `medinovai-1in-kubernetes`.

## Pipeline Architecture

```
Push to main → CI (lint → test → security → build) → CD (staging → production)
Tagged release → Auto-deploy to production → GitHub Release created
```

## Environments

| Environment | Branch/Trigger | Auto-Deploy | Approval Required |
|-------------|---------------|-------------|-------------------|
| Development | feature/* | No | No |
| Staging | main (push) | Yes | No |
| Production | v* (tag) | Yes | Yes |

## CI Pipeline (.github/workflows/ci.yml)

1. **Lint & Format** — Code style enforcement
2. **Unit Tests** — Automated test suite with coverage
3. **Security Scan** — Trivy vulnerability scanning (CRITICAL/HIGH)
4. **Build & Package** — Artifact creation and Docker image build

## CD Pipeline (.github/workflows/cd.yml)

1. **Deploy to Staging** — Automatic on main branch push
2. **Deploy to Production** — Triggered by version tags (v*)
3. **Create Release** — Auto-generated release notes

## Rollback Procedure

1. Identify the last known good release tag
2. Trigger manual deployment: `gh workflow run cd.yml -f environment=production`
3. Verify health checks pass
4. Update incident log

## Health Checks

- Application health: `GET /health`
- Readiness probe: `GET /ready`
- Liveness probe: `GET /alive`

## Monitoring

- CI/CD status: GitHub Actions dashboard
- Deployment logs: GitHub Actions run logs
- Security alerts: GitHub Security tab
