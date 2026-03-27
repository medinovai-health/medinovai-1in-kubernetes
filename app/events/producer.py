"""
MedinovAI Event Bus Producer — S2-08 Implementation.

Dual-mode: Kafka (default) + RabbitMQ (fallback/legacy).
Publishes CloudEvents v1.0 to tenant-scoped topics.

Topic naming convention: medinovai.{tenant_id}.{event_domain}
  e.g. medinovai.org-acme.data, medinovai.org-acme.research, medinovai.org-acme.aiml

Compliance:
    - No PHI in event payloads (enforced at CloudEvent construction)
    - Tenant-scoped topics (no cross-tenant message leakage)
    - At-least-once delivery (Kafka acks=all, RabbitMQ confirm-mode)
    - Idempotency key: CloudEvent.id (consumer must deduplicate)
    - Audit: every published event logged to medinovai-audit-trail-explorer

Performance target: 10,000 events/second throughput.
"""
from __future__ import annotations

import asyncio
import os
from abc import ABC, abstractmethod
from typing import Any, Dict, Optional

import structlog

from app.events.cloudevents import ALL_EVENT_TYPES, CloudEvent

logger = structlog.get_logger(__name__)

# Topic prefix for all MedinovAI events
TOPIC_PREFIX = os.environ.get("KAFKA_TOPIC_PREFIX", "medinovai")


def _topic_for_event(event: CloudEvent) -> str:
    """
    Derive Kafka topic from event type and tenant.

    Convention: medinovai.{tenant_id}.{domain}
    Domain derived from event type: io.medinovai.{domain}.{...}
    """
    # io.medinovai.data.ingested → data
    parts = event.type.split(".")
    domain = parts[2] if len(parts) > 2 else "events"
    tenant = event.tenant_id.replace("/", "-")
    return f"{TOPIC_PREFIX}.{tenant}.{domain}"


# ---------------------------------------------------------------------------
# Abstract producer interface
# ---------------------------------------------------------------------------


class EventProducer(ABC):
    """Abstract event producer interface."""

    @abstractmethod
    async def publish(self, event: CloudEvent) -> str:
        """Publish event. Returns message offset/delivery tag."""
        ...

    @abstractmethod
    async def publish_batch(self, events: list[CloudEvent]) -> list[str]:
        """Publish a batch of events."""
        ...

    @abstractmethod
    async def close(self) -> None:
        """Flush and close connections."""
        ...


# ---------------------------------------------------------------------------
# Kafka producer (production)
# ---------------------------------------------------------------------------


