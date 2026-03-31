# AI Explainability Standards

**Governance Control**: GOV-05
**Version**: 1.0.0
**Effective Date**: 2026-02-14
**Owner**: AI Governance Board
**Review Cycle**: Quarterly
**Framework Reference**: `docs/AI_GOVERNANCE_FRAMEWORK.md`

---

## Purpose

Models must translate predictions into clinically actionable reasoning in plain language. Every AI-generated output that affects clinical decisions, patient care, or healthcare administration must be interpretable by the clinicians and users who rely on it.

These standards define what explainability means at each risk level, what fields are required in AI outputs, and how compliance is enforced.

---

## Core Principles

1. **Proportional depth.** Explainability requirements scale with risk. Low-risk models need minimal explanation; critical-risk models need comprehensive transparency.
2. **Plain language.** All explanations must use clinically appropriate, non-technical language. If a general internist cannot understand the explanation, it fails the standard.
3. **Source attribution.** AI-generated content must cite the data sources and evidence that informed the output.
4. **AI content labeling.** All AI-generated content must be clearly and prominently labeled as AI-generated. No exceptions.
5. **Actionability.** Explanations must help the clinician make a better decision, not just satisfy a checkbox. "The model predicted X because of Y" is good. "The model used a neural network" is not.

---

## Explainability Tiers

Explainability tier is determined by the model's `risk_class` in the Model Risk Register (GOV-01). The tier must match or exceed the risk class.

### Tier 1: Low Risk

**Applies to**: Models classified as `low` risk (administrative, operational, non-clinical).

**Required output fields**:

| Field | Type | Description |
|-------|------|-------------|
| `confidence_score` | float (0.0-1.0) | Model's confidence in the output |
| `ai_generated` | boolean | Must be `true` -- labels output as AI-generated |

**Example**:
```json
{
  "prediction": "Schedule conflict detected",
  "confidence_score": 0.92,
  "ai_generated": true
}
```

### Tier 2: Medium Risk

**Applies to**: Models classified as `medium` risk (workflow-affecting, non-clinical decisions).

**Required output fields**:

| Field | Type | Description |
|-------|------|-------------|
| `confidence_score` | float (0.0-1.0) | Model's confidence in the output |
| `contributing_factors` | array (top 3) | The top 3 factors that most influenced the prediction |
| `ai_generated` | boolean | Must be `true` |

**Example**:
```json
{
  "prediction": "High likelihood of appointment no-show",
  "confidence_score": 0.78,
  "contributing_factors": [
    "Patient has missed 3 of last 5 appointments",
    "Appointment is on a Monday (historically higher no-show rate)",
    "No appointment reminder confirmation received"
  ],
  "ai_generated": true
}
```

### Tier 3: High Risk

**Applies to**: Models classified as `high` risk (informs clinical decisions, advisory role).

**Required output fields**:

| Field | Type | Description |
|-------|------|-------------|
| `confidence_score` | float (0.0-1.0) | Model's confidence in the output |
| `contributing_factors` | array (all significant) | All factors that significantly influenced the prediction, ranked by importance |
| `reasoning_chain` | string | Plain-language explanation of how the model arrived at the prediction |
| `data_sources` | array | Specific data sources used for this prediction |
| `ai_generated` | boolean | Must be `true` |

**Example**:
```json
{
  "prediction": "Elevated risk of sepsis (risk score: 0.73)",
  "confidence_score": 0.73,
  "contributing_factors": [
    "White blood cell count elevated (15,200/uL, normal <11,000)",
    "Temperature 38.9C (sustained >38.5C for 6 hours)",
    "Heart rate 112 bpm (elevated above baseline of 78)",
    "Recent urinary catheter placement (infection vector)"
  ],
  "reasoning_chain": "The patient's vital signs and lab values match patterns associated with early sepsis. Elevated WBC combined with sustained fever and tachycardia in the presence of an indwelling catheter suggests an infectious process. The sepsis risk score of 0.73 exceeds the alert threshold of 0.60.",
  "data_sources": [
    "Lab results: CBC from 2026-02-14 06:00",
    "Vital signs: Nursing flowsheet entries 00:00-06:00",
    "Clinical notes: Catheter placement note from 2026-02-12"
  ],
  "ai_generated": true
}
```

### Tier 4: Critical Risk

**Applies to**: Models classified as `critical` risk (directly drives treatment, diagnosis, or triage decisions).

