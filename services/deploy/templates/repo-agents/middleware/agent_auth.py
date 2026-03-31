"""
AtlasOS Agent Auth Middleware for FastAPI.

Uses stdlib only (no extra deps). For async-safe RBAC calls, run in executor.

Validates X-AtlasOS-Agent-Id header against RBAC Guard.
Logs agent actions. Returns 401 when auth is required and validation fails.

Environment:
  AGENT_AUTH_REQUIRED    - If 'true', reject requests without valid agent ID (default: false)
  ATLASOS_RBAC_GUARD_URL - Base URL for RBAC Guard validation (e.g. http://rbac-guard:8080)
  ATLASOS_AGENT_ID       - Optional; allow bypass when header matches this (dev/single-agent)
"""
from __future__ import annotations

import asyncio
import json
import logging
import os
import re
import ssl
from typing import Callable
from urllib.error import URLError
from urllib.request import Request as UrlRequest, urlopen

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse, Response

logger = logging.getLogger(__name__)

AGENT_HEADER = "X-AtlasOS-Agent-Id"
AGENT_AUTH_REQUIRED = os.environ.get("AGENT_AUTH_REQUIRED", "false").lower() in ("true", "1", "yes")
RBAC_GUARD_URL = os.environ.get("ATLASOS_RBAC_GUARD_URL", "").rstrip("/")
BYPASS_AGENT_ID = os.environ.get("ATLASOS_AGENT_ID", "")
VALID_AGENT_ID_PATTERN = re.compile(r"^[a-zA-Z0-9][a-zA-Z0-9_-]{0,62}$")


def is_valid_agent_id_format(agent_id: str) -> bool:
    """Validate agent ID format (1–63 chars, alphanumeric, dash, underscore)."""
    return bool(agent_id and VALID_AGENT_ID_PATTERN.match(agent_id))


async def validate_agent_with_rbac(agent_id: str) -> bool:
    """
    Validate agent ID against RBAC Guard.
    Returns True if agent is authorized, False otherwise.
    """
    if not RBAC_GUARD_URL:
        logger.warning("ATLASOS_RBAC_GUARD_URL not set; skipping RBAC validation")
        return True

    url = f"{RBAC_GUARD_URL}/api/v1/agents/validate"
    params = {"agent_id": agent_id}

    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            r = await client.get(url, params=params)
            if r.status_code == 200:
                data = r.json()
                return data.get("authorized", False)
            logger.warning("RBAC Guard returned %s for agent %s: %s", r.status_code, agent_id, r.text[:200])
            return False
    except httpx.RequestError as e:
        logger.error("RBAC Guard unreachable for agent %s: %s", agent_id, e)
        return False


async def agent_auth_middleware_handler(request: Request, call_next: Callable) -> Response:
    """Core handler for agent auth middleware."""
    agent_id = request.headers.get(AGENT_HEADER, "").strip()

    # Skip validation for health/status endpoints
    path = request.scope.get("path", "")
    if path in ("/agent/health", "/agent/status", "/health", "/ready"):
        return await call_next(request)

    # Dev bypass: single configured agent
    if BYPASS_AGENT_ID and agent_id == BYPASS_AGENT_ID:
        logger.debug("Agent %s allowed via ATLASOS_AGENT_ID bypass", agent_id)
        response = await call_next(request)
        _log_agent_action(request, agent_id, response.status_code)
        return response

    if not agent_id:
        if AGENT_AUTH_REQUIRED:
            logger.warning("Rejected request: missing %s", AGENT_HEADER)
            return JSONResponse(
                status_code=401,
                content={
                    "error": "unauthorized",
                    "message": f"Missing required header: {AGENT_HEADER}",
                },
            )
        return await call_next(request)

    if not is_valid_agent_id_format(agent_id):
        if AGENT_AUTH_REQUIRED:
            logger.warning("Rejected request: invalid agent ID format: %s", agent_id[:20])
            return JSONResponse(
                status_code=401,
                content={
                    "error": "unauthorized",
                    "message": "Invalid agent ID format",
                },
            )
        return await call_next(request)

    authorized = await validate_agent_with_rbac(agent_id)
    if not authorized and AGENT_AUTH_REQUIRED:
        logger.warning("Rejected request: agent %s not authorized by RBAC", agent_id)
        return JSONResponse(
            status_code=401,
            content={
                "error": "unauthorized",
                "message": "Agent not authorized",
            },
        )

    response = await call_next(request)
    _log_agent_action(request, agent_id, response.status_code)
    return response


def _log_agent_action(request: Request, agent_id: str, status_code: int) -> None:
    """Log agent action (method, path, agent_id, status). No PHI."""
    method = request.scope.get("method", "")
    path = request.scope.get("path", "")
    logger.info(
        "agent_action agent_id=%s method=%s path=%s status=%d",
        agent_id,
        method,
        path,
        status_code,
    )


class AgentAuthMiddleware(BaseHTTPMiddleware):
    """FastAPI/Starlette middleware for AtlasOS agent auth."""

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        return await agent_auth_middleware_handler(request, call_next)
