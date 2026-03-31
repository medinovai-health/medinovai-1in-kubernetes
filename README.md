# MedinovAI medinovai-infrastructure

**Part of:** MedinovAI Platform v5
**Domain:** infrastructure
**Type:** Monorepo
**Created:** 2026-03-30
**Description:** Infrastructure - Helm, Terraform, deploy engine, monitoring, DevOps tooling

## Structure

```
medinovai-infrastructure/
├── services/          # Deployable microservices (one directory per service)
├── libs/              # Shared libraries (internal dependencies)
├── deploy/
│   └── charts/        # Helm charts per service
├── docs/              # Architecture, runbooks, ADRs
├── .github/
│   └── workflows/     # Path-filtered CI/CD per service
└── .cursor/
    └── rules/         # AI coding assistant rules
```

## Adding a Service

See [WORKSPACE.md](WORKSPACE.md) for the standard migration workflow.

## Migration Status

This monorepo is part of the MedinovAI 192-repo consolidation.
See the brain repo `medinovai-Developer` for the master migration plan.
