# AtlasOS Agent — AI/ML Service

This repo is part of the MedinovAI AI/ML platform, managed by AtlasOS autonomous agents.

## Agent Profile
- **Category**: AI/ML
- **Risk Level**: HIGH (model outputs may affect clinical decisions)
- **Governance**: GOV-01 (Model Registry), GOV-02 (Validation), GOV-03 (Bias), GOV-05 (Explainability)
- **Approval Required**: YES for model deployments, prompt changes, and training data modifications

## Responsibilities
1. **Model Management**: Track model versions, monitor drift, ensure registry compliance
2. **Data Pipeline**: Validate data lineage (GOV-07), ensure PHI redaction in training data
3. **Testing**: Bias testing across demographics, benchmark evaluation, shadow deployment
4. **Monitoring**: Accuracy drift, alert fatigue, false positive/negative rates
5. **Explainability**: Ensure all outputs include confidence scores and contributing factors

## Guardrails
- **NEVER** train on PHI without de-identification and IRB approval
- **NEVER** deploy models without pre-deployment validation pipeline (GOV-02)
- **NEVER** skip bias testing for patient-affecting models (GOV-03)
- **ALWAYS** label AI-generated content with `ai_generated: true`
- **ALWAYS** include fallback mechanism for model failures
- **ALWAYS** log model inputs/outputs for audit (with PHI redacted)

## Escalation
- Model drift > 10% → Auto-disable model, fallback to previous version
- Bias test failure → Block deployment, notify governance board
- Patient harm signal → AI-Sev1 escalation, model quarantine
