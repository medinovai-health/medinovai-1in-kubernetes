"""
Phase AA: AtlasOS Universal Agent OS — Shared Integration Test Fixtures.

Provides service URL configuration, test user creation/cleanup,
event publishing helpers, and wait-for-event utilities.
"""
from __future__ import annotations

import asyncio
import os
import time
import uuid
from datetime import datetime, timezone
from typing import Any, AsyncGenerator, Callable

import httpx
import pytest
import pytest_asyncio

# ─── Service URL Configuration ─────────────────────────────────────────────
# Override via env vars for local/Docker/K8s testing.
# Defaults assume port-forward from K8s or Docker Compose local mapping.

def _url(env_key: str, default: str) -> str:
    return os.environ.get(env_key, default).rstrip("/")

# Core AtlasOS / MedinovAI services
SECURITY_SERVICE_URL = _url("SECURITY_SERVICE_URL", "http://localhost:9000")
STREAM_BUS_URL = _url("STREAM_BUS_URL", "http://localhost:3000")
AGENT_PROVISIONER_URL = _url("AGENT_PROVISIONER_URL", "http://localhost:3111")
REGISTRY_URL = _url("REGISTRY_URL", "http://localhost:8080")
RBAC_GUARD_URL = _url("RBAC_GUARD_URL", "http://localhost:3113")
MCP_DEPLOY_URL = _url("MCP_DEPLOY_URL", "http://localhost:3120")
CLUSTER_BRAIN_URL = _url("CLUSTER_BRAIN_URL", "http://localhost:8100")
AGENT_CONFIG_API_URL = _url("AGENT_CONFIG_API_URL", "http://localhost:3102")
ESCALATION_RESOLVER_URL = _url("ESCALATION_RESOLVER_URL", "http://localhost:3117")
WEBHOOK_RECEIVER_URL = _url("WEBHOOK_RECEIVER_URL", "http://localhost:3121")
NOTIFICATION_SERVICE_URL = _url("NOTIFICATION_SERVICE_URL", "http://localhost:8080")

# Timeouts
HTTP_TIMEOUT = float(os.environ.get("INTEGRATION_HTTP_TIMEOUT", "15"))
EVENT_PROPAGATION_TIMEOUT = float(os.environ.get("EVENT_PROPAGATION_TIMEOUT", "10"))
EVENT_POLL_INTERVAL = float(os.environ.get("EVENT_POLL_INTERVAL", "0.5"))


# ─── HTTP Client ────────────────────────────────────────────────────────────

@pytest_asyncio.fixture
async def http_client() -> AsyncGenerator[httpx.AsyncClient, None]:
    """Async HTTP client with default timeout."""
    async with httpx.AsyncClient(timeout=HTTP_TIMEOUT) as client:
        yield client


@pytest.fixture
def http_client_sync() -> httpx.Client:
    """Sync HTTP client for tests that need it."""
    return httpx.Client(timeout=HTTP_TIMEOUT)


# ─── Service Availability Helpers ───────────────────────────────────────────

async def check_service_available(client: httpx.AsyncClient, url: str, path: str = "/health") -> bool:
    """Check if a service is reachable at url + path."""
    try:
        r = await client.get(f"{url.rstrip('/')}{path}")
        return r.status_code == 200
    except Exception:
        return False


def is_service_available_sync(client: httpx.Client, url: str, path: str = "/health") -> bool:
    """Sync check if a service is reachable."""
    try:
        r = client.get(f"{url.rstrip('/')}{path}")
        return r.status_code == 200
    except Exception:
        return False


# ─── Test User Creation/Cleanup ──────────────────────────────────────────────

def make_test_user_id() -> str:
    """Generate a unique test user ID to avoid collisions."""
    return f"test-user-{uuid.uuid4().hex[:12]}"


def make_test_user_payload() -> dict[str, Any]:
    """Create a minimal user payload for IAM/security service."""
    user_id = make_test_user_id()
    return {
        "id": user_id,
        "email": f"{user_id}@integration-test.medinov.ai",
        "username": user_id,
        "roles": ["user"],
        "tenant_id": "integration-test-tenant",
        "created_at": datetime.now(timezone.utc).isoformat(),
    }


# ─── Event Publishing Helper ─────────────────────────────────────────────────

async def publish_event(
    client: httpx.AsyncClient,
    event_type: str,
    payload: dict[str, Any],
    source: str = "integration-test",
) -> bool:
    """
    Publish an event to the stream bus.
    Stream bus expects: POST /events with { type, source, payload, timestamp }.
    """
    event = {
        "type": event_type,
        "source": source,
        "payload": payload,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
    url = f"{STREAM_BUS_URL.rstrip('/')}/events"
    try:
        r = await client.post(url, json=event)
        return r.status_code in (200, 201, 202)
    except Exception:
        return False


def publish_event_sync(
    client: httpx.Client,
    event_type: str,
    payload: dict[str, Any],
    source: str = "integration-test",
) -> bool:
    """Sync version of publish_event."""
    event = {
        "type": event_type,
        "source": source,
        "payload": payload,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
    url = f"{STREAM_BUS_URL.rstrip('/')}/events"
    try:
        r = client.post(url, json=event)
        return r.status_code in (200, 201, 202)
    except Exception:
        return False


# ─── Wait-for-Event Helper ───────────────────────────────────────────────────

async def wait_for_event(
    predicate: Callable[[], Any],
    timeout: float = EVENT_PROPAGATION_TIMEOUT,
    interval: float = EVENT_POLL_INTERVAL,
) -> bool:
    """
    Poll predicate until it returns truthy or timeout.
    Use for verifying event propagation (e.g. agent provisioned, registry updated).
    """
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            result = predicate()
            if asyncio.iscoroutine(result):
                result = await result
            if result:
                return True
        except Exception:
            pass
        await asyncio.sleep(interval)
    return False


# ─── Fixtures for Individual Tests ──────────────────────────────────────────

@pytest_asyncio.fixture
async def stream_bus_available(http_client: httpx.AsyncClient) -> bool:
    """Check if stream bus is available; skip-dependent tests use this."""
    return await check_service_available(http_client, STREAM_BUS_URL, "/health/ready") or await check_service_available(
        http_client, STREAM_BUS_URL, "/health"
    )


@pytest_asyncio.fixture
async def mcp_deploy_available(http_client: httpx.AsyncClient) -> bool:
    """Check if MCP-deploy is available."""
    return await check_service_available(http_client, MCP_DEPLOY_URL)


@pytest_asyncio.fixture
async def cluster_brain_available(http_client: httpx.AsyncClient) -> bool:
    """Check if cluster brain is available."""
    return await check_service_available(http_client, CLUSTER_BRAIN_URL)


@pytest.fixture
def test_user() -> dict[str, Any]:
    """Provide a test user payload for registration/role tests."""
    return make_test_user_payload()
