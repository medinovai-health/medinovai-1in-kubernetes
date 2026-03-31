# AI Governance Framework for MedinovAI Platform

**Version**: 1.0.0
**Effective Date**: 2026-02-14
**Owner**: AI Governance Board
**Review Cycle**: Quarterly
**Regulatory Basis**: FDA AI/ML Software as a Medical Device (SaMD), EU AI Act, HIPAA, 21 CFR Part 11, ICH-GCP E6(R2)

---

## Purpose

This document defines the 10 mandatory AI governance controls that apply to every AI-powered feature, model, and algorithm across the MedinovAI platform. These controls are non-negotiable for any system that generates predictions, recommendations, classifications, or decisions that affect patient care, clinical operations, or healthcare administration.

Every MedinovAI product, service, and internal tool that uses AI/ML must comply with these controls. Compliance is verified through the AI Governance Board (see `docs/AI_GOVERNANCE_BOARD.md`), automated enforcement (see `.cursor/rules/ai-governance-controls.mdc`), and the pre-deployment validation pipeline (see `workflows/ai-model-validation.lobster.md`).

---

## Control Summary

| ID | Control | Risk Level | Audit Frequency | Implementing Files |
|----|---------|-----------|-----------------|-------------------|
| GOV-01 | Model Risk Register | Critical | Continuous + Quarterly Review | `templates/ai-ml/config/model_risk_register_schema.json`, `templates/ai-ml/skills/model-registry/SKILL.md` |
| GOV-02 | Pre-Deployment Validation | Critical | Every Deployment | `workflows/ai-model-validation.lobster.md` |
| GOV-03 | Bias Testing Protocol | High | Every Deployment + Quarterly | `templates/ai-ml/skills/bias-testing/SKILL.md` |
| GOV-04 | Human Override Pathways | High | Quarterly Review | `templates/ai-ml/AGENTS.md`, `templates/clinical/AGENTS.md` |
| GOV-05 | Explainability Standards | High | Every Deployment | `templates/ai-ml/config/explainability_standards.md` |
| GOV-06 | Performance Monitoring | Critical | Continuous | `templates/ai-ml/HEARTBEAT.md` |
| GOV-07 | Data Lineage Tracking | High | Continuous + Quarterly | `templates/data/config/data_lineage_schema.json`, `templates/data/AGENTS.md` |
| GOV-08 | Vendor Accountability Terms | Medium | Annual + Contract Renewal | `templates/docs-standards/vendor-ai-accountability-terms.md` |
| GOV-09 | Incident Response Protocol | Critical | Every Incident + Annual Drill | `templates/ai-ml/skills/ai-incident-response/SKILL.md` |
| GOV-10 | Cross-Functional Oversight | High | Monthly | `docs/AI_GOVERNANCE_BOARD.md` |

---

## GOV-01: Model Risk Register

### Description

A living inventory of every deployed AI/ML model with impact classification and mitigation plans. No model may operate in production without being registered.

### Requirements

1. **Registration**: Every AI model must be registered before deployment. Registration includes: model ID, name, version, vendor, purpose, clinical use flag, risk class, impact classification, data types consumed, deployment status, mitigation plan, owner, last validation date, and next review date.
2. **Risk Classification**: Models are classified as `low`, `medium`, `high`, or `critical` based on their impact on patient safety, clinical decisions, and regulatory exposure.
3. **Completeness Check**: The heartbeat system must verify that no unregistered model is running in production.
4. **Review Cadence**: All registered models are reviewed quarterly. Critical-risk models are reviewed monthly.

### Regulatory Basis

- FDA Guidance on AI/ML-Based SaMD: Predetermined Change Control Plan
- EU AI Act Article 9: Risk Management System
- ISO 14971: Medical Device Risk Management

### Evidence Required

- Complete model risk register (JSON conforming to schema)
- Quarterly review meeting minutes
- Completeness audit results

### Implementing Files

- Schema: `templates/ai-ml/config/model_risk_register_schema.json`
- Maintenance Skill: `templates/ai-ml/skills/model-registry/SKILL.md`

---

## GOV-02: Pre-Deployment Validation

### Description

Mandatory clinical and technical testing before any AI algorithm touches patient care. No AI model, prompt, or pipeline change may reach production without passing the validation pipeline.

### Requirements

1. **Registry Check**: Model must be registered in the Model Risk Register.
2. **Benchmark Evaluation**: Model must meet or exceed baseline performance metrics.
3. **Bias Audit**: Model must pass demographic fairness tests (see GOV-03).
4. **Clinical Safety Review**: Clinical-use models require human clinical review and approval.
5. **Explainability Verification**: Outputs must include required explainability fields (see GOV-05).
6. **Shadow Deployment**: Model must run in shadow/staging before production.
7. **Performance Baseline**: Pre-deployment performance metrics must be captured for future drift detection.

