"""
Integration / Contract Tests — Infrastructure Management (medinovai-infrastructure)
Generated from schemas/openapi.yaml
"""
import os
import pytest
import httpx


class TestResourceContract:
    """Contract tests for /api/v1/resources endpoints."""

    E_BASE = os.getenv("API_URL", "http://localhost:8080")
    E_TOKEN = os.getenv("TEST_JWT", "Bearer test-token")
    E_ORG = os.getenv("TEST_ORG_ID", "org-test-001")

    @pytest.mark.asyncio
    async def test_list_resources_returns_paginated(self):
        """GET /api/v1/resources returns paginated list."""
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"{self.E_BASE}/api/v1/resources",
                params={"page": 1, "page_size": 10},
                headers={"Authorization": self.E_TOKEN, "org-id": self.E_ORG},
            )
        assert resp.status_code == 200
        body = resp.json()
        assert "data" in body
        assert "pagination" in body
        assert isinstance(body["data"], list)

    @pytest.mark.asyncio
    async def test_create_resources_requires_auth(self):
        """POST /api/v1/resources without auth returns 401."""
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{self.E_BASE}/api/v1/resources",
                json={"name": "test-resource"},
                headers={"org-id": self.E_ORG},
            )
        assert resp.status_code == 401

    @pytest.mark.asyncio
    async def test_get_resources_not_found(self):
        """GET /api/v1/resources/nonexistent returns 404."""
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"{self.E_BASE}/api/v1/resources/00000000-0000-0000-0000-000000000000",
                headers={"Authorization": self.E_TOKEN, "org-id": self.E_ORG},
            )
        assert resp.status_code == 404
        assert "error_code" in resp.json()


class TestClusterContract:
    """Contract tests for /api/v1/clusters endpoints."""

    E_BASE = os.getenv("API_URL", "http://localhost:8080")
    E_TOKEN = os.getenv("TEST_JWT", "Bearer test-token")
    E_ORG = os.getenv("TEST_ORG_ID", "org-test-001")

    @pytest.mark.asyncio
    async def test_list_clusters_returns_paginated(self):
        """GET /api/v1/clusters returns paginated list."""
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"{self.E_BASE}/api/v1/clusters",
                params={"page": 1, "page_size": 10},
                headers={"Authorization": self.E_TOKEN, "org-id": self.E_ORG},
            )
        assert resp.status_code == 200
        body = resp.json()
        assert "data" in body
        assert "pagination" in body
        assert isinstance(body["data"], list)

    @pytest.mark.asyncio
    async def test_create_clusters_requires_auth(self):
        """POST /api/v1/clusters without auth returns 401."""
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{self.E_BASE}/api/v1/clusters",
                json={"name": "test-cluster"},
                headers={"org-id": self.E_ORG},
            )
        assert resp.status_code == 401

    @pytest.mark.asyncio
    async def test_get_clusters_not_found(self):
        """GET /api/v1/clusters/nonexistent returns 404."""
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"{self.E_BASE}/api/v1/clusters/00000000-0000-0000-0000-000000000000",
                headers={"Authorization": self.E_TOKEN, "org-id": self.E_ORG},
            )
        assert resp.status_code == 404
        assert "error_code" in resp.json()


class TestMonitorContract:
    """Contract tests for /api/v1/monitors endpoints."""

    E_BASE = os.getenv("API_URL", "http://localhost:8080")
    E_TOKEN = os.getenv("TEST_JWT", "Bearer test-token")
    E_ORG = os.getenv("TEST_ORG_ID", "org-test-001")

    @pytest.mark.asyncio
    async def test_list_monitors_returns_paginated(self):
        """GET /api/v1/monitors returns paginated list."""
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"{self.E_BASE}/api/v1/monitors",
                params={"page": 1, "page_size": 10},
                headers={"Authorization": self.E_TOKEN, "org-id": self.E_ORG},
            )
        assert resp.status_code == 200
        body = resp.json()
        assert "data" in body
        assert "pagination" in body
        assert isinstance(body["data"], list)

    @pytest.mark.asyncio
    async def test_create_monitors_requires_auth(self):
        """POST /api/v1/monitors without auth returns 401."""
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{self.E_BASE}/api/v1/monitors",
                json={"name": "test-monitor"},
                headers={"org-id": self.E_ORG},
            )
        assert resp.status_code == 401

    @pytest.mark.asyncio
    async def test_get_monitors_not_found(self):
        """GET /api/v1/monitors/nonexistent returns 404."""
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"{self.E_BASE}/api/v1/monitors/00000000-0000-0000-0000-000000000000",
                headers={"Authorization": self.E_TOKEN, "org-id": self.E_ORG},
            )
        assert resp.status_code == 404
        assert "error_code" in resp.json()


class TestAlertContract:
    """Contract tests for /api/v1/alerts endpoints."""

    E_BASE = os.getenv("API_URL", "http://localhost:8080")
    E_TOKEN = os.getenv("TEST_JWT", "Bearer test-token")
    E_ORG = os.getenv("TEST_ORG_ID", "org-test-001")

    @pytest.mark.asyncio
    async def test_list_alerts_returns_paginated(self):
        """GET /api/v1/alerts returns paginated list."""
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"{self.E_BASE}/api/v1/alerts",
                params={"page": 1, "page_size": 10},
                headers={"Authorization": self.E_TOKEN, "org-id": self.E_ORG},
            )
        assert resp.status_code == 200
        body = resp.json()
        assert "data" in body
        assert "pagination" in body
        assert isinstance(body["data"], list)

    @pytest.mark.asyncio
    async def test_create_alerts_requires_auth(self):
        """POST /api/v1/alerts without auth returns 401."""
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{self.E_BASE}/api/v1/alerts",
                json={"name": "test-alert"},
                headers={"org-id": self.E_ORG},
            )
        assert resp.status_code == 401

    @pytest.mark.asyncio
    async def test_get_alerts_not_found(self):
        """GET /api/v1/alerts/nonexistent returns 404."""
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"{self.E_BASE}/api/v1/alerts/00000000-0000-0000-0000-000000000000",
                headers={"Authorization": self.E_TOKEN, "org-id": self.E_ORG},
            )
        assert resp.status_code == 404
        assert "error_code" in resp.json()
