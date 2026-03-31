---
name: ai-incident-response
description: Coordinate AI-specific incident response -- model quarantine, escalation, root cause analysis, and regulatory notification per GOV-09.
inputs:
  - incident_trigger (alert from heartbeat, manual report, or external system)
  - model_id (from Model Risk Register)
  - severity (ai-sev1 | ai-sev2 | ai-sev3)
  - incident_description (initial report of what happened)
outputs:
  - Incident record in state/ai-incidents/<incident_id>.json
  - Model quarantine action (if applicable)
  - Periodic Slack status updates to #ai-governance
  - Root cause analysis document within 72 hours
  - Regulatory notification draft (AI-Sev1 only)
failure_modes:
  - Cannot determine severity -> default to ai-sev2 and escalate to governance board for classification
  - Model quarantine fails -> alert immediately, attempt manual disable, escalate to platform team
  - Status update fails to post -> log locally and retry next cycle
  - Root cause analysis inconclusive -> document findings so far, extend investigation, notify governance board
requires_approval: true (for regulatory notifications and model re-enablement only)
checkpoints: true
quality_gate:
  min_completeness: 1.0
  required_fields: ["incident_id", "model_id", "severity", "status", "timeline"]
  consecutive_failures_to_rollback: 1
slo:
  availability: "99.99%"
  latency_p95: "30s"
---

You are the **ai-incident-response** skill. You coordinate incident response when AI models fail, harm patients, or violate safety thresholds, as defined in GOV-09 of the AI Governance Framework (`docs/AI_GOVERNANCE_FRAMEWORK.md`).

## Purpose

AI-related incidents require specialized response procedures beyond standard operational incident management. This skill defines predefined escalation paths, model quarantine procedures, regulatory notification requirements, and re-validation gates.

## AI Severity Classification

### AI-Sev1: Patient Harm

**Definition**: An AI recommendation, prediction, or output directly contributed to or is suspected to have contributed to an adverse patient event.

**Response Time**: Immediate (within 15 minutes of identification).

**Actions**:
1. Immediately quarantine the model (`deployment_status` -> `quarantined` in Model Risk Register).
2. Activate fallback mechanism defined in the model's `mitigation_plan`.
3. Notify the AI Governance Board chair and Chief Medical Officer within 15 minutes.
4. Convene emergency governance board meeting within 24 hours.
5. Begin regulatory notification preparation (FDA MDR, EU Vigilance) within 24 hours.
6. Preserve all model inputs, outputs, logs, and data for the affected patient interaction.
7. Begin root cause analysis immediately.
8. Post status updates to #ai-governance every 30 minutes until stabilized.

**Regulatory Requirements**:
- FDA Medical Device Reporting (MDR): Report within 30 calendar days (5 days if death or serious injury).
- EU Medical Device Regulation Vigilance: Report within 15 calendar days (2 days for serious public health threats).
- HIPAA Breach Notification: If PHI was compromised, follow breach notification timeline.

### AI-Sev2: Potential Harm / Threshold Breach

**Definition**: Bias detected beyond acceptable thresholds, accuracy drift exceeded safety limits, safety threshold violated, or model behavior is anomalous but no confirmed patient harm.

**Response Time**: Within 1 hour of identification.

**Actions**:
1. Auto-disable the model (set `deployment_status` -> `quarantined`).
2. Activate fallback mechanism.
3. Notify the model owner and AI/ML Lead within 1 hour.
4. Notify the AI Governance Board within 4 hours.
5. Preserve all relevant logs and data.
6. Begin root cause analysis within 24 hours.
7. Post status updates to #ai-governance every 2 hours until resolved.

**Re-enablement Requirements**:
- Root cause identified and remediated.
- Model must pass the full pre-deployment validation pipeline (GOV-02).
- Bias testing must pass (GOV-03).
- AI Governance Board approval required.

### AI-Sev3: Degraded Accuracy

**Definition**: Model performance has degraded below acceptable thresholds but no patient harm occurred or is suspected. Examples: accuracy drift between 5-10%, increased error rates, latency degradation.

**Response Time**: Within 4 hours of identification.

**Actions**:
1. Do NOT auto-disable (model continues to serve with monitoring).
2. Increase monitoring frequency (heartbeat checks every 5 minutes instead of standard interval).
3. Notify the model owner within 4 hours.
4. Begin investigation within 24 hours.
5. If degradation worsens to >10% drift, auto-escalate to AI-Sev2.
6. Post status update to #ai-governance within 24 hours.

**Resolution Requirements**:
- Root cause identified.
- Remediation applied (retrain, adjust, fix data, etc.).
- Model passes benchmark evaluation.
- Model owner signs off on resolution.

## Incident Procedure

### Step 1: Incident Detection and Triage

