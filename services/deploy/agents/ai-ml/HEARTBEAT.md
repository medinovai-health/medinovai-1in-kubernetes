# AI/ML Operations Agent -- Heartbeat Checks

Run these checks proactively. Only alert when something needs attention. Silence means healthy.

## Checks

### 1. Model Quality Monitoring
- **Detect**: Check that evaluation benchmarks exist and are current. Verify model performance has not regressed since last deployment.
- **Remediate**: Run eval suite. Compare against baseline. Flag regressions.
- **Verify**: Confirm eval metrics are within acceptable range.
- **Alert if**: Any model metric regresses by more than 5% from baseline.

### 2. Prompt Quality and Versioning
- **Detect**: Check that all production prompts are versioned. Verify prompt changes have accompanying eval results. Look for prompt injection vulnerabilities.
- **Remediate**: Version unversioned prompts. Add input sanitization. Draft eval tests for uncovered prompts.
- **Verify**: Run evals on all active prompts.
- **Alert if**: Unversioned prompts in production or prompt injection vectors detected.

### 3. Token Cost Monitoring
- **Detect**: Track token usage per model, per endpoint. Compare against budgets. Identify cost spikes.
- **Remediate**: Suggest caching, prompt optimization, or model downgrade for low-complexity tasks.
- **Verify**: Estimate savings from recommended changes.
- **Alert if**: Daily token cost exceeds budget by more than 20%.

### 4. RAG Retrieval Quality
- **Detect**: If RAG is used, check retrieval precision and recall. Verify embeddings are up to date. Check for stale or missing documents in the vector store.
- **Remediate**: Re-index stale documents. Adjust chunking strategy. Add missing documents.
- **Verify**: Run retrieval quality eval after changes.
- **Alert if**: Retrieval precision drops below 80% or documents are more than 7 days stale.

### 5. Hallucination Detection Patterns
- **Detect**: Check that all AI-generated outputs have source attribution or confidence scoring. Verify that outputs are validated against known facts where applicable.
- **Remediate**: Add source attribution to unsourced outputs. Add confidence scoring. Add fact-checking for high-stakes outputs.
- **Verify**: Run validation pipeline on sample outputs.
- **Alert if**: AI output presented as authoritative without source attribution.

### 6. API Provider Health
- **Detect**: Check connectivity and response times for AI providers (OpenAI, Anthropic, Hugging Face, etc.). Verify API key validity and quota.
- **Remediate**: For degraded providers, ensure fallback routing is configured. Check API key rotation schedule.
- **Verify**: Confirm fallback works.
- **Alert if**: Primary AI provider is degraded or API key expires within 7 days.

### 7. Training Data Integrity
- **Detect**: If training pipeline exists, verify data integrity (no corruption, no train/test leakage, no PII in training data).
- **Remediate**: Fix data issues. Add data validation pipeline.
- **Verify**: Run data validation checks.
- **Alert if**: PII detected in training data or train/test leakage found.

### 8. Responsible AI Checks (GOV-03, GOV-04, GOV-05)
- **Detect**: Check for bias testing results per the formal Bias Testing Protocol (`skills/bias-testing/SKILL.md`, governance control GOV-03). Verify all production models with `clinical_use: true` have a bias audit within the last 90 days. Verify AI-generated content is labeled per Explainability Standards (`config/explainability_standards.md`, GOV-05). Check that human override pathways are enabled for all clinical-use models (GOV-04).
- **Remediate**: If bias audit is missing or overdue, trigger the `bias-testing` skill for the affected model. If AI content labeling is missing, flag the feature for remediation. If human override is disabled for a clinical model, escalate immediately.
- **Verify**: Confirm bias audit report exists and passes. Confirm AI content labels are present. Confirm override pathway is functional.
- **Alert if**: Bias audit is missing, overdue, or failed. AI content is unlabeled in user-facing features. Human override is disabled for any clinical-use model.

### 9. Accuracy Drift Detection (GOV-06)
- **Detect**: For each production model in the Model Risk Register, compare current performance metrics against the rolling 30-day baseline captured during deployment (see `workflows/ai-model-validation.lobster.md`, Step 7). Check accuracy, precision, recall, F1, and any model-specific metrics.
- **Remediate**: If drift is between 5-10%, alert the model owner and recommend investigation. If drift exceeds 10%, automatically disable the model and fall back to the defined `mitigation_plan.fallback_mechanism` from the Model Risk Register. Trigger AI Incident Response (GOV-09, AI-Sev2).
- **Verify**: After remediation, confirm the fallback is active and serving correctly. Confirm the model owner has been notified.
- **Alert if**: Any key metric drifts >5% from baseline. CRITICAL alert if >10% drift detected.

### 10. Alert Fatigue Monitoring (GOV-06)
- **Detect**: Track the alert-to-action ratio for each AI model that generates clinician-facing alerts. Calculate `action_rate = alerts_acted_upon / total_alerts_generated` over a rolling 7-day window. Check per-model and per-clinical-unit.
- **Remediate**: If action_rate drops below 60% (>40% alerts dismissed), flag the model for review. Draft a recommendation to adjust alert thresholds, consolidate alerts, or reduce alert frequency. Notify the model owner.
- **Verify**: After threshold adjustment, monitor action_rate for improvement over the next 7 days.
- **Alert if**: Alert-to-action ratio drops below 60% for any model. CRITICAL alert if below 40% (severe alert fatigue).

### 11. Clinical Outcome Tracking (GOV-06)
- **Detect**: For models with `clinical_use: true`, correlate AI recommendations with downstream patient outcomes where outcome data is available. Track: recommendation acceptance rate, outcome concordance (did the recommended action lead to the expected outcome), and adverse event correlation (were any adverse events temporally associated with AI recommendations).
- **Remediate**: If outcome concordance drops below the model's established baseline, flag for investigation. If adverse event correlation is detected, trigger AI Incident Response (GOV-09). Compile monthly outcome reports for the AI Governance Board.
- **Verify**: Confirm outcome data pipeline is current and complete. Confirm adverse event correlation checks are running.
- **Alert if**: Outcome concordance drops >10% from baseline. Any adverse event temporal correlation detected with AI recommendation.

### 12. Model Risk Register Completeness (GOV-01)
- **Detect**: Enumerate all known production AI endpoints and services. Compare against registered models with `deployment_status: "production"` in the Model Risk Register. Check for models with overdue `next_review_date`.
- **Remediate**: For unregistered models, create a placeholder entry and immediately escalate to the model owner for full registration. For overdue reviews, notify the model owner and governance board.
- **Verify**: Confirm all production models are registered. Confirm no reviews are overdue.
- **Alert if**: Any unregistered AI model is running in production (CRITICAL). Any model review is overdue by more than 14 days.

## Suppression Rules

- Do NOT alert if all checks pass.
- Do NOT re-alert on the same issue within the current session.
- PII in training data and hallucination alerts are NEVER suppressed.
- Unregistered production model alerts (check #12) are NEVER suppressed.
- Adverse event correlation alerts (check #11) are NEVER suppressed.
