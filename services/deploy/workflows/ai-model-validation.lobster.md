# AI Model Pre-Deployment Validation Pipeline

An approval-gated workflow for validating AI/ML models before production deployment. Implements governance control GOV-02 from `docs/AI_GOVERNANCE_FRAMEWORK.md`.

No AI model, prompt change, or pipeline modification may reach production without passing this pipeline.

## Pipeline Steps

```
[1] Registry Check → [2] Benchmark Evaluation → [3] Bias Audit → [4] CLINICAL SAFETY GATE
    → [5] Explainability Check → [6] Shadow Deployment → [7] Performance Baseline
    → [8] FINAL APPROVAL GATE → [9] Production Deployment → [10] Post-Deploy Health Check
```

## Step 1: Registry Check

- **Tool**: `exec` (sandbox)
- **Action**: Verify the model is registered in the Model Risk Register (GOV-01)
- **Checks**:
  - Model ID exists in `state/model_risk_register.json`
  - `deployment_status` is not `quarantined` or `retired`
  - All required registry fields are populated
  - `next_review_date` is not past due
  - `mitigation_plan.fallback_mechanism` is defined
- **Output**: `{"registered": true|false, "model_id": "...", "risk_class": "...", "clinical_use": true|false, "blockers": [...]}`
- **On blocker**: Stop pipeline, notify requester -- model must be registered before validation
- **Timeout**: 30s

## Step 2: Benchmark Evaluation

- **Tool**: `exec` (sandbox)
- **Action**: Run the model evaluation suite and compare against baseline metrics
- **Checks**:
  - Eval suite exists for this model
  - All benchmark metrics meet or exceed baseline
  - No metric has regressed by more than 5% from the last validated version
- **Output**: `{"eval_passed": true|false, "metrics": {"accuracy": N, "precision": N, "recall": N, "f1": N, ...}, "baseline_comparison": {...}, "regressions": [...]}`
- **On failure**: Stop pipeline, post evaluation report to #ai-governance
- **Timeout**: 600s

## Step 3: Bias Audit

- **Tool**: `exec` (sandbox)
- **Action**: Run demographic fairness tests per GOV-03 Bias Testing Protocol
- **Checks**:
  - Evaluate across all required demographic groups: age, sex, race/ethnicity, language, socioeconomic status, disability status
  - Compute fairness metrics: equalized odds, demographic parity, predictive parity, calibration
  - No demographic group has >10% performance disparity vs. overall population
- **Output**: `{"bias_audit_passed": true|false, "demographics_tested": [...], "fairness_metrics": {...}, "disparities": [...]}`
- **On failure**: Stop pipeline, create bias remediation ticket, notify governance board
- **Timeout**: 600s

## Step 4: CLINICAL SAFETY REVIEW GATE

- **Type**: Human approval required (conditional -- only for clinical-use models)
- **Condition**: Skip if `clinical_use` is `false` in the registry
- **Approvers**: Chief Medical Officer + AI/ML Lead
- **Present**: Model purpose, risk class, evaluation results, bias audit results, data types consumed, fallback mechanism
- **Timeout**: 48h
- **On reject**: End pipeline, record rejection reason in governance audit trail
- **On timeout**: End pipeline, notify requester and governance board

## Step 5: Explainability Check

- **Tool**: `exec` (sandbox)
- **Action**: Verify model outputs include required explainability fields per GOV-05
- **Checks**:
  - Determine required explainability tier from `risk_class`
  - Run sample inputs through the model
  - Verify outputs include all required fields for the tier:
    - Low: `confidence_score`
    - Medium: `confidence_score`, `contributing_factors` (top 3)
    - High: `confidence_score`, `contributing_factors`, `reasoning_chain`, `data_sources`
    - Critical: All of high + `uncertainty_quantification`, `alternative_recommendations`
  - Verify AI content labeling is present
- **Output**: `{"explainability_passed": true|false, "required_tier": "...", "fields_present": [...], "fields_missing": [...]}`
- **On failure**: Stop pipeline, return missing field list to development team
- **Timeout**: 120s

