# test_main.py — medinovai-1in-kubernetes
# Build: 20260413.2800.001 | © 2026 DescartesBio / MedinovAI Health.
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from main import app
from src.database import Base, get_db

SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base.metadata.create_all(bind=engine)

def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

client = TestClient(app)

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"

def test_create_and_get_record():
    # Test Create
    payload = {
        "entity_id": "TEST-12345",
        "status": "active",
        "payload": {"key": "value"},
        "is_phi": False
    }
    response = client.post("/api/v1/1inkubernetes/", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["entity_id"] == "TEST-12345"
    assert "id" in data
    
    # Test Get
    response = client.get(f"/api/v1/1inkubernetes/TEST-12345")
    assert response.status_code == 200
    assert response.json()["entity_id"] == "TEST-12345"
