# Architecture Overview — medinovai-deploy

**Tier:** Tier 2 — Platform / Infrastructure (FDA Class I)
**Language:** Shell
**Standard:** `medinovai-ai-standards/ARCHITECTURE.md` | C4 Model

---

## Service Purpose

> TODO: One paragraph description of what this service does and why it exists.

---

## C4 Context Diagram

```mermaid
C4Context
    title System Context — medinovai-deploy

    Person(user, "User", "TODO: Who uses this service?")
    System(service, "medinovai-deploy", "TODO: What does this service do?")
    System_Ext(auth, "Keycloak (OIDC)", "Authentication & Authorization")
    System_Ext(db, "MySQL", "Primary data store")
    System_Ext(mq, "ActiveMQ", "Event messaging")
    System_Ext(otel, "OpenTelemetry Collector", "Observability")

    Rel(user, service, "Uses", "HTTPS/REST")
    Rel(service, auth, "Validates JWT", "HTTPS")
    Rel(service, db, "Reads/Writes", "TLS MySQL")
    Rel(service, mq, "Publishes/Subscribes", "ActiveMQ")
    Rel(service, otel, "Sends traces/metrics/logs", "gRPC")
```

---

## Key Components

| Component | Language | Purpose |
|-----------|----------|---------|
| API Layer | Shell | REST endpoints, request validation, auth middleware |
| Service Layer | Shell | Business logic, domain rules |
| Data Layer | Shell | Database access, caching |
| Event Layer | Shell | ActiveMQ publisher/subscriber |

---

## Data Flow

```mermaid
sequenceDiagram
    participant Client
    participant API as medinovai-deploy API
    participant Auth as Keycloak
    participant Service as Business Logic
    participant DB as MySQL

    Client->>API: POST /api/v1/resource (Bearer token)
    API->>Auth: Validate JWT
    Auth-->>API: Claims (user_id, tenant_id, roles)
    API->>Service: Process request
    Service->>DB: Write + audit log
    DB-->>Service: Confirmation
    Service-->>API: Result
    API-->>Client: 201 Created + response envelope
```

---

## Dependencies

| Dependency | Type | Purpose | Tier |
|------------|------|---------|------|
| medinovai-security-service | Runtime | RBAC policy decisions | Platform |
| medinovai-audit-service | Runtime | Audit trail persistence | Platform |
| MySQL | Infrastructure | Primary database | Platform |
| ActiveMQ | Infrastructure | Event messaging | Platform |
| Keycloak | Infrastructure | Identity provider | Platform |
| OpenTelemetry Collector | Infrastructure | Observability | Platform |

---

## Architecture Decision Records

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| ADR-001 | TODO: First significant architectural decision | Proposed | TODO |

---

## Deployment Architecture

See `kubernetes/` or `infrastructure/` for deployment manifests.
Environment configuration via AWS Secrets Manager + environment variables.
