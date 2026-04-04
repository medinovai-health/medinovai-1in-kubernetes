# CHARTER.md — `<monorepo-name>`
**Platform Standard v2.1 | (c) 2026 Copyright MedinovAI. All Rights Reserved.**

## Purpose
`<One paragraph describing the primary purpose of this monorepo and what domain it owns.>`

## Scope
This monorepo owns the following domains and is the **single source of truth** for:
- `<Domain 1>` — `<brief description>`
- `<Domain 2>` — `<brief description>`

## Out of Scope
The following concerns are explicitly **NOT** owned by this monorepo:
- `<Concern 1>` — owned by `<other-monorepo>`
- `<Concern 2>` — owned by `<other-monorepo>`

## Compliance Tier
| Field | Value |
|---|---|
| **Compliance Tier** | `<Tier 1 HIPAA/FDA 21 CFR Part 11 / Tier 2 / Tier 3 / Tier 4>` |
| **PHI Safe** | `<Yes / No>` |
| **Audit Required** | `<Yes / No>` |
| **Risk Classification** | `<High / Medium / Low>` |

## Team Ownership
| Role | Team |
|---|---|
| **Primary Owner** | `<team-name>-squad` |
| **Security Review** | `security-compliance-squad` |
| **Infrastructure Review** | `infrastructure-squad` |

## Monorepo Structure
```
<monorepo-name>/
├── services/           # Deployable microservices (one per subdirectory)
│   └── <service-name>/
│       ├── module-manifest.yaml   # REQUIRED — machine-readable identity
│       ├── CLAUDE.md              # REQUIRED — AI coding context
│       ├── Dockerfile             # REQUIRED
│       ├── docker-compose.yml     # REQUIRED — uses port-registry.json
│       └── src/
├── libs/               # Shared libraries (not independently deployable)
│   └── <lib-name>/
├── docs/               # Architecture docs, ADRs, specs
├── .cursor/rules/      # AI agent coding rules
├── CLAUDE.md           # Monorepo-level AI context
├── CHARTER.md          # This file
├── MISTAKES.md         # Known failure patterns and fixes
└── WORKSPACE.md        # How to add services and run locally
```

## Adding a New Service
1. Create `services/<service-name>/` directory.
2. Copy `module-manifest.yaml` template and fill in all fields.
3. Assign a port from `medinovai-deploy/config/port-registry.json`.
4. Add `CLAUDE.md`, `Dockerfile`, `docker-compose.yml`, and `README.md`.
5. Open a PR — the 10-gate CI pipeline will validate compliance.

## Key Rules (from `medinovai-platform-context.mdc`)
1. No PHI in logs, errors, or stack traces.
2. Every state-changing function must call `audit_logger.log()`.
3. All ports must come from `port-registry.json` — no hardcoding.
4. Functions must not exceed 40 lines.
5. Test coverage minimum: 85%.
