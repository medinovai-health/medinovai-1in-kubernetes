# CHARTER.md — `services/command-center`
**MedinovAI Platform Standard v2.1 | (c) 2026 Copyright MedinovAI. All Rights Reserved.**
**Version: 3.0.0 | Build: 20260414 | Migrated from: medinovai-2pl-atlas-os/ui**

---

## Purpose

The MedinovAI Command Center is the **unified control plane** for all Dev/QA/Staging/Prod
environments. It is the single pane of glass through which developers, IT administrators,
and the MedinovAI team observe, manage, control, and govern every aspect of the platform
once deployed — from individual container health to cross-environment compliance posture.

The Command Center is **not** a passive dashboard. It is an active, intelligent participant
in platform governance, powered by **Nexus** — a dedicated self-learning, self-improving
AI agent trained exclusively on MedinovAI's operational knowledge graph.

---

## Scope

This service owns the following domains and is the **single source of truth** for:

- **Observability** — Real-time metrics, logs, traces, and health across all 190+ services
- **Deployment Control** — Trigger, monitor, rollback, and promote across all environments
- **Incident Management** — Detection, triage, escalation, and autonomous remediation
- **Compliance Enforcement** — HIPAA, GDPR, FDA 21 CFR Part 11 posture monitoring
- **Security Operations** — Threat detection, access anomalies, audit trail integrity
- **Agent Fleet Management** — Observe, control, and retrain all deployed AI agents
- **Knowledge Synchronization** — Keeps Brain, Deploy, and AtlasOS in continuous sync
- **Nexus AI Agent** — The Command Center's own self-learning operational AI

---

## Out of Scope

| Concern | Owned By |
|---------|---------|
| Agent runtime execution | `medinovai-2pl-atlas-os` |
| Clinical data processing | `medinovai-lis`, `medinovai-ctms` |
| Public-facing marketing | `medinovai-website` |
| LLM model training | `medinovai-healthLLM` |
| ZTM marketing automation | `zeroTouchMarketing` |

---

## Architectural Position

```
┌─────────────────────────────────────────────────────────────────┐
│                    medinovai-infrastructure                      │
│                                                                 │
│  services/command-center/  ◄── YOU ARE HERE                    │
│       │                                                         │
│       │  observes (read-only)                                   │
│       ▼                                                         │
│  medinovai-2pl-atlas-os    medinovai-Deploy    medinovai-brain  │
│  medinovai-lis             medinovai-ctms      all 190+ repos   │
└─────────────────────────────────────────────────────────────────┘
```

**Key principle:** The Command Center OBSERVES but does not MODIFY other services directly.
All remediation actions are executed via the respective service's own API or deployment pipeline.

---

## Compliance Tier

| Field | Value |
|-------|-------|
| **Compliance Tier** | Tier 2 — Platform Infrastructure |
| **PHI Safe** | Yes — no PHI ever flows through Command Center |
| **Audit Required** | Yes — all control actions logged to immutable audit chain |
| **Risk Classification** | High — controls production deployments |

---

## 50 Blind Spots Addressed (v3.0)

### Agent Behavior (4)
1. Agent drift detection — behavioral baseline comparison on every cycle
2. Zombie agent detection — heartbeat timeout + auto-termination
3. Silent RAG failure detection — response quality scoring with fallback
4. Token anomaly detection — per-agent token budget monitoring

### Security & Compliance (10)
5. Cross-tenant data leakage detection via response fingerprinting
6. Shadow IT detection — unauthorized service discovery on Tailscale network
7. Ollama sprawl monitoring — inventory all Ollama instances, require explicit approval
8. Hardcoded secret scanning — pre-commit + runtime environment variable audit
9. Incomplete audit trail detection — gap analysis on audit chain
10. Stale API key rotation alerts — 90-day rotation enforcement
11. Unencrypted data-at-rest detection — storage encryption posture check
12. Excessive privilege detection — RBAC drift monitoring
13. Missing MFA enforcement — auth provider posture check
14. Vendor dependency vulnerability scanning — daily CVE feed integration

### Infrastructure & DevOps (9)
15. Configuration drift detection — desired vs. actual state comparison
16. Stale feature flags — flags older than 90 days flagged for review
17. Certificate expiration monitoring — 30/14/7/1 day alerts
18. Unverified backup integrity — daily restore test simulation
19. Resource exhaustion prediction — ML-based capacity forecasting
20. Docker image vulnerability scanning — Trivy integration on every build
21. Orphaned container detection — containers with no parent service
22. Network partition detection — inter-service connectivity matrix
23. Clock skew monitoring — NTP drift alerts across all nodes

