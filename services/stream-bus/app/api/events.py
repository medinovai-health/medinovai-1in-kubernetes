"""
MedinovAI Real-Time Stream Bus — Event Publish API
Task Reference: S2-08
Version: 1.0.0
Date: 2026-02-24

HTTP interface for publishing CloudEvents v1.0 to the event bus.
Supports both single-event and batch publishing.

Endpoints:
    POST /api/v1/events/publish         — Publish a single event
    POST /api/v1/events/publish/batch   — Publish a batch of events (max 100)
    GET  /api/v1/events/types           — List all 13 supported event types

Routing (configured via EVENT_BUS_BACKEND env var):
    kafka    → KafkaEventProducer (production, default)
    rabbitmq → RabbitMQEventProducer (fallback)

Compliance:
    - No PHI allowed in event data payload (enforced at construction)
    - X-Tenant-ID required on every request
    - Every published event emits a structured audit log entry (21 CFR Part 11)
    - Idempotency: clients should reuse the same event_id on retry
"""

from __future__ import annotations

import uuid
from typing import Any, Dict, List, Optional

import structlog
from fastapi import APIRouter, Header, HTTPException
from pydantic import BaseModel, Field

from app.events.cloudevents import ALL_EVENT_TYPES, CloudEvent
from app.events.producer import get_event_producer

logger = structlog.get_logger("medinovai.stream_bus.api")
router = APIRouter()


# ─── Request / Response Models ────────────────────────────────────────────────

class PublishEventRequest(BaseModel):
    """Payload for publishing a single CloudEvent."""
    event_type: str = Field(
        ...,
        description="CloudEvent type — must be one of the 13 MedinovAI event types",
        examples=["io.medinovai.data.dqgate.passed"],
    )
    source: str = Field(
        "medinovai-data-services",
        description="Source service publishing the event",
    )
    data: Dict[str, Any] = Field(
        default_factory=dict,
        description="Event payload — MUST NOT contain PHI",
    )
    correlation_id: Optional[str] = Field(
        None,
        description="Trace/correlation ID for end-to-end observability",
    )
    event_id: Optional[str] = Field(
        None,
        description="Idempotency key — reuse the same ID on retry",
    )


class PublishEventResponse(BaseModel):
    event_id: str
    event_type: str
    offset: str
    tenant_id: str
    status: str = "published"


class BatchPublishRequest(BaseModel):
    events: List[PublishEventRequest] = Field(
        ...,
        min_length=1,
        max_length=100,
        description="Up to 100 events per batch",
    )


class BatchPublishResponse(BaseModel):
    published: int
    failed: int
    offsets: List[str]
    errors: List[str]


# ─── PHI Firewall ────────────────────────────────────────────────────────────

_PHI_INDICATORS = frozenset({
    "patient_name", "first_name", "last_name", "name",
    "ssn", "social_security", "dob", "date_of_birth",
    "phone", "email", "address", "mrn", "medical_record_number",
    "ip_address", "npi", "birth_date", "death_date",
    "zip_code", "zip", "postal_code",
})


def _collect_keys_recursive(obj: Any, depth: int = 0) -> set:
    """Recursively collect all string keys from a nested dict/list structure."""
    if depth > 5 or not isinstance(obj, (dict, list)):
        return set()
    if isinstance(obj, list):
        keys: set = set()
        for item in obj:
            keys |= _collect_keys_recursive(item, depth + 1)
        return keys
    keys = {k.lower() for k in obj.keys()}
    for v in obj.values():
        keys |= _collect_keys_recursive(v, depth + 1)
    return keys


def _check_no_phi(data: Dict[str, Any], event_type: str) -> None:
    """Reject events containing PHI field names at any nesting depth."""
    all_keys = _collect_keys_recursive(data)
    phi_found = all_keys & _PHI_INDICATORS
    if phi_found:
        logger.warning(
            "event_phi_blocked",
            event_type=event_type,
            phi_fields=sorted(phi_found),
        )
        raise HTTPException(
            status_code=400,
            detail=(
                f"PHI field(s) detected in event data: {sorted(phi_found)}. "
                "Events must not contain PHI. Use pseudonymous IDs only."
            ),
        )


