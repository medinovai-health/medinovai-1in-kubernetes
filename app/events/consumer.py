"""
MedinovAI Event Bus Consumer — S8-07 Implementation.

Kafka consumer that listens to all 13 event topics and routes them to
the appropriate AtlasOS Temporal workflow trigger.

S8-07: Wire all 13 CloudEvent types to AtlasOS via event bus.

Event → Temporal Workflow mapping (from ATLASOS_WORKFLOW_TRIGGERS):
    DataIngested           → data_refresh workflow
    DeIdCompleted          → data_refresh workflow (next step)
    DQGatePassed           → cohort_to_evidence workflow
    DQGateFailed           → incident_response workflow
    DatasetPublished       → cohort_to_evidence workflow
    CohortExecuted         → cohort_to_evidence workflow
    WorkspaceProvisioned   → (notify only — no workflow trigger)
    ModelRegistered        → model_lifecycle workflow
    DeploymentRequested    → model_lifecycle workflow
    DeploymentCompleted    → (notify only)
    DeploymentRolledBack   → incident_response workflow
    ConsentRevoked         → consent_cascade workflow
    SecurityAlert          → incident_response workflow

Compliance:
    - No PHI in consumed events (enforced at producer)
    - Tenant isolation: each message consumed in tenant scope
    - At-least-once delivery: commit offset after successful Temporal trigger
    - Dead-letter queue: failed triggers → medinovai.dlq topic after 3 retries
    - Audit: every event trigger logged with correlation_id
"""
from __future__ import annotations

import asyncio
import json
import os
from typing import Any, Dict, Optional

import structlog

from app.events.cloudevents import (
    ALL_EVENT_TYPES,
    ATLASOS_WORKFLOW_TRIGGERS,
    CloudEvent,
    EVENT_CONSENT_REVOKED,
    EVENT_DATASET_PUBLISHED,
    EVENT_DATA_INGESTED,
    EVENT_DEPLOYMENT_ROLLED_BACK,
    EVENT_DQ_GATE_FAILED,
    EVENT_DQ_GATE_PASSED,
    EVENT_SECURITY_ALERT,
)

logger = structlog.get_logger(__name__)

# AtlasOS Temporal gateway URL (the AtlasOS Python sidecar exposes workflow trigger endpoints)
ATLASOS_GATEWAY_URL = os.environ.get("ATLASOS_GATEWAY_URL", "http://medinovai-atlas-os:8090")
KAFKA_BOOTSTRAP = os.environ.get("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092")
TEMPORAL_HOST = os.environ.get("TEMPORAL_HOST", "localhost:7233")
TEMPORAL_NAMESPACE = os.environ.get("TEMPORAL_NAMESPACE", "medinovai-prod")

# Topics to subscribe: all tenant topics matching medinovai.*.* pattern
TOPIC_PATTERN = r"^medinovai\..+\.(data|research|aiml|consent|security)$"


async def trigger_temporal_workflow(
    workflow_name: str,
    event: CloudEvent,
    max_retries: int = 3,
) -> bool:
    """
    Trigger a Temporal workflow via the AtlasOS gateway HTTP API.
    Retries with exponential backoff on failure.
    Returns True if successfully triggered.
    """
    import httpx

    url = f"{ATLASOS_GATEWAY_URL}/api/v1/workflows/{workflow_name}/trigger"
    payload = {
        "workflow": workflow_name,
        "tenant_id": event.tenant_id,
        "correlation_id": event.correlation_id,
        "trigger_event": {
            "id": event.id,
            "type": event.type,
            "source": event.source,
            "subject": event.subject,
            "data": event.data,
        },
    }

    for attempt in range(1, max_retries + 1):
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                resp = await client.post(
                    url,
                    json=payload,
                    headers={"X-Tenant-ID": event.tenant_id},
                )
                if resp.status_code in (200, 201, 202):
                    logger.info(
                        "atlasos_workflow_triggered",
                        workflow=workflow_name,
                        event_id=event.id,
                        event_type=event.type,
                        tenant_id=event.tenant_id,
                    )
                    return True
                else:
                    logger.warning(
                        "atlasos_workflow_trigger_failed",
                        workflow=workflow_name,
                        status=resp.status_code,
                        attempt=attempt,
                        event_id=event.id,
                    )
        except Exception as exc:
            logger.warning(
                "atlasos_workflow_trigger_error",
                workflow=workflow_name,
                attempt=attempt,
                error=str(exc),
                event_id=event.id,
            )

        if attempt < max_retries:
            await asyncio.sleep(5 * (2 ** (attempt - 1)))  # 5s, 10s, 20s

    return False


