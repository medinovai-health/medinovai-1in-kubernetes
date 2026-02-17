# Engineering Agent — Tool Rules & Safety

## Trace ID Policy
- Include a `trace_id` in every log entry and API call for end-to-end tracing. Format: `{agent_id}-{session_id}-{seq}`.

## Exec Policy
- **Sandbox only** for all code execution. Never run on gateway host.
- Allowed binaries: `python3`, `node`, `bash`, `git` (read-only), `npm` (audit only), `pip` (audit only).
- Never run `git push`, `git merge`, `npm publish`, or any destructive command.
- Test execution is allowed in sandbox with timeout of 300s max.

## GitHub Integration
- Read operations (list PRs, get diff, get checks): always allowed.
- Write operations (post comment, create issue): require approval.
- Merge/close operations: NEVER allowed via automation.
- Use GitHub API (via exec scripts) rather than browser when possible.

## CI/CD Access
- Read CI logs: allowed.
- Trigger CI reruns: requires approval.
- Modify CI config: NEVER allowed via automation.

## Dependency Scanning
- Run audit commands (`npm audit`, `pip audit`, `safety check`) in sandbox.
- Fetch CVE data from public databases.
- Never auto-apply dependency updates — produce a plan for human review.

## Data Handling
- Source code diffs may contain secrets — scan and redact before logging.
- Never post full diffs to Slack — summarize with line references.
- Store CI failure digests in `outputs/ci/` with run ID naming.

## Guardian Pre-Execution Validation
Before any side-effect action (send, deploy, pay, delete, modify permissions):
1. Submit action request to Guardian agent via `sessions_send`.
2. If Guardian returns `allowed: false`, do NOT execute. Follow Guardian's `required_approval` guidance.
3. If Guardian is unreachable, proceed with warning logged to audit trail.

## Circuit Breaker Policy
Before calling any external API, check `state/circuit_breakers.json` for the relevant service:
- **closed**: Proceed normally. On failure, increment `failures`. If `failures >= threshold`, set state to `open` and record `opened_at`.
- **open**: Do NOT call the API. Return a cached/fallback response or queue the request to `state/dead_letter/`. After `resetTimeout`, set state to `half-open`.
- **half-open**: Allow ONE probe request. If it succeeds, reset to `closed` (failures=0). If it fails, return to `open`.

## Retry + Dead Letter Policy
On transient failures (HTTP 429, 502, 503, timeouts, connection resets):
1. Retry with exponential backoff: ~1s, ~3s, ~9s, ~27s, ~60s (max 5 retries, decorrelated jitter).
2. After max retries exhausted, write the failed item to `state/dead_letter/` as a JSON file named `{timestamp}_{action}.json`.
3. Never retry structural errors (401, 403, schema mismatch). Escalate immediately.

## Idempotency Policy
Before creating any resource (issue, comment, review):
1. Compute an idempotency key: `sha256(action + target + unique_source_id)`.
2. Check `state/idempotency_keys.json` — if the key exists and TTL has not expired, skip the action.
3. After successful execution, store the key with timestamp. Keys expire after 24 hours.
