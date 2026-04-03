"""Policy engine endpoints."""

from fastapi import APIRouter
from pydantic import BaseModel
from typing import Optional, Dict, Any, List

router = APIRouter(prefix="/policy", tags=["policy"])


class PolicyRequest(BaseModel):
    user_id: str
    action: str
    resource: str
    resource_attributes: Optional[Dict[str, Any]] = None
    context: Optional[Dict[str, Any]] = None


class Policy(BaseModel):
    id: str
    name: str
    description: Optional[str] = None
    rules: List[Dict[str, Any]] = []
    enabled: bool = True


@router.post("/evaluate")
async def evaluate_policy(request: PolicyRequest):
    """Evaluate a policy request."""
    # Phase 1: Simple stub - allow infrastructure access
    # Phase 2: Implement OPA/Rego policy evaluation
    return {
        "decision": "allow",
        "request": request.dict(),
        "reason": "Infrastructure access granted",
    }


@router.get("/policies")
async def list_policies():
    """List all policies."""
    return {
        "policies": [
            {
                "id": "infra-access",
                "name": "Infrastructure Access Policy",
                "description": "Controls access to infrastructure services",
                "enabled": True,
            },
            {
                "id": "monitoring-read",
                "name": "Monitoring Read Policy",
                "description": "Allows read access to monitoring dashboards",
                "enabled": True,
            },
        ]
    }