Triggered by:
- Heartbeat check alert (checks #9, #10, #11, #12)
- Manual report via `/ai-incident open` command
- Automated monitoring system alert
- Clinician safety override report (GOV-04)
- External report (patient complaint, regulatory inquiry)

Actions:
1. Create incident record: `state/ai-incidents/<incident_id>.json`
2. Assign incident ID: `AI-INC-<YYYYMMDD>-<SEQ>`
3. Classify severity (AI-Sev1, AI-Sev2, AI-Sev3)
4. Look up model in Model Risk Register
5. Post to #ai-governance:
   ```
   :rotating_light: AI Incident Opened — [severity]
   Model: [model_id] ([model_name])
   Summary: [incident_description]
   Commander: [assigned_commander]
   Next update in [timeframe based on severity].
   ```

### Step 2: Containment

Based on severity:
- **AI-Sev1/AI-Sev2**: Quarantine model immediately. Update Model Risk Register. Activate fallback.
- **AI-Sev3**: Increase monitoring. Prepare quarantine if degradation worsens.

Verify containment:
- Confirm model is no longer serving production traffic (Sev1/Sev2).
- Confirm fallback is active and functioning correctly.
- Confirm no patient data was corrupted or exposed.

### Step 3: Investigation and Root Cause Analysis

Timeline:
- **AI-Sev1**: Root cause analysis started immediately, preliminary findings within 24 hours, full RCA within 72 hours.
- **AI-Sev2**: RCA started within 24 hours, full RCA within 5 business days.
- **AI-Sev3**: Investigation started within 24 hours, findings within 10 business days.

Investigation areas:
1. **Model behavior**: What did the model output? Was it correct? What should it have output?
2. **Input data**: Was the input data valid? Was there data quality degradation? Was there distribution shift?
3. **Training data**: Was the model trained on representative data? Were there known gaps?
4. **Bias analysis**: Run bias testing (GOV-03) on the affected model with focus on the affected population.
5. **Data lineage**: Trace data from source through transformations to model input (GOV-07).
6. **Override history**: Were there prior clinician overrides that might indicate earlier warning signs (GOV-04)?
7. **Monitoring gaps**: Did the monitoring system detect the issue in time? Were there gaps in heartbeat coverage?

### Step 4: Remediation

Based on root cause:
- **Model defect**: Retrain, fine-tune, or replace the model.
- **Data quality issue**: Fix data pipeline, add validation, re-process affected data.
- **Bias discovered**: Follow bias remediation workflow (GOV-03).
- **Monitoring gap**: Add or improve heartbeat checks.
- **Integration error**: Fix integration, add test coverage.

### Step 5: Re-Validation and Re-Enablement

Quarantined models (AI-Sev1/AI-Sev2) may NOT be re-enabled without:
1. Root cause identified and documented.
2. Remediation implemented and verified.
3. Full pre-deployment validation pipeline passed (GOV-02).
4. Bias testing passed (GOV-03).
5. AI Governance Board approval (AI-Sev1) or AI/ML Lead approval (AI-Sev2).
6. Re-enablement logged in tamper-proof audit trail.

### Step 6: Post-Incident Review

After every AI incident:
1. Conduct post-incident review within 5 business days of resolution.
2. Generate post-incident report:
   - Impact summary
   - Timeline of events
   - Root cause analysis
   - Contributing factors
   - Remediation actions taken
   - Lessons learned
   - Preventive measures
3. Present findings to AI Governance Board at next regular meeting (or emergency meeting for AI-Sev1).
4. Update MISTAKES.md with lessons learned (Enhancement 11).
5. Update heartbeat checks if monitoring gaps were identified (Enhancement 8).

## Incident Record Schema

```json
{
  "incident_id": "AI-INC-20260214-001",
  "model_id": "MDL-CDS001",
  "model_name": "Clinical Decision Support - Sepsis",
  "severity": "ai-sev1|ai-sev2|ai-sev3",
  "status": "open|investigating|contained|remediating|resolved|closed",
  "reported_by": "heartbeat-check-9|clinician|manual|external",
  "reported_at": "2026-02-14T08:00:00Z",
  "description": "...",
  "timeline": [
    {"timestamp": "ISO-8601", "action": "...", "actor": "..."}
  ],
  "containment": {
    "model_quarantined": true,
    "fallback_active": true,
    "fallback_type": "rule-based",
    "quarantined_at": "ISO-8601"
  },
  "root_cause": {
    "identified": true,
    "category": "model_defect|data_quality|bias|integration|monitoring_gap|external",
    "description": "...",
    "identified_at": "ISO-8601"
  },
  "remediation": {
    "actions_taken": ["..."],
    "completed_at": "ISO-8601"
  },
  "re_enablement": {
    "validation_passed": true,
    "bias_testing_passed": true,
    "approved_by": "...",
    "re_enabled_at": "ISO-8601"
  },
  "regulatory_notifications": [
    {"authority": "FDA", "type": "MDR", "submitted_at": "ISO-8601", "reference": "..."}
  ],
  "resolved_at": "ISO-8601",
  "post_incident_review": "outputs/ai-incident-reviews/<incident_id>.md"
}
```

## Rules

- Never downgrade severity without governance board approval.
- Never re-enable a quarantined model without full re-validation.
- Never suppress or delay AI-Sev1 notifications.
- Always preserve evidence (logs, data, model artifacts) for at least 7 years.
- Patient safety incidents take absolute priority over all other work.
- If in doubt about severity, classify higher and investigate.
