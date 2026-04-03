"""Authentication middleware for protecting infrastructure endpoints.

This middleware can be used by other services to validate tokens
via the security service's /validate endpoint.
"""

import logging
from functools import wraps
from typing import Optional, Callable

import httpx
from fastapi import Request, HTTPException, status
from fastapi.responses import JSONResponse, RedirectResponse

from app.config import get_settings

logger = logging.getLogger("medinovai.security.middleware")


class AuthMiddleware:
    """Middleware to protect endpoints with security service token validation."""

    def __init__(self, public_paths: Optional[list] = None, redirect_to_login: bool = False):
        self.public_paths = public_paths or ["/health", "/ready", "/", "/login", "/docs", "/redoc", "/openapi.json"]
        self.redirect_to_login = redirect_to_login
        self.settings = get_settings()

    async def __call__(self, request: Request, call_next):
        # Skip auth for public paths
        path = request.url.path
        if any(path.startswith(p) for p in self.public_paths):
            return await call_next(request)

        # Skip auth for health checks from internal IPs
        client_host = request.client.host if request.client else None
        if client_host and self._is_internal_ip(client_host):
            # Check for health check patterns
            if path.endswith("/health") or path.endswith("/ready"):
                return await call_next(request)

        # Validate token
        token = self._extract_token(request)
        if not token:
            if self.redirect_to_login:
                return RedirectResponse(url=f"{self.settings.keycloak_url}/login?redirect={request.url}")
            return JSONResponse(
                status_code=status.HTTP_401_UNAUTHORIZED,
                content={"detail": "Authentication required"},
            )

        # Validate with security service
        valid, user_info = await self._validate_token(token)
        if not valid:
            if self.redirect_to_login:
                return RedirectResponse(url=f"{self.settings.keycloak_url}/login?redirect={request.url}")
            return JSONResponse(
                status_code=status.HTTP_401_UNAUTHORIZED,
                content={"detail": "Invalid or expired token"},
            )

        # Attach user info to request state
        request.state.user = user_info
        return await call_next(request)

    def _extract_token(self, request: Request) -> Optional[str]:
        """Extract Bearer token from Authorization header."""
        auth_header = request.headers.get("Authorization", "")
        if auth_header.startswith("Bearer "):
            return auth_header[7:]
        # Also check for access_token in cookies
        return request.cookies.get("kc_access")

    async def _validate_token(self, token: str) -> tuple[bool, Optional[dict]]:
        """Validate token via security service or Keycloak directly."""
        try:
            # Try to validate via local Keycloak introspection
            introspect_url = (
                f"{self.settings.keycloak_url}/realms/{self.settings.keycloak_realm}"
                "/protocol/openid-connect/token/introspect"
            )
            async with httpx.AsyncClient(timeout=5) as client:
                resp = await client.post(
                    introspect_url,
                    data={
                        "token": token,
                        "client_id": "admin-cli",
                    },
                )
            if resp.status_code == 200:
                data = resp.json()
                if data.get("active"):
                    return True, {
                        "sub": data.get("sub"),
                        "email": data.get("email"),
                        "preferred_username": data.get("preferred_username"),
                        "roles": data.get("realm_access", {}).get("roles", []),
                        "tenant_id": data.get("tenant_id"),
                    }
        except Exception as e:
            logger.error(f"Token validation error: {e}")

        return False, None

    def _is_internal_ip(self, ip: str) -> bool:
        """Check if IP is internal (localhost, docker, k8s pod range)."""
        internal_prefixes = [
            "127.",
            "10.",
            "172.16.",
            "172.17.",
            "172.18.",
            "172.19.",
            "172.20.",
            "172.21.",
            "172.22.",
            "172.23.",
            "172.24.",
            "172.25.",
            "172.26.",
            "172.27.",
            "172.28.",
            "172.29.",
            "172.30.",
            "172.31.",
            "192.168.",
            "::1",
            "fe80:",
        ]
        return any(ip.startswith(prefix) for prefix in internal_prefixes)


def require_auth(redirect_to_login: bool = False):
    """Decorator to require authentication for specific endpoints."""
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        async def wrapper(request: Request, *args, **kwargs):
            # Extract token
            auth_header = request.headers.get("Authorization", "")
            token = None
            if auth_header.startswith("Bearer "):
                token = auth_header[7:]
            if not token:
                token = request.cookies.get("kc_access")

            if not token:
                if redirect_to_login:
                    return RedirectResponse(url=f"/login?redirect={request.url}")
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Authentication required",
                )

            # Validate token
            settings = get_settings()
            try:
                introspect_url = (
                    f"{settings.keycloak_url}/realms/{settings.keycloak_realm}"
                    "/protocol/openid-connect/token/introspect"
                )
                async with httpx.AsyncClient(timeout=5) as client:
                    resp = await client.post(
                        introspect_url,
                        data={
                            "token": token,
                            "client_id": "admin-cli",
                        },
                    )
                if resp.status_code != 200:
                    raise HTTPException(
                        status_code=status.HTTP_401_UNAUTHORIZED,
                        detail="Token validation failed",
                    )
                data = resp.json()
                if not data.get("active"):
                    raise HTTPException(
                        status_code=status.HTTP_401_UNAUTHORIZED,
                        detail="Token is inactive or expired",
                    )

                # Attach user to request
                request.state.user = {
                    "sub": data.get("sub"),
                    "email": data.get("email"),
                    "preferred_username": data.get("preferred_username"),
                    "roles": data.get("realm_access", {}).get("roles", []),
                    "tenant_id": data.get("tenant_id"),
                }
            except httpx.HTTPError:
                raise HTTPException(
                    status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                    detail="Authentication service unavailable",
                )

            return await func(request, *args, **kwargs)
        return wrapper
    return decorator


# FastAPI dependency for protected routes
async def get_current_user(request: Request) -> dict:
    """Dependency to get current authenticated user."""
    user = getattr(request.state, "user", None)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
        )
    return user


async def require_role(role: str):
    """Dependency factory to require specific role."""
    async def check_role(request: Request) -> dict:
        user = await get_current_user(request)
        roles = user.get("roles", [])
        if role not in roles and "admin" not in roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Required role: {role}",
            )
        return user
    return check_role
