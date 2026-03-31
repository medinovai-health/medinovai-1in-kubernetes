# Deploy Pipeline

An approval-gated workflow for deploying code to staging and production.

## Pipeline Steps

```
[1] Pre-flight Checks → [2] Build & Test → [3] Deploy to Staging → [4] Smoke Tests
    → [5] APPROVAL GATE → [6] Deploy to Production → [7] Health Check → [8] Notify
```

## Step 1: Pre-flight Checks
- **Tool**: `exec` (sandbox)
- **Action**: Verify deployment prerequisites
- **Checks**:
  - CI passing on target branch
  - No open critical incidents
  - Deploy window (business hours, not Friday 4pm)
  - No other deploy in progress (lock check)
- **Output**: `{"ready": true|false, "checks": {...}, "blockers": [...]}`
- **On blocker**: Stop pipeline, notify requester with reason
- **Timeout**: 60s

## Step 2: Build & Test
- **Tool**: `exec` (sandbox)
- **Action**: Run build and test suite
- **Commands**:
  ```bash
  npm run build --json 2>&1
  npm run test -- --json 2>&1
  ```
- **Output**: `{"build": "ok|fail", "tests": {"passed": N, "failed": N, "skipped": N}}`
- **On failure**: Stop pipeline, post build/test output to #eng
- **Timeout**: 300s

## Step 3: Deploy to Staging
- **Tool**: `exec` (gateway — requires elevated access)
- **Action**: Deploy the build to staging environment
- **Output**: `{"environment": "staging", "version": "...", "url": "https://staging...."}`
- **Timeout**: 180s
- **On failure**: Alert #eng, stop pipeline

## Step 4: Smoke Tests
- **Tool**: `browser` + `exec`
- **Action**: Run automated smoke tests against staging
- **Tests**:
  - Health endpoint returns 200
  - Login flow works
  - Key API endpoints respond
  - No console errors on main pages
- **Output**: `{"passed": N, "failed": N, "screenshots": [...]}`
- **On failure**: Stop pipeline, attach screenshots, alert #eng

## Step 5: APPROVAL GATE
- **Type**: Human approval required
- **Approvers**: Eng lead + on-call engineer
- **Present**: Build info, test results, staging URL, smoke test results
- **Timeout**: 4h
- **On reject**: Rollback staging (optional), end pipeline
- **On timeout**: End pipeline, notify requester

## Step 6: Deploy to Production
- **Tool**: `exec` (gateway — requires elevated access)
- **Action**: Deploy to production
- **Strategy**: Rolling deployment (or blue-green if configured)
- **Output**: `{"environment": "production", "version": "...", "deployed_at": "ISO-8601"}`
- **Timeout**: 300s
- **On failure**: Auto-rollback to previous version, alert #eng + #exec

## Step 7: Health Check
- **Tool**: `exec` + `web_fetch`
- **Action**: Verify production health post-deploy
- **Checks**:
  - Health endpoint returns 200
  - Error rate hasn't spiked (check monitoring)
  - Key metrics within normal range
- **Wait**: 5 minutes after deploy before checking
- **Output**: `{"healthy": true|false, "metrics": {...}}`
- **On failure**: Auto-rollback, alert with full diagnostic

## Step 8: Notify
- **Tool**: Slack delivery
- **Action**: Post deployment summary
- **Channels**: #eng, #exec
- **Message**:
  ```
  :rocket: Deployed v{version} to production
  Changes: {commit_summary}
  Tests: {passed}/{total} passed
  Deploy time: {duration}
  Status: Healthy
  ```

## Rollback Procedure
If any post-deploy check fails:
1. Immediately revert to previous version
2. Post rollback notification to #eng + #exec
3. Create incident ticket
4. Preserve deploy logs for diagnosis

## Configuration

```json
{
  "pipeline": "deploy",
  "version": "1.0",
  "timeout_total": "6h",
  "output_cap_bytes": 100000,
  "resume_enabled": true,
  "deploy_windows": {
    "allowed": "Mon-Thu 09:00-16:00 America/New_York",
    "override_requires": "eng-lead approval"
  },
  "notifications": {
    "on_complete": ["#eng", "#exec"],
    "on_failure": ["#eng", "#exec", "requester_dm"]
  }
}
```
