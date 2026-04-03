"""Audit logging endpoints."""

import logging
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Request
from pydantic import BaseModel

from app.config import get_settings

router = APIRouter(prefix="/audit", tags=["audit"])
logger = logging.getLogger("medinovai.security.audit")


class AuditEvent(BaseModel):
    timestamp: str
    actor_id: str
    action: str
    resource: str
    resource_id: Optional[str] = None
    tenant_id: Optional[str] = None
    details: Optional[dict] = None
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None


@router.post("/log")
async def log_audit_event(event: AuditEvent, request: Request):
    """Log an audit event."""
    settings = get_settings()
    
    # Add request metadata
    event.ip_address = request.client.host if request.client else None
    event.user_agent = request.headers.get("user-agent")
    
    # Log to structured logging
    logger.info(
        "audit_event",
        extra={
            "timestamp": event.timestamp or datetime.now(timezone.utc).isoformat(),
            "actor_id": event.actor_id,
            "action": event.action,
            "resource": event.resource,
            "resource_id": event.resource_id,
            "tenant_id": event.tenant_id,
            "details": event.details,
            "ip_address": event.ip_address,
            "user_agent": event.user_agent,
        }
    )
    
    return {"status": "logged", "event_id": f"audit-{datetime.now(timezone.utc).timestamp()}"}


@router.get("/events")
async def query_audit_events(
    actor_id: Optional[str] = None,
    resource: Optional[str] = None,
    action: Optional[str] = None,
    limit: int = 100
):
    """Query audit events (stub - would query database in production)."""
    return {
        "events": [],
        "total": 0,
        "query": {"actor_id": actor_id, "resource": resource, "action": action, "limit": limit}
    }
