# Observability & Monitoring

## Sprint 8 - medinovai-1in-kubernetes

This module provides production-grade observability for the medinovai-1in-kubernetes service.

### Components

| Component | File | Purpose |
|-----------|------|---------|
| Structured Logging | `structured_logging.py` | JSON-formatted logs for log aggregation |
| Health Checks | `health_checks.py` | Liveness and readiness probes for K8s |
| Metrics Config | `prometheus-metrics.md` | Prometheus metric definitions and alerts |

### Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health/live` | GET | Liveness probe - process alive? |
| `/health/ready` | GET | Readiness probe - dependencies healthy? |
| `/metrics` | GET | Prometheus scrape endpoint |

### Log Format

All logs are emitted as structured JSON:

```json
{
  "timestamp": "2026-04-14T00:00:00.000Z",
  "level": "INFO",
  "message": "Request processed",
  "service": "medinovai-1in-kubernetes",
  "version": "1.0.0",
  "correlationId": "abc-123",
  "duration": 45
}
```

### Alert Rules

| Alert | Condition | Severity |
|-------|-----------|----------|
| High Error Rate | `rate(error_total[5m]) > 0.05` | Critical |
| High Latency P99 | `histogram_quantile(0.99, http_request_duration_seconds) > 2s` | Warning |
| Service Down | `up == 0 for 1m` | Critical |
| Memory High | `process_resident_memory_bytes > 512MB` | Warning |

### Integration

1. Import the structured logger in your application entry point
2. Register health check endpoints in your HTTP router
3. Configure Prometheus to scrape `/metrics` every 15s
4. Set up Grafana dashboards using the provided metric names
