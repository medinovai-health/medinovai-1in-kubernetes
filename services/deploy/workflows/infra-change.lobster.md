# Infrastructure Change Pipeline

An approval-gated workflow for making infrastructure changes via Terraform.

## Pipeline Steps

```
[1] Plan → [2] Review → [3] APPROVAL GATE → [4] Apply → [5] Verify → [6] Notify
```

## Step 1: Plan
- **Tool**: `exec` (sandbox)
- **Action**: Run `terraform plan` for the affected environment
- **Output**: `{"changes": {"add": N, "change": N, "destroy": N}, "plan_file": "...", "plan_text": "..."}`
- **Alert if**: Any `destroy` operations detected
- **Timeout**: 120s

## Step 2: Review
- **Tool**: Slack delivery
- **Action**: Post the plan summary to #eng for review
- **Present**: Resources added, changed, destroyed. Full plan diff. Estimated cost impact.
- **Highlight**: Any security group changes, IAM changes, or destructive operations

## Step 3: APPROVAL GATE
- **Type**: Human approval required
- **Approvers**:
  - Non-destructive changes: Eng lead
  - Destructive changes: Eng lead + CTO
  - Production changes: Eng lead + CTO
  - Security group / IAM: Eng lead + Security lead
- **Present**: Plan summary, cost impact, risk assessment
- **Timeout**: 8h
- **On reject**: End pipeline, no changes applied
- **On timeout**: End pipeline, notify requester

## Step 4: Apply
- **Tool**: `exec` (gateway — requires elevated access)
- **Action**: Run `terraform apply` with the approved plan
- **Output**: `{"applied": true, "resources_changed": N, "duration_seconds": N}`
- **Timeout**: 600s
- **On failure**: Do NOT retry automatically. Alert #eng + requester with error.

## Step 5: Verify
- **Tool**: `exec` + `web_fetch`
- **Action**: Verify the infrastructure change was applied correctly
- **Checks**:
  - `terraform plan` shows no drift (plan is clean)
  - Affected services are healthy
  - No new error alerts from monitoring
- **Wait**: 5 minutes after apply before checking
- **Output**: `{"verified": true|false, "checks": {...}}`
- **On failure**: Alert with diagnostic. DO NOT auto-rollback (infra rollback requires careful handling).

## Step 6: Notify
- **Tool**: Slack delivery
- **Action**: Post change summary
- **Channels**: #eng
- **Message**:
  ```
  Infrastructure change applied to {environment}
  Resources: +{added} ~{changed} -{destroyed}
  Duration: {duration}
  Status: Verified ✓
  ```

## Configuration

```json
{
  "pipeline": "infra-change",
  "version": "1.0",
  "timeout_total": "12h",
  "output_cap_bytes": 200000,
  "resume_enabled": true,
  "auto_approve": false
}
```
