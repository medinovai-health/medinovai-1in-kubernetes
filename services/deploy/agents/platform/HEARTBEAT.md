# Platform Operations Agent -- Heartbeat Checks

Run these checks proactively. Only alert when something needs attention. Silence means healthy.

## Checks

### 1. Infrastructure-as-Code Validation
- **Detect**: Verify all infrastructure is defined in code. Check for drift between code and actual state. Validate syntax and configuration.
- **Remediate**: Update IaC to match desired state. Fix syntax errors. Add missing resource definitions.
- **Verify**: Plan/dry-run the changes.
- **Alert if**: Infrastructure drift detected or IaC validation fails.

### 2. Secret Exposure Scan
- **Detect**: Scan for hardcoded credentials, API keys, database passwords, and private keys in code, config files, and Docker images.
- **Remediate**: Replace with secret manager references. Update `.env.example` with placeholders.
- **Verify**: Confirm no secrets in committed code.
- **Alert if**: Any secret found in source code. NEVER suppress.

### 3. Container Security
- **Detect**: Check Dockerfiles for: running as root, using `latest` tags, including unnecessary tools, missing health checks, and large image sizes.
- **Remediate**: Add non-root user, pin image versions, multi-stage builds, health checks.
- **Verify**: Build and test the improved image.
- **Alert if**: Container runs as root or uses unpinned base image.

### 4. Deployment Safety
- **Detect**: Verify deployment configurations include health checks, resource limits, rollback policies, and gradual rollout settings.
- **Remediate**: Add missing deployment safety configuration.
- **Verify**: Simulate a deployment with dry-run.
- **Alert if**: Deployment lacks health checks or rollback configuration.

### 5. Monitoring Coverage
- **Detect**: Verify that deployed services have health check endpoints, structured logging, and metric emission configured.
- **Remediate**: Add missing monitoring configuration.
- **Verify**: Confirm health checks respond and logs are structured.
- **Alert if**: Any deployed service lacks health monitoring.

### 6. Cost Optimization
- **Detect**: Check for over-provisioned resources, idle instances, unattached volumes, and unused load balancers.
- **Remediate**: Suggest right-sizing or cleanup.
- **Verify**: Estimate cost savings.
- **Alert if**: Obvious waste detected (idle resources for > 7 days).

### 7. Backup and Recovery
- **Detect**: Verify backup configurations exist for databases, state stores, and critical configuration. Check backup retention policies.
- **Remediate**: Add missing backup configuration. Set appropriate retention.
- **Verify**: Confirm backup can be restored (dry-run if possible).
- **Alert if**: Critical data lacks backup configuration.

### 8. SSL/TLS and Certificate Health
- **Detect**: Check for certificate expiration, weak cipher suites, and HTTP (non-HTTPS) endpoints in production configuration.
- **Remediate**: Configure certificate renewal. Update cipher suites. Enforce HTTPS redirects.
- **Verify**: Validate certificate chain and expiration dates.
- **Alert if**: Certificate expires within 30 days or weak ciphers detected.

## Suppression Rules

- Do NOT alert if all checks pass.
- Do NOT re-alert on the same issue within the current session.
- Secret exposure and certificate expiration alerts are NEVER suppressed.
