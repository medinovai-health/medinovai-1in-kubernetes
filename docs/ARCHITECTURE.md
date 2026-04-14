# Architecture Guide — medinovai-1in-kubernetes

> (c) 2025 MedinovAI — Empowering human will for cure.
> Sprint 11: Documentation & API Docs

## System Context

`medinovai-1in-kubernetes` operates within the MedinovAI **AI/ML Engine** layer, providing
core capabilities for the healthcare platform.

## Technology Stack

| Component | Technology |
|-----------|-----------|
| Language | Python |
| Layer | AI/ML Engine |
| Container | Docker + Kubernetes |
| CI/CD | GitHub Actions |
| Monitoring | Prometheus + Grafana |
| Logging | OpenTelemetry |
| Security | Vault + RBAC |

## Component Diagram

```
┌─────────────────────────────────────────┐
│              medinovai-1in-kubernetes                │
├─────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌───────┐ │
│  │ API Layer│  │ Business │  │ Data  │ │
│  │          │──│  Logic   │──│ Layer │ │
│  └──────────┘  └──────────┘  └───────┘ │
├─────────────────────────────────────────┤
│  Infrastructure: Docker, K8s, Vault     │
└─────────────────────────────────────────┘
```

## Data Flow

1. Request arrives at API gateway
2. Authentication/authorization validated
3. Business logic processes request
4. Data layer handles persistence
5. Response returned with audit trail

## Security Architecture

- All PHI encrypted with AES-256-GCM
- mTLS between services
- RBAC with role-based access control
- Audit logging on all data mutations
- Secret rotation via HashiCorp Vault

## Scalability

- Horizontal scaling via Kubernetes HPA
- Database connection pooling
- Redis caching layer
- Async processing via message queues

## Disaster Recovery

- RPO: 1 hour (point-in-time recovery)
- RTO: 15 minutes (automated failover)
- Multi-region replication enabled
- Automated backup verification
