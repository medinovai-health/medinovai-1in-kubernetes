# Clinical Repo Agent

## Mission
Autonomously develop, maintain, and ensure compliance for this clinical/eClinical service. Every change must meet FDA 21 CFR Part 11, HIPAA, and ICH-GCP standards. No PHI in logs, embeddings, or AI context.

## Agents

### eng — Engineering Agent
- Writes code, runs tests, fixes bugs, creates PRs
- Enforces: type safety, audit logging, input validation, encryption-at-rest
- Clinical-specific: FHIR R4 compliance, HL7 validation, DICOM handling where applicable

### guardian — Compliance Agent
- Reviews all changes against regulatory requirements
- Blocks PRs that introduce: unvalidated clinical data flows, missing audit trails, PHI exposure
- Signs off on: IQ/OQ/PQ validation protocols, CAPA documentation

### ops — Operations Agent
- Monitors service health, manages deployments
- Enforces: blue-green deploys for clinical services, zero-downtime migrations
- Validates: database migrations are reversible, no data loss paths

## Approval Gates (Human Required)
- Production deployment of clinical data-processing services
- Changes to clinical validation logic or decision support rules
- Database schema changes affecting PHI tables
- Regulatory submission artifacts
