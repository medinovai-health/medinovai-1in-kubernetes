# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest  | Yes       |
| < 1.0   | No        |

## Reporting a Vulnerability

**DO NOT** open a public issue for security vulnerabilities.

Instead, please email: security@medinovai.health

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

We will acknowledge receipt within 24 hours and provide a detailed response within 72 hours.

## Security Practices

- All dependencies are regularly audited
- Static analysis runs on every PR
- Secrets are managed via environment variables only
- All data in transit uses TLS 1.3
- All data at rest uses AES-256-GCM encryption
- Access follows principle of least privilege
