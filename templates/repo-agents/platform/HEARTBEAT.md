# Platform Repo Heartbeat

**Cadence**: Every 30 minutes

## Checks

| Check | Action on Failure |
|-------|-------------------|
| CI status | Alert; block merge if broken |
| Deployment health | Page on critical |
| Secret expiry | Alert 7 days before |
| Dependency updates | Notify; create PR for critical |
| Drift detection | Alert; document and remediate |

## Scope

- Verify CI pipeline green for main branch.
- Check deployment health (uptime, error rate, latency).
- Audit secret expiration dates.
- Run dependency update scanner (Dependabot, Renovate).
- Compare IaC state vs live; flag drift.

## Outputs

- Status: pass / fail / degraded
- Timestamp and run ID
- Links to dashboards and reports
