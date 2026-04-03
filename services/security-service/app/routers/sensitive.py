"""Sensitive action approval workflow."""

from fastapi import APIRouter
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime, timezone

router = APIRouter(prefix="/sensitive", tags=["sensitive"])


class SensitiveActionRequest(BaseModel):
    user_id: str
    action: str
    resource: str
    justification: str
    approvers: Optional[List[str]] = None


@router.post("/request")
async def request_sensitive_action(request: SensitiveActionRequest):
    """Request approval for a sensitive action."""
    # Phase 1: Stub - auto-approve for infrastructure
    return {
        "request_id": f"sa-{datetime.now(timezone.utc).timestamp()}",
        "status": "approved",
        "action": request.action,
        "resource": request.resource,
        "approved_by": "system",
        "expires_at": (datetime.now(timezone.utc)).isoformat(),
    }


@router.get("/pending/{user_id}")
async def get_pending_approvals(user_id: str):
    """Get pending sensitive action approvals for a user."""
    return {"user_id": user_id, "pending": []}
