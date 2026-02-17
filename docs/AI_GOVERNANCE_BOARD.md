# AI Governance Board Charter

**Governance Control**: GOV-10
**Version**: 1.0.0
**Effective Date**: 2026-02-14
**Framework Reference**: `docs/AI_GOVERNANCE_FRAMEWORK.md`

---

## Purpose

The AI Governance Board provides cross-functional oversight of all AI systems deployed across the MedinovAI platform. It ensures that AI deployment and operation are reviewed by a diverse group including clinicians, ethicists, technologists, and legal experts -- not controlled unilaterally by any single function.

The Board is the highest authority on AI governance decisions within MedinovAI.

---

## Board Composition

The AI Governance Board must include the following roles. Each role represents a critical perspective that prevents blind spots in AI governance.

| Role | Responsibility | Required Expertise |
|------|---------------|--------------------|
| **Chief Medical Officer (Chair)** | Clinical safety perspective, patient impact assessment, clinical workflow understanding | Clinical medicine, patient safety, healthcare operations |
| **AI/ML Lead** | Technical assessment of model capabilities, limitations, and risks | Machine learning, AI systems, model evaluation |
| **Ethicist** | Ethical implications of AI decisions, bias assessment, equity considerations | Healthcare ethics, AI ethics, social impact |
| **Legal/Regulatory Counsel** | Regulatory compliance, liability assessment, contract review | FDA regulations, EU AI Act, HIPAA, healthcare law |
| **Patient Advocate** | Patient perspective, communication clarity, consent and transparency | Patient experience, health literacy, advocacy |
| **Data Privacy Officer** | Data protection, privacy compliance, PHI/PII safeguards | HIPAA, GDPR, data privacy, information security |

### Alternate Members

Each primary member must designate an alternate who can attend and vote in their absence. Alternates must have equivalent expertise and authority.

### Quorum

A quorum requires at least 4 of 6 members (or their alternates) present, which must include at minimum the Chair (or alternate) and one of either the Legal/Regulatory Counsel or Data Privacy Officer.

---

## Decision Authority

The AI Governance Board has authority over the following decisions:

### Mandatory Board Approval Required

1. **New Clinical AI Deployments**: Approval to deploy any new AI model with `clinical_use: true` to production (final gate in GOV-02 pipeline for critical-risk models).
2. **Bias Remediation Plans**: Approval of remediation plans when bias testing (GOV-03) reveals demographic disparities.
3. **Model Re-Enablement after AI-Sev1**: Approval to re-enable any model quarantined due to an AI-Sev1 incident (GOV-09).
4. **Vendor AI Contracts**: Review and approval of vendor accountability terms (GOV-08) for new AI vendor relationships.
5. **Risk Class Upgrades**: Approval when a model's risk classification is changed to `high` or `critical`.
6. **Governance Framework Changes**: Approval of any changes to the AI Governance Framework itself.
7. **Exemption Requests**: Any request to deviate from governance controls must be approved by the Board with documented risk acceptance.

### Board-Informed (Notification, No Approval Required)

1. AI-Sev2 and AI-Sev3 incidents (notification within 24 hours).
2. Quarterly bias audit results (presented at next regular meeting).
3. Model Risk Register quarterly review results.
4. Performance monitoring drift alerts.
5. Vendor compliance review results.

---

## Review Cadence

### Regular Meetings

- **Frequency**: Monthly
- **Duration**: 90 minutes
- **Format**: Hybrid (in-person + video conference)

### Standard Agenda

1. **Previous Action Items Review** (10 min) -- Status of outstanding action items.
2. **Model Risk Register Review** (15 min) -- New registrations, overdue reviews, completeness audit.
3. **Incident Review** (15 min) -- AI incidents since last meeting, post-incident reports.
4. **Bias Audit Results** (15 min) -- Quarterly or pre-deployment bias audit findings.
5. **Performance Monitoring Dashboard** (10 min) -- Drift alerts, alert fatigue metrics, clinical outcomes.
6. **New Deployment Approvals** (15 min) -- New clinical AI models requesting production approval.
7. **Policy and Standards Updates** (5 min) -- Changes to governance controls, regulatory updates.
8. **Open Floor** (5 min) -- Escalated concerns, emerging issues.

