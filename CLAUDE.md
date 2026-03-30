# medinovai-infrastructure — AI Development Rules

## Repo Identity
| Field | Value |
|-------|-------|
| Repo | medinovai-infrastructure |
| Repo ID | medinovai-1in-kubernetes |
| Tier | 1 |
| Domain | infrastructure |
| Language | HCL |
| Risk Class | high |
| Platform Standard | v2.0 |

## Platform Standards (MANDATORY)
- All development follows Spec-Driven Development (SDD): SPECIFY → VALIDATE → BMAD → TESTS → IMPLEMENT → VALIDATE → DEPLOY
- Never write implementation code without a specification
- Never write code before tests (TDD: RED → GREEN → REFACTOR)
- Use platform shared services — never reimplement auth, secrets, audit, or telemetry locally

## Coding Standards
- Platform standard coding conventions, structlog/structured logging
- Async/await for all I/O operations
- Pydantic/Zod models for request/response validation

## Naming Conventions
- Constants: `E_` prefix in UPPER_CASE (e.g., `E_MODULE_ID`)
- Variables: `mos_` prefix in lowerCamelCase (e.g., `mos_patientData`)
- Code blocks: Maximum 40 lines for readability
- Encoding: UTF-8 everywhere

## Logging Standard (ZTA Format)
ALL logging MUST use structured JSON format (ZTA standard):
```json
{"timestamp": "ISO8601", "level": "INFO", "service_id": "medinovai-infrastructure",
  "correlation_id": "uuid", "tenant_id": "string", "actor_id": "string",
  "event": "string", "category": "audit|business|debug", "phi_safe": true}
```
- NEVER use print() or plain logging.info()
- NEVER log raw PHI/PII values (use IDs only)

## Port Authority
- ALL ports from medinovai-health/Deploy/config/port-registry.json
- NO hardcoded ports — load from registry

## Platform References
- Unified Standard: medinovai-Developer/docs/platform-audit/UNIFIED_ALIGNMENT_STANDARD_v2.0.md
- System Docs: medinovai-Developer/docs/platform-audit/SYSTEM_TECHNICAL_DOCUMENTATION.md
