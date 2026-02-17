# Vendor AI Accountability Terms Template

**Governance Control**: GOV-08
**Version**: 1.0.0
**Effective Date**: 2026-02-14
**Owner**: AI Governance Board + Legal/Regulatory Counsel
**Review Cycle**: Annual + Contract Renewal
**Framework Reference**: `docs/AI_GOVERNANCE_FRAMEWORK.md`

---

## Purpose

This template defines the mandatory terms that must be included in any contract with a third-party vendor providing AI models, AI-powered APIs, AI services, or AI components used in the MedinovAI platform. These terms ensure transparency, accountability, and clear liability assignment.

All vendor AI contracts must incorporate these terms. Deviations require explicit approval from the AI Governance Board.

---

## Instructions

When negotiating a vendor AI contract:
1. Copy the relevant sections below into the contract or addendum.
2. Fill in vendor-specific details in the `[brackets]`.
3. Any section that cannot be agreed upon must be documented with the reason and escalated to the AI Governance Board for risk acceptance decision.
4. The executed contract reference must be recorded in the Model Risk Register (`vendor_contract_ref` field) for each model covered.

---

## Section 1: Transparency Requirements

### 1.1 Model Documentation

Vendor SHALL provide and maintain the following documentation for each AI model or algorithm:

a. **Model Architecture**: Description of the model type, architecture, and version (e.g., "transformer-based language model, version 3.2"). Vendor is not required to disclose proprietary implementation details but must disclose the general architecture class.

b. **Training Data Description**: Description of training data including: data sources (by category, not individual records), approximate dataset size, time period covered, geographic and demographic representation, and any known gaps or underrepresented populations.

c. **Known Limitations**: Documented list of known limitations, failure modes, edge cases, and scenarios where the model is NOT suitable for use.

d. **Performance Benchmarks**: Published benchmark results on standard evaluation datasets relevant to the model's intended use, including accuracy, precision, recall, F1, and any domain-specific metrics.

e. **Change Notification**: Vendor SHALL notify MedinovAI in writing at least [30] calendar days before any material change to the model, including: model version updates, training data changes, architecture changes, or performance characteristic changes.

### 1.2 Ongoing Transparency

a. Vendor SHALL provide quarterly performance reports including: accuracy metrics, availability metrics, latency metrics, and any known issues or degradation events.

b. Vendor SHALL disclose any known bias, fairness concerns, or adverse findings related to the model within [5] business days of discovery.

c. Vendor SHALL maintain a public or client-accessible model card (per Mitchell et al., 2019) for each model used by MedinovAI.

---

## Section 2: Retraining Rights

### 2.1 Retraining Requests

a. MedinovAI retains the right to request model retraining when:
   - Bias testing reveals demographic disparities exceeding thresholds (GOV-03)
   - Performance monitoring detects accuracy drift beyond acceptable limits (GOV-06)
   - Clinical incidents are linked to model behavior (GOV-09)
   - Regulatory requirements change

b. Vendor SHALL respond to retraining requests within [10] business days with a plan and timeline.

c. Vendor SHALL complete retraining within [60] calendar days of an approved retraining plan, unless a different timeline is mutually agreed upon.

### 2.2 Training Data Audit

a. MedinovAI retains the right to audit the training data (or representative samples thereof) for bias, data quality, and compliance concerns.

b. Vendor SHALL cooperate with bias audits conducted by MedinovAI or its designated auditor, providing necessary access within [10] business days of request.

c. Audit results are confidential but may be shared with regulatory authorities upon lawful request.

---

## Section 3: Performance Guarantees

### 3.1 Service Level Agreements

Vendor SHALL maintain the following minimum performance levels:

| Metric | Target | Measurement Period | Remedy |
|--------|--------|-------------------|--------|
| Model Accuracy | >= [X]% on agreed evaluation set | Monthly | Service credit of [Y]% per [Z]% below target |
| API Availability | >= [99.9]% uptime | Monthly | Service credit per SLA breach tier |
| API Latency (p95) | <= [X] ms | Monthly | Investigation and remediation plan within 5 days |
| Model Freshness | Retrained within [X] months | Quarterly | Retraining initiated within 10 business days |

### 3.2 Performance Monitoring

a. MedinovAI retains the right to independently monitor model performance using its own evaluation datasets and metrics (GOV-06).

b. Vendor SHALL provide API endpoints or mechanisms for MedinovAI to conduct ongoing performance evaluation.

c. In case of disagreement on performance metrics, an independent third-party evaluation SHALL be conducted at shared cost.

---

## Section 4: Liability Assignment

### 4.1 Model Failure Liability

a. **Vendor Liability**: Vendor is liable for model failures caused by: defects in model architecture, errors in training data curation, failure to disclose known limitations, failure to meet performance SLAs, and failure to notify MedinovAI of material model changes.

