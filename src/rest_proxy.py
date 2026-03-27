"""
REST proxy for medinovai-real-time-stream-bus.
Exposes Kafka operations via HTTP for services that cannot use Kafka natively.
"""
from __future__ import annotations

import json
import os
import uuid
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, AsyncGenerator

import jsonschema
from confluent_kafka import Consumer, Producer
from confluent_kafka.admin import AdminClient
from fastapi import FastAPI, HTTPException, Request


# --- Configuration ---
KAFKA_BOOTSTRAP = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092")
PORT = int(os.getenv("PORT", "3140"))
SERVICE_NAME = os.getenv("SERVICE_NAME", "medinovai-real-time-stream-bus")
DEAD_LETTER_TOPIC = "stream-bus.dead-letter"
SCHEMAS_DIR = Path(__file__).parent / "schemas"

# Required event fields for validation
REQUIRED_FIELDS = {"event_type", "timestamp", "source", "tenant_id"}

# Global producer/consumer (initialized on startup)
_producer: Producer | None = None
_admin: AdminClient | None = None
_schema_cache: dict[str, dict] = {}


# --- Schema loading ---
def _load_schemas() -> dict[str, dict]:
    """Load all JSON schemas from schemas directory."""
    cache: dict[str, dict] = {}
    if not SCHEMAS_DIR.exists():
        return cache
    for path in SCHEMAS_DIR.glob("*.json"):
        try:
            with open(path) as f:
                cache[path.stem] = json.load(f)
        except (json.JSONDecodeError, OSError):
            pass
    return cache


def _get_schema_for_event_type(event_type: str) -> dict | None:
    """Get schema for event_type (e.g., iam_user_created)."""
    return _schema_cache.get(event_type.replace(".", "_"))


def _validate_event(event: dict[str, Any]) -> tuple[bool, str | None]:
    """
    Validate event has required fields and conforms to schema if available.
    Returns (valid, error_message).
    """
    if not isinstance(event, dict):
        return False, "Event must be a JSON object"

    missing = REQUIRED_FIELDS - set(event.keys())
    if missing:
        return False, f"Missing required fields: {', '.join(sorted(missing))}"

    ts = event.get("timestamp")
    if not isinstance(ts, str):
        return False, "Field 'timestamp' must be ISO8601 string"
    try:
        datetime.fromisoformat(ts.replace("Z", "+00:00"))
    except (ValueError, TypeError):
        return False, "Field 'timestamp' must be valid ISO8601 format"

    event_type = event.get("event_type")
    if schema := _get_schema_for_event_type(str(event_type)):
        try:
            jsonschema.validate(event, schema)
        except jsonschema.ValidationError as e:
            return False, str(e)

    return True, None