### Emergency Meetings

- **Trigger**: AI-Sev1 incident (patient harm confirmed or suspected).
- **Convocation**: Within 24 hours of incident identification.
- **Required Attendees**: Chair, AI/ML Lead, Legal/Regulatory Counsel (minimum).
- **Agenda**: Incident briefing, containment verification, regulatory notification review, immediate next steps.

---

## Escalation Path

Any team member across MedinovAI may escalate an AI concern to the Governance Board.

### Escalation Channels

1. **Slack**: Post to #ai-governance with tag `@ai-governance-board`.
2. **Email**: ai-governance-board@medinovai.com.
3. **Incident System**: Flag any incident as "governance-escalation" to route to the Board.
4. **Direct Contact**: Contact any Board member directly.

### Escalation Categories

| Category | Response Time | Example |
|----------|--------------|---------|
| **Emergency** (patient safety) | 2 hours | Suspected patient harm from AI recommendation |
| **Urgent** (compliance risk) | 24 hours | Regulatory audit finding, undisclosed vendor model change |
| **Standard** (improvement) | Next regular meeting | Suggestion to update bias testing protocol, new vendor evaluation |

### Whistleblower Protection

Any person escalating an AI concern in good faith is protected from retaliation. Concerns about AI safety, bias, or ethics are always valid escalation reasons and must be investigated.

---

## Meeting Artifacts

All Board artifacts are stored in the tamper-proof audit trail (Enhancement 18) and are available for regulatory inspection.

### Required Artifacts Per Meeting

| Artifact | Format | Storage Location | Retention |
|----------|--------|-----------------|-----------|
| Agenda | Markdown | `outputs/governance-board/<date>/agenda.md` | 7 years |
| Minutes | Markdown | `outputs/governance-board/<date>/minutes.md` | 7 years |
| Decisions | JSON | `outputs/governance-board/<date>/decisions.json` | 7 years |
| Action Items | JSON | `outputs/governance-board/<date>/action_items.json` | 7 years |
| Attendance | JSON | `outputs/governance-board/<date>/attendance.json` | 7 years |
| Presentations | PDF/Markdown | `outputs/governance-board/<date>/presentations/` | 7 years |

### Decision Record Format

```json
{
  "decision_id": "GOV-DEC-20260214-001",
  "meeting_date": "2026-02-14",
  "subject": "Approval of MDL-CDS002 for production deployment",
  "decision": "approved|rejected|deferred|conditionally_approved",
  "conditions": ["Must pass bias re-audit with expanded dataset", "..."],
  "rationale": "Model meets all GOV-02 validation requirements. Bias audit passed with no disparities above threshold.",
  "governance_controls_referenced": ["GOV-01", "GOV-02", "GOV-03"],
  "votes": {
    "for": 5,
    "against": 0,
    "abstain": 1
  },
  "action_items": [
    {"assignee": "AI/ML Lead", "action": "Schedule production deployment for 2026-02-21", "due_date": "2026-02-18"}
  ],
  "recorded_by": "Board Secretary"
}
```

---

## Annual Governance Effectiveness Review

Once per year, the Board conducts a self-assessment:

1. **Control Effectiveness**: Are all 10 governance controls achieving their intended outcomes?
2. **Incident Analysis**: Trends in AI incidents -- are they decreasing in frequency and severity?
3. **Bias Trends**: Are bias audit results improving over time?
4. **Override Analysis**: What do clinician override patterns tell us about model quality?
5. **Regulatory Compliance**: Are we meeting all regulatory obligations?
6. **Board Effectiveness**: Is the Board composition adequate? Are meetings productive? Are decisions timely?
7. **Framework Updates**: Does the AI Governance Framework need revision?

Results are documented in `outputs/governance-board/annual-review-<year>.md` and shared with MedinovAI executive leadership.

---

## Revision History

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2026-02-14 | AI Governance Board | Initial board charter |
