from fastapi import Request, Response, HTTPException
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse
import semver
import os

SERVER_VERSION = os.getenv("VERSION", "1.0.0")
API_VERSION = "v1"

class VersionCheckMiddleware(BaseHTTPMiddleware):
    """Middleware to check version compatibility."""
    
    async def dispatch(self, request: Request, call_next):
        # Skip version check for /api/version endpoint
        if request.url.path == "/api/version":
            return await call_next(request)
        
        # Extract version headers
        client_version = request.headers.get("x-client-version")
        required_api_version = request.headers.get("x-required-api-version")
        
        # Check if client version is provided
        if not client_version:
            return JSONResponse(
                status_code=400,
                content={
                    "error": "Missing X-Client-Version header",
                    "message": "All API requests must include X-Client-Version header",
                    "documentation": "https://docs.medinovai.com/api/versioning"
                }
            )
        
        # Check compatibility
        if required_api_version and not is_compatible(client_version, required_api_version):
            return JSONResponse(
                status_code=409,
                content={
                    "error": "Version incompatibility",
                    "message": f"Client version {client_version} is not compatible with required API version {required_api_version}",
                    "clientVersion": client_version,
                    "serverVersion": SERVER_VERSION,
                    "apiVersion": API_VERSION,
                    "upgradeGuide": "https://docs.medinovai.com/api/migration"
                }
            )
        
        # Process request
        response = await call_next(request)
        
        # Add version headers to response
        response.headers["X-Server-Version"] = SERVER_VERSION
        response.headers["X-API-Version"] = API_VERSION
        response.headers["X-Compatible"] = "true"
        
        return response

def is_compatible(client_version: str, required_version: str) -> bool:
    """Check if client version is compatible with required version."""
    try:
        client = semver.VersionInfo.parse(client_version)
        required = semver.VersionInfo.parse(required_version)
        
        # Major version must match
        if client.major != required.major:
            return False
        
        # Minor version must be >= required
        if client.minor < required.minor:
            return False
        
        return True
    except Exception as e:
        print(f"Version compatibility check error: {e}")
        return False
