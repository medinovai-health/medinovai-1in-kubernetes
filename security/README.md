# MedinovAI Healthcare LIS - Security & Compliance Infrastructure

[![Security Gate](https://img.shields.io/badge/Security%20Gate-Passing-green)](./security-gate.yml)
[![HIPAA Compliant](https://img.shields.io/badge/HIPAA-Compliant-blue)](./compliance/hipaa-checklist.yaml)
[![SOC 2](https://img.shields.io/badge/SOC%202-Type%20II-blue)](./compliance/soc2-controls.yaml)
[![FDA 21 CFR Part 11](https://img.shields.io/badge/FDA-21%20CFR%20Part%2011-blue)](./compliance/fda-21cfr11.yaml)

This directory contains the security scanning configurations, compliance checklists, and security policies for the MedinovAI Healthcare Laboratory Information System (LIS).

## Overview

As a healthcare application handling Protected Health Information (PHI), MedinovAI LIS is subject to multiple regulatory requirements:

- **HIPAA** - Health Insurance Portability and Accountability Act
- **SOC 2** - Service Organization Control 2 Type II
- **FDA 21 CFR Part 11** - Electronic Records and Electronic Signatures

## Directory Structure

```
security/
├── scanning/                    # Security scanning configurations
│   ├── semgrep-rules.yaml      # SAST rules for healthcare
│   ├── trivy-config.yaml       # Container vulnerability scanning
│   ├── snyk-policy.yaml        # Dependency scanning policy
│   └── gitleaks-config.yaml    # Secret detection rules
│
├── compliance/                  # Compliance frameworks
│   ├── hipaa-checklist.yaml    # HIPAA Security Rule controls
│   ├── soc2-controls.yaml      # SOC 2 Trust Services Criteria
│   └── fda-21cfr11.yaml        # FDA electronic records requirements
│
├── policies/                    # Security policies
│   ├── container-security-policy.yaml
│   ├── network-security-policy.yaml
│   ├── secrets-management-policy.yaml
│   └── phi-access-policy.yaml
│
├── .github/workflows/           # Security automation
│   ├── security-gate.yml       # Pre-deployment security checks
│   ├── compliance-audit.yml    # Automated compliance audits
│   └── vulnerability-scan.yml  # Continuous vulnerability scanning
│
├── reports/                     # Report templates
│   ├── security-dashboard-template.json
│   └── compliance-report-template.md
│
└── README.md                    # This file
```

## Quick Start

### Running Security Scans Locally

```bash
# Run Semgrep SAST scan
semgrep --config ./scanning/semgrep-rules.yaml .

# Run Trivy container scan
trivy image --config ./scanning/trivy-config.yaml medinovai-lis:latest

# Run Gitleaks secret scan
gitleaks detect --config ./scanning/gitleaks-config.yaml --source .

# Run Snyk dependency scan
snyk test --policy-path=./scanning/snyk-policy.yaml
```

### Checking Compliance Status

```bash
# View HIPAA checklist
cat ./compliance/hipaa-checklist.yaml

# View SOC 2 controls
cat ./compliance/soc2-controls.yaml

# View FDA 21 CFR Part 11 requirements
cat ./compliance/fda-21cfr11.yaml
```

## Security Scanning

### SAST Scanning (Semgrep)

The Semgrep rules in `scanning/semgrep-rules.yaml` include healthcare-specific checks:

- **PHI Exposure Prevention** - Detects logging of sensitive patient data
- **Authentication/Authorization** - Ensures endpoints are protected
- **SQL Injection** - Prevents database attacks
- **Cryptography** - Enforces strong encryption
- **Audit Logging** - Verifies PHI access is logged
- **FDA Electronic Signatures** - Validates signature requirements

### Container Scanning (Trivy)

The Trivy configuration includes:

- OS vulnerability scanning
- Library vulnerability scanning
- Configuration scanning
- Healthcare-specific policies (HIPAA, SOC 2)
- Secret scanning

### Dependency Scanning (Snyk)

The Snyk policy enforces:

- Severity thresholds for healthcare applications
- License compliance (GPL prohibited)
- Auto-remediation settings
- SLA requirements for vulnerability fixes

### Secret Detection (Gitleaks)

The Gitleaks configuration detects:

- PHI/PII patterns (SSN, MRN, insurance IDs)
- Database credentials
- API keys and tokens
- Cloud provider credentials
- Healthcare integration credentials (FHIR, Epic, Cerner)

## Compliance Frameworks

### HIPAA Security Rule

The `hipaa-checklist.yaml` covers:

- **Administrative Safeguards (§164.308)** - Security management, workforce security, security awareness
- **Physical Safeguards (§164.310)** - Facility access, workstation security, device controls
- **Technical Safeguards (§164.312)** - Access control, audit controls, integrity, transmission security

### SOC 2 Type II

The `soc2-controls.yaml` implements Trust Services Criteria:

- **CC1** - Control Environment
- **CC2** - Communication and Information
- **CC3** - Risk Assessment
- **CC4** - Monitoring Activities
- **CC5** - Control Activities
- **CC6** - Logical and Physical Access Controls
- **CC7** - System Operations
- **CC8** - Change Management
- **CC9** - Risk Mitigation

### FDA 21 CFR Part 11

The `fda-21cfr11.yaml` covers:

- **§11.10** - Electronic Records (validation, audit trails, access control)
- **§11.50** - Signature Manifestation
- **§11.100** - General Signature Requirements
- **§11.200** - Electronic Signature Components
- **§11.300** - Controls for Identification Codes/Passwords

## Security Policies

### Container Security Policy

Requirements for containerized workloads:

- Approved base images only
- Non-root user required
- Health checks mandatory
- Resource limits required
- No secrets in images

### Network Security Policy

Network segmentation and controls:

- Zone-based architecture (DMZ, API, Application, PHI, Database)
- Default deny network policies
- TLS 1.2+ required
- WAF and DDoS protection
- VPN for administrative access

### Secrets Management Policy

Secure handling of credentials:

- AWS Secrets Manager for storage
- Automatic rotation schedules
- HSM for critical keys
- No hardcoded secrets
- Audit all secret access

### PHI Access Policy

Protected Health Information controls:

- Role-based access control
- Minimum necessary standard
- Complete audit trails
- Break-glass procedures
- 18 HIPAA identifiers protected

## CI/CD Integration

### Security Gate Workflow

The security gate runs on every PR and push to main:

1. **Secret Scanning** - Gitleaks and TruffleHog
2. **SAST Scanning** - Semgrep and CodeQL
3. **Dependency Scanning** - Snyk and OWASP Dependency Check
4. **Container Scanning** - Trivy and Grype
5. **IaC Scanning** - Checkov and Trivy
6. **License Compliance** - FOSSA

### Compliance Audit Workflow

Automated compliance checks run daily:

- HIPAA Security Rule verification
- SOC 2 controls assessment
- FDA 21 CFR Part 11 checks
- Consolidated compliance report generation

### Vulnerability Scan Workflow

Continuous scanning every 6 hours:

- Dependency vulnerabilities
- Container vulnerabilities
- Infrastructure vulnerabilities
- Automated issue creation for critical findings

## Remediation SLAs

| Severity | Remediation Timeline | Escalation |
|----------|---------------------|------------|
| Critical | 24 hours | Immediate |
| High | 7 days | 24 hours |
| Medium | 30 days | 7 days |
| Low | 90 days | 30 days |

## Evidence Collection

Compliance evidence is automatically collected and stored:

- **Retention**: 7 years (HIPAA requirement)
- **Storage**: Encrypted S3 bucket
- **Artifacts**: Scan reports, access logs, configuration snapshots

## Contacts

| Role | Contact |
|------|---------|
| Security Team | security@medinovai.com |
| Privacy Officer | privacy@medinovai.com |
| Compliance Team | compliance@medinovai.com |
| On-Call Security | PagerDuty: security-oncall |

## Additional Resources

- [HIPAA Security Rule](https://www.hhs.gov/hipaa/for-professionals/security/index.html)
- [SOC 2 Trust Services Criteria](https://www.aicpa.org/resources/landing/trust-services-criteria)
- [FDA 21 CFR Part 11](https://www.ecfr.gov/current/title-21/chapter-I/subchapter-A/part-11)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks)

---

*This security infrastructure is maintained by the MedinovAI Security Team.*
*Last Updated: 2026-01-27*
