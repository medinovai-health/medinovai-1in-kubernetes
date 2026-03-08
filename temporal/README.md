# MedinovAI Temporal Workflow Engine

**Sprint:** S0-08 — Temporal POC  
**Status:** Active

Temporal is the HIPAA-compliant workflow orchestration engine for MedinovAI. It replaces all custom schedulers. This directory contains the Sprint 0 POC configuration and hello-world workflow.

## Quick Start (Local)

```bash
# 1. Start local Temporal server
docker run --rm -p 7233:7233 -p 8233:8233 temporalio/auto-setup:latest

# 2. Install dependencies
pip install -r temporal/requirements.txt

# 3. Run worker + trigger test workflow
TEMPORAL_ENVIRONMENT=local python temporal/workers/hello_worker.py --trigger
```

Expected output:
```
[medinovai-temporal] Connected to Temporal (local)
[medinovai-temporal] Workflow triggered: medinovai-hello-world-abc12345
[medinovai-temporal] Result: {'greeting': 'MedinovAI Temporal POC — MedinovAI Health Data Network is operational.', ...}
[medinovai-temporal] Sprint 0 Exit Criterion #8: PASS — Temporal hello-world completed
```

## Production (Temporal Cloud)

```bash
# Copy and fill in your Temporal Cloud credentials
cp temporal/.env.temporal.example temporal/.env.temporal

# Start worker with Cloud config
source temporal/.env.temporal
TEMPORAL_ENVIRONMENT=production python temporal/workers/hello_worker.py
```

## Directory Structure

```
temporal/
├── config/
│   └── temporal.yaml       ← Connection config (local + cloud)
├── workflows/
│   └── hello_world.py      ← Sprint 0 POC workflow
├── workers/
│   └── hello_worker.py     ← Worker + test trigger
├── requirements.txt
├── .env.temporal.example   ← Environment variable template (commit-safe)
└── README.md
```

## Sprint F Workflows (to be implemented in Sprint 8)

| Workflow | Task Queue | Autonomy |
|---|---|---|
| Partner Onboarding | medinovai-partner-onboarding | 90% |
| Cohort → Study → Evidence | medinovai-cohort-study | 100% |
| Model Lifecycle | medinovai-model-lifecycle | 85% |
| Incident Response | medinovai-incident-response | 80% |
| Data Refresh | medinovai-data-refresh | 95% |
| Consent Cascade | medinovai-consent-cascade | 100% |
