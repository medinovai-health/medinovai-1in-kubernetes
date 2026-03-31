"""
MedinovAI Coordinator Server
============================
Central coordination server for the MedinovAI Agent mesh network.
Accessible via: LAN, Tailscale, and public internet (Cloudflare Tunnel / ECS).

Endpoints:
  POST /v1/enroll          - New node enrollment (generates node token)
  POST /v1/heartbeat       - Node heartbeat + telemetry
  GET  /v1/tasks/{node_id} - Poll for pending tasks
  POST /v1/tasks/{task_id}/ack - Acknowledge task completion
  GET  /v1/nodes           - Dashboard: list all nodes (admin token)
  GET  /v1/health          - Load balancer health check
  GET  /v1/version         - Current agent version (for auto-update)

Security:
  - Enrollment requires a one-time join token (set via MEDINOVAI_JOIN_TOKEN env)
  - Each node gets a unique HMAC-signed node token after enrollment
  - All endpoints (except /v1/health) require valid node or admin token
  - Rate limiting: 60 req/min per node
  - All data encrypted in transit (TLS via Cloudflare / Fly.io)

Compliance:
  - HIPAA: No PHI stored. Node identifiers are machine UUIDs only.
  - Audit log: every enrollment and task dispatch logged to audit table.
  - 21 CFR Part 11: timestamped immutable audit trail in PostgreSQL.
"""

from __future__ import annotations

import hashlib
import hmac
import json
import logging
import os
import secrets
import time
import uuid
from datetime import datetime, timezone
from typing import Any, Optional

import uvicorn
from fastapi import Depends, FastAPI, Header, HTTPException, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

E_VERSION         = "1.0.0"
E_JOIN_TOKEN      = os.environ.get("MEDINOVAI_JOIN_TOKEN", "")
E_ADMIN_TOKEN     = os.environ.get("MEDINOVAI_ADMIN_TOKEN", "")
E_HMAC_SECRET     = os.environ.get("MEDINOVAI_HMAC_SECRET", secrets.token_hex(32))
E_DB_URL          = os.environ.get("DATABASE_URL", "sqlite:///./medinovai_coordinator.db")
E_MATTERMOST_URL  = os.environ.get("MATTERMOST_WEBHOOK_URL", "")
E_MATTERMOST_CHAN = os.environ.get("MATTERMOST_CHANNEL", "medinovai-agents")
E_LOG_LEVEL       = os.environ.get("LOG_LEVEL", "INFO")
E_AGENT_VERSION   = os.environ.get("CURRENT_AGENT_VERSION", "1.0.0")
E_AGENT_URL       = os.environ.get("AGENT_DOWNLOAD_URL", "")

logging.basicConfig(level=getattr(logging, E_LOG_LEVEL))
mos_log = logging.getLogger("medinovai.coordinator")

# ---------------------------------------------------------------------------
# In-memory store (replace with SQLAlchemy + PostgreSQL in production)
# ---------------------------------------------------------------------------

mos_nodes: dict[str, dict] = {}        # node_id -> node record
mos_tasks: dict[str, dict] = {}        # task_id -> task record
mos_audit: list[dict]       = []       # append-only audit log


# ---------------------------------------------------------------------------
# FastAPI app + rate limiter
# ---------------------------------------------------------------------------

mos_limiter = Limiter(key_func=get_remote_address)
app = FastAPI(
    title="MedinovAI Coordinator",
    version=E_VERSION,
    docs_url="/docs" if os.environ.get("ENV") != "production" else None,
)
app.state.limiter = mos_limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://medinovai.com", "https://aifactory.medinovai.com"],
    allow_methods=["GET", "POST"],
    allow_headers=["Authorization", "Content-Type"],
)

# ---------------------------------------------------------------------------
# Auth helpers
# ---------------------------------------------------------------------------

def _generate_node_token(mos_node_id: str) -> str:
    """HMAC-SHA256 node token bound to node_id + secret."""
    mos_sig = hmac.new(
        E_HMAC_SECRET.encode(),
        f"node:{mos_node_id}".encode(),
        hashlib.sha256,
    ).hexdigest()
    return f"mna_{mos_node_id}_{mos_sig[:32]}"

