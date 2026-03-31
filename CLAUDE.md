# CLAUDE.md - medinovai-infrastructure

## Purpose

Infrastructure - Helm, Terraform, deploy engine, monitoring, DevOps tooling

## Compliance Tier

- **Platform Tier:** Varies by service
- **Compliance Tier:** Varies by service (check each service.yaml)

## Repo Identity

| Field | Value |
|-------|-------|
| Repo | medinovai-infrastructure |
| Type | Monorepo |
| Domain | infrastructure |
| Language | Mixed (Python, TypeScript, C#) |
| Platform Standard | v2.1 |

## How to Run Tests

```bash
# Per-service tests
cd services/<service-name>
pytest  # Python
npm test  # Node.js
dotnet test  # C#
```

## Coding Conventions

- Constants: `E_VARIABLE` (uppercase, E_ prefix)
- Variables: `mos_variableName` (lowerCamelCase, mos_ prefix)
- Methods: max 40 lines
- Docstrings: Google-style on all public functions
- Type hints on ALL function parameters and returns
- Logging: structlog ZTA format (structured JSON)
- Encoding: UTF-8 everywhere
