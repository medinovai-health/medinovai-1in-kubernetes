"""Pytest configuration and fixtures"""
import pytest
from unittest.mock import Mock, patch
import asyncio

@pytest.fixture
def mock_database():
    """Mock database connection"""
    with patch('services.database.get_connection') as mock:
        yield mock

@pytest.fixture
def mock_redis():
    """Mock Redis connection"""
    with patch('services.cache.get_redis') as mock:
        yield mock

@pytest.fixture
def test_client():
    """Test client for API testing"""
    from app import create_app
    app = create_app(testing=True)
    with app.test_client() as client:
        yield client

@pytest.fixture
def event_loop():
    """Create event loop for async tests"""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()
