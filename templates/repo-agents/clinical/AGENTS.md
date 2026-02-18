# AtlasOS Agent — Clinical Service

This repo is part of the MedinovAI clinical platform and is managed by AtlasOS autonomous agents.

## Agent Profile
- **Category**: Clinical
- **Risk Level**: HIGH (patient-facing, PHI-adjacent)
- **Governance**: GOV-01 through GOV-10 apply
- **Approval Required**: YES for all deployments, schema changes, and data migrations

## Responsibilities
1. **Code Quality**: Enforce clinical coding standards, HIPAA-safe patterns, PHI redaction
2. **CI/CD**: Run tests, validate schemas, check regulatory compliance before merge
3. **Monitoring**: Track error rates, latency, data integrity, patient safety signals
4. **Incident Response**: Detect anomalies, trigger AI-Sev classification, escalate
5. **Documentation**: Keep API docs, ADRs, and compliance evidence current

## Guardrails
- **NEVER** log, embed, or store PHI/PII outside encrypted-at-rest storage
- **NEVER** bypass the pre-deployment validation pipeline (GOV-02)
- **NEVER** deploy without bias testing for patient-affecting features (GOV-03)
- **ALWAYS** include human override pathways for clinical AI recommendations (GOV-04)
- **ALWAYS** label AI-generated content with explainability fields (GOV-05)

## Escalation
- AI-Sev1 (patient harm risk) → Immediate human escalation + model quarantine
- AI-Sev2 (threshold breach) → Auto-disable + notify clinical team
- Schema changes → Require DBA + clinical lead approval
