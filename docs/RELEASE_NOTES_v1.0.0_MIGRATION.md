# Release Notes v1.0.0 - Monorepo Migration

**Task Reference:** MONO-2026-Q1 / CCR-MONO-2026-001  
**Release Date:** 2026-03-31  
**Version:** v1.0.0-migration-2026Q1  
**Migration ID:** MONO-2026-Q1  
**Status:** Production Ready

## Executive Summary

This release marks the successful consolidation of **192** individual repositories into **seven** well-structured monorepos under `medinovai-health`, representing a major milestone in MedinovAI platform engineering. Source history was preserved using `git filter-repo` style subtree migrations where applicable, and each monorepo now owns a clear domain boundary (platform, security, data, clinical, experience, infrastructure, and reference architecture).

## What is New

### Monorepo architecture

- **Seven unified monorepos** replacing scattered single-service repositories across the organization.
- **104 migrated components** (source repositories or packages placed under `services/`, `apps/`, `libs/`, or `deploy/` paths) per the authoritative `monorepo-migration/migration-manifest.json` inventory.
- **Path-filtered CI/CD** so pull requests build and test only the workspaces that changed.
- **Shared libraries** colocated with consumers where appropriate, with explicit dependency boundaries between monorepos.

### Services and domains by monorepo

#### medinovai-platform-brain (reference and standards)

- Canonical **architecture and specification host** (evolution of `medinovai-Developer`).
- **Org deploy reference** (`medinovai-deploy` into `deploy/`), **developer standards**, **AI standards**, **governance templates**, **help** and **architecture catalog** documentation.
- **Not a production runtime**; this monorepo is the platform brain for contracts, specs, and engineering guidance.

#### medinovai-core-platform (13 migrated components)

- **Registry**, **Security Service (MSS)**, **ZeroTrustAudit**.
- **Role-based permissions**, **Universal Sign-On**.
- **Workflow**, **notification**, **email/mail**, **smart scheduler**, **real-time stream bus** (see monorepo layout for final folder names).
- Shared **core** and **constitution** libraries.

#### medinovai-security-compliance (9 migrated components)

- **Encryption vault**, **secrets manager bridge**, **consent preference API**, **HIPAA/GDPR guard**.
- **Cognitive firewall**, **policy diff watcher**, **audit trail explorer**, **quality certification**, **Trust** schemas.

#### medinovai-data-integration (7 migrated components)

- **Data services**, **EPG** (Edge Privacy Gateway reference path), **data lake loader**, **ETL designer**, **data officer**, **CDR** (Clinical Data Repository), **data-generator** library.

#### medinovai-clinical-research (40 migrated components)

- Full **eClinical** surface area: **CTMS**, **EDC**, **ePRO**, **eConsent**, **eSource**, **eISF**, **IWRS**, **RBM**, **site feasibility**, **pharmacovigilance**, **eSign**, and related modules.
- **LIS**, **lab order router**, **regulatory submissions**, and adjacent clinical or operational scaffolds as laid out in the monorepo.

#### medinovai-experience (19 migrated components)

- **UI/UX library**, **UI components**, **Prism** design system, **multimodal shell**, **white-label**, **accessibility**, **content translator**.
- Applications including **contract management**, **sales**, **SAES**, **chatbot**, **CEO assistant**, **DocuGenie** variants, **developer portal**, **workspace hub**, **GoLive**, and **voice/TTS** libraries.

#### medinovai-infrastructure (9 migrated components)

- **Infrastructure core** (existing repo content), **canary rollout orchestrator**, **edge cache/CDN**, **feature flag console**, **devops telemetry**, **test infrastructure**, **QA agent builder**, **guideline updater**, **ops monitoring**.

## Migration statistics

| Metric | Value |
|--------|-------|
| Repositories in scope | 192 |
| Target monorepos | 7 |
| Migrated components (manifest) | 104 |
| Estimated commits preserved (org-wide) | 50,000+ |
| Path-scoped CI workflows | 38+ (initial tranche; expand per package) |
| Legacy repos archived (wave) | 60 |
| Execution window (calendar) | 2 days |

Machine-readable metrics: `docs/monorepo-migration/migration-metrics.json`.

## Breaking changes

**None by design.** Public HTTP APIs, event contracts, and integration URLs are expected to remain compatible; consumers should pin to service versions as documented per package. Any exception must be recorded in the service README and in QMS change control.

## Deprecations

- **Grade E** and other low-trust legacy repositories were **archived** (26 in the legacy cleanup wave).
- **Migrated source repositories** are marked **read-only** (34+) with redirect notices to the owning monorepo; open PRs should retarget the monorepo path.

## Rollback information

- Legacy repositories were tagged: `pre-monorepo-migration-20260330` (where tagging automation completed).
- Formal rollback and dual-run policy: **CCR-MONO-2026-001** (`monorepo-migration/qms/CCR-MONO-2026-001.md` in the migration workspace, or equivalent path in `medinovai-platform-brain`).

## Known issues

- **GitHub Actions** path filters and workflow `workflow_dispatch` need a **first successful run** on each monorepo after merge to `main`.
- Some services still require **environment-specific configuration** (secrets via **secrets-manager-bridge**, not committed `.env`).
- A small number of historical **BMAD-generated** Dockerfiles may still need **stub or port-alignment fixes** before cluster deploy (see deployment brain runbooks).

## Upgrade instructions

1. Clone the appropriate monorepo: `gh repo clone medinovai-health/<monorepo-name>`.
2. If the repository uses submodules, run: `git submodule update --init --recursive`.
3. Open the **service or app README** under `services/<name>/` or `apps/<name>/` for stack-specific bootstrap.
4. Run the monorepo **root** `README` quickstart (Docker Compose or `make` targets) where documented.
5. For contract-first work, follow **OpenAPI** sources in `medinovai-platform-brain` `data-contracts/` until each monorepo publishes its own generated SDKs.

## Contributors

- Platform Engineering Team  
- Multi-agent automation system (migration scripts, manifest validation, tagging)

## Artifacts

| Artifact | Location |
|----------|----------|
| Migration report | `docs/monorepo-migration/FINAL_MIGRATION_REPORT.md` |
| Metrics JSON | `docs/monorepo-migration/migration-metrics.json` |
| QMS / change record | `monorepo-migration/qms/CCR-MONO-2026-001.md` |
| Authoritative inventory | `monorepo-migration/migration-manifest.json` |

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-03-31 | Platform Engineering | Initial monorepo migration release notes |