### Regulatory Basis

- FDA 21 CFR Part 820: Design Controls
- IEC 62304: Software Lifecycle Processes
- GAMP 5 / Computer Software Assurance (CSA)

### Evidence Required

- Validation pipeline execution log (pass/fail per step)
- Benchmark evaluation results
- Bias audit report
- Clinical safety review approval record
- Shadow deployment metrics

### Implementing Files

- Pipeline: `workflows/ai-model-validation.lobster.md`

---

## GOV-03: Bias Testing Protocol

### Description

Routine audits across demographics to detect and correct algorithmic inequity. Every AI model that affects patient care or clinical decisions must be tested for bias before deployment and on a quarterly schedule.

### Requirements

1. **Demographic Coverage**: Tests must cover: age group, sex, race/ethnicity, language, socioeconomic status, and disability status.
2. **Fairness Metrics**: Measure equalized odds, demographic parity, predictive parity, and calibration across all demographic groups.
3. **Threshold Enforcement**: No demographic group may have a performance disparity greater than 10% relative to the overall population metric.
4. **Remediation Workflow**: When bias is detected: flag, investigate root cause, retrain or adjust, re-test, and obtain approval before re-deployment.
5. **Audit Schedule**: Before every deployment (mandatory) and quarterly (routine).

### Regulatory Basis

- EU AI Act Article 10: Data and Data Governance
- HHS Section 1557: Non-Discrimination in Health Programs
- FDA Guidance: Ensuring Equity in AI/ML-Based Medical Devices

### Evidence Required

- Bias audit report per model (demographics, metrics, pass/fail)
- Remediation records (if bias detected)
- Quarterly audit schedule and results

### Implementing Files

