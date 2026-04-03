"""Token validator endpoint — the backend the SDK's client.py calls.

POST /validate accepts {"token": "..."} and returns user info or error.
Phase 1 proxies to Keycloak introspection; Phase 2 adds JWKS validation.
"""

import logging

import httpx
from fastapi import APIRouter
from pydantic import BaseModel

from app.config import get_settings

router = APIRouter(tags=["token-validator"])
logger = logging.getLogger("medinovai.security.token_validator")


class ValidateRequest(BaseModel):
    token: str


@router.post("/validate")
async def validate(body: ValidateRequest):
    settings = get_settings()
    introspect_url = (
        f"{settings.keycloak_url}/realms/{settings.keycloak_realm}"
        "/protocol/openid-connect/token/introspect"
    )
    try:
        async with httpx.AsyncClient(timeout=5) as client:
            resp = await client.post(
                introspect_url,
                data={
                    "token": body.token,
                    "client_id": "admin-cli",
                },
            )
        if resp.status_code != 200:
            return {"valid": False, "error": "Introspection request failed"}

        data = resp.json()
        if not data.get("active"):
            return {"valid": False, "error": "Token is inactive or expired"}

        return {
            "valid": True,
            "user": {
                "sub": data.get("sub", ""),
                "email": data.get("email", ""),
                "name": data.get("name", ""),
                "preferred_username": data.get("preferred_username", ""),
                "roles": data.get("realm_access", {}).get("roles", []),
                "permissions": data.get("permissions", []),
                "tenant_id": data.get("tenant_id"),
                "department": data.get("department"),
            },
        }
    except httpx.HTTPError as exc:
        logger.error("Token validation failed: %s", exc)
        return {"valid": False, "error": f"Validation service error: {exc}"}
