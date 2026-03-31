# .ai-standards — MedinovAI Central Standards

This directory provides the Claude AI agent with MedinovAI's platform-wide coding
standards, compliance rules, and architectural guidelines.

## Single Source of Truth

All standards documents live in **medinovai-Developer** and are distributed to every
repository via this stub directory.

Full standards: https://github.com/medinovai-health/medinovai-Developer/tree/main/medinovai-ai-standards

## Documents

| File | Purpose |
|---|---|
| `CLAUDE.md` | Master AI agent instructions (imported by root CLAUDE.md) |
| `CODING_STANDARDS.md` | Naming conventions, language patterns |
| `COMPLIANCE_MATRIX.md` | FDA, EU MDR, HIPAA, GDPR, ISO 13485, IEC 62304 |
| `SECURITY_AND_ZEROTRUST.md` | ZeroTrustAudit, RBAC, audit trails |
| `OBSERVABILITY.md` | Logging L0-L4, OpenTelemetry, Registry |
| `AGENT_HARNESS.md` | Claude Harness 2.0 standard |
| `ARCHITECTURE.md` | AutonomyOS platform architecture |
| `REPO_BOOTSTRAP.md` | New repo setup guide |

## Usage

The root `CLAUDE.md` in this repo contains:
```
@import .ai-standards/CLAUDE.md
```

This import directive loads the master standards when any AI agent works in this repo.

## Updates

Standards are managed centrally in medinovai-Developer. Do not edit these files directly
in individual repos — raise a PR against medinovai-Developer instead.

**Owner:** Mayank Trivedi, Chief AI Officer, MedinovAI