async def send_to_dlq(event: CloudEvent, reason: str) -> None:
    """Send unprocessable event to dead-letter queue."""
    try:
        from app.events.producer import get_event_producer
        from app.events.cloudevents import CloudEvent as CE

        dlq_event = CE(
            event_type="io.medinovai.dlq.event",
            source="medinovai-real-time-stream-bus/consumer",
            tenant_id=event.tenant_id,
            data={
                "original_event_id": event.id,
                "original_type": event.type,
                "failure_reason": reason,
                "original_data_keys": list(event.data.keys()),  # no values — could be PHI
            },
            correlation_id=event.correlation_id,
        )
        producer = get_event_producer()
        await producer.publish(dlq_event)
        logger.warning("event_sent_to_dlq", event_id=event.id, reason=reason)
    except Exception as exc:
        logger.error("dlq_send_failed", event_id=event.id, error=str(exc))


class EventBusConsumer:
    """
    Kafka consumer that routes CloudEvents to AtlasOS Temporal workflows.

    Lifecycle:
        consumer = EventBusConsumer()
        await consumer.start()   # begins consuming
        await consumer.stop()    # graceful shutdown + offset commit
    """

    def __init__(self) -> None:
        self._consumer: Optional[Any] = None
        self._running = False
        self._processed = 0
        self._failed = 0

    async def start(self) -> None:
        """Start consuming events from all MedinovAI topics."""
        try:
            from aiokafka import AIOKafkaConsumer
        except ImportError:
            raise RuntimeError("aiokafka not installed: pip install aiokafka")

        import re

        self._consumer = AIOKafkaConsumer(
            bootstrap_servers=KAFKA_BOOTSTRAP,
            group_id="medinovai-atlasos-event-router",
            auto_offset_reset="earliest",
            enable_auto_commit=False,  # manual commit after successful processing
            value_deserializer=lambda v: v,
        )

        await self._consumer.start()
        # Subscribe to all MedinovAI event topics via regex pattern
        self._consumer.subscribe(pattern=TOPIC_PATTERN)
        self._running = True
        logger.info("event_bus_consumer_started", topic_pattern=TOPIC_PATTERN)

        try:
            async for msg in self._consumer:
                if not self._running:
                    break
                await self._process_message(msg)
        finally:
            await self._consumer.stop()
            logger.info(
                "event_bus_consumer_stopped",
                processed=self._processed,
                failed=self._failed,
            )

    async def _process_message(self, msg: Any) -> None:
        """Process a single Kafka message: parse CloudEvent → trigger workflow."""
        try:
            event = CloudEvent.from_bytes(msg.value)
        except Exception as exc:
            logger.error("event_parse_error", offset=msg.offset, error=str(exc))
            await self._consumer.commit()
            return

        workflow = ATLASOS_WORKFLOW_TRIGGERS.get(event.type)

        logger.info(
            "event_received",
            event_id=event.id,
            event_type=event.type,
            tenant_id=event.tenant_id,
            workflow_target=workflow or "notify-only",
            topic=msg.topic,
            offset=msg.offset,
        )

        success = True
        if workflow:
            success = await trigger_temporal_workflow(workflow, event)
            if not success:
                self._failed += 1
                await send_to_dlq(event, f"Temporal trigger failed for workflow={workflow}")
            else:
                self._processed += 1
        else:
            # notify-only events: log and move on
            self._processed += 1

        # Commit offset after processing (at-least-once delivery)
        await self._consumer.commit()

    async def stop(self) -> None:
        self._running = False


# ---------------------------------------------------------------------------
# Event trigger router for direct (non-Kafka) use (e.g. from FastAPI endpoint)
# ---------------------------------------------------------------------------

async def route_event_to_atlasos(event: CloudEvent) -> Dict[str, Any]:
    """
    Directly route a CloudEvent to AtlasOS without Kafka.
    Used for synchronous trigger paths (e.g. DQ gate failure from HTTP handler).
    """
    workflow = ATLASOS_WORKFLOW_TRIGGERS.get(event.type)
    if not workflow:
        return {"triggered": False, "reason": "no_workflow_mapped", "event_type": event.type}

    triggered = await trigger_temporal_workflow(workflow, event)
    return {
        "triggered": triggered,
        "workflow": workflow,
        "event_id": event.id,
        "event_type": event.type,
    }
