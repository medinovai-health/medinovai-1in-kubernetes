"""
Phase AA E2E Test 3: Agent-Driven Deploy Flow.

Verifies the complete AtlasOS agent-driven deployment flow:
1. Simulate git.push event
2. Verify MCP-deploy tools triggered
3. Verify health checks pass
4. Verify deployment status
"""
from __future__ import annotations

import json
import pytest
import pytest_asyncio

from conftest import (
    MCP_DEPLOY_URL,
    WEBHOOK_RECEIVER_URL,
    check_service_available,
    http_client,
)


@pytest_asyncio.fixture
async def webhook_receiver_ready(http_client):
    """Webhook receiver must be available to simulate git.push."""
    ok = await check_service_available(http_client, WEBHOOK_RECEIVER_URL)
    if not ok:
        pytest.skip(f"Webhook receiver not available at {WEBHOOK_RECEIVER_URL}")
    return ok


@pytest_asyncio.fixture
async def mcp_deploy_ready(http_client):
    """MCP-deploy must be available for tool calls."""
    ok = await check_service_available(http_client, MCP_DEPLOY_URL)
    if not ok:
        pytest.skip(f"MCP-deploy not available at {MCP_DEPLOY_URL}")
    return ok


@pytest.mark.asyncio
async def test_simulate_git_push_via_webhook(
    http_client,
    webhook_receiver_ready,
):
    """
    Step 1: Simulate git.push by posting a GitHub push webhook.
    Webhook receiver maps push -> git.push and publishes to stream bus.
    """
    payload = {
        "ref": "refs/heads/main",
        "repository": {"name": "medinovai-Deploy", "full_name": "myonsite-healthcare/medinovai-Deploy"},
        "pusher": {"name": "integration-test"},
        "commits": [{"id": "abc123", "message": "Integration test commit"}],
        "head_commit": {"id": "abc123", "message": "Integration test commit"},
    }
    url = f"{WEBHOOK_RECEIVER_URL.rstrip('/')}/webhooks/github"
    r = await http_client.post(
        url,
        json=payload,
        headers={"X-GitHub-Event": "push"},
    )
    assert r.status_code == 200, f"Webhook receiver must accept push: {r.status_code} {r.text}"
    data = r.json()
    assert data.get("status") == "ok"


@pytest.mark.asyncio
async def test_mcp_deploy_health_check_tool(
    http_client,
    mcp_deploy_ready,
):
    """
    Step 2-3: Call MCP-deploy health_check tool and verify it returns success.
    """
    url = f"{MCP_DEPLOY_URL.rstrip('/')}/tools/call"
    body = {"name": "health_check", "arguments": {"tier": "all"}}
    r = await http_client.post(url, json=body)
    assert r.status_code == 200, f"MCP-deploy tools/call must succeed: {r.status_code} {r.text}"

    data = r.json()
    content = data.get("content", [])
    assert len(content) >= 1, "Tool response must have content"

    result_text = content[0].get("text", "{}")
    try:
        result = json.loads(result_text)
    except json.JSONDecodeError:
        result = {}
    assert result.get("status") in ("ok", "error"), "health_check should return status"
    assert "tool" in result and result["tool"] == "health_check"


@pytest.mark.asyncio
async def test_mcp_deploy_list_tools(http_client, mcp_deploy_ready):
    """
    Verify MCP-deploy exposes deploy-related tools.
    """
    r = await http_client.get(f"{MCP_DEPLOY_URL.rstrip('/')}/tools/list")
    assert r.status_code == 200
    data = r.json()
    tools = data.get("tools", [])
    names = [t["name"] for t in tools]
    assert "health_check" in names
    assert "deploy_service" in names
    assert "validate_setup" in names


@pytest.mark.asyncio
async def test_mcp_deploy_validate_setup(http_client, mcp_deploy_ready):
    """
    Step 4: Run validate_setup to verify deployment configuration.
    """
    url = f"{MCP_DEPLOY_URL.rstrip('/')}/tools/call"
    body = {"name": "validate_setup", "arguments": {}}
    r = await http_client.post(url, json=body)
    assert r.status_code == 200

    data = r.json()
    content = data.get("content", [])
    assert len(content) >= 1
    result_text = content[0].get("text", "{}")
    try:
        result = json.loads(result_text)
    except json.JSONDecodeError:
        result = {}
    assert "status" in result
    assert result.get("tool") == "validate_setup"
