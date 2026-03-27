"""
ActiveMQ Event Publisher — Infrastructure Management (medinovai-infrastructure)
Publishes domain events per atlasos-events.yaml
"""
import json
import logging
import os
import uuid
from datetime import datetime, timezone
from typing import Any

mos_logger = logging.getLogger("medinovai-infrastructure.events")

E_AMQP_URL = os.getenv("AMQP_URL", "amqp://localhost:5672")
E_SERVICE = "infrastructure"


async def mos_publishEvent(
    mos_resource: str,
    mos_action: str,
    mos_orgId: str,
    mos_actorId: str,
    mos_resourceId: str,
    mos_correlationId: str | None = None,
    mos_data: dict[str, Any] | None = None,
) -> None:
    """Publish domain event to ActiveMQ topic."""
    mos_topic = f"medinovai.{E_SERVICE}.{mos_resource}.{mos_action}"
    mos_event = {
        "event_id": str(uuid.uuid4()),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "org_id": mos_orgId,
        "actor_id": mos_actorId,
        "resource_id": mos_resourceId,
        "action": mos_action,
        "correlation_id": mos_correlationId or str(uuid.uuid4()),
        "data": mos_data or {},
    }
    try:
        import aio_pika  # type: ignore
        mos_conn = await aio_pika.connect_robust(E_AMQP_URL)
        async with mos_conn:
            mos_ch = await mos_conn.channel()
            mos_exchange = await mos_ch.declare_exchange(
                mos_topic, aio_pika.ExchangeType.TOPIC, durable=True
            )
            await mos_exchange.publish(
                aio_pika.Message(
                    body=json.dumps(mos_event).encode(),
                    content_type="application/json",
                    delivery_mode=aio_pika.DeliveryMode.PERSISTENT,
                    headers={"ce-type": mos_topic, "ce-source": E_SERVICE},
                ),
                routing_key=mos_action,
            )
        mos_logger.info("Published: %s", mos_topic)
    except ImportError:
        mos_logger.warning("aio_pika not installed — event not published")
    except Exception as e:
        # Fire-and-forget: never block the request path
        mos_logger.error("Event publish failed %s: %s", mos_topic, type(e).__name__)
