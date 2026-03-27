# Error Handling Patterns — medinovai-deploy

**Standard:** `medinovai-ai-standards/CODING_STANDARDS.md` | Dim 18
**Principle:** No silent failures. Every error is caught, classified, logged, and surfaced.

---

## Standard Error Envelope

All API error responses MUST use this envelope:

```json
{
  "error": {
    "code":     "VALIDATION_ERROR",
    "message":  "Patient ID is required",
    "details":  {"field": "patient_id", "constraint": "required"},
    "traceId":  "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "timestamp": "2026-03-27T10:30:00Z"
  }
}
```

## Error Code Registry

| Code | HTTP Status | Meaning | Retry? |
|------|-------------|---------|--------|
| `VALIDATION_ERROR` | 400 | Input failed validation | No |
| `AUTHENTICATION_ERROR` | 401 | Missing or invalid token | No |
| `AUTHORIZATION_ERROR` | 403 | Insufficient permissions | No |
| `NOT_FOUND` | 404 | Resource not found | No |
| `CONFLICT` | 409 | Resource state conflict | No |
| `RATE_LIMITED` | 429 | Too many requests | Yes (with backoff) |
| `INTERNAL_ERROR` | 500 | Unexpected server error | Yes (1x) |
| `SERVICE_UNAVAILABLE` | 503 | Dependency unavailable | Yes (with backoff) |
| `TIMEOUT` | 504 | Operation exceeded timeout | Yes (1x) |

## Circuit Breaker Pattern

```python
# Pattern for all external service calls
from medinovai_platform.resilience import CircuitBreaker

E_CIRCUIT_TIMEOUT_SECS = 5
E_CIRCUIT_FAILURE_THRESHOLD = 5
E_CIRCUIT_RESET_TIMEOUT_SECS = 30

mos_breaker = CircuitBreaker(
    failure_threshold=E_CIRCUIT_FAILURE_THRESHOLD,
    recovery_timeout=E_CIRCUIT_RESET_TIMEOUT_SECS,
    name="external-service"
)

@mos_breaker
async def mos_callExternalService(mos_request):
    # External call here
    pass
```

## Retry with Exponential Backoff

```python
import asyncio, random

E_MAX_RETRIES = 3
E_BASE_DELAY_SECS = 1.0
E_MAX_DELAY_SECS = 30.0

async def mos_withRetry(mos_fn, *mos_args, **mos_kwargs):
    for mos_attempt in range(E_MAX_RETRIES + 1):
        try:
            return await mos_fn(*mos_args, **mos_kwargs)
        except (ServiceUnavailableError, TimeoutError) as mos_e:
            if mos_attempt == E_MAX_RETRIES:
                raise
            mos_delay = min(
                E_BASE_DELAY_SECS * (2 ** mos_attempt) + random.uniform(0, 1),
                E_MAX_DELAY_SECS
            )
            await asyncio.sleep(mos_delay)
```

## Global Exception Handler (FastAPI)

```python
from fastapi import Request
from fastapi.responses import JSONResponse
import logging, uuid

mos_logger = logging.getLogger(__name__)

@app.exception_handler(Exception)
async def mos_globalExceptionHandler(mos_request: Request, mos_exc: Exception):
    mos_trace_id = str(uuid.uuid4())
    mos_logger.error(
        "Unhandled exception",
        extra={
            "traceId": mos_trace_id,
            "path": str(mos_request.url),
            "method": mos_request.method,
            "error": str(mos_exc),
        },
        exc_info=True
    )
    return JSONResponse(
        status_code=500,
        content={
            "error": {
                "code": "INTERNAL_ERROR",
                "message": "An unexpected error occurred",
                "traceId": mos_trace_id
            }
        }
    )
```

## Graceful Degradation

```python
E_CACHE_FALLBACK_TTL_SECS = 300  # 5-minute stale cache on dependency failure

async def mos_getPatientData(mos_patient_id: str):
    try:
        return await mos_primaryDataService.get(mos_patient_id)
    except ServiceUnavailableError:
        # Degrade to cache — safe for read operations
        mos_cached = await mos_cache.get(f"patient:{mos_patient_id}")
        if mos_cached:
            mos_logger.warning("Serving stale cache", extra={"patient_id": mos_patient_id})
            return mos_cached
        raise  # No fallback available — surface error to caller
```

## Alerting Integration

```python
# PagerDuty integration for critical errors
E_PAGERDUTY_ROUTING_KEY = os.getenv("E_PAGERDUTY_ROUTING_KEY")

async def mos_alertCriticalError(mos_error_msg: str, mos_context: dict):
    if E_PAGERDUTY_ROUTING_KEY:
        await mos_pagerdutyClient.trigger(
            routing_key=E_PAGERDUTY_ROUTING_KEY,
            summary=mos_error_msg,
            severity="critical",
            custom_details=mos_context,
            source="medinovai-deploy"
        )
```
