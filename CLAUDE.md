# CLAUDE.md — medinovai-infrastructure

## Identity
Infrastructure — IaC, Kubernetes configs, Terraform modules, deployment
**Stack:** HCL/Terraform, Python, YAML
**Tier:** 2 — Platform
**Type:** Monorepo

## Always Apply
- Patient safety first, always
- `E_` prefix for ALL constants: `E_MAX_RETRIES`, `E_MODULE_ID`
- `mos_` prefix for ALL variables: `mos_patientId`, `mos_correlationId`
- Code blocks <= 40 lines — break larger functions into named helpers
- Type hints on ALL function parameters and returns
- Google-style docstrings on all public functions and classes
- Structured JSON logging (structlog for Python, pino for Node)
- No `sudo`, no elevated permissions, no destructive commands

## Coding Conventions
| Pattern | Convention | Example |
|---|---|---|
| Constants | `E_` prefix, ALL_CAPS | `E_MAX_RETRIES`, `E_MODULE_ID` |
| Variables | `mos_` prefix, lowerCamelCase | `mos_patientId`, `mos_correlationId` |
| Functions | descriptive, language-standard | `mos_validatePatient()` |
| Classes | PascalCase, domain-prefixed | `MosPatientService` |

## Session Protocol

### First session (no `progress.md` exists):
1. Run `pwd` to confirm working directory
2. Create `init.sh` (install deps + start dev server + health-check)
3. Create `features.json` (all features `passes: false`)
4. Create `progress.md` (initial state entry)
5. Initial git commit on feature branch. **STOP and wait for confirmation.**

### Subsequent sessions (`progress.md` exists):
1. Run `pwd` -> read `git log --oneline -5` + `progress.md`
2. Run `bash init.sh` and existing tests — verify not already broken
3. Read `features.json` -> select ONE highest-priority feature where `passes: false`
4. Implement -> E2E browser/API verify -> update `features.json` (`passes: true`) -> update `progress.md` -> git commit. **STOP.**


## Monorepo Structure
- `services/` — individual service modules (each deployable independently)
- `libs/` — shared libraries consumed by services
- `docs/` — architecture, migration notes, templates
- `WORKSPACE.md` — git subtree migration guide
- `VERSIONS.md` — version tracking per service

## Key Files
- `features.json` — feature tracking (one feature per session)
- `progress.md` — session log (read at start, update at end)
- `init.sh` — dev server start + smoke test
- `WORKSPACE.md` — monorepo workspace guide
- `VERSIONS.md` — service version tracking
