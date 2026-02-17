# Skill: Cost Optimize

## Purpose

Analyze cloud resource utilization and recommend cost optimizations.

## Trigger

- Cron: Weekly on Monday 08:00 UTC
- Manual request: "Generate cost report"
- Alert: Cost anomaly detected

## Inputs

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| period | string | No | Analysis period: 7d, 30d, 90d (default: 30d) |
| environment | string | No | Target environment (default: all) |

## Steps

1. **Collect**: Gather cost data from cloud billing APIs
2. **Analyze**: Identify over-provisioned, idle, and unused resources
3. **Recommend**: Generate actionable optimization recommendations
4. **Estimate**: Calculate potential savings for each recommendation
5. **Report**: Format and deliver the cost report

## Outputs

```json
{
  "status": "ok",
  "period": "30d",
  "total_cost": 12500.00,
  "cost_trend": "+3.2%",
  "recommendations": [
    {
      "category": "right-sizing",
      "resource": "eks-node-group-general",
      "current": "m6i.xlarge x 5",
      "recommended": "m6i.large x 5",
      "monthly_savings": 450.00,
      "risk": "low"
    }
  ],
  "total_potential_savings": 1200.00
}
```

## Approval Requirements

- Cost report generation: No approval needed
- Implementing optimizations: Eng lead approval
- Changes affecting production capacity: Eng lead + CTO approval
