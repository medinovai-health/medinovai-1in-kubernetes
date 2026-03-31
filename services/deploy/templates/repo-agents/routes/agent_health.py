"""
AtlasOS Agent Health Routes for FastAPI.

Exposes GET /agent/status and GET /agent/health for agent discovery and health checks.

Environment:
  AGENT_STATE_FILE - Path to JSON state file (default: ./state/agent_state.json)
  AGENT_ID         - Agent identifier (fallback when state file absent)
  AGENT_NAME       - Human-readable agent name
  AGENT_VERSION    - Agent version string
  AGENT_CAPABILITIES - Comma-separated capabilities (optional)
"""
from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from pathlib import Path

from fastapi import APIRouter

router = APIRouter(prefix="/agent", tags=["agent"])

AGENT_STATE_FILE = os.environ.get("AGENT_STATE_FILE", "state/agent_state.json")
AGENT_ID = os.environ.get("AGENT_ID", "")
AGENT_NAME = os.environ.get("AGENT_NAME", "AtlasOS Agent")
AGENT_VERSION = os.environ.get("AGENT_VERSION", "1.0.0")
AGENT_CAPABILITIES = [
    c.strip() for c in (os.environ.get("AGENT_CAPABILITIES", "") or "").split(",") if c.strip()
]


def _load_state() -> dict:
    """Load agent state from file or return empty dict."""
    path = Path(AGENT_STATE_FILE)
    if not path.exists():
        return {}
    try:
        with path.open() as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError):
        return {}


def _agent_info() -> dict:
    """Build agent info from state file or env vars."""
    state = _load_state()
    return {
        "agent_id": state.get("agent_id") or AGENT_ID or "unknown",
        "name": state.get("name") or AGENT_NAME,
        "version": state.get("version") or AGENT_VERSION,
        "capabilities": state.get("capabilities") or AGENT_CAPABILITIES,
        "status": state.get("status", "operational"),
        "last_heartbeat": state.get("last_heartbeat"),
        "started_at": state.get("started_at"),
    }


@router.get("/status")
async def get_agent_status() -> dict:
    """
    Return agent info from state file or env vars.
    Used for agent discovery and registry.
    """
    info = _agent_info()
    info["timestamp"] = datetime.now(timezone.utc).isoformat()
    return info


@router.get("/health")
async def get_agent_health() -> dict:
    """
    Return agent health status for load balancers and health checks.
    """
    info = _agent_info()
    status = info.get("status", "operational")
    healthy = status in ("operational", "ready", "running")

    return {
        "status": "healthy" if healthy else "degraded",
        "agent_id": info["agent_id"],
        "version": info["version"],
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "details": {
            "operational_status": status,
            "capabilities_count": len(info.get("capabilities", [])),
        },
    }