**Required output fields**:

| Field | Type | Description |
|-------|------|-------------|
| `confidence_score` | float (0.0-1.0) | Model's confidence in the output |
| `contributing_factors` | array (all significant) | All factors that significantly influenced the prediction |
| `reasoning_chain` | string | Plain-language step-by-step reasoning |
| `data_sources` | array | Specific data sources used |
| `uncertainty_quantification` | object | What the model is uncertain about and why |
| `alternative_recommendations` | array | Other plausible interpretations or recommendations the model considered |
| `limitations` | array | Known limitations relevant to this prediction |
| `ai_generated` | boolean | Must be `true` |

**Example**:
```json
{
  "prediction": "Recommend initiating empiric antibiotic therapy for suspected pneumonia",
  "confidence_score": 0.81,
  "contributing_factors": [
    "Chest X-ray: Right lower lobe infiltrate identified by imaging AI",
    "Productive cough for 4 days with purulent sputum",
    "Temperature 39.2C",
    "CRP elevated at 145 mg/L",
    "Patient age 72 (higher pneumonia risk)"
  ],
  "reasoning_chain": "Chest imaging shows a right lower lobe infiltrate consistent with community-acquired pneumonia. Combined with clinical presentation (productive cough, fever, elevated CRP) and patient age, this meets clinical criteria for CAP. Guidelines recommend empiric therapy initiation without waiting for culture results in patients meeting these criteria.",
  "data_sources": [
    "Imaging: CXR from 2026-02-14 (radiology report + AI analysis)",
    "Lab: CRP, CBC from 2026-02-14",
    "Clinical notes: HPI from admission note",
    "Guideline: ATS/IDSA CAP Guidelines 2024"
  ],
  "uncertainty_quantification": {
    "confidence_interval": [0.68, 0.91],
    "uncertain_factors": [
      "Sputum culture not yet available -- empiric coverage may need adjustment",
      "Prior antibiotic use in last 90 days unknown -- may affect resistance patterns"
    ]
  },
  "alternative_recommendations": [
    "If penicillin allergy: substitute azithromycin + fluoroquinolone per guidelines",
    "If immunocompromised: broaden coverage to include atypical organisms",
    "If no improvement in 48-72h: consider CT chest and bronchoscopy"
  ],
  "limitations": [
    "This model was trained primarily on adult populations; performance in pediatric patients has not been validated",
    "Imaging AI infiltrate detection has a false positive rate of approximately 8% for right lower lobe findings"
  ],
  "ai_generated": true
}
```

---

## Enforcement

### Development-Time

- The Cursor rule (`.cursor/rules/ai-governance-controls.mdc`) reminds developers to include explainability fields appropriate to the model's risk tier.
- Code reviews must verify that AI output schemas include the required fields for the model's explainability tier.

### Pre-Deployment

- The pre-deployment validation pipeline (`workflows/ai-model-validation.lobster.md`, Step 5) runs sample inputs through the model and verifies all required explainability fields are present.
- Models that fail the explainability check cannot proceed to deployment.

### Runtime

- The Guardian Agent (Enhancement 20) validates AI outputs before delivery to clinicians. Outputs missing required explainability fields are blocked.
- Heartbeat check #8 monitors for unlabeled AI content in production.

---

## Validation Checklist

For each AI output, verify:

- [ ] `ai_generated` field is present and `true`
- [ ] `confidence_score` is present and within [0.0, 1.0]
- [ ] Required fields for the model's explainability tier are all present
- [ ] `contributing_factors` are in plain language (no raw feature names or model internals)
- [ ] `reasoning_chain` (if required) explains the "why" in language a clinician can act on
- [ ] `data_sources` (if required) are specific enough to be verifiable
- [ ] `uncertainty_quantification` (if required) identifies specific areas of uncertainty
- [ ] `alternative_recommendations` (if required) are clinically valid alternatives

---

## Tier Assignment Matrix

| Risk Class | Explainability Tier | Required Fields Count | Clinical Review Required |
|-----------|--------------------|-----------------------|------------------------|
| low | Tier 1 | 2 | No |
| medium | Tier 2 | 3 | No |
| high | Tier 3 | 5 | Yes |
| critical | Tier 4 | 8 | Yes + Governance Board |

---

## Revision History

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2026-02-14 | AI Governance Board | Initial explainability standards |
