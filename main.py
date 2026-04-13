# main.py — medinovai-1in-kubernetes
# Build: 20260413.2600.001 | © 2026 DescartesBio / MedinovAI Health.
import os
import time

from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor, ConsoleSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor

# Initialize tracing
trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)
trace.get_tracer_provider().add_span_processor(BatchSpanProcessor(ConsoleSpanExporter()))

from src import models, router
from src.database import engine
models.Base.metadata.create_all(bind=engine)
\nfrom fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from prometheus_client import make_asgi_app, Counter, Histogram
import httpx

app = FastAPI(
    title="medinovai-1in-kubernetes",
    version="v4.0.0",
    description="MedinovAI Service: medinovai-1in-kubernetes"
)

# CORS

FastAPIInstrumentor.instrument_app(app)
SQLAlchemyInstrumentor().instrument(engine=engine)

app.include_router(router.router)
\napp.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Metrics
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
REQUEST_LATENCY = Histogram('http_request_duration_seconds', 'HTTP request latency', ['method', 'endpoint'])

metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)

@app.middleware("http")
async def monitor_requests(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    duration = time.time() - start_time
    
    REQUEST_COUNT.labels(
        method=request.method, 
        endpoint=request.url.path, 
        status=response.status_code
    ).inc()
    
    REQUEST_LATENCY.labels(
        method=request.method, 
        endpoint=request.url.path
    ).observe(duration)
    
    return response

# Health Endpoints
@app.get("/health")
def health_check():
    return {"status": "ok", "service": "medinovai-1in-kubernetes", "build": "20260413.2600.001"}

@app.get("/ready")
def readiness_check():
    return {"status": "ready"}

@app.get("/live")
def liveness_check():
    return {"status": "alive"}

# AtlasOS Service Registry
@app.on_event("startup")
async def register_with_atlas():
    gateway_url = os.getenv("ATLAS_OS_GATEWAY_URL", "http://atlas-gateway:8000")
    try:
        async with httpx.AsyncClient() as client:
            await client.post(f"{gateway_url}/registry/register", json={
                "service": "medinovai-1in-kubernetes",
                "version": "v4.0.0",
                "endpoints": ["/health", "/metrics"]
            }, timeout=2.0)
        print(f"Registered medinovai-1in-kubernetes with AtlasOS Gateway")
    except Exception as e:
        print(f"AtlasOS Registration failed (non-fatal): {e}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
