"""Zero-touch provisioning endpoints."""

from fastapi import APIRouter
from pydantic import BaseModel
from typing import Optional, List

router = APIRouter(prefix="/zero-touch", tags=["zero-touch"])


class ProvisionRequest(BaseModel):
    user_id: str
    email: str
    tenant_id: Optional[str] = "default"
    requested_roles: List[str] = []


@router.post("/provision")
async def provision_user(request: ProvisionRequest):
    """Provision a new user with zero-touch workflow."""
    # Phase 1: Stub - would create user in Keycloak and assign roles
    return {
        "status": "provisioned",
        "user_id": request.user_id,
        "email": request.email,
        "tenant_id": request.tenant_id,
        "assigned_roles": request.requested_roles,
        "activation_url": f"/activate?user={request.user_id}",
    }


@router.get("/status/{user_id}")
async def get_provisioning_status(user_id: str):
    """Get provisioning status for a user."""
    return {
        "user_id": user_id,
        "status": "active",
        "provisioned_at": "2024-01-01T00:00:00Z",
    }