- Protocol Skill: `templates/ai-ml/skills/bias-testing/SKILL.md`
- Heartbeat Check: `templates/ai-ml/HEARTBEAT.md` (Check #8)

---

## GOV-04: Human Override Pathways

### Description

Clear processes for clinicians to reject AI recommendations without workflow penalties. Clinicians must always have the authority to override AI outputs, and exercising that authority must never result in punitive consequences.

### Requirements

1. **Override Action**: Every AI recommendation presented to a clinician must include an explicit override mechanism.
2. **No Penalty**: Override frequency must never be used as a punitive performance metric for clinicians.
3. **Audit Logging**: Every override must be logged: who overrode, when, what recommendation was overridden, and the clinician's stated reason.
4. **Feedback Loop**: Override data must be analyzed monthly to identify patterns that indicate model improvement opportunities.
5. **Workflow Integration**: Overrides must not add extra steps or friction compared to accepting the recommendation.

### Regulatory Basis

- FDA Guidance on Clinical Decision Support Software
- EU AI Act Article 14: Human Oversight
- AMA Principles for Augmented Intelligence in Health Care

### Evidence Required

- Override mechanism documentation per AI feature
- Override frequency reports (non-punitive)
- Monthly override pattern analysis
- Clinician feedback on override workflow

### Implementing Files

- AI/ML Rules: `templates/ai-ml/AGENTS.md` (Human Override Pathways section)
- Clinical Rules: `templates/clinical/AGENTS.md` (Clinical Override Pathways section)

---

## GOV-05: Explainability Standards

### Description

Models must translate predictions into clinically actionable reasoning in plain language. AI-generated outputs that affect clinical decisions must be interpretable by the clinicians who rely on them.

### Requirements

1. **Tiered Explainability**: Explainability depth is proportional to model risk class:
   - **Low risk**: Confidence score required.
   - **Medium risk**: Confidence score + top-3 contributing factors.
   - **High risk**: Full reasoning chain + contributing factors + data sources used.
   - **Critical risk**: Full reasoning chain + contributing factors + data sources + uncertainty quantification + alternative recommendations.
2. **Plain Language**: All explanations must use clinically appropriate, non-technical language that the target clinician can understand.
3. **Source Attribution**: AI-generated content must cite the data sources and evidence that informed the output.
4. **AI Content Labeling**: All AI-generated content must be clearly labeled as AI-generated.
5. **Guardian Enforcement**: Outputs missing required explainability fields are blocked by the Guardian agent before reaching clinicians.

### Regulatory Basis

- EU AI Act Article 13: Transparency
- FDA Guidance on Transparency for ML-Based Medical Devices
- NIST AI Risk Management Framework: Explainability and Interpretability

### Evidence Required

- Explainability standards document with tier definitions
- Sample outputs demonstrating compliance per tier
- Guardian validation logs (blocked outputs)

### Implementing Files

- Standards: `templates/ai-ml/config/explainability_standards.md`

---

## GOV-06: Performance Monitoring

### Description

Real-time dashboards tracking accuracy drift, alert fatigue, and clinical outcomes. Deployed models must be continuously monitored to detect degradation before it affects patient care.

### Requirements

1. **Accuracy Drift Detection**: Compare model performance against a rolling 30-day baseline. Alert on >5% degradation in any key metric.
2. **Alert Fatigue Monitoring**: Track the alert-to-action ratio. Flag when clinicians dismiss >40% of AI-generated alerts, indicating possible alert fatigue.
3. **Clinical Outcome Tracking**: Monitor downstream patient outcomes correlated with AI recommendations to measure real-world effectiveness.
4. **Dashboard Availability**: Performance dashboards must be accessible to all governance board members and model owners.
5. **Automated Response**: When drift exceeds critical thresholds, the model must be automatically disabled and fall back to rule-based or human decision-making.

### Regulatory Basis

- FDA Post-Market Surveillance Requirements for SaMD
- EU AI Act Article 72: Post-Market Monitoring
- ISO 13485: Quality Management for Medical Devices

### Evidence Required

- Drift detection alerts and resolution records
- Alert fatigue ratio reports
- Clinical outcome correlation reports
- Dashboard access logs

### Implementing Files

- Heartbeat Checks: `templates/ai-ml/HEARTBEAT.md` (Checks #9, #10, #11)

---

## GOV-07: Data Lineage Tracking

### Description

Complete audit trails showing where data came from and how it shaped model behavior. Every piece of data that feeds into an AI model must be traceable from source to prediction.

### Requirements

1. **Source Documentation**: Every data source must be documented with: source ID, source type, collection method, and consent basis.
2. **Transformation Chain**: Every transformation applied to data must be logged with: step name, tool used, timestamp, input hash, and output hash.
3. **Model-Data Linkage**: Every model must record which data sources and versions were used for training and inference.
4. **Immutability**: Lineage records must be immutable (append-only). Ties into the tamper-proof audit trail (Enhancement 18).
5. **Retention Compliance**: Data retention policies must be documented and enforced per data source.

### Regulatory Basis

- 21 CFR Part 11: Electronic Records
- HIPAA Security Rule: Integrity Controls
- EU AI Act Article 12: Record-Keeping
- ALCOA+ Principles

### Evidence Required

- Data lineage records conforming to schema
- Transformation chain audit logs
- Model-data linkage documentation
- Retention policy enforcement records

### Implementing Files

- Schema: `templates/data/config/data_lineage_schema.json`
- Agent Rules: `templates/data/AGENTS.md` (Data Lineage section)

---

## GOV-08: Vendor Accountability Terms

### Description

Contracts requiring transparency, retraining rights, and clear liability assignment for any third-party AI model, API, or service used in the MedinovAI platform.

### Requirements

1. **Transparency**: Vendors must disclose model architecture, training data description, known limitations, and performance benchmarks.
2. **Retraining Rights**: MedinovAI retains the right to request model retraining and to audit training data for bias and quality.
3. **Performance Guarantees**: Vendor SLAs must specify accuracy, latency, and uptime targets with defined remedies for breach.
4. **Liability Assignment**: Contracts must clearly assign liability for model failures, adverse patient outcomes, and regulatory violations.
5. **Incident Cooperation**: Vendors must participate in incident response within defined SLAs (see GOV-09).
6. **Data Rights**: MedinovAI retains data portability, deletion rights, and prohibition on secondary use of patient data.
7. **Exit Terms**: Contracts must include model portability and data export provisions on termination.

### Regulatory Basis

- EU AI Act Article 28: Obligations of Deployers
- HIPAA Business Associate Agreements
- FDA Guidance on Third-Party Software Components

### Evidence Required

- Executed vendor contracts with all required terms
- Annual vendor compliance review records
- Vendor incident response participation records

### Implementing Files

- Template: `templates/docs-standards/vendor-ai-accountability-terms.md`

---

## GOV-09: Incident Response Protocol

### Description

Predefined escalation paths when AI models fail, harm patients, or violate safety thresholds. AI-related incidents require specific response procedures beyond standard operational incident management.

### Requirements

1. **AI Severity Classification**:
   - **AI-Sev1** (Patient Harm): AI recommendation contributed to an adverse patient event. Immediate model quarantine, regulatory notification, clinical review.
   - **AI-Sev2** (Potential Harm / Threshold Breach): Bias detected, drift exceeded safety limits, or safety threshold violated. Auto-disable model, notify governance board, mandatory re-validation.
   - **AI-Sev3** (Degraded Accuracy): Model performance degraded but no patient harm. Investigate, remediate, monitor.
2. **Model Quarantine**: Ability to immediately disable any AI model and fall back to rule-based or human decisions.
3. **Regulatory Notification**: AI-Sev1 incidents must be reported to regulatory bodies within required timeframes (FDA MDR, EU Vigilance).
4. **Root Cause Analysis**: Every AI incident must produce a root cause analysis within 72 hours.
5. **Re-Validation Gate**: Quarantined models may not be re-enabled without passing the full pre-deployment validation pipeline (GOV-02).

### Regulatory Basis

- FDA 21 CFR Part 803: Medical Device Reporting
- EU Medical Device Regulation: Vigilance Reporting
- HIPAA Breach Notification Rule

### Evidence Required

- Incident response records per AI incident
- Model quarantine and re-enablement logs
- Regulatory notification records (AI-Sev1)
- Root cause analysis documents
- Re-validation pipeline results

### Implementing Files

- Protocol Skill: `templates/ai-ml/skills/ai-incident-response/SKILL.md`

---

## GOV-10: Cross-Functional Oversight

### Description

Governance boards with clinicians, ethicists, technologists, and legal experts reviewing AI decisions. No single function should unilaterally control AI deployment and operation in healthcare.

### Requirements

1. **Board Composition**: The AI Governance Board must include: Chief Medical Officer (clinical), AI/ML Lead (technical), Ethicist, Legal/Regulatory Counsel, Patient Advocate, and Data Privacy Officer.
2. **Review Cadence**: Monthly regular reviews. Emergency convocation for AI-Sev1 incidents (within 24 hours).
3. **Decision Authority**: The board approves/rejects new clinical AI deployments, approves bias remediation plans, reviews vendor accountability terms, and oversees the Model Risk Register.
4. **Meeting Artifacts**: Agenda, minutes, decisions, and action items are stored in the tamper-proof audit trail.
5. **Escalation Path**: Any team member may escalate an AI concern to the governance board.

### Regulatory Basis

- EU AI Act Article 26: Obligations of Deployers (governance structures)
- FDA Quality System Regulation: Management Responsibility
- Joint Commission Standards for Health IT Governance

### Evidence Required

- Board charter and membership roster
- Meeting minutes and decision records
- Escalation records
- Annual governance effectiveness review

### Implementing Files

- Board Charter: `docs/AI_GOVERNANCE_BOARD.md`

---

## Enforcement Mechanisms

### Development-Time

- **Cursor Rule** (`.cursor/rules/ai-governance-controls.mdc`): Enforces governance awareness during development. Reminds developers to check the Model Risk Register, requires explainability fields, flags clinical AI changes lacking bias testing.

### Deployment-Time

- **Pre-Deployment Validation Pipeline** (`workflows/ai-model-validation.lobster.md`): Approval-gated pipeline that blocks non-compliant models from reaching production.
- **Guardian Agent** (Enhancement 20): Pre-execution validator that checks all AI actions against governance policies.

### Runtime

- **Heartbeat Checks** (`templates/ai-ml/HEARTBEAT.md`): Continuous monitoring for drift, bias, registry completeness, alert fatigue, and clinical outcomes.
- **Tamper-Proof Audit Trail** (Enhancement 18): Hash-chained, append-only logs for all governance-relevant actions.

### Distribution

- **Deploy Script** (`scripts/deploy_agents.sh`): Distributes governance templates, schemas, and skills to all 100+ MedinovAI repositories.

---

## Compliance Matrix

| Regulatory Requirement | Governing Control(s) | Implementation Status |
|----------------------|----------------------|----------------------|
| FDA SaMD Risk Management | GOV-01, GOV-02, GOV-09 | Active |
| FDA Post-Market Surveillance | GOV-06, GOV-09 | Active |
| EU AI Act Risk Management (Art. 9) | GOV-01, GOV-02, GOV-03 | Active |
| EU AI Act Transparency (Art. 13) | GOV-05, GOV-08 | Active |
| EU AI Act Human Oversight (Art. 14) | GOV-04, GOV-10 | Active |
| EU AI Act Data Governance (Art. 10) | GOV-03, GOV-07 | Active |
| EU AI Act Record-Keeping (Art. 12) | GOV-07 | Active |
| EU AI Act Post-Market (Art. 72) | GOV-06 | Active |
| HIPAA Security Rule | GOV-07, GOV-09 | Active |
| 21 CFR Part 11 | GOV-07 | Active |
| 21 CFR Part 820 (Design Controls) | GOV-02 | Active |
| ICH-GCP E6(R2) | GOV-01, GOV-02, GOV-04 | Active |

---

## Revision History

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2026-02-14 | AI Governance Board | Initial framework establishing all 10 controls |

---

*This document is the single source of truth for AI governance at MedinovAI. It is distributed to all repositories via `scripts/deploy_agents.sh` and referenced by all agent templates, workflows, and cursor rules.*
