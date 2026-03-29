# Cursor Rule: MedinovAI AtlasOS Autopilot — medinovai-Deploy

Source of truth: `MEDINOVAI_AUTOPILOT.md`

## Service Identity
- Name: medinovai-Deploy
- Tier: 1 | Squad: infrastructure-squad
- Risk: Low | Domain: Infrastructure

## Enforce
- DTO/DAL gating for all database access
- ActiveMQ microservice communications
- JSON + Swagger/OpenAPI for all APIs
- `e_` constants, `mos_` variables naming convention
- Blocks <= 40 lines; refactor if larger
- Evidence bundles + traceability updates on every PR
- Safe-by-default autonomy with approval gates
- OODA error recovery loop on all failures
- Zero PHI/PII in logs, embeddings, or stored context
- Tenant isolation via X-Tenant-ID header
