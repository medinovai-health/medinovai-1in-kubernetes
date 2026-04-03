"""Health and readiness endpoints."""

from datetime import datetime, timezone

from fastapi import APIRouter

from app.config import get_settings

router = APIRouter(tags=["health"])


@router.get("/health")
async def health():
    s = get_settings()
    return {
        "status": "healthy",
        "service": s.service_name,
        "version": s.version,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "registry": s.registry_url,
    }


@router.get("/ready")
async def ready():
    return {"status": "ready", "service": get_settings().service_name}


@router.get("/")
async def root():
    s = get_settings()
    return {
        "service": s.service_name,
        "status": "operational",
        "version": s.version,
    }