## Step 6: Shadow Deployment

- **Tool**: `exec` (gateway)
- **Action**: Deploy the model to shadow/staging environment
- **Behavior**: Model receives production traffic but responses are not served to users. Responses are logged for comparison against the current production model.
- **Output**: `{"environment": "shadow", "model_id": "...", "version": "...", "shadow_url": "...", "started_at": "ISO-8601"}`
- **Timeout**: 300s
- **On failure**: Alert #ai-governance, stop pipeline

## Step 7: Performance Baseline Capture

- **Tool**: `exec` (sandbox) + `web_fetch`
- **Action**: Capture performance baseline metrics from shadow deployment for future drift detection
- **Wait**: 1 hour of shadow traffic before capturing baseline (configurable per model)
- **Metrics captured**:
  - Accuracy, precision, recall, F1 on shadow traffic
  - Latency p50, p95, p99
  - Token usage (if LLM)
  - Error rate
  - Agreement rate with current production model
- **Output**: `{"baseline_captured": true, "metrics": {...}, "shadow_duration_hours": N, "sample_size": N}`
- **On insufficient data**: Extend shadow period, alert requester
- **Timeout**: 7200s (2 hours)

## Step 8: FINAL APPROVAL GATE

- **Type**: Human approval required
- **Approvers**: Model owner + AI/ML Lead. For critical-risk models: also requires governance board chair.
- **Present**: Full validation report (registry check, benchmarks, bias audit, clinical review, explainability, shadow metrics, baseline)
- **Timeout**: 24h
- **On reject**: Rollback shadow deployment, end pipeline, record rejection
- **On timeout**: End pipeline, notify all stakeholders

## Step 9: Production Deployment

- **Tool**: `exec` (gateway -- requires elevated access)
- **Action**: Deploy validated model to production
- **Strategy**: Canary deployment (10% traffic for 30 minutes, then full rollout)
- **Pre-deploy**: Update Model Risk Register: `deployment_status` -> `production`, `last_validated` -> today
- **Output**: `{"environment": "production", "model_id": "...", "version": "...", "deployed_at": "ISO-8601", "canary_percentage": 10}`
- **Timeout**: 600s
- **On failure**: Auto-rollback to previous model version, alert #ai-governance + model owner

## Step 10: Post-Deploy Health Check

- **Tool**: `exec` + `web_fetch`
- **Action**: Verify production health after deployment
- **Wait**: 30 minutes after full rollout before checking
- **Checks**:
  - Model endpoint returns 200
  - Accuracy has not degraded vs. baseline (captured in Step 7)
  - Error rate is within normal range
  - Latency is within SLO
  - No unexpected drift in output distribution
- **Output**: `{"healthy": true|false, "metrics": {...}, "comparison_to_baseline": {...}}`
- **On failure**: Auto-rollback to previous version, trigger AI Incident Response (GOV-09, AI-Sev2), alert #ai-governance

## Rollback Procedure

If any post-deploy check fails:
1. Immediately revert to previous model version
2. Update Model Risk Register: `deployment_status` -> `quarantined` for the new version
3. Post rollback notification to #ai-governance + #eng
4. Create AI incident ticket (AI-Sev2 minimum)
5. Preserve all deployment logs and metrics for root cause analysis
6. Model may not be re-deployed without passing this full pipeline again

## Configuration

```json
{
  "pipeline": "ai-model-validation",
  "version": "1.0",
  "governance_control": "GOV-02",
  "timeout_total": "72h",
  "output_cap_bytes": 500000,
  "resume_enabled": true,
  "shadow_duration_hours": 1,
  "canary_percentage": 10,
  "canary_duration_minutes": 30,
  "bias_disparity_threshold_pct": 10,
  "drift_alert_threshold_pct": 5,
  "notifications": {
    "on_complete": ["#ai-governance", "#eng", "model_owner_dm"],
    "on_failure": ["#ai-governance", "#eng", "#exec", "model_owner_dm"],
    "on_bias_failure": ["#ai-governance", "governance_board_dm"]
  }
}
```
