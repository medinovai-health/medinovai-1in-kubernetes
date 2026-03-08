"""
MedinovAI Real-Time Stream Bus — FastAPI Application
Task Reference: S2-08
Version: 1.0.0
Date: 2026-02-24

Exposes:
    GET  /health
    GET  /api/v1/events/types
    POST /api/v1/events/publish
    POST /api/v1/events/publish/batch
    GET  /version

Run:
    uvicorn app.main:app --host 0.0.0.0 --port 8060
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.version import router as version_router
from app.api.events import router as events_router
from app.middleware.version_check import VersionCheckMiddleware

app = FastAPI(
    title="MedinovAI Real-Time Stream Bus",
    version="1.0.0",
    description=(
        "CloudEvents v1.0 publish API for inter-service event bus. "
        "Dual backend: Kafka (production) + RabbitMQ (fallback). "
        "X-Tenant-ID required on all event endpoints."
    ),
)

app.add_middleware(VersionCheckMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(version_router)
app.include_router(events_router, prefix="/api/v1/events", tags=["Event Bus"])


@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "service": "medinovai-real-time-stream-bus",
        "version": "1.0.0",
    }


@app.get("/ready")
async def ready():
    return {"status": "ready"}
