from fastapi import FastAPI
from datetime import datetime
import os

SERVICE_NAME = os.getenv("SERVICE_NAME", "unknown-service")
app = FastAPI(title=SERVICE_NAME)

@app.get("/health")
async def health():
    return {"status": "healthy", "service": SERVICE_NAME, "timestamp": datetime.utcnow().isoformat()}

@app.get("/ready")
async def ready():
    return {"status": "ready", "service": SERVICE_NAME}

@app.get("/")
async def root():
    return {"service": SERVICE_NAME, "status": "operational", "version": "1.0.0"}
