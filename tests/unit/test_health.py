import pytest

def test_health_check_endpoint(mock_api_client):
    """
    Tests the health check endpoint for a 200 OK response.
    """
    response = mock_api_client.get("/health")
    assert response.status_code == 200

def test_service_readiness(mock_db_session):
    """
    Tests the service readiness by checking database connectivity.
    """
    assert mock_db_session.query("SELECT 1").all() is not None

def test_dependency_checks(mock_api_client):
    """
    Tests the dependency checks for external services.
    """
    response = mock_api_client.get("/health/dependencies")
    assert response.status_code == 200
