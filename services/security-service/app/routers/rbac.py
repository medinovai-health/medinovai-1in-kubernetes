"""RBAC (Role-Based Access Control) endpoints."""

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import List, Optional

from app.config import get_settings

router = APIRouter(prefix="/rbac", tags=["rbac"])


class Role(BaseModel):
    id: str
    name: str
    description: Optional[str] = None
    permissions: List[str] = []


class Permission(BaseModel):
    id: str
    name: str
    resource: str
    action: str


@router.get("/roles")
async def list_roles():
    """List all available roles."""
    return {
        "roles": [
            {"id": "admin", "name": "Administrator", "permissions": ["*:*"]},
            {"id": "operator", "name": "Infrastructure Operator", "permissions": ["infra:read", "infra:write", "monitoring:read"]},
            {"id": "viewer", "name": "Read Only", "permissions": ["infra:read", "monitoring:read"]},
        ]
    }


@router.get("/permissions")
async def list_permissions():
    """List all available permissions."""
    return {
        "permissions": [
            {"id": "infra:read", "name": "Read Infrastructure", "resource": "infrastructure", "action": "read"},
            {"id": "infra:write", "name": "Modify Infrastructure", "resource": "infrastructure", "action": "write"},
            {"id": "monitoring:read", "name": "View Monitoring", "resource": "monitoring", "action": "read"},
            {"id": "security:admin", "name": "Security Administration", "resource": "security", "action": "admin"},
        ]
    }


@router.post("/check")
async def check_permission(user_id: str, permission: str):
    """Check if a user has a specific permission."""
    # Phase 1: Stub - always allow for infrastructure admins
    # Phase 2: Integrate with Keycloak token introspection
    return {"user_id": user_id, "permission": permission, "granted": True}
