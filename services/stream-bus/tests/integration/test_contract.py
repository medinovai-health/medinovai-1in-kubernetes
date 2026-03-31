"""
Integration / Contract Tests — Real-time Stream Bus (medinovai-real-time-stream-bus)
Generated from schemas/openapi.yaml
"""
import os
import pytest
import httpx


class TestStreamContract:
    """Contract tests for /api/v1/streams endpoints."""

    E_BASE = os.getenv("API_URL", "http://localhost:8080")
    E_TOKEN = os.getenv("TEST_JWT", "Bearer test-token")
    E_ORG = os.getenv("TEST_ORG_ID", "org-test-001")

    @pytest.mark.asyncio
    async def test_list_streams_returns_paginated(self):
        """GET /api/v1/streams returns paginated list."""
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"{self.E_BASE}/api/v1/streams",
                params={"page": 1, "page_size": 10},
                headers={"Authorization": self.E_TOKEN, "org-id": self.E_ORG},
            )
        assert resp.status_code == 200
        body = resp.json()
        assert "data" in body
        assert "pagination" in body
        assert isinstance(body["data"], list)

    @pytest.mark.asyncio
    async def test_create_streams_requires_auth(self):
        """POST /api/v1/streams without auth returns 401."""
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{self.E_BASE}/api/v1/streams",
                json={"name": "test-stream"},
                headers={"org-id": self.E_ORG},
            )
        assert resp.status_code == 401

    @pytest.mark.asyncio
    async def test_get_streams_not_found(self):
        """GET /api/v1/streams/nonexistent returns 404."""
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"{self.E_BASE}/api/v1/streams/00000000-0000-0000-0000-000000000000",
                headers={"Authorization": self.E_TOKEN, "org-id": self.E_ORG},
            )
        assert resp.status_code == 404
        assert "error_code" in resp.json()


class TestTopicContract:
    """Contract tests for /api/v1/topics endpoints."""

    E_BASE = os.getenv("API_URL", "http://localhost:8080")
    E_TOKEN = os.getenv("TEST_JWT", "Bearer test-token")
    E_ORG = os.getenv("TEST_ORG_ID", "org-test-001")

    @pytest.mark.asyncio
    async def test_list_topics_returns_paginated(self):
        """GET /api/v1/topics returns paginated list."""
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"{self.E_BASE}/api/v1/topics",
                params={"page": 1, "page_size": 10},
                headers={"Authorization": self.E_TOKEN, "org-id": self.E_ORG},
            )
        assert resp.status_code == 200
        body = resp.json()
        assert "data" in body
        assert "pagination" in body
        assert isinstance(body["data"], list)

    @pytest.mark.asyncio
    async def test_create_topics_requires_auth(self):
        """POST /api/v1/topics without auth returns 401."""
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{self.E_BASE}/api/v1/topics",
                json={"name": "test-topic"},
                headers={"org-id": self.E_ORG},
            )
        assert resp.status_code == 401

    @pytest.mark.asyncio
    async def test_get_topics_not_found(self):
        """GET /api/v1/topics/nonexistent returns 404."""
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"{self.E_BASE}/api/v1/topics/00000000-0000-0000-0000-000000000000",
                headers={"Authorization": self.E_TOKEN, "org-id": self.E_ORG},
            )
        assert resp.status_code == 404
        assert "error_code" in resp.json()


class TestConsumerContract:
    """Contract tests for /api/v1/consumers endpoints."""

    E_BASE = os.getenv("API_URL", "http://localhost:8080")
    E_TOKEN = os.getenv("TEST_JWT", "Bearer test-token")
    E_ORG = os.getenv("TEST_ORG_ID", "org-test-001")

    @pytest.mark.asyncio
    async def test_list_consumers_returns_paginated(self):
        """GET /api/v1/consumers returns paginated list."""
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"{self.E_BASE}/api/v1/consumers",
                params={"page": 1, "page_size": 10},
                headers={"Authorization": self.E_TOKEN, "org-id": self.E_ORG},
            )
        assert resp.status_code == 200
        body = resp.json()
        assert "data" in body
        assert "pagination" in body
        assert isinstance(body["data"], list)

    @pytest.mark.asyncio
    async def test_create_consumers_requires_auth(self):
        """POST /api/v1/consumers without auth returns 401."""
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{self.E_BASE}/api/v1/consumers",
                json={"name": "test-consumer"},
                headers={"org-id": self.E_ORG},
            )
        assert resp.status_code == 401

    @pytest.mark.asyncio
    async def test_get_consumers_not_found(self):
        """GET /api/v1/consumers/nonexistent returns 404."""
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"{self.E_BASE}/api/v1/consumers/00000000-0000-0000-0000-000000000000",
                headers={"Authorization": self.E_TOKEN, "org-id": self.E_ORG},
            )
        assert resp.status_code == 404
        assert "error_code" in resp.json()


class TestOffsetContract:
    """Contract tests for /api/v1/offsets endpoints."""

    E_BASE = os.getenv("API_URL", "http://localhost:8080")
    E_TOKEN = os.getenv("TEST_JWT", "Bearer test-token")
    E_ORG = os.getenv("TEST_ORG_ID", "org-test-001")

    @pytest.mark.asyncio
    async def test_list_offsets_returns_paginated(self):
        """GET /api/v1/offsets returns paginated list."""
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"{self.E_BASE}/api/v1/offsets",
                params={"page": 1, "page_size": 10},
                headers={"Authorization": self.E_TOKEN, "org-id": self.E_ORG},
            )
        assert resp.status_code == 200
        body = resp.json()
        assert "data" in body
        assert "pagination" in body
        assert isinstance(body["data"], list)

    @pytest.mark.asyncio
    async def test_create_offsets_requires_auth(self):
        """POST /api/v1/offsets without auth returns 401."""
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{self.E_BASE}/api/v1/offsets",
                json={"name": "test-offset"},
                headers={"org-id": self.E_ORG},
            )
        assert resp.status_code == 401

    @pytest.mark.asyncio
    async def test_get_offsets_not_found(self):
        """GET /api/v1/offsets/nonexistent returns 404."""
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"{self.E_BASE}/api/v1/offsets/00000000-0000-0000-0000-000000000000",
                headers={"Authorization": self.E_TOKEN, "org-id": self.E_ORG},
            )
        assert resp.status_code == 404
        assert "error_code" in resp.json()
