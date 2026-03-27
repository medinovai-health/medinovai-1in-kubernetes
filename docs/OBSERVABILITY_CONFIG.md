# Observability Configuration — medinovai-deploy

**Tier:** 2 | **Minimum Logging Level:** L2 (Platform Ops)
**Standard:** `medinovai-ai-standards/OBSERVABILITY.md` v3.0.0
**SLO Target:** 99.5% availability

---

## OpenTelemetry Setup

### Service Name
```
OTEL_SERVICE_NAME=medinovai-deploy
OTEL_EXPORTER_OTLP_ENDPOINT=grpc-collector.medinovai.health:4317
```

### Required SDK Initialization
See `opentelemetry.yaml` in this repo for full configuration.
Reference implementation: `medinovai-ai-standards/OBSERVABILITY.md#SDK-Configuration`

## Logging Levels (L0–L5)

| Level | Name              | When to Use                              |
|-------|-------------------|------------------------------------------|
| L0    | SILENT            | Tests/local dev only                     |
| L1    | OPERATIONAL       | Lifecycle events (start/stop/config)     |
| L2    | PLATFORM_OPS      | Service calls, errors, performance       |
| L3    | CLINICAL_EVIDENCE | PHI access, clinical decisions, consents |
| L4    | FORENSIC          | Full request/response for investigations |
| L5    | DEBUG             | Never in production                      |

**This service minimum:** L2 (Platform Ops)

## Required Log Fields

Every structured log entry MUST include:
```json
{
  "timestamp": "ISO8601",
  "level": "INFO|WARN|ERROR",
  "service": "medinovai-deploy",
  "traceId": "otel-trace-id",
  "spanId": "otel-span-id",
  "tenantId": "uuid",
  "userId": "uuid-or-system",
  "action": "verb.resource.result",
  "duration_ms": 0
}
```

## Health Check Endpoint

Implement `GET /health` returning:
```json
{
  "status": "healthy|degraded|unhealthy",
  "version": "1.0.0",
  "uptime": 12345,
  "checks": [
    {"name": "database", "status": "healthy", "latency_ms": 3},
    {"name": "cache", "status": "healthy"},
    {"name": "message_bus", "status": "healthy"}
  ]
}
```

## Metrics (Prometheus)

Expose `GET /metrics` with:
- `http_requests_total{method, endpoint, status}`
- `http_request_duration_seconds{method, endpoint}`
- `active_connections`
- `error_rate`


## Registry Heartbeat

Send heartbeat every 30 seconds to:
```
POST https://registry.medinovai.health/v1/heartbeat
{
  "service": "medinovai-deploy",
  "status": "healthy",
  "version": "...",
  "region": "$REGION",
  "tenantId": "$TENANT_ID"
}
```

## SLO Tracking

| SLO | Target | Alert Threshold |
|-----|--------|-----------------|
| Availability | 99.5% | < 99% triggers page |
| P95 Latency | < 1000ms | > 2s triggers alert |
| Error Rate | < 0.5% | > 1% triggers alert |