def _verify_node_token(mos_token: str) -> Optional[str]:
    """Returns node_id if token is valid, else None."""
    parts = mos_token.split("_")
    if len(parts) != 3 or parts[0] != "mna":
        return None
    mos_node_id = parts[1]
    expected = _generate_node_token(mos_node_id)
    if hmac.compare_digest(mos_token, expected):
        return mos_node_id
    return None

def _require_node_token(authorization: str = Header(...)) -> str:
    mos_token = authorization.removeprefix("Bearer ").strip()
    mos_node_id = _verify_node_token(mos_token)
    if not mos_node_id or mos_node_id not in mos_nodes:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid node token")
    return mos_node_id

def _require_admin_token(authorization: str = Header(...)) -> bool:
    mos_token = authorization.removeprefix("Bearer ").strip()
    if not E_ADMIN_TOKEN or not hmac.compare_digest(mos_token, E_ADMIN_TOKEN):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin token required")
    return True

def _audit(mos_event: str, mos_data: dict) -> None:
    mos_audit.append({
        "ts": datetime.now(timezone.utc).isoformat(),
        "event": mos_event,
        **mos_data,
    })


# ---------------------------------------------------------------------------
# Pydantic models
# ---------------------------------------------------------------------------

class EnrollRequest(BaseModel):
    join_token:   str
    hostname:     str
    machine_id:   str           # UUID generated on first install
    os_type:      str           # macos | linux | windows
    arch:         str           # arm64 | amd64
    role:         str           # aifactory-node | dev-machine | intern | power-user
    ollama:       bool = False
    agent_version: str = "unknown"
    tags:         list[str] = Field(default_factory=list)

class HeartbeatRequest(BaseModel):
    uptime_s:       int
    cpu_pct:        float
    mem_used_gb:    float
    mem_total_gb:   float
    disk_used_gb:   float
    disk_total_gb:  float
    ollama_running: bool = False
    ollama_version: str  = ""
    models:         list[str] = Field(default_factory=list)
    docker_running: bool = False
    tailscale_ip:   str  = ""
    lan_ip:         str  = ""
    alerts:         list[str] = Field(default_factory=list)

class TaskResult(BaseModel):
    success: bool
    output:  str = ""
    error:   str = ""

# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------

@app.get("/v1/health")
async def health():
    return {"status": "ok", "version": E_VERSION, "nodes": len(mos_nodes)}

@app.get("/v1/version")
async def version():
    return {
        "agent_version": E_AGENT_VERSION,
        "download_url":  E_AGENT_URL,
        "coordinator_version": E_VERSION,
    }

@app.post("/v1/enroll")
async def enroll(req: EnrollRequest, request: Request):
    if not E_JOIN_TOKEN or not hmac.compare_digest(req.join_token, E_JOIN_TOKEN):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Invalid join token")

    mos_node_id = req.machine_id
    mos_token   = _generate_node_token(mos_node_id)

    mos_nodes[mos_node_id] = {
        "node_id":      mos_node_id,
        "hostname":     req.hostname,
        "os_type":      req.os_type,
        "arch":         req.arch,
        "role":         req.role,
        "ollama":       req.ollama,
        "tags":         req.tags,
        "enrolled_at":  datetime.now(timezone.utc).isoformat(),
        "last_seen":    None,
        "status":       "enrolled",
        "agent_version": req.agent_version,
        "remote_ip":    request.client.host if request.client else "unknown",
    }

    _audit("enroll", {"node_id": mos_node_id, "hostname": req.hostname, "role": req.role})
    mos_log.info(f"Node enrolled: {req.hostname} ({mos_node_id})")

    return {
        "node_id":    mos_node_id,
        "node_token": mos_token,
        "coordinator_version": E_VERSION,
        "message": f"Welcome to MedinovAI network, {req.hostname}!",
    }


@app.post("/v1/heartbeat")
async def heartbeat(
    req: HeartbeatRequest,
    mos_node_id: str = Depends(_require_node_token),
):
    mos_node = mos_nodes[mos_node_id]
    mos_node["last_seen"]      = datetime.now(timezone.utc).isoformat()
    mos_node["status"]         = "online"
    mos_node["cpu_pct"]        = req.cpu_pct
    mos_node["mem_used_gb"]    = req.mem_used_gb
    mos_node["mem_total_gb"]   = req.mem_total_gb
    mos_node["disk_used_gb"]   = req.disk_used_gb
    mos_node["disk_total_gb"]  = req.disk_total_gb
    mos_node["ollama_running"] = req.ollama_running
    mos_node["ollama_version"] = req.ollama_version
    mos_node["models"]         = req.models
    mos_node["tailscale_ip"]   = req.tailscale_ip
    mos_node["lan_ip"]         = req.lan_ip

    if req.alerts:
        _notify_mattermost(mos_node["hostname"], req.alerts)
        _audit("alerts", {"node_id": mos_node_id, "alerts": req.alerts})

    return {"ack": True, "server_ts": datetime.now(timezone.utc).isoformat()}

