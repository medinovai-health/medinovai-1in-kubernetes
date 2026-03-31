# Skill: Infrastructure Provision

## Purpose

Provision or modify cloud infrastructure for the MedinovAI platform using Terraform.

## Trigger

- Manual request: "Provision infrastructure for {environment}"
- Webhook: New environment request from provisioning workflow
- Scheduled: Drift remediation after drift detection

## Inputs

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| environment | string | Yes | Target environment (dev, staging, production) |
| modules | string[] | No | Specific modules to provision (default: all) |
| dry_run | boolean | No | Plan only, do not apply (default: true) |

## Steps

1. **Validate**: Run `terraform validate` for the target environment
2. **Plan**: Run `terraform plan` and capture the plan output
3. **Review**: If any destructive operations, flag for human review
4. **Approval**: Route through infra-change approval pipeline
5. **Apply**: Run `terraform apply` with the approved plan
6. **Verify**: Confirm resources are in desired state (plan shows no changes)
7. **Log**: Record the change in audit trail

## Outputs

```json
{
  "status": "ok|error|needs_human",
  "environment": "staging",
  "changes": {
    "added": 3,
    "changed": 1,
    "destroyed": 0
  },
  "plan_summary": "...",
  "applied": true,
  "verified": true
}
```

## Failure Modes

| Failure | Classification | Response |
|---------|---------------|----------|
| Terraform init fails | Structural | Check backend config, credentials |
| Plan shows unexpected destroys | Logic | Halt, flag for review |
| Apply fails mid-execution | Structural | Do NOT retry. Check state. Escalate. |
| Apply succeeds but verify fails | Logic | Investigate drift. May need targeted fix. |
| Credentials expired | Structural | Refresh credentials, retry once |

## Approval Requirements

- Non-destructive changes: Eng lead approval
- Destructive changes: Eng lead + CTO approval
- Production changes: Always require approval
- Dev/staging non-destructive: May auto-approve
