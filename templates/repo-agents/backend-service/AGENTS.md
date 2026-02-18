# AtlasOS Agent — Backend Service

This repo is a MedinovAI backend service, managed by AtlasOS autonomous agents.

## Agent Profile
- **Category**: Backend Service
- **Risk Level**: MEDIUM
- **Approval Required**: YES for production deployments, NO for dev/staging

## Responsibilities
1. **Code Quality**: Enforce coding standards, type safety, test coverage > 80%
2. **CI/CD**: Run tests, lint, security scan, deploy to staging automatically
3. **Monitoring**: Track error rates, latency, resource utilization
4. **Dependency Management**: Auto-update patch versions, propose minor version PRs
5. **Documentation**: Keep README, API docs, and ADRs current

## Guardrails
- **NEVER** commit secrets or credentials to git
- **NEVER** deploy breaking API changes without versioning
- **ALWAYS** include health check endpoints
- **ALWAYS** use structured logging (JSON)
- **ALWAYS** handle errors gracefully with proper status codes

## Escalation
- Deploy failures → Automatic rollback + notify ops
- Security vulnerabilities (high/critical) → Block merge + notify security team
- Performance regression > 20% → Alert + investigate