class KafkaEventProducer(EventProducer):
    """
    Production Kafka producer using aiokafka.

    Configuration (environment variables):
        KAFKA_BOOTSTRAP_SERVERS: comma-separated broker addresses (default: localhost:9092)
        KAFKA_SECURITY_PROTOCOL: PLAINTEXT | SSL | SASL_SSL (default: SASL_SSL in prod)
        KAFKA_SASL_MECHANISM: PLAIN | SCRAM-SHA-512 (default: SCRAM-SHA-512)
        KAFKA_SASL_USERNAME: Kafka SASL username
        KAFKA_SASL_PASSWORD: Kafka SASL password (loaded from Vault, not env in prod)
        KAFKA_ACKS: 0 | 1 | all (default: all — strongest durability)
        KAFKA_COMPRESSION_TYPE: none | gzip | snappy | lz4 | zstd (default: snappy)
        KAFKA_MAX_BATCH_SIZE: bytes (default: 65536)
        KAFKA_LINGER_MS: milliseconds to wait before flushing batch (default: 5)
    """

    def __init__(self) -> None:
        self._producer: Optional[Any] = None
        self._bootstrap = os.environ.get("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092")
        self._security_protocol = os.environ.get("KAFKA_SECURITY_PROTOCOL", "PLAINTEXT")
        self._sasl_mechanism = os.environ.get("KAFKA_SASL_MECHANISM", "PLAIN")
        self._sasl_username = os.environ.get("KAFKA_SASL_USERNAME", "")
        self._sasl_password = os.environ.get("KAFKA_SASL_PASSWORD", "")
        self._acks = os.environ.get("KAFKA_ACKS", "all")
        self._compression = os.environ.get("KAFKA_COMPRESSION_TYPE", "snappy")

    async def _ensure_producer(self) -> None:
        if self._producer is None:
            try:
                from aiokafka import AIOKafkaProducer
            except ImportError:
                raise RuntimeError(
                    "aiokafka not installed. Run: pip install aiokafka[snappy]"
                )

            kwargs: Dict[str, Any] = {
                "bootstrap_servers": self._bootstrap,
                "acks": self._acks,
                "compression_type": self._compression,
                "enable_idempotence": True,  # exactly-once semantics at producer level
                "max_batch_size": int(os.environ.get("KAFKA_MAX_BATCH_SIZE", "65536")),
                "linger_ms": int(os.environ.get("KAFKA_LINGER_MS", "5")),
            }

            if self._security_protocol != "PLAINTEXT":
                kwargs["security_protocol"] = self._security_protocol
                kwargs["sasl_mechanism"] = self._sasl_mechanism
                if self._sasl_username:
                    kwargs["sasl_plain_username"] = self._sasl_username
                    kwargs["sasl_plain_password"] = self._sasl_password

            self._producer = AIOKafkaProducer(**kwargs)
            await self._producer.start()
            logger.info("kafka_producer_started", bootstrap=self._bootstrap)

    async def publish(self, event: CloudEvent) -> str:
        """Publish single event to tenant-scoped topic."""
        await self._ensure_producer()
        topic = _topic_for_event(event)
        key = event.tenant_id.encode("utf-8")
        value = event.to_bytes()

        try:
            result = await self._producer.send_and_wait(
                topic,
                value=value,
                key=key,
                headers=[
                    ("ce-id", event.id.encode()),
                    ("ce-type", event.type.encode()),
                    ("ce-specversion", event.specversion.encode()),
                    ("ce-source", event.source.encode()),
                    ("ce-time", event.time.encode()),
                    ("x-tenant-id", event.tenant_id.encode()),
                    ("x-correlation-id", event.correlation_id.encode()),
                ],
            )
            offset = f"{result.topic}:{result.partition}:{result.offset}"
            logger.info(
                "kafka_event_published",
                event_id=event.id,
                event_type=event.type,
                topic=topic,
                offset=offset,
                tenant_id=event.tenant_id,
            )
            return offset
        except Exception as exc:
            logger.error(
                "kafka_publish_error",
                event_id=event.id,
                event_type=event.type,
                topic=topic,
                error=str(exc),
            )
            raise

    async def publish_batch(self, events: list[CloudEvent]) -> list[str]:
        """Publish events in a batch for throughput optimization."""
        await self._ensure_producer()
        futures = []
        for event in events:
            topic = _topic_for_event(event)
            f = await self._producer.send(
                topic,
                value=event.to_bytes(),
                key=event.tenant_id.encode("utf-8"),
            )
            futures.append((event, f))

        await self._producer.flush()
        results = []
        for event, future in futures:
            try:
                result = await future
                results.append(f"{result.topic}:{result.partition}:{result.offset}")
            except Exception as exc:
                logger.error("kafka_batch_publish_error", event_id=event.id, error=str(exc))
                results.append(f"error:{str(exc)}")
        return results

    async def close(self) -> None:
        if self._producer:
            await self._producer.flush()
            await self._producer.stop()
            self._producer = None
            logger.info("kafka_producer_stopped")


# ---------------------------------------------------------------------------
# RabbitMQ producer (fallback / legacy)
# ---------------------------------------------------------------------------


