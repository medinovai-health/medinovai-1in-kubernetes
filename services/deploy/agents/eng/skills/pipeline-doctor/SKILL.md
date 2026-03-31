# Skill: Pipeline Doctor

## Purpose

Diagnose and fix broken CI/CD pipelines. Analyze failure patterns, identify root causes, and suggest or apply fixes.

## Trigger

- Webhook: CI pipeline failure event
- Cron: Poll for pipelines broken > 1 hour
- Manual: "Diagnose pipeline failure for {repo}"

## Inputs

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| repo | string | Yes | Repository with broken pipeline |
| run_id | string | No | Specific workflow run ID |
| branch | string | No | Branch with failure (default: main) |

## Steps

1. **Fetch logs**: Retrieve pipeline logs from GitHub Actions
2. **Classify failure**: Build error, test failure, infra issue, flaky test, timeout
3. **Root cause**: Identify the specific failure point
4. **Check history**: Has this failure happened before? Check MISTAKES.md
5. **Suggest fix**: Provide actionable fix with specific steps
6. **Track**: If same failure 3+ times, auto-create tracking ticket

## Outputs

```json
{
  "status": "ok",
  "repo": "medinovai-api-gateway",
  "failure_type": "test_failure",
  "root_cause": "Flaky test: auth.test.ts line 42 — race condition in token refresh",
  "occurrences": 3,
  "suggested_fix": "Add retry logic or mock the token refresh in test setup",
  "tracking_ticket": "ENG-142"
}
```
