# ZeroTrust Compliance Checklist — medinovai-real-time-stream-bus

**Tier:** 2 | **Classification:** FDA Class I / IEC 62304-A
**Standard:** `medinovai-ai-standards/SECURITY_AND_ZEROTRUST.md` v3.0.0
**Last Review:** TODO — Set review date

---

## Authentication & Identity

- [ ] All endpoints require JWT Bearer token validation
- [ ] Token validation uses Keycloak OIDC endpoint
- [ ] Token expiry enforced (max 15 minutes for Tier 1)
- [ ] MFA enforced for admin/clinical actions
- [ ] Service-to-service auth uses mTLS or service account tokens
- [ ] No API keys stored in code or environment (uses AWS Secrets Manager)

## Authorization (RBAC/ABAC)

- [ ] RBAC roles defined and mapped to platform squads
- [ ] Least-privilege: each endpoint declares minimum required role
- [ ] Tenant isolation enforced: tenant_id validated on every request
- [ ] Field-level access control applied to PHI/PII fields
- [ ] Authorization failures return 403 (not 404)
- [ ] Authorization decisions logged with trace ID

## Audit Trail

- [ ] All data mutations logged (CREATE/UPDATE/DELETE)
- [ ] Log format includes: timestamp, user_id, tenant_id, action, resource_id, trace_id
- [ ] PHI access logged separately (access log)
- [ ] Logs forwarded to centralized ELK stack
- [ ] Logs immutable (no modification/deletion permitted)
- [ ] Audit queries available via `GET /api/v1/audit?resource_id=...`

## Data Protection

- [ ] PHI/PII encrypted at rest (AES-256)
- [ ] PHI/PII encrypted in transit (TLS 1.2+)
- [ ] No PHI/PII in log messages (IDs only)
- [ ] No PHI/PII in error responses returned to client
- [ ] Database connections use encrypted channels
- [ ] Backup encryption verified

## Input Validation & OWASP

- [ ] All inputs validated and sanitized
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention on any HTML output
- [ ] CSRF protection on state-changing endpoints
- [ ] Rate limiting configured (see `/health` for limits)
- [ ] Dependency vulnerability scan in CI (safety/npm audit)



## Container & Infrastructure Security

- [ ] Docker image runs as non-root user
- [ ] No secrets in Dockerfile or image layers
- [ ] Container image scanned in CI (Trivy/Grype)
- [ ] Network policies restrict pod-to-pod communication
- [ ] Kubernetes RBAC limits service account permissions

---
**Completion Target:** Sprint 3
**Owner:** Security Team + Repo Tech Lead
**Review Cadence:** Quarterly or after significant architecture change
