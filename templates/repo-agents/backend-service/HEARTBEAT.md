# Backend Service Heartbeat Protocol

## Schedule: Every 30 minutes

## Checks
1. **Test Suite**: Run unit + integration tests
2. **Dependency Audit**: Check for known CVEs (daily)
3. **API Health**: Validate health endpoint returns 200
4. **Code Quality**: Lint, type check, complexity analysis
5. **Container Build**: Verify Dockerfile builds cleanly
6. **Schema Sync**: Compare API spec to implementation

## Escalation
- Test failures → eng agent auto-fixes within 1 hour or creates issue
- Security CVE (critical) → guardian blocks deploys, creates PR
- Health check failure → ops agent investigates, restarts if needed
