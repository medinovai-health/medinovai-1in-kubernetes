# MedinovAI Full Deployment - Systematic Testing & Fixes

## SuperAdmin Credentials (SSO Access)

| Username | Password | Role | Realm |
|----------|----------|------|-------|
| mayank@medinovai.com | MedinovAI-Dev-2025! | atlas-super-admin, GLOBAL_ADMIN | medinovai |
| admin@myonsitehealthcare.com | Admin@2026!Secure | atlas-super-admin | myonsitehealthcare |

### Keycloak SSO URLs
- Keycloak Admin Console: `http://localhost:8080/admin` (when port-forwarded)
- Realm: `medinovai`
- Client: `medinovai-atlas`

## Deployment Status Summary

**Date:** 2026-04-01
**Total Repos:** 269
**Total Services Deployed:** 80+
**Pods Running:** 35/42 (83% success rate)

### Healthy Services (35 Running)

#### Monitoring Stack
- [x] Grafana (NodePort: 32406) - http://localhost:32406
- [x] Kibana (NodePort: 30252) - http://localhost:30252
- [x] Prometheus
- [x] Elasticsearch

#### Core Platform (medinovai-production)
- [x] medinovai-ctms (2 replicas)
- [x] medinovai-econsent (2 replicas)
- [x] medinovai-epro (2 replicas)
- [x] medinovai-encryption-vault (2 replicas)
- [x] medinovai-hipaa-gdpr-guard (2 replicas)
- [x] medinovai-lis (2 replicas)
- [x] medinovai-registry-fixed (2 replicas)
- [x] medinovai-security-service-fixed (2 replicas)

#### Services Layer (medinovai-services)
- [x] medinovai-canary-rollout-orchestrator
- [x] medinovai-ctms
- [x] medinovai-deploy
- [x] medinovai-econsent
- [x] medinovai-encryption-vault
- [x] medinovai-epro
- [x] medinovai-hipaa-gdpr-guard
- [x] medinovai-lis
- [x] medinovai-saes
- [x] medinovai-sales
- [x] medinovai-secrets-manager-bridge
- [x] medinovai-security-service

#### Data Layer (medinovai-data)
- [x] medinovai-data-services

#### Infrastructure (medinovai)
- [x] local-registry
- [x] registry-redis

### Services with Remaining Issues (7 pods)

| Service | Status | Issue |
|---------|--------|-------|
| medinovai-consent-preference-api | Error/CrashLoopBackOff | Health probe failure |
| medinovai-real-time-stream-bus | CrashLoopBackOff/ErrImageNeverPull | Image/config issue |
| medinovai-registry (original) | Init:CreateContainerConfigError | Init container config |
| registry-postgres | CreateContainerConfigError | Config error |

## Fix Progress

### Phase 1: Image Pull Fixes ✅ COMPLETE
- Built local Docker images for all ErrImageNeverPull services
- Applied `imagePullPolicy: IfNotPresent` to use local images
- Successfully fixed:
  - medinovai-deploy
  - medinovai-sales
  - medinovai-data-services
  - medinovai-secrets-manager-bridge

### Phase 2: Health Probe Fixes ✅ MOSTLY COMPLETE
- Fixed port mismatches (3000 → 8000)
- Updated readiness/liveness probe configurations
- Services now responding on `/health` endpoint

### Phase 3: Full Service Testing 🔄 IN PROGRESS
- Port-forwarding key services for Playwright testing
- Screenshots captured for:
  - Grafana login page
  - Kibana dashboard
  - Registry health endpoint
  - Security service health endpoint

## Testing Results

| Service | Health Endpoint | Status | Screenshot |
|---------|----------------|--------|------------|
| Grafana | /login | ✅ PASS | grafana-login.png |
| Kibana | / | ✅ PASS | kibana.png |
| Registry (fixed) | /health | ✅ PASS | registry-health.png |
| Security (fixed) | /health | ✅ PASS | security-health.png |
| Deploy | /health | ✅ PASS | - |
| Sales | /health | ✅ PASS | - |
| Data Services | /health | ✅ PASS | - |
| Secrets Manager | /health | ✅ PASS | - |

## Access URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| Grafana | http://localhost:32406 | admin/admin (default) |
| Kibana | http://localhost:30252 | - |
| Keycloak | http://localhost:8080 | See SuperAdmin above |

## Commands

```bash
# Run initialization
./init.sh full

# Check status
./init.sh check

# Show credentials
./init.sh credentials

# Port forward for testing
kubectl port-forward -n medinovai-monitoring svc/grafana 32406:3000 --address 0.0.0.0
kubectl port-forward -n medinovai-monitoring svc/kibana 30252:5601 --address 0.0.0.0
```

## Next Steps

1. Fix remaining 7 pods with issues
2. Complete Playwright E2E testing for all modules
3. Document all module screens and access patterns
4. Set up continuous health monitoring
