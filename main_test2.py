import os
from fastapi import FastAPI
from prometheus_client import make_asgi_app

app = FastAPI(title=os.environ.get("SERVICE_NAME", "medinovai-canary-rollout-orchestrator"))

@app.get("/health")
def health():
    return {"status": "healthy", "service": os.environ.get("SERVICE_NAME", "medinovai-canary-rollout-orchestrator"), "version": "dev-1.0.0"}

@app.get("/metrics")
def metrics():
    return make_asgi_app()