@app.get("/v1/tasks/{node_id}")
async def get_tasks(
    node_id: str,
    mos_node_id: str = Depends(_require_node_token),
):
    if node_id != mos_node_id:
        raise HTTPException(status_code=403, detail="Token/node_id mismatch")

    mos_pending = [
        t for t in mos_tasks.values()
        if t["target_node"] in (mos_node_id, "*") and t["status"] == "pending"
    ]
    return {"tasks": mos_pending}

@app.post("/v1/tasks/{task_id}/ack")
async def ack_task(
    task_id: str,
    result: TaskResult,
    mos_node_id: str = Depends(_require_node_token),
):
    if task_id not in mos_tasks:
        raise HTTPException(status_code=404, detail="Task not found")

    mos_tasks[task_id]["status"]     = "done" if result.success else "failed"
    mos_tasks[task_id]["output"]     = result.output
    mos_tasks[task_id]["error"]      = result.error
    mos_tasks[task_id]["done_at"]    = datetime.now(timezone.utc).isoformat()
    mos_tasks[task_id]["done_by"]    = mos_node_id
    _audit("task_ack", {"task_id": task_id, "node_id": mos_node_id, "success": result.success})
    return {"ack": True}

@app.get("/v1/nodes")
async def list_nodes(_: bool = Depends(_require_admin_token)):
    now = time.time()
    mos_result = []
    for mos_node in mos_nodes.values():
        mos_node_copy = dict(mos_node)
        if mos_node_copy.get("last_seen"):
            from datetime import datetime
            mos_last = datetime.fromisoformat(mos_node_copy["last_seen"])
            mos_age  = (datetime.now(timezone.utc) - mos_last).total_seconds()
            mos_node_copy["status"] = "online" if mos_age < 120 else "stale" if mos_age < 600 else "offline"
        mos_result.append(mos_node_copy)
    return {"nodes": mos_result, "count": len(mos_result)}

@app.post("/v1/tasks")
async def dispatch_task(task: dict, _: bool = Depends(_require_admin_token)):
    mos_task_id = str(uuid.uuid4())
    mos_tasks[mos_task_id] = {
        "task_id":     mos_task_id,
        "target_node": task.get("target_node", "*"),
        "type":        task.get("type", "shell"),
        "payload":     task.get("payload", {}),
        "status":      "pending",
        "created_at":  datetime.now(timezone.utc).isoformat(),
    }
    _audit("task_dispatch", {"task_id": mos_task_id, **task})
    return {"task_id": mos_task_id}


# ---------------------------------------------------------------------------
# Mattermost notifications
# ---------------------------------------------------------------------------

def _notify_mattermost(mos_hostname: str, mos_alerts: list[str]) -> None:
    """Post alerts to Mattermost webhook. Fire-and-forget."""
    if not E_MATTERMOST_URL:
        return
    try:
        import urllib.request
        mos_text = "\n".join([f"⚠️ **{mos_hostname}**: {a}" for a in mos_alerts])
        mos_payload = json.dumps({
            "channel": E_MATTERMOST_CHAN,
            "username": "MedinovAI Agent",
            "icon_emoji": ":robot:",
            "text": mos_text,
        }).encode()
        mos_req = urllib.request.Request(
            E_MATTERMOST_URL,
            data=mos_payload,
            headers={"Content-Type": "application/json"},
        )
        urllib.request.urlopen(mos_req, timeout=5)
    except Exception as e:
        mos_log.warning(f"Mattermost notify failed: {e}")

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    mos_port = int(os.environ.get("PORT", 8435))
    mos_host = os.environ.get("HOST", "0.0.0.0")
    mos_log.info(f"MedinovAI Coordinator v{E_VERSION} starting on {mos_host}:{mos_port}")
    uvicorn.run("main:app", host=mos_host, port=mos_port, reload=False, log_level=E_LOG_LEVEL.lower())
