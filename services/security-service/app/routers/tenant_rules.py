"""Tenant-specific security rules."""

from fastapi import APIRouter
from pydantic import BaseModel
from typing import Optional, List, Dict, Any

router = APIRouter(prefix="/tenant-rules", tags=["tenant-rules"])


class TenantRule(BaseModel):
    id: str
    tenant_id: str
    rule_type: str
    configuration: Dict[str, Any]
    enabled: bool = True


@router.get("/{tenant_id}")
async def get_tenant_rules(tenant_id: str):
    """Get all security rules for a tenant."""
    return {
        "tenant_id": tenant_id,
        "rules": [
            {
                "id": "mfa-required",
                "rule_type": "mfa",
                "configuration": {"required": True, "methods": ["totp"]},
                "enabled": True,
            },
            {
                "id": "session-timeout",
                "rule_type": "session",
                "configuration": {"timeout_minutes": 30},
                "enabled": True,
            },
        ],
    }


@router.post("/{tenant_id}")
async def create_tenant_rule(tenant_id: str, rule: TenantRule):
    """Create a new security rule for a tenant."""
    return {"status": "created", "rule_id": rule.id, "tenant_id": tenant_id}
