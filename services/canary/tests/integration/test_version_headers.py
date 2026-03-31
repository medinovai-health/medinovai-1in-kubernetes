import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

class TestVersionHeaders:
    """Integration tests for version header exchange."""
    
    def test_include_version_headers_in_response(self):
        """Should include version headers in response."""
        response = client.get(
            "/api/v1/test",
            headers={"X-Client-Version": "1.0.0"}
        )
        
        assert "x-server-version" in response.headers
        assert "x-api-version" in response.headers
        assert response.headers["x-api-version"] == "v1"
    
    def test_accept_compatible_client_versions(self):
        """Should accept compatible client versions."""
        response = client.get(
            "/api/v1/test",
            headers={
                "X-Client-Version": "1.0.0",
                "X-Required-API-Version": "^1.0.0"
            }
        )
        
        assert response.status_code != 409
        assert response.headers.get("x-compatible") == "true"
    
    def test_reject_incompatible_major_versions(self):
        """Should reject incompatible major versions."""
        response = client.get(
            "/api/v1/test",
            headers={
                "X-Client-Version": "1.0.0",
                "X-Required-API-Version": "^2.0.0"
            }
        )
        
        assert response.status_code == 409
        assert "error" in response.json()
        assert "incompatibility" in response.json()["error"]
    
    def test_reject_missing_client_version_header(self):
        """Should reject missing client version header."""
        response = client.get("/api/v1/test")
        
        assert response.status_code == 400
        assert "Missing X-Client-Version" in response.json()["error"]

class TestVersionCompatibility:
    """Tests for version compatibility logic."""
    
    def test_accept_same_major_and_minor_versions(self):
        """Should accept same major and minor versions."""
        response = client.get(
            "/api/v1/test",
            headers={
                "X-Client-Version": "1.2.0",
                "X-Required-API-Version": "^1.2.0"
            }
        )
        
        assert response.status_code != 409
    
    def test_accept_higher_minor_versions(self):
        """Should accept higher minor versions."""
        response = client.get(
            "/api/v1/test",
            headers={
                "X-Client-Version": "1.5.0",
                "X-Required-API-Version": "^1.2.0"
            }
        )
        
        assert response.status_code != 409
    
    def test_reject_lower_minor_versions(self):
        """Should reject lower minor versions."""
        response = client.get(
            "/api/v1/test",
            headers={
                "X-Client-Version": "1.1.0",
                "X-Required-API-Version": "^1.2.0"
            }
        )
        
        assert response.status_code == 409

class TestVersionEndpoint:
    """Tests for version endpoint."""
    
    def test_version_endpoint_no_headers_required(self):
        """Version endpoint should not require version headers."""
        response = client.get("/api/version")
        
        assert response.status_code == 200
    
    def test_version_endpoint_returns_complete_info(self):
        """Should return complete version information."""
        response = client.get("/api/version")
        data = response.json()
        
        assert "service" in data
        assert "version" in data
        assert "apiVersion" in data
        assert "buildDate" in data
        assert "status" in data
