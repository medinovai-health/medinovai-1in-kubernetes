from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_get_version():
    """Test GET /api/version endpoint."""
    response = client.get("/api/version")
    
    assert response.status_code == 200
    assert "service" in response.json()
    assert "version" in response.json()
    assert response.json()["apiVersion"] == "v1"
    assert response.json()["status"] == "stable"

def test_version_check_compatible():
    """Test version check middleware with compatible versions."""
    response = client.get(
        "/api/v1/test",
        headers={
            "X-Client-Version": "1.0.0",
            "X-Required-API-Version": "^1.0.0"
        }
    )
    
    assert "x-server-version" in response.headers
    assert response.headers["x-api-version"] == "v1"
    assert response.headers["x-compatible"] == "true"

def test_version_check_missing():
    """Test version check middleware with missing client version."""
    response = client.get("/api/v1/test")
    
    assert response.status_code == 400
    assert "Missing X-Client-Version" in response.json()["error"]

def test_version_check_incompatible():
    """Test version check middleware with incompatible versions."""
    response = client.get(
        "/api/v1/test",
        headers={
            "X-Client-Version": "1.0.0",
            "X-Required-API-Version": "^2.0.0"
        }
    )
    
    assert response.status_code == 409
    assert "incompatibility" in response.json()["error"]
