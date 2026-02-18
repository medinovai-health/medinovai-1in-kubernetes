# AI/ML Repo Heartbeat

**Cadence**: Every 1 hour

## Checks

| Check | Action on Failure |
|-------|-------------------|
| Model registry | Alert if unregistered or stale |
| Inference latency | Alert if P99 > SLA |
| Prediction drift | Alert; trigger review |
| Bias metrics | Alert if outside bounds |
| Token cost | Alert on anomaly |

## Scope

- Verify all production models in registry with current metadata.
- Monitor inference latency (P50, P95, P99).
- Run drift detection (data, predictions).
- Compute and compare bias metrics vs baseline.
- Track token/API cost; flag anomalies.

## Outputs

- Status: pass / fail / degraded
- Timestamp and run ID
- Links to registry, dashboards, cost reports
