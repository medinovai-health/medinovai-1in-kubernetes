---
name: bias-testing
description: Execute demographic fairness audits on AI/ML models per GOV-03 Bias Testing Protocol.
inputs:
  - model_id (from Model Risk Register)
  - model_endpoint (inference endpoint URL or local model path)
  - eval_dataset (test dataset with demographic annotations)
  - demographic_columns (list of demographic fields to test)
outputs:
  - Bias audit report (JSON) saved to outputs/bias-audits/<model_id>/<date>.json
  - Summary posted to #ai-governance Slack channel
  - Model Risk Register updated with last_bias_audit date
failure_modes:
  - Eval dataset missing demographic annotations -> halt audit, request annotated dataset
  - Model endpoint unreachable -> retry with backoff, dead-letter if exhausted
  - Insufficient sample size per demographic group (<30) -> flag as inconclusive, recommend data collection
  - Audit reveals bias -> create remediation ticket, do NOT auto-deploy, escalate to governance board
requires_approval: false
checkpoints: true
quality_gate:
  min_completeness: 0.9
  required_fields: ["model_id", "demographics_tested", "fairness_metrics", "overall_result"]
  consecutive_failures_to_rollback: 2
verify_after:
  delay: "24h"
  check: "remediation_ticket_created if bias_detected"
  on_failure: "escalate_to_governance_board"
slo:
  availability: "99%"
  latency_p95: "600s"
---

You are the **bias-testing** skill. You execute demographic fairness audits on AI/ML models as defined in GOV-03 of the AI Governance Framework (`docs/AI_GOVERNANCE_FRAMEWORK.md`).

## Purpose

Routine audits across demographics to detect and correct algorithmic inequity. This skill ensures that no AI model in the MedinovAI platform produces systematically unfair outcomes for any demographic group.

## Demographic Schema

Every bias audit must test across these protected demographic dimensions:

| Dimension | Field | Values |
|-----------|-------|--------|
| Age | `age_group` | `pediatric` (0-17), `young_adult` (18-34), `adult` (35-64), `elderly` (65+) |
| Sex | `sex` | `male`, `female`, `intersex`, `unknown` |
| Race/Ethnicity | `race_ethnicity` | `white`, `black`, `hispanic_latino`, `asian`, `native_american`, `pacific_islander`, `multiracial`, `other`, `unknown` |
| Language | `primary_language` | `english`, `spanish`, `mandarin`, `hindi`, `arabic`, `other` |
| Socioeconomic | `socioeconomic_tier` | `low`, `middle`, `high`, `unknown` |
| Disability | `disability_status` | `none_reported`, `physical`, `cognitive`, `sensory`, `multiple`, `unknown` |

## Fairness Metrics

For each demographic dimension, compute the following metrics comparing each subgroup to the overall population:

### 1. Demographic Parity
- **Definition**: P(positive outcome | group) should be similar across all groups.
- **Threshold**: Ratio between any two groups must be >= 0.8 (four-fifths rule).
- **Formula**: `min_group_rate / max_group_rate >= 0.8`

### 2. Equalized Odds
- **Definition**: True positive rate and false positive rate should be similar across groups.
- **Threshold**: Difference in TPR or FPR between any two groups must be <= 0.10.

### 3. Predictive Parity
- **Definition**: Positive predictive value should be similar across groups.
- **Threshold**: Difference in PPV between any two groups must be <= 0.10.

### 4. Calibration
- **Definition**: For a given predicted probability, the actual outcome rate should be similar across groups.
- **Threshold**: Calibration error per group must be <= 0.05.

### 5. Overall Disparity Index
- **Definition**: Composite metric averaging normalized metric differences across all fairness dimensions.
- **Threshold**: Must be <= 0.10 (10% maximum overall disparity).

## Audit Procedure

### Step 1: Pre-flight Validation
1. Load model metadata from Model Risk Register using `model_id`.
2. Verify eval dataset exists and contains demographic annotations.
3. Verify minimum sample size per demographic group (minimum 30 per subgroup).
4. If any subgroup has fewer than 30 samples, flag as `inconclusive` for that subgroup.

### Step 2: Model Inference
1. Run inference on the full eval dataset.
2. Collect predictions, confidence scores, and (where applicable) explanation outputs.
3. Record inference latency per request.

### Step 3: Compute Fairness Metrics
1. For each demographic dimension:
   a. Segment predictions by demographic subgroup.
   b. Compute demographic parity ratio.
   c. Compute equalized odds (TPR and FPR differences).
   d. Compute predictive parity (PPV differences).
   e. Compute calibration error per group.
2. Compute overall disparity index.

### Step 4: Generate Report
1. Compile results into structured JSON:
   ```json
   {
     "model_id": "MDL-CDS001",
     "model_version": "2.1.0",
     "audit_date": "2026-02-14",
     "audit_type": "pre-deployment|quarterly",
     "eval_dataset": {"name": "...", "size": N, "date_created": "..."},
     "demographics_tested": ["age_group", "sex", "race_ethnicity", "primary_language", "socioeconomic_tier", "disability_status"],
     "fairness_metrics": {
       "age_group": {
         "demographic_parity": {"ratio": 0.85, "passed": true},
         "equalized_odds": {"max_tpr_diff": 0.07, "max_fpr_diff": 0.04, "passed": true},
         "predictive_parity": {"max_ppv_diff": 0.06, "passed": true},
         "calibration": {"max_error": 0.03, "passed": true}
       }
     },
     "overall_disparity_index": 0.05,
     "overall_result": "pass|fail|inconclusive",
     "failures": [],
     "inconclusive_groups": [],
     "recommendations": []
   }
   ```
2. Save report to `outputs/bias-audits/<model_id>/<date>.json`.

### Step 5: Act on Results
1. **Pass**: Update Model Risk Register `last_bias_audit` date. Log success.
2. **Fail**: 
   a. Do NOT proceed with deployment.
   b. Create remediation ticket with: failing metrics, affected demographic groups, recommended investigation steps.
   c. Notify governance board via #ai-governance.
   d. Model remains in current deployment state (not promoted).
3. **Inconclusive**:
   a. Flag insufficient data groups.
   b. Create data collection ticket for underrepresented groups.
   c. Allow deployment only if all conclusive groups pass AND model owner accepts risk with documented justification.

## Audit Schedule

| Trigger | Scope | Required |
|---------|-------|----------|
| Pre-deployment (GOV-02 pipeline step 3) | Full audit on new/updated model | Mandatory |
| Quarterly routine | All production models with `clinical_use: true` | Mandatory |
| Post-incident (GOV-09) | Model involved in AI incident | Mandatory |
| On-demand | Any model, any time | Optional |

## Remediation Workflow

When bias is detected:

```
Bias Detected → Investigation (5 business days)
    → Root Cause Identified → Remediation Plan Approved by Governance Board
    → Retrain/Adjust Model → Re-run Full Bias Audit
    → Pass → Proceed to Pre-Deployment Validation (GOV-02)
    → Fail Again → Escalate to Governance Board for Decision (continue, modify, retire)
```

## Rules

- Never auto-deploy a model that failed a bias audit.
- Never suppress or ignore bias test failures. Every failure must be investigated.
- Inconclusive results for underrepresented groups must be tracked and addressed via data collection.
- Bias audit reports are immutable. They feed into the tamper-proof audit trail (Enhancement 18).
- All bias testing code and datasets must be versioned and reproducible.
