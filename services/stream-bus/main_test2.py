from prometheus_client import Counter, Histogram, make_asgi_app
from fastapi import FastAPI
import uvicorn

app = FastAPI(title="MedinovAI Real-Time Stream Bus", version="1.0.0")

# ── Prometheus metrics ────────────────────────────────────────────────────────
_REQUEST_COUNT = Counter(
    'http_requests_total', 'HTTP request count',
    ['method', 'path', 'status']
)
_REQUEST_LATENCY = Histogram(
    'http_request_duration_seconds', 'HTTP request latency',
    ['method', 'path']
)

@app.middleware("http")
async def _metrics_middleware(request, call_next):
    import time as _time
    start = _time.time()
    response = await call_next(request)
    duration = _time.time() - start
    path = request.url.path
    _REQUEST_COUNT.labels(request.method, path, response.status_code).inc()
    _REQUEST_LATENCY.labels(request.method, path).observe(duration)
    return response

# Mount Prometheus metrics endpoint
app.mount("/metrics", make_asgi_app())

@app.get("/health")
def health():
    return {"status": "ok", "service": "medinovai-real-time-stream-bus"}

@app.get("/")
def root():
    return {"service": "medinovai-real-time-stream-bus", "status": "running", "version": "1.0.0"}

@app.get("/api/status")
def status():
    return {"service": "medinovai-real-time-stream-bus", "status": "ok", "streams": []}

@app.post("/api/publish")
def publish(message: dict = {}):
    return {"published": True, "message_id": "mock-id"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=3000)
