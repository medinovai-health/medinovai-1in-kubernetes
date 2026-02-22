from fastapi import FastAPI
import uvicorn

app = FastAPI(title="MedinovAI Real-Time Stream Bus", version="1.0.0")

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
