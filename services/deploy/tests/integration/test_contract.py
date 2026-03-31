"""
Integration / Contract Tests — Deployment Service (medinovai-deploy)
Generated from schemas/openapi.yaml
"""
import os
import pytest
import httpx


class TestDeploymentContract:
    """Contract tests for /api/v1/deployments endpoints."""

    E_BASE = os.getenv("API_URL", "http://localhost:8080")
    E_TOKEN = os.getenv("TEST_JWT", "Bearer test-token")
    E_ORG = os.getenv("TEST_ORG_ID", "org-test-001")

    @pytest.mark.asyncio
    async def test_list_deployments_returns_paginated(self):
        """GET /api/v1/deployments returns paginated list."""
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"{self.E_BASE}/api/v1/deployments",
                params={"page": 1, "page_size": 10},
                headers={"Authorization": self.E_TOKEN, "org-id": self.E_ORG},
            )
        assert resp.status_code == 200
        body = resp.json()
        assert "data" in body
        assert "pagination" in body
        assert isinstance(body["data"], list)

    @pytest.mark.asyncio
    async def test_create_deployments_requires_auth(self):
        """POST /api/v1/deployments without auth returns 401."""
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{self.E_BASE}/api/v1/deployments",
                json={"name": "test-deployment"},
                headers={"org-id": self.E_ORG},
            )
        assert resp.status_code == 401

    @pytest.mark.asyncio
    async def test_get_deployments_not_found(self):
        """GET /api/v1/deployments/nonexistent returns 404."""
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"{self.E_BASE}/api/v1/deployments/00000000-0000-0000-0000-000000000000",
                headers={"Authorization": self.E_TOKEN, "org-id": self.E_ORG},
            )
        assert resp.status_code == 404
        assert "error_code" in resp.json()


class TestReleaseContract:
    """Contract tests for /api/v1/releases endpoints."""

    E_BASE = os.getenv("API_URL", "http://localhost:8080")
    E_TOKEN = os.getenv("TEST_JWT", "Bearer test-token")
    E_ORG = os.getenv("TEST_ORG_ID", "org-test-001")

    @pytest.mark.asyncio
    async def test_list_releases_returns_paginated(self):
        """GET /api/v1/releases returns paginated list."""
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"{self.E_BASE}/api/v1/releases",
                params={"page": 1, "page_size": 10},
                headers={"Authorization": self.E_TOKEN, "org-id": self.E_ORG},
            )
        assert resp.status_code == 200
        body = resp.json()
        assert "data" in body
        assert "pagination" in body
        assert isinstance(body["data"], list)

    @pytest.mark.asyncio
    async def test_create_releases_requires_auth(self):
        """POST /api/v1/releases without auth returns 401."""
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{self.E_BASE}/api/v1/releases",
                json={"name": "test-release"},
                headers={"org-id": self.E_ORG},
            )
        assert resp.status_code == 401

    @pytest.mark.asyncio
    async def test_get_releases_not_found(self):
        """GET /api/v1/releases/nonexistent returns 404."""
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"{self.E_BASE}/api/v1/releases/00000000-0000-0000-0000-000000000000",
                headers={"Authorization": self.E_TOKEN, "org-id": self.E_ORG},
            )
        assert resp.status_code == 404
        assert "error_code" in resp.json()


class TestRollbackContract:
    """Contract tests for /api/v1/rollbacks endpoints."""

    E_BASE = os.getenv("API_URL", "http://localhost:8080")
    E_TOKEN = os.getenv("TEST_JWT", "Bearer test-token")
    E_ORG = os.getenv("TEST_ORG_ID", "org-test-001")

    @pytest.mark.asyncio
    async def test_list_rollbacks_returns_paginated(self):
        """GET /api/v1/rollbacks returns paginated list."""
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"{self.E_BASE}/api/v1/rollbacks",
                params={"page": 1, "page_size": 10},
                headers={"Authorization": self.E_TOKEN, "org-id": self.E_ORG},
            )
        assert resp.status_code == 200
        body = resp.json()
        assert "data" in body
        assert "pagination" in body
        assert isinstance(body["data"], list)

    @pytest.mark.asyncio
    async def test_create_rollbacks_requires_auth(self):
        """POST /api/v1/rollbacks without auth returns 401."""
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{self.E_BASE}/api/v1/rollbacks",
                json={"name": "test-rollback"},
                headers={"org-id": self.E_ORG},
            )
        assert resp.status_code == 401

    @pytest.mark.asyncio
    async def test_get_rollbacks_not_found(self):
        """GET /api/v1/rollbacks/nonexistent returns 404."""
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"{self.E_BASE}/api/v1/rollbacks/00000000-0000-0000-0000-000000000000",
                headers={"Authorization": self.E_TOKEN, "org-id": self.E_ORG},
            )
        assert resp.status_code == 404
        assert "error_code" in resp.json()


class TestConfigContract:
    """Contract tests for /api/v1/configs endpoints."""

    E_BASE = os.getenv("API_URL", "http://localhost:8080")
    E_TOKEN = os.getenv("TEST_JWT", "Bearer test-token")
    E_ORG = os.getenv("TEST_ORG_ID", "org-test-001")

    @pytest.mark.asyncio
    async def test_list_configs_returns_paginated(self):
        """GET /api/v1/configs returns paginated list."""
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"{self.E_BASE}/api/v1/configs",
                params={"page": 1, "page_size": 10},
                headers={"Authorization": self.E_TOKEN, "org-id": self.E_ORG},
            )
        assert resp.status_code == 200
        body = resp.json()
        assert "data" in body
        assert "pagination" in body
        assert isinstance(body["data"], list)

    @pytest.mark.asyncio
    async def test_create_configs_requires_auth(self):
        """POST /api/v1/configs without auth returns 401."""
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{self.E_BASE}/api/v1/configs",
                json={"name": "test-config"},
                headers={"org-id": self.E_ORG},
            )
        assert resp.status_code == 401

    @pytest.mark.asyncio
    async def test_get_configs_not_found(self):
        """GET /api/v1/configs/nonexistent returns 404."""
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"{self.E_BASE}/api/v1/configs/00000000-0000-0000-0000-000000000000",
                headers={"Authorization": self.E_TOKEN, "org-id": self.E_ORG},
            )
        assert resp.status_code == 404
        assert "error_code" in resp.json()
