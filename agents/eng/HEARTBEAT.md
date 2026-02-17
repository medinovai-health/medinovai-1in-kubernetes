# Engineering Agent — Heartbeat Checks

Run these checks every heartbeat cycle (default: every 30 minutes).
Only alert when something needs attention — silence means healthy.

## Checks

### 1. CI health on main branch
- **Detect**: Check the last 3 CI runs on the `main` branch. Cross-reference fingerprints against `state/ci_fingerprints.json`.
- **Remediate**: If failure matches a known flaky test pattern, auto-trigger a re-run. If it's a new failure, create a diagnostic summary.
- **Verify**: Confirm re-run passed or diagnostic was delivered to the responsible team.
- **Alert if**: Main has been broken for > 1 hour after remediation attempt.

### 2. PR queue age
- **Detect**: Check open PRs that haven't received a review in > 24 hours.
- **Remediate**: Post a gentle nudge to the PR author's team channel. Suggest alternate reviewers based on file ownership.
- **Verify**: Confirm a reviewer was assigned within 4 hours of nudge.
- **Alert if**: PR remains unreviewed after 48 hours (escalate to team lead).

### 3. Dependency vulnerability scan
- **Detect**: Check if there are any critical/high CVEs in cached scan results.
- **Remediate**: Auto-draft a patch plan for critical CVEs. Create tracking issues for high-severity vulnerabilities.
- **Verify**: Confirm tracking issues were created and assigned.
- **Alert if**: Critical CVE has no assignee or patch plan after 24 hours.

### 4. Deploy queue check
- **Detect**: Approved deploys waiting to execute > 2 hours. Check for deploy locks.
- **Remediate**: If no lock exists, notify the deploy owner that their deploy is ready. If locked, provide lock reason and ETA.
- **Verify**: Confirm deploy owner acknowledged.
- **Alert if**: Deploy queued > 4 hours with no action.

### 5. Service health endpoints
- **Detect**: Ping key service health endpoints (from config/endpoints.json if present). Flag non-200 or response time > 5 seconds.
- **Remediate**: Run basic diagnostics (recent deploys, resource usage). Notify on-call if service degraded.
- **Verify**: Re-ping after 5 minutes to confirm transient vs persistent issue.
- **Alert if**: Service still unhealthy after 2 consecutive checks.

### 6. Dead letter triage
- **Detect**: Check `state/dead_letter/` for items older than 24 hours.
- **Remediate**: Group items by failure type and surface a summary for human review.
- **Verify**: Confirm items were reviewed or re-queued.
- **Alert if**: Dead letter items remain unprocessed after 48 hours.

### 7. SLO burn rate
- **Detect**: Check `state/slo/` for any skill with burn_rate > 2x target.
- **Remediate**: Reduce invocation frequency or switch to degraded mode for affected skill.
- **Verify**: Confirm burn rate returned to < 1.5x after adjustment.
- **Alert if**: Burn rate remains elevated after remediation attempt.

## Suppression Rules
- Do NOT alert if all checks pass.
- Do NOT re-alert on the same CI failure fingerprint within 2 hours.
- During deploy freezes, suppress deploy queue alerts.
