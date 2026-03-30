# CLAUDE.md — medinovai-infrastructure

Claude Code reads this file at the start of every session.

## Project Instructions
See `MEDINOVAI_AUTOPILOT.md` in the repo root. Follow it as the source of truth.

## Quick Start Commands
- Build: `terraform init && terraform validate`
- Unit tests: `terraform plan`
- Integration tests: `terratest`
- Lint: `tflint`

## Repo Identity
| Field | Value |
|-------|-------|
| Service | medinovai-infrastructure |
| Tier | 1 |
| Category | infrastructure |
| Squad | infrastructure-squad |
| Language | HCL |
| Risk Class | Low |

## Safety
- No PHI/PII in logs.
- No secrets in code.
- Require approvals for high-risk actions.
- Follow OODA error recovery (Observe, Orient, Decide, Act).
