# Service Reliability Agent -- Heartbeat Checks

Run these checks proactively. Only alert when something needs attention. Silence means healthy.

## Checks

### 1. Health Endpoint Verification
- **Detect**: Verify `/health` and `/ready` endpoints exist and return 200 with meaningful status.
- **Remediate**: If missing, draft the health check implementation covering database, cache, and critical dependencies.
- **Verify**: Confirm endpoints respond correctly.
- **Alert if**: Health endpoints are missing or return incorrect status.

### 2. Error Handling Coverage
- **Detect**: Scan for unhandled promise rejections, missing try/catch blocks around I/O operations, and missing error middleware.
- **Remediate**: Add appropriate error handling with structured error responses.
- **Verify**: Confirm all I/O paths have error handling.
- **Alert if**: External calls lack error handling or timeout configuration.

### 3. Database Migration Safety
- **Detect**: Check pending migrations for destructive operations. Verify reversibility. Check for missing indexes on frequently queried columns.
- **Remediate**: Flag destructive operations. Suggest non-destructive alternatives. Draft index additions.
- **Verify**: Confirm migration can be rolled back.
- **Alert if**: Irreversible migration detected or missing critical indexes.

### 4. Dependency Vulnerability Scan
- **Detect**: Check for known CVEs in production dependencies.
- **Remediate**: Identify safe upgrade path. Draft dependency update.
- **Verify**: Run tests after upgrade.
- **Alert if**: Critical or high severity CVE in production dependencies.

### 5. Secret Exposure Check
- **Detect**: Scan for hardcoded API keys, database credentials, tokens, or passwords in source code, config files, and environment examples.
- **Remediate**: Replace with environment variable references. Update `.env.example` with placeholder.
- **Verify**: Confirm no secrets in committed code.
- **Alert if**: Any secret or credential found in source code.

### 6. API Contract Consistency
- **Detect**: Verify that API responses match documented schemas. Check for undocumented endpoints or response fields.
- **Remediate**: Update API documentation or fix response schemas.
- **Verify**: Validate responses against schema.
- **Alert if**: API responses deviate from documented contract.

### 7. Connection Pool and Resource Limits
- **Detect**: Check that database connection pools, HTTP client pools, and thread/worker pools have explicit limits configured.
- **Remediate**: Add pool configuration with appropriate limits.
- **Verify**: Confirm configuration is applied.
- **Alert if**: Any pool runs without explicit limits (risk of resource exhaustion).

### 8. Logging and Observability
- **Detect**: Verify structured logging is in place. Check for correlation ID propagation. Verify log levels are appropriate (no DEBUG in production config).
- **Remediate**: Add structured logging where missing. Add correlation ID middleware.
- **Verify**: Confirm logs are structured and include request context.
- **Alert if**: Critical paths lack structured logging.

## Suppression Rules

- Do NOT alert if all checks pass.
- Do NOT re-alert on the same issue within the current session unless it has changed.
- Secret exposure alerts are NEVER suppressed.
