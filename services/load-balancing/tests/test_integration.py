"""Integration tests for service"""
import pytest
from testcontainers.postgres import PostgresContainer
from testcontainers.redis import RedisContainer

class TestServiceIntegration:
    """Integration tests for service"""
    
    @pytest.fixture(scope="class")
    def postgres_container(self):
        """PostgreSQL test container"""
        with PostgresContainer("postgres:15") as postgres:
            yield postgres
    
    @pytest.fixture(scope="class")
    def redis_container(self):
        """Redis test container"""
        with RedisContainer("redis:7") as redis:
            yield redis
    
    def test_database_integration(self, postgres_container):
        """Test database integration"""
        assert postgres_container.get_connection_url()
    
    def test_cache_integration(self, redis_container):
        """Test cache integration"""
        assert redis_container.get_connection_url()
    
    def test_api_integration(self, test_client):
        """Test API integration"""
        response = test_client.get('/health')
        assert response.status_code == 200
