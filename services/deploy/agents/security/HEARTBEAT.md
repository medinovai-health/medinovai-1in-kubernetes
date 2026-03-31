# Security Sentinel Agent -- Heartbeat Checks

Run these checks proactively. Only alert when something needs attention. Silence means healthy.

## Checks

### 1. Secret Exposure Scan
- **Detect**: Scan all source code, config files, environment examples, and Docker images for hardcoded secrets, API keys, passwords, private keys, and tokens.
- **Remediate**: Replace with secret manager references. Rotate any exposed secrets immediately.
- **Verify**: Re-scan after remediation. Confirm rotation complete.
- **Alert if**: Any secret found in source code. NEVER suppress. Treat as compromised.

### 2. Dependency Vulnerability Scan
- **Detect**: Check all dependencies for known CVEs. Prioritize by severity and exploitability.
- **Remediate**: Draft upgrade to patched version. If no patch exists, document mitigation.
- **Verify**: Run tests after upgrade.
- **Alert if**: Critical CVE with known exploit in production dependency.

### 3. Authentication Flow Integrity
- **Detect**: Verify authentication endpoints enforce rate limiting, account lockout, MFA where required, and secure token handling.
- **Remediate**: Add missing security controls. Fix weak patterns.
- **Verify**: Test authentication flow against OWASP guidelines.
- **Alert if**: Authentication endpoint lacks rate limiting or uses weak token patterns.

### 4. Authorization Policy Validation
- **Detect**: Check RBAC/ABAC policies for over-permissioned roles, missing permission checks on sensitive endpoints, and privilege escalation paths.
- **Remediate**: Tighten permissions. Add missing authorization checks. Remove unused roles.
- **Verify**: Test with least-privilege accounts.
- **Alert if**: Sensitive endpoint lacks authorization check or role has excessive permissions.

### 5. Encryption Verification
- **Detect**: Verify encryption at rest for sensitive data stores. Verify TLS configuration for all external communications. Check for weak ciphers.
- **Remediate**: Enable encryption where missing. Upgrade cipher suites. Enforce TLS 1.2+ minimum.
- **Verify**: Validate encryption configuration.
- **Alert if**: Sensitive data stored unencrypted or weak ciphers in use.

### 6. Audit Log Completeness
- **Detect**: Verify that authentication events, authorization decisions, data access, and privilege changes are logged. Check for gaps.
- **Remediate**: Add logging for uncovered security events. Ensure tamper-evident storage.
- **Verify**: Confirm log coverage matches compliance requirements.
- **Alert if**: Critical security event type lacks audit logging.

### 7. Input Validation
- **Detect**: Check for SQL injection, XSS, SSRF, and command injection vulnerabilities. Verify input sanitization on all external-facing endpoints.
- **Remediate**: Add input validation and output encoding. Use parameterized queries.
- **Verify**: Test with known attack payloads.
- **Alert if**: Any injection vulnerability detected.

### 8. Compliance Posture
- **Detect**: Check compliance requirements (HIPAA, GDPR, SOC 2) against current implementation. Identify gaps.
- **Remediate**: Draft remediation plan for each gap with regulatory reference.
- **Verify**: Re-assess after remediation.
- **Alert if**: New compliance gap identified.

## Suppression Rules

- Do NOT alert if all checks pass.
- Secret exposure, active vulnerabilities, and compliance gaps are NEVER suppressed.
- All security alerts include severity classification and recommended response timeline.
