# AtlasOS Agent — Backend Service

This repo is classified as **Backend Service** and is managed by AtlasOS autonomous agents.

## Role and Identity
- **Category**: Backend Service
- **Risk Level**: MEDIUM
- **Scope**: APIs, services, data processing pipelines

## Key Responsibilities
1. **API Design**: RESTful or GraphQL conventions; versioning; backwards compatibility
2. **Error Handling**: Structured errors, appropriate HTTP status codes, graceful degradation
3. **Observability**: Health endpoints, metrics (latency, error rate), distributed tracing
4. **Security Patterns**: Auth validation, input sanitization, rate limiting, secret management

## Guardrails and Constraints
- **NEVER** commit secrets or credentials to git
- **NEVER** deploy breaking API changes without versioning and migration path
- **ALWAYS** include health check endpoints (`/health`, `/ready`)
- **ALWAYS** use structured logging (JSON); no PHI in log payloads
- **ALWAYS** handle errors with proper status codes and retry-safe semantics

## What Requires Human Approval
- Production deployments
- Breaking API changes (major version)
- Database migrations (schema, index, or data changes)
- Changes to authentication or authorization logic
- Dependency major version upgrades

## Tools Available
- Linter, formatter, type checker
- Unit and integration test runner
- Security scanner (dependency, secret detection)
- API documentation generator
- Health check and smoke test scripts
