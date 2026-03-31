# Skill: Drift Remediate

## Purpose

Detect and remediate infrastructure drift between desired state (IaC) and actual state (cloud resources).

## Trigger

- Cron: Daily at 03:00 UTC
- Alert: Drift detected by monitoring
- Manual request: "Check for drift"

## Inputs

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| environment | string | Yes | Target environment |
| auto_remediate | boolean | No | Auto-fix non-destructive drift (default: false) |

## Steps

1. **Detect**: Run `terraform plan` and parse for differences
2. **Classify**: Categorize each difference:
   - **Additive**: Resource added outside Terraform (import or remove)
   - **Modified**: Resource changed outside Terraform (restore or adopt)
   - **Missing**: Resource deleted outside Terraform (recreate or remove from state)
3. **Risk assess**: Determine if remediation is safe
4. **Remediate** (if approved):
   - Non-destructive: `terraform apply` to restore desired state
   - Destructive: Flag for human review
5. **Verify**: Confirm drift is resolved
6. **Report**: Log drift event for trend analysis

## Outputs

```json
{
  "status": "ok|drift_found|needs_human",
  "environment": "production",
  "drift_items": [
    {
      "resource": "aws_security_group.api",
      "type": "modified",
      "field": "ingress.0.cidr_blocks",
      "expected": "[\"10.0.0.0/16\"]",
      "actual": "[\"10.0.0.0/16\", \"0.0.0.0/0\"]",
      "risk": "high",
      "auto_remediable": false
    }
  ],
  "remediated": 0,
  "needs_review": 1
}
```

## Auto-Remediation Rules

| Drift Type | Auto-Remediate? | Reason |
|------------|----------------|--------|
| Tag changes | Yes | Non-functional |
| Scaling parameter drift | Yes | Restore desired capacity |
| Security group rule added | NO | Potential security incident — investigate |
| IAM policy changed | NO | Potential security incident — investigate |
| Resource deleted | NO | Potential data loss — investigate |
| Configuration drift | Case by case | Depends on resource type |
