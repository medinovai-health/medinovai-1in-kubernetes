"""Break-glass access endpoints for emergency scenarios."""

from fastapi import APIRouter
from pydantic import BaseModel
from typing import Optional
from datetime import datetime, timezone

router = APIRouter(prefix="/break-glass", tags=["break-glass"])


class BreakGlassRequest(BaseModel):
    user_id: str
    reason: str
    requested_access: str
    ticket_id: Optional[str] = None


@router.post("/request")
async def request_break_glass_access(request: BreakGlassRequest):
    """Request emergency break-glass access."""
    # Phase 1: Stub - log and approve for infrastructure
    # Phase 2: Implement approval workflow with notifications
    return {
        "request_id": f"bg-{datetime.now(timezone.utc).timestamp()}",
        "status": "approved",
        "user_id": request.user_id,
        "reason": request.reason,
        "expires_at": (datetime.now(timezone.utc)).isoformat(),
        "granted_access": request.requested_access,
    }


@router.get("/status/{request_id}")
async def get_break_glass_status(request_id: str):
    """Get status of a break-glass request."""
    return {
        "request_id": request_id,
        "status": "active",
        "expires_at": (datetime.now(timezone.utc)).isoformat(),
    }