def _send_to_dead_letter(topic: str, raw_payload: bytes, error: str, key: str | None = None) -> None:
    """Send malformed event to dead-letter topic."""
    if not _producer:
        return
    dl_payload = {
        "original_topic": topic,
        "error": error,
        "raw_payload": raw_payload.decode("utf-8", errors="replace"),
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
    try:
        _producer.produce(
            DEAD_LETTER_TOPIC,
            key=key or str(uuid.uuid4()),
            value=json.dumps(dl_payload).encode("utf-8"),
        )
        _producer.flush(timeout=5)
    except Exception:
        pass


# --- Kafka operations ---
def _get_producer() -> Producer:
    if _producer is None:
        raise RuntimeError("Kafka producer not initialized")
    return _producer


def _get_admin() -> AdminClient:
    if _admin is None:
        raise RuntimeError("Kafka admin not initialized")
    return _admin


# --- FastAPI app ---
@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    global _producer, _admin, _schema_cache
    _schema_cache = _load_schemas()
    _producer = Producer({"bootstrap.servers": KAFKA_BOOTSTRAP})
    _admin = AdminClient({"bootstrap.servers": KAFKA_BOOTSTRAP})
    yield
    if _producer:
        _producer.flush(timeout=10)
        _producer = None


app = FastAPI(
    title=SERVICE_NAME,
    description="REST proxy for Kafka event backbone",
    version="1.0.0",
    lifespan=lifespan,
)


@app.get("/health")
async def health() -> dict[str, Any]:
    """Health check."""
    try:
        _get_admin().list_topics(timeout=5)
        kafka_ok = True
    except Exception:
        kafka_ok = False
    return {
        "status": "healthy" if kafka_ok else "degraded",
        "service": SERVICE_NAME,
        "kafka": "connected" if kafka_ok else "disconnected",
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


@app.get("/ready")
async def ready() -> dict[str, str]:
    """Readiness check."""
    return {"status": "ready", "service": SERVICE_NAME}


@app.get("/topics")
async def list_topics() -> dict[str, list[str]]:
    """List all Kafka topics."""
    try:
        md = _get_admin().list_topics(timeout=10)
        topics = sorted([t for t in md.topics.keys() if not t.startswith("_")])
        return {"topics": topics}
    except Exception as e:
        raise HTTPException(status_code=503, detail=str(e)) from e


@app.post("/publish/{topic:path}")
async def publish(topic: str, request: Request) -> dict[str, Any]:
    """
    Publish event to Kafka topic.
    Body: { "event": { "event_type", "timestamp", "source", "tenant_id", ... } }
    """
    try:
        body = await request.json()
    except Exception as e:
        raw = await request.body()
        _send_to_dead_letter(topic, raw, f"Invalid JSON: {e}")
        raise HTTPException(status_code=400, detail="Invalid JSON body") from e

    event = body.get("event") if isinstance(body, dict) else body
    if not event:
        raise HTTPException(status_code=400, detail="Missing 'event' in body")

    valid, err = _validate_event(event)
    if not valid:
        raw = json.dumps(body).encode("utf-8")
        _send_to_dead_letter(topic, raw, err or "Validation failed")
        raise HTTPException(status_code=400, detail=err) from None

    key = event.get("correlation_id") or event.get("tenant_id") or str(uuid.uuid4())
    value = json.dumps(event).encode("utf-8")

    try:
        _get_producer().produce(topic, key=key, value=value)
        _get_producer().flush(timeout=10)
    except Exception as e:
        raw = json.dumps(event).encode("utf-8")
        _send_to_dead_letter(topic, raw, str(e), key=key)
        raise HTTPException(status_code=503, detail=str(e)) from e

    return {
        "status": "published",
        "topic": topic,
        "key": key,
        "event_type": event.get("event_type"),
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


@app.post("/events")
async def publish_events(request: Request) -> dict[str, Any]:
    """
    Alternative publish endpoint (e.g. for webhooks).
    Body: { "events": [...], "topic": "optional" }
    or single event: { "event_type", "timestamp", "source", "tenant_id", ... }
    """
    try:
        body = await request.json()
    except Exception as e:
        raise HTTPException(status_code=400, detail="Invalid JSON body") from e

    events: list[dict]
    default_topic: str | None = None

    if isinstance(body, dict):
        if "events" in body:
            events = body.get("events", [])
            default_topic = body.get("topic")
        elif "event_type" in body and "timestamp" in body and "source" in body and "tenant_id" in body:
            events = [body]
            default_topic = body.get("topic")
        else:
            raise HTTPException(status_code=400, detail="Expected 'events' array or single event object")
    else:
        raise HTTPException(status_code=400, detail="Expected JSON object")

    results: list[dict] = []
    for i, event in enumerate(events):
        topic = default_topic or _topic_from_event_type(event.get("event_type", "unknown"))
        valid, err = _validate_event(event)
        if not valid:
            raw = json.dumps(event).encode("utf-8")
            _send_to_dead_letter(topic, raw, err or "Validation failed")
            results.append({"index": i, "status": "dead_letter", "error": err})
            continue
        key = event.get("correlation_id") or event.get("tenant_id") or str(uuid.uuid4())
        value = json.dumps(event).encode("utf-8")
        try:
            _get_producer().produce(topic, key=key, value=value)
            results.append({"index": i, "status": "published", "topic": topic, "key": key})
        except Exception as e:
            raw = json.dumps(event).encode("utf-8")
            _send_to_dead_letter(topic, raw, str(e), key=key)
            results.append({"index": i, "status": "dead_letter", "error": str(e)})

    _get_producer().flush(timeout=10)
    return {"status": "completed", "results": results}


def _topic_from_event_type(event_type: str) -> str:
    """Map event_type to topic name."""
    normalized = event_type.replace(".", "_").replace("-", "_").lower()
    return f"stream-bus.{normalized}"


@app.get("/subscribe/{topic:path}/{group:path}")
async def subscribe(topic: str, group: str, timeout_ms: int = 5000) -> dict[str, Any]:
    """
    Long-poll consumer: fetch messages from topic for consumer group.
    Returns up to 10 messages or blocks up to timeout_ms.
    """
    consumer = Consumer(
        {
            "bootstrap.servers": KAFKA_BOOTSTRAP,
            "group.id": group,
            "auto.offset.reset": "earliest",
            "enable.auto.commit": True,
        }
    )
    consumer.subscribe([topic])
    messages: list[dict] = []
    try:
        msg = consumer.poll(timeout=timeout_ms / 1000.0)
        count = 0
        while msg and count < 10:
            if msg.error():
                break
            try:
                payload = json.loads(msg.value().decode("utf-8"))
            except (json.JSONDecodeError, AttributeError):
                payload = {"raw": msg.value().decode("utf-8", errors="replace")}
            messages.append(
                {
                    "key": msg.key().decode("utf-8") if msg.key() else None,
                    "partition": msg.partition(),
                    "offset": msg.offset(),
                    "payload": payload,
                }
            )
            count += 1
            msg = consumer.poll(timeout=0.1)
    finally:
        consumer.close()

    return {"topic": topic, "group": group, "messages": messages}


# --- Entrypoint ---
def main() -> None:
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=PORT)


if __name__ == "__main__":
    main()