b. **MedinovAI Liability**: MedinovAI is liable for: using the model outside its documented intended use, failure to implement recommended safeguards, failure to act on vendor-disclosed limitations, and integration errors in MedinovAI's systems.

c. **Shared Liability**: For outcomes where both vendor model behavior and MedinovAI integration contribute to an adverse event, liability is apportioned based on root cause analysis conducted jointly.

### 4.2 Indemnification

a. Vendor SHALL indemnify MedinovAI against claims arising from: undisclosed model defects, undisclosed training data issues (bias, copyright, privacy violations), and breach of performance SLAs.

b. MedinovAI SHALL indemnify Vendor against claims arising from: use of the model outside documented intended use and MedinovAI integration errors.

### 4.3 Insurance

a. Vendor SHALL maintain professional liability insurance of at least $[X] million covering AI-related claims.

b. Vendor SHALL provide certificate of insurance upon request.

---

## Section 5: Incident Cooperation

### 5.1 Incident Response Obligations

a. In the event of an AI-related incident involving the vendor's model (per GOV-09), Vendor SHALL:
   - Acknowledge the incident within [4] hours of notification
   - Provide initial technical assessment within [24] hours
   - Participate in root cause analysis within [72] hours
   - Implement agreed-upon remediation within the timeline determined by incident severity

b. Vendor SHALL designate an incident response contact available during MedinovAI's business hours.

c. For AI-Sev1 incidents (patient harm), Vendor SHALL provide 24/7 emergency response within [2] hours.

### 5.2 Regulatory Cooperation

a. Vendor SHALL cooperate with regulatory inquiries related to the model, including providing documentation, participating in reviews, and supporting regulatory submissions.

b. Vendor SHALL not destroy or alter model artifacts (training data, model versions, logs) that may be relevant to regulatory inquiry for a minimum of [7] years.

---

## Section 6: Data Rights

### 6.1 Data Ownership and Use

a. All data provided by MedinovAI to the Vendor remains the property of MedinovAI (or its patients, as applicable).

b. Vendor SHALL NOT use MedinovAI's data for: training models for other customers, benchmarking, marketing, or any purpose beyond providing the contracted service to MedinovAI.

c. Vendor SHALL NOT share MedinovAI's data with any third party without explicit written consent.

### 6.2 Data Portability

a. Upon request, Vendor SHALL export all MedinovAI data in a standard, machine-readable format within [30] calendar days.

b. Export formats must be documented and non-proprietary.

### 6.3 Data Deletion

a. Upon contract termination or MedinovAI request, Vendor SHALL permanently delete all MedinovAI data within [30] calendar days.

b. Vendor SHALL provide written certification of data deletion.

c. Exception: Data required for regulatory compliance may be retained for the minimum legally required period, after which it must be deleted.

### 6.4 PHI/PII Protections

a. Vendor SHALL comply with HIPAA, GDPR, and all applicable privacy regulations.

b. A separate Business Associate Agreement (BAA) is required if the Vendor processes PHI.

c. Vendor SHALL implement encryption at rest and in transit for all MedinovAI data.

d. Vendor SHALL notify MedinovAI of any data breach involving MedinovAI data within [24] hours of discovery.

---

## Section 7: Exit Terms

### 7.1 Model Portability

a. If MedinovAI decides to transition away from the Vendor's model, Vendor SHALL provide a [90]-day transition period with continued service at contracted levels.

b. Vendor SHALL provide sufficient model documentation for MedinovAI to evaluate and implement alternative solutions.

c. If the model was custom-trained on MedinovAI data, MedinovAI retains the right to the trained model weights, or Vendor SHALL provide a functionally equivalent model that MedinovAI can operate independently.

### 7.2 Data Export on Termination

a. All data export rights (Section 6.2) apply during and after contract termination.

b. Vendor SHALL maintain data availability for export for [90] calendar days after contract termination.

### 7.3 Transition Assistance

a. Vendor SHALL provide reasonable transition assistance during the exit period, including: technical documentation, data migration support, and knowledge transfer sessions.

b. Transition assistance fees, if any, must be defined in the contract.

---

## Section 8: Governance and Compliance

### 8.1 Annual Review

a. MedinovAI and Vendor SHALL conduct an annual vendor compliance review covering all terms in this agreement.

b. Review results are reported to the AI Governance Board (GOV-10).

### 8.2 Right to Audit

a. MedinovAI retains the right to audit Vendor's compliance with these terms annually, with [30] days advance notice.

b. Vendor SHALL cooperate with audits and provide reasonable access to documentation and personnel.

### 8.3 Regulatory Changes

a. If regulatory requirements change (FDA, EU AI Act, HIPAA, etc.), both parties SHALL negotiate in good faith to update these terms within [60] calendar days.

b. Vendor SHALL proactively notify MedinovAI of regulatory changes that may affect the model or service.

---

## Revision History

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2026-02-14 | AI Governance Board | Initial vendor accountability terms template |
