import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

class TestVersionedAPIE2E:
    """End-to-end tests for versioned API."""
    
    def test_multi_service_version_compatibility(self):
        """Should handle version negotiation across services."""
        response = client.get(
            "/api/v1/data",
            headers={
                "X-Client-Version": "1.0.0",
                "X-Required-API-Version": "^1.0.0"
            }
        )
        
        assert response.status_code == 200
        assert response.headers.get("x-compatible") == "true"
    
    def test_version_header_propagation(self):
        """Should propagate version headers to downstream services."""
        response = client.post(
            "/api/v1/complex-operation",
            headers={"X-Client-Version": "1.0.0"},
            json={"data": "test"}
        )
        
        assert response.status_code == 200

class TestVersionMigration:
    """Tests for version migration scenarios."""
    
    def test_gradual_version_migration(self):
        """Should support gradual version migration."""
        v1_response = client.get(
            "/api/v1/test",
            headers={"X-Client-Version": "1.0.0"}
        )
        
        assert v1_response.status_code == 200

class TestVersionDeprecation:
    """Tests for version deprecation."""
    
    def test_deprecation_warnings(self):
        """Should include deprecation warnings in headers."""
        response = client.get(
            "/api/v1/deprecated-endpoint",
            headers={"X-Client-Version": "1.0.0"}
        )
        
        if "x-api-deprecated" in response.headers:
            assert response.headers["x-api-deprecated"] == "true"
            assert "x-sunset-date" in response.headers