### Application Health (8)
24. Unmapped API dependency detection — service mesh topology analysis
25. Memory leak detection — heap growth trend analysis
26. Missing telemetry gaps — services with no metrics for >5 minutes
27. Unvalidated input detection — API fuzzing integration
28. Dead code detection — coverage gap analysis
29. N+1 query detection — database query pattern analysis
30. Slow query alerting — P99 latency threshold monitoring
31. Error budget burn rate — SLO/SLA burn rate dashboard

### Network & Access (6)
32. Missing rate limiting detection — API gateway policy audit
33. Unsecured WebSocket detection — WSS enforcement check
34. Inadequate session management — session timeout policy audit
35. Open port audit — weekly port scan vs. port-registry.json
36. DNS poisoning detection — DNS response integrity monitoring
37. Lateral movement detection — unusual inter-service call patterns

### Risk & Threat Management (13)
38. Threat intelligence feed integration — CVE/NVD/MITRE ATT&CK
39. IDS/IPS posture check — Falco rule coverage audit
40. EDR coverage verification — endpoint protection inventory
41. DLP policy enforcement — data exfiltration pattern detection
42. Vendor risk assessment tracking — third-party SLA monitoring
43. Ransomware behavior detection — file system entropy monitoring
44. Supply chain attack detection — dependency hash verification
45. Insider threat detection — anomalous access pattern analysis
46. Zero-day vulnerability alerting — exploit database monitoring
47. Incident response playbook coverage — gap analysis
48. Business continuity test scheduling — DR drill automation
49. Regulatory change monitoring — HIPAA/GDPR/FDA update feeds
50. AI model poisoning detection — training data integrity verification

---

## 50 Hardening Points Implemented (v3.0)

### Resilience & Reliability (7)
1. Global circuit breakers on all external service calls
2. Chaos engineering integration — weekly automated fault injection
3. Automated rollback on health check failure
4. Blue/green deployment support for zero-downtime updates
5. Multi-region health aggregation
6. Graceful degradation — read-only mode when write services are down
7. Automated backup verification with restore simulation

### Security & Access Control (14)
8. Zero Trust architecture — every request authenticated and authorized
9. mTLS on all inter-service communication
10. WAF integration — OWASP Top 10 protection
11. MFA enforcement for all admin actions
12. Hardware token support (FIDO2/WebAuthn)
13. Network segmentation — Command Center isolated in its own VLAN
14. Immutable audit log — append-only, cryptographically signed
15. Secrets management via HashiCorp Vault (no env var secrets)
16. RBAC with principle of least privilege
17. Session management — 15-minute idle timeout, 8-hour max
18. API key rotation automation
19. Penetration testing integration — automated DAST on every release
20. Security headers enforcement (CSP, HSTS, X-Frame-Options)
21. Input sanitization on all API endpoints

### DevOps & Infrastructure (9)
22. Infrastructure as Code enforcement — no manual cloud console changes
23. Immutable infrastructure — containers never modified in place
24. Automated dependency updates via Renovate
25. Container image signing and verification
26. SBOM (Software Bill of Materials) generation on every build
27. Multi-stage Docker builds with minimal attack surface
28. Read-only root filesystem in containers
29. Non-root container execution
30. Resource limits on all containers (CPU/memory/disk)

### Observability & Monitoring (6)
31. Centralized structured logging (OpenTelemetry → Grafana Loki)
32. Distributed tracing (OpenTelemetry → Jaeger/Tempo)
33. Alert fatigue management — alert correlation and deduplication
34. Synthetic monitoring — simulated user journeys every 5 minutes
35. Real-time anomaly detection on all metrics streams
36. SLO/SLA dashboard with error budget burn rate

### Process & Governance (14)
37. Mandatory code review — no direct pushes to main
38. SAST on every PR (Semgrep + CodeQL)
39. DAST on every release (OWASP ZAP)
40. Threat modeling documentation required for all new features
41. Vendor risk assessment process
42. Change management workflow — all production changes require approval
43. Incident post-mortem automation — template generation
44. Compliance report generation — automated HIPAA/GDPR reports
45. Security awareness training tracking
46. Bug bounty program integration
47. Regulatory change management process
48. Third-party audit support tooling
49. Executive security dashboard
50. AI governance framework — model cards, bias testing, explainability

---

## Team Ownership

| Role | Team |
|------|------|
| **Primary Owner** | `platform-infra-squad` |
| **Security Review** | `security-compliance-squad` |
| **Infrastructure Review** | `infrastructure-squad` |
| **AI Agent Owner** | `ai-platform-squad` |

---

## Key Rules

1. No PHI in logs, errors, or stack traces — ever.
2. All control actions must be logged to the immutable audit chain before execution.
3. Nexus AI Agent may recommend but never execute without human approval in production.
4. All secrets via Vault — never environment variables in production.
5. Every deployment must pass the 10-gate CI pipeline before promotion.
6. The Command Center must remain operational even when all other services are down.
