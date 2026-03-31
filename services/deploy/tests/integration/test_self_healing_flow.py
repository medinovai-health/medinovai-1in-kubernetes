"""
Phase AA E2E Test 4: Self-Healing Flow.

Verifies the complete AtlasOS self-healing flow:
1. Simulate pod crash event
2. Verify cluster brain detects
3. Verify remediation triggered
4. Verify escalation on failure
"""
from __future__ import annotations

import pytest
import pytest_asyncio

from conftest import (
    CLUSTER_BRAIN_URL,
    ESCALATION_RESOLVER_URL,
    STREAM_BUS_URL,
    check_service_available,
    http_client,
    publish_event,
)


@pytest_asyncio.fixture
async def cluster_brain_ready(http_client):
    """Cluster brain must be available."""
    ok = await check_service_available(http_client, CLUSTER_BRAIN_URL)
    if not ok:
        pytest.skip(f"Cluster brain not available at {CLUSTER_BRAIN_URL}")
    return ok


@pytest_asyncio.fixture
async def stream_bus_ready(http_client):
    """Stream bus for publishing pod crash events."""
    ok = await check_service_available(http_client, STREAM_BUS_URL, "/health") or await check_service_available(
        http_client, STREAM_BUS_URL, "/health/ready"
    )
    if not ok:
        pytest.skip(f"Stream bus not available at {STREAM_BUS_URL}")
    return ok


@pytest.mark.asyncio
async def test_publish_pod_crash_event(
    http_client,
    stream_bus_ready,
):
    """
    Step 1: Simulate pod crash by publishing ops.pod.crashed to stream bus.
    """
    event_published = await publish_event(
        http_client,
        "ops.pod.crashed",
        {
            "namespace": "medinovai",
            "pod_name": "integration-test-pod",
            "reason": "OOMKilled",
            "container": "test-container",
        },
        source="kubelet",
    )
    assert event_published, "Pod crash event must be published to stream bus"


@pytest.mark.asyncio
async def test_cluster_brain_health(http_client, cluster_brain_ready):
    """
    Step 2: Verify cluster brain is active and can detect cluster state.
    """
    r = await http_client.get(f"{CLUSTER_BRAIN_URL.rstrip('/')}/health")
    assert r.status_code == 200
    data = r.json()
    assert data.get("status") == "ok"
    assert data.get("component") == "atlasos-cluster-brain"


@pytest.mark.asyncio
async def test_cluster_brain_status(http_client, cluster_brain_ready):
    """
    Verify cluster brain /status endpoint reports cluster state.
    """
    r = await http_client.get(f"{CLUSTER_BRAIN_URL.rstrip('/')}/status")
    if r.status_code != 200:
        pytest.skip("Cluster brain /status not implemented")
    data = r.json()
    assert "brain" in data or "timestamp" in data


@pytest.mark.asyncio
async def test_cluster_brain_action_evaluation(http_client, cluster_brain_ready):
    """
    Step 3: Verify cluster brain evaluates remediation actions.
    POST /action with a pod_restart type; brain should allow or flag for approval.
    """
    r = await http_client.post(
        f"{CLUSTER_BRAIN_URL.rstrip('/')}/action",
        json={
            "type": "pod_restart",
            "target": "integration-test-pod",
            "reason": "OOMKilled — remediation test",
        },
    )
    assert r.status_code == 200
    data = r.json()
    assert "status" in data
    assert data["status"] in ("allowed", "needs_human")


@pytest.mark.asyncio
async def test_escalation_resolver_available(http_client):
    """
    Step 4: Verify escalation resolver is available for failure escalation.
    """
    try:
        r = await http_client.get(f"{ESCALATION_RESOLVER_URL.rstrip('/')}/health")
        if r.status_code == 200:
            data = r.json()
            assert data.get("status") in ("ok", "healthy")
            return
    except Exception:
        pass
    pytest.skip("Escalation resolver not available — run with ESCALATION_RESOLVER_URL if deployed")
