"""Authentication endpoints — proxy to Keycloak."""

import logging

import httpx
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.config import get_settings

router = APIRouter(prefix="/auth", tags=["auth"])
logger = logging.getLogger("medinovai.security.auth")


class LoginRequest(BaseModel):
    username: str
    password: str
    client_id: str = "admin-cli"


class TokenValidateRequest(BaseModel):
    token: str


@router.post("/login")
async def login(body: LoginRequest):
    settings = get_settings()
    token_url = (
        f"{settings.keycloak_url}/realms/{settings.keycloak_realm}"
        "/protocol/openid-connect/token"
    )
    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.post(
            token_url,
            data={
                "grant_type": "password",
                "client_id": body.client_id,
                "username": body.username,
                "password": body.password,
            },
        )
    if resp.status_code != 200:
        raise HTTPException(status_code=401, detail="Authentication failed")
    return resp.json()


@router.post("/validate")
async def validate_token(body: TokenValidateRequest):
    settings = get_settings()
    introspect_url = (
        f"{settings.keycloak_url}/realms/{settings.keycloak_realm}"
        "/protocol/openid-connect/token/introspect"
    )
    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.post(
            introspect_url,
            data={
                "token": body.token,
                "client_id": "admin-cli",
            },
        )
    if resp.status_code != 200:
        return {"valid": False, "error": "Introspection failed"}
    data = resp.json()
    if not data.get("active"):
        return {"valid": False, "error": "Token is inactive"}
    return {
        "valid": True,
        "user": {
            "sub": data.get("sub"),
            "email": data.get("email", ""),
            "name": data.get("name", ""),
            "preferred_username": data.get("preferred_username", ""),
            "roles": data.get("realm_access", {}).get("roles", []),
            "permissions": data.get("permissions", []),
            "tenant_id": data.get("tenant_id"),
        },
    }


@router.post("/logout")
async def logout(refresh_token: str | None = None):
    if not refresh_token:
        return {"message": "No refresh token provided"}
    settings = get_settings()
    logout_url = (
        f"{settings.keycloak_url}/realms/{settings.keycloak_realm}"
        "/protocol/openid-connect/logout"
    )
    async with httpx.AsyncClient(timeout=10) as client:
        await client.post(
            logout_url,
            data={
                "client_id": "admin-cli",
                "refresh_token": refresh_token,
            },
        )
    return {"message": "Logged out"}
