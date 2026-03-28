# medinovai-Deploy — AI Development Rules

## Repo Identity
| Field | Value |
|-------|-------|
| Repo | medinovai-Deploy |
| Tier | 0 |
| Grade | D |
| Domain | platform |
| Language | shell |
| Risk Class | low |
| Platform Standard | v2.0 |

## Platform Standards (MANDATORY)
- All development follows Spec-Driven Development (SDD): SPECIFY → VALIDATE → BMAD → TESTS → IMPLEMENT → VALIDATE → DEPLOY
- Never write implementation code without a specification
- Never write code before tests (TDD: RED → GREEN → REFACTOR)
- Use platform shared services — never reimplement auth, secrets, audit, or telemetry locally

## Coding Standards
- Python 3.10+ with type hints on ALL functions
- PEP 8 style, 120 char line length
- Google-style docstrings
- Async/await for all I/O operations
- Pydantic models for request/response validation
- structlog for ALL logging (ZTA format)

## Naming Conventions
- Constants: `E_` prefix in UPPER_CASE (e.g., `E_MODULE_ID`)
- Variables: `mos_` prefix in lowerCamelCase (e.g., `mos_patientData`)
- Code blocks: Maximum 40 lines for readability
- Encoding: UTF-8 everywhere

## Logging Standard (ZTA Format)
ALL logging MUST use structured JSON format (ZTA standard):
```json
{"timestamp": "ISO8601", "level": "INFO", "service_id": "medinovai-Deploy",
  "correlation_id": "uuid", "tenant_id": "string", "actor_id": "string",
  "event": "string", "category": "audit|business|debug", "phi_safe": true}
```
- NEVER use print() or plain logging.info()
- NEVER log raw PHI/PII values (use IDs only)
- Audit events: category="audit", always Level 3 metadata
- Debug events: only emitted when debug mode active

## Code Navigation — jCodeMunch
```
list_repos                                             → check indexed repos
search_symbols: { "repo": "medinovai-Deploy", "query": "..." } → find functions/classes
get_symbol:     { "repo": "medinovai-Deploy", "symbol_id": "..." } → get source
get_context_bundle: { "repo": "medinovai-Deploy", "symbol_id": "..." } → symbol + imports
```

## Platform References
- Unified Standard: medinovai-Developer/docs/platform-audit/UNIFIED_ALIGNMENT_STANDARD_v2.0.md
- System Docs: medinovai-Developer/docs/platform-audit/SYSTEM_TECHNICAL_DOCUMENTATION.md
- Alignment Plan: medinovai-Developer/docs/platform-audit/MASTER_ALIGNMENT_PLAN.md
