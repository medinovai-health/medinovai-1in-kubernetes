"""
StreamBus Python client — publish and subscribe via REST proxy.
Auto-includes tenant_id, correlation_id, timestamp.
"""
from __future__ import annotations

import threading
import uuid
from datetime import datetime, timezone
from typing import Any, Callable

import httpx


def _default_base_url() -> str:
    import os
    return os.getenv("STREAM_BUS_URL", "http://localhost:3140")


def _enrich_event(event: dict[str, Any], tenant_id: str | None, correlation_id: str | None) -> dict[str, Any]:
    """Ensure event has required fields; auto-fill if missing."""
    enriched = dict(event)
    if "timestamp" not in enriched:
        enriched["timestamp"] = datetime.now(timezone.utc).isoformat()
    if "tenant_id" not in enriched and tenant_id:
        enriched["tenant_id"] = tenant_id
    if "correlation_id" not in enriched and correlation_id:
        enriched["correlation_id"] = correlation_id
    return enriched


def publish(
    topic: str,
    event: dict[str, Any],
    *,
    base_url: str | None = None,
    tenant_id: str | None = None,
    correlation_id: str | None = None,
) -> dict[str, Any]:
    """
    Publish event to Kafka topic via REST proxy.
    Auto-includes tenant_id, correlation_id, timestamp if not present.
    """
    url = (base_url or _default_base_url()).rstrip("/") + f"/publish/{topic}"
    enriched = _enrich_event(event, tenant_id, correlation_id or str(uuid.uuid4()))
    with httpx.Client(timeout=30.0) as client:
        resp = client.post(url, json={"event": enriched})
        resp.raise_for_status()
        return resp.json()


def subscribe(
    topic: str,
    group: str,
    handler: Callable[[dict[str, Any]], None],
    *,
    base_url: str | None = None,
    timeout_ms: int = 5000,
    poll_interval_ms: int = 1000,
    stop_event: threading.Event | None = None,
) -> None:
    """
    Subscribe to events from topic (long-poll consumer).
    Blocks and calls handler for each message until stop_event is set.
    """
    url = (base_url or _default_base_url()).rstrip("/") + f"/subscribe/{topic}/{group}"
    ev = stop_event or threading.Event()
    while not ev.is_set():
        try:
            with httpx.Client(timeout=(timeout_ms + 5000) / 1000.0) as client:
                resp = client.get(url, params={"timeout_ms": timeout_ms})
                resp.raise_for_status()
                data = resp.json()
            for msg in data.get("messages", []):
                payload = msg.get("payload", {})
                try:
                    handler(payload)
                except Exception:
                    pass  # handler errors are swallowed; log in production
        except httpx.HTTPError:
            pass
        except Exception:
            pass
        ev.wait(timeout=poll_interval_ms / 1000.0)


class StreamBusClient:
    """
    StreamBus client with connection management.
    Maintains base_url, default tenant_id, and optional correlation context.
    """

    def __init__(
        self,
        base_url: str | None = None,
        tenant_id: str | None = None,
        default_correlation_id: str | None = None,
    ) -> None:
        self._base_url = base_url or _default_base_url()
        self._tenant_id = tenant_id
        self._correlation_id = default_correlation_id

    @property
    def base_url(self) -> str:
        return self._base_url

    @property
    def tenant_id(self) -> str | None:
        return self._tenant_id

    def with_tenant(self, tenant_id: str) -> "StreamBusClient":
        """Return a new client with the given tenant_id."""
        return StreamBusClient(
            base_url=self._base_url,
            tenant_id=tenant_id,
            default_correlation_id=self._correlation_id,
        )

    def with_correlation(self, correlation_id: str) -> "StreamBusClient":
        """Return a new client with the given correlation_id."""
        return StreamBusClient(
            base_url=self._base_url,
            tenant_id=self._tenant_id,
            default_correlation_id=correlation_id,
        )

    def publish(self, topic: str, event: dict[str, Any]) -> dict[str, Any]:
        """Publish event to topic. Auto-includes tenant_id, correlation_id, timestamp."""
        return publish(
            topic,
            event,
            base_url=self._base_url,
            tenant_id=self._tenant_id,
            correlation_id=self._correlation_id or str(uuid.uuid4()),
        )

    def publish_events(self, events: list[dict[str, Any]], topic: str | None = None) -> dict[str, Any]:
        """Batch publish via /events endpoint."""
        url = self._base_url.rstrip("/") + "/events"
        enriched = [
            _enrich_event(e, self._tenant_id, self._correlation_id or str(uuid.uuid4()))
            for e in events
        ]
        body: dict[str, Any] = {"events": enriched}
        if topic:
            body["topic"] = topic
        with httpx.Client(timeout=60.0) as client:
            resp = client.post(url, json=body)
            resp.raise_for_status()
            return resp.json()

    def subscribe(
        self,
        topic: str,
        group: str,
        handler: Callable[[dict[str, Any]], None],
        *,
        timeout_ms: int = 5000,
        poll_interval_ms: int = 1000,
        stop_event: threading.Event | None = None,
    ) -> None:
        """Subscribe to topic with consumer group."""
        subscribe(
            topic,
            group,
            handler,
            base_url=self._base_url,
            timeout_ms=timeout_ms,
            poll_interval_ms=poll_interval_ms,
            stop_event=stop_event,
        )

    def list_topics(self) -> list[str]:
        """List all topics."""
        url = self._base_url.rstrip("/") + "/topics"
        with httpx.Client(timeout=10.0) as client:
            resp = client.get(url)
            resp.raise_for_status()
            return resp.json().get("topics", [])
