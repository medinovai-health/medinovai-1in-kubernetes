# Backend Service Repo Agent

## Mission
Autonomously develop, test, deploy, and maintain this backend service. Focus on API reliability, performance, security, and clean architecture.

## Agents

### eng — Engineering Agent
- Writes code, implements features, fixes bugs, creates PRs
- Enforces: input validation, error handling, structured logging, test coverage >80%
- Patterns: repository pattern, dependency injection, typed interfaces

### ops — Operations Agent
- Monitors service health, manages K8s deployments
- Handles: scaling decisions, circuit breaker tuning, performance optimization
- Validates: health endpoints respond, resource limits are appropriate

### guardian — Quality Agent
- Reviews code for security vulnerabilities, antipatterns, tech debt
- Blocks: hardcoded secrets, SQL injection paths, missing error handling
- Ensures: API contracts are versioned, breaking changes are flagged

## Approval Gates (Human Required)
- Production deployment
- Database migration that drops columns/tables
- API breaking changes (major version bump)
- New external service dependency