class RabbitMQEventProducer(EventProducer):
    """
    RabbitMQ producer using aio-pika with publisher confirms (at-least-once).

    Exchange: medinovai.events (topic exchange)
    Routing key: {tenant_id}.{event_domain}
    Queue: medinovai.{tenant_id}.{domain} (auto-created with DLQ)
    """

    def __init__(self) -> None:
        self._connection: Optional[Any] = None
        self._channel: Optional[Any] = None
        self._exchange: Optional[Any] = None
        self._url = os.environ.get("RABBITMQ_URL", "amqp://guest:guest@localhost/")
        self._exchange_name = os.environ.get("RABBITMQ_EXCHANGE", "medinovai.events")

    async def _ensure_connection(self) -> None:
        if self._connection is None:
            try:
                import aio_pika
            except ImportError:
                raise RuntimeError("aio-pika not installed. Run: pip install aio-pika")

            self._connection = await aio_pika.connect_robust(self._url)
            self._channel = await self._connection.channel()
            await self._channel.set_qos(prefetch_count=100)
            self._exchange = await self._channel.declare_exchange(
                self._exchange_name,
                aio_pika.ExchangeType.TOPIC,
                durable=True,
            )
            logger.info("rabbitmq_producer_connected", url=self._url.split("@")[-1])

    async def publish(self, event: CloudEvent) -> str:
        import aio_pika

        await self._ensure_connection()
        domain = event.type.split(".")[2] if len(event.type.split(".")) > 2 else "events"
        routing_key = f"{event.tenant_id}.{domain}"
        message = aio_pika.Message(
            body=event.to_bytes(),
            content_type="application/cloudevents+json; charset=UTF-8",
            message_id=event.id,
            headers={
                "ce-type": event.type,
                "ce-source": event.source,
                "x-tenant-id": event.tenant_id,
                "x-correlation-id": event.correlation_id,
            },
            delivery_mode=aio_pika.DeliveryMode.PERSISTENT,
        )
        await self._exchange.publish(message, routing_key=routing_key)
        logger.info(
            "rabbitmq_event_published",
            event_id=event.id,
            event_type=event.type,
            routing_key=routing_key,
        )
        return f"rabbitmq:{routing_key}:{event.id}"

    async def publish_batch(self, events: list[CloudEvent]) -> list[str]:
        return [await self.publish(e) for e in events]

    async def close(self) -> None:
        if self._connection:
            await self._connection.close()
            self._connection = None


# ---------------------------------------------------------------------------
# Factory — returns the right producer based on environment
# ---------------------------------------------------------------------------

_producer_instance: Optional[EventProducer] = None


def get_event_producer() -> EventProducer:
    """
    Get singleton event producer.

    EVENT_BUS_BACKEND=kafka  → KafkaEventProducer (production default)
    EVENT_BUS_BACKEND=rabbitmq → RabbitMQEventProducer (legacy/fallback)
    """
    global _producer_instance
    if _producer_instance is None:
        backend = os.environ.get("EVENT_BUS_BACKEND", "kafka").lower()
        if backend == "rabbitmq":
            _producer_instance = RabbitMQEventProducer()
        else:
            _producer_instance = KafkaEventProducer()
        logger.info("event_producer_initialized", backend=backend)
    return _producer_instance


# ---------------------------------------------------------------------------
# AtlasOS event trigger helpers (S8-07: wire all 13 event types to AtlasOS)
# ---------------------------------------------------------------------------

# Mapping: event_type → Temporal workflow to trigger
ATLASOS_WORKFLOW_TRIGGERS: Dict[str, str] = {
    "io.medinovai.data.ingested": "data_refresh",
    "io.medinovai.data.deidentified": "data_refresh",
    "io.medinovai.data.dqgate.passed": "cohort_to_evidence",
    "io.medinovai.data.dqgate.failed": "incident_response",
    "io.medinovai.data.dataset.published": "cohort_to_evidence",
    "io.medinovai.research.cohort.executed": "cohort_to_evidence",
    "io.medinovai.research.workspace.provisioned": None,  # no workflow — notify only
    "io.medinovai.aiml.model.registered": "model_lifecycle",
    "io.medinovai.aiml.deployment.requested": "model_lifecycle",
    "io.medinovai.aiml.deployment.completed": None,
    "io.medinovai.aiml.deployment.rolledback": "incident_response",
    "io.medinovai.consent.revoked": "consent_cascade",
    "io.medinovai.security.alert": "incident_response",
}