# ─── Endpoints ───────────────────────────────────────────────────────────────

@router.get("/types", summary="List all supported CloudEvent types (S2-08)")
async def list_event_types():
    """Return all 13 MedinovAI CloudEvent types."""
    return {"event_types": ALL_EVENT_TYPES, "count": len(ALL_EVENT_TYPES)}


@router.post("/publish", response_model=PublishEventResponse,
             summary="Publish a single CloudEvent to the event bus (S2-08)")
async def publish_event(
    body: PublishEventRequest,
    x_tenant_id: str = Header(..., alias="X-Tenant-ID"),
):
    tenant_id = x_tenant_id.strip()
    if not tenant_id:
        raise HTTPException(status_code=400, detail="X-Tenant-ID header is required")

    if body.event_type not in ALL_EVENT_TYPES:
        raise HTTPException(
            status_code=400,
            detail=(
                f"Unknown event type '{body.event_type}'. "
                f"Supported types: {ALL_EVENT_TYPES}"
            ),
        )

    _check_no_phi(body.data, body.event_type)

    event = CloudEvent(
        event_type=body.event_type,
        source=body.source,
        tenant_id=tenant_id,
        data=body.data,
        correlation_id=body.correlation_id or str(uuid.uuid4()),
    )
    if body.event_id:
        event.id = body.event_id  # override auto-generated ID for idempotency

    try:
        producer = get_event_producer()
        offset = await producer.publish(event)
        logger.info(
            "event_published_via_api",
            event_id=event.id,
            event_type=event.type,
            tenant_id=tenant_id,
            offset=offset,
        )
        return PublishEventResponse(
            event_id=event.id,
            event_type=event.type,
            offset=offset,
            tenant_id=tenant_id,
        )
    except Exception as exc:
        logger.error("event_publish_failed", event_type=body.event_type,
                     tenant_id=tenant_id, error=str(exc)[:200])
        raise HTTPException(status_code=503, detail=f"Event bus unavailable: {exc}") from exc


@router.post("/publish/batch", response_model=BatchPublishResponse,
             summary="Publish a batch of CloudEvents (max 100) (S2-08)")
async def publish_batch(
    body: BatchPublishRequest,
    x_tenant_id: str = Header(..., alias="X-Tenant-ID"),
):
    tenant_id = x_tenant_id.strip()
    if not tenant_id:
        raise HTTPException(status_code=400, detail="X-Tenant-ID header is required")

    cloud_events: List[CloudEvent] = []
    errors: List[str] = []

    for req in body.events:
        if req.event_type not in ALL_EVENT_TYPES:
            errors.append(f"Unknown event type '{req.event_type}'")
            continue
        try:
            _check_no_phi(req.data, req.event_type)
        except HTTPException as exc:
            errors.append(exc.detail)
            continue
        evt = CloudEvent(
            event_type=req.event_type,
            source=req.source,
            tenant_id=tenant_id,
            data=req.data,
            correlation_id=req.correlation_id or str(uuid.uuid4()),
        )
        if req.event_id:
            evt.id = req.event_id
        cloud_events.append(evt)

    offsets: List[str] = []
    if cloud_events:
        try:
            producer = get_event_producer()
            offsets = await producer.publish_batch(cloud_events)
        except Exception as exc:
            logger.error("batch_publish_failed", tenant_id=tenant_id, error=str(exc)[:200])
            errors.append(f"Batch publish failed: {exc}")

    logger.info("batch_events_published",
                tenant_id=tenant_id,
                published=len(offsets),
                failed=len(errors))

    return BatchPublishResponse(
        published=len(offsets),
        failed=len(errors),
        offsets=offsets,
        errors=errors,
    )
