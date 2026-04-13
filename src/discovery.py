# discovery.py — medinovai-1in-kubernetes
# Build: 20260413.2900.001 | © 2026 DescartesBio / MedinovAI Health.
import os
import httpx
import asyncio
from functools import lru_cache

# Tailscale mDNS suffix
TAILNET_SUFFIX = os.getenv("TAILNET_SUFFIX", ".tailnet.medinovai")

@lru_cache(maxsize=128)
def get_service_url(service_name: str) -> str:
    """
    Resolves a service URL using Tailscale mDNS.
    Example: 'billing' -> 'http://billing.tailnet.medinovai:8000'
    """
    # Check if explicitly overridden
    override = os.getenv(f"{service_name.upper()}_URL")
    if override:
        return override
        
    return f"http://{service_name}{TAILNET_SUFFIX}:8000"

async def register_with_atlas():
    """
    Registers this service with the AtlasOS Service Registry on startup.
    """
    atlas_url = get_service_url("atlasos")
    payload = {
        "service_name": "1in-kubernetes",
        "repo_name": "medinovai-1in-kubernetes",
        "version": "v8.0.0",
        "health_endpoint": "/health"
    }
    
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(f"{atlas_url}/api/v1/registry/register", json=payload, timeout=5.0)
            response.raise_for_status()
            print(f"✅ Successfully registered medinovai-1in-kubernetes with AtlasOS Service Registry")
    except Exception as e:
        print(f"⚠️ Failed to register with AtlasOS: {e}")
