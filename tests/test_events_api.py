"""
Unit tests for S2-08: Event Bus Publish API.
Tests PHI firewall, event type validation, and batch logic.
"""

import pytest
from fastapi.testclient import TestClient
from unittest.mock import AsyncMock, MagicMock, patch

from app.api.events import router, _check_no_phi, _PHI_INDICATORS
from app.events.cloudevents import ALL_EVENT_TYPES, EVENT_DATA_INGESTED


class TestPHIFirewall:
    """PHI field detection in event payloads."""

    def test_clean_payload_passes(self):
        """Non-PHI payload should not raise."""
        _check_no_phi(
            {"dataset_id": "ds-123", "row_count": 1000, "tenant_id": "org-acme"},
            EVENT_DATA_INGESTED,
        )

    def test_phi_field_blocked(self):
        """A payload with patient_name should be blocked."""
        from fastapi import HTTPException
        with pytest.raises(HTTPException) as exc_info:
            _check_no_phi(
                {"patient_name": "John Doe", "dataset_id": "ds-123"},
                EVENT_DATA_INGESTED,
            )
        assert exc_info.value.status_code == 400
        assert "patient_name" in exc_info.value.detail

    def test_ssn_blocked(self):
        from fastapi import HTTPException
        with pytest.raises(HTTPException):
            _check_no_phi({"ssn": "123-45-6789"}, "io.medinovai.data.ingested")

    def test_email_blocked(self):
        from fastapi import HTTPException
        with pytest.raises(HTTPException):
            _check_no_phi({"email": "test@test.com"}, "io.medinovai.data.ingested")

    def test_multiple_phi_fields_all_reported(self):
        from fastapi import HTTPException
        with pytest.raises(HTTPException) as exc_info:
            _check_no_phi(
                {"patient_name": "X", "ssn": "Y", "dataset_id": "ds-1"},
                "io.medinovai.data.ingested",
            )
        detail = exc_info.value.detail
        assert "patient_name" in detail or "ssn" in detail


class TestEventTypes:
    def test_all_13_event_types_defined(self):
        assert len(ALL_EVENT_TYPES) == 13

    def test_required_event_types_present(self):
        required = [
            "io.medinovai.data.ingested",
            "io.medinovai.data.dqgate.passed",
            "io.medinovai.consent.revoked",
            "io.medinovai.security.alert",
        ]
        for et in required:
            assert et in ALL_EVENT_TYPES, f"{et} missing from ALL_EVENT_TYPES"


class TestPublishAPIValidation:
    """Test publish endpoint validation logic (no real event bus)."""

    def setup_method(self):
        from fastapi import FastAPI
        app = FastAPI()
        app.include_router(router, prefix="/api/v1/events")
        self.client = TestClient(app, raise_server_exceptions=True)

    def test_unknown_event_type_rejected(self):
        with patch("app.api.events.get_event_producer") as mock_factory:
            resp = self.client.post(
                "/api/v1/events/publish",
                json={"event_type": "io.unknown.event", "data": {}},
                headers={"X-Tenant-ID": "org-test"},
            )
        assert resp.status_code == 400
        assert "Unknown event type" in resp.json()["detail"]

    def test_phi_in_data_rejected(self):
        with patch("app.api.events.get_event_producer"):
            resp = self.client.post(
                "/api/v1/events/publish",
                json={
                    "event_type": "io.medinovai.data.ingested",
                    "data": {"patient_name": "Jane Doe", "dataset_id": "ds-1"},
                },
                headers={"X-Tenant-ID": "org-test"},
            )
        assert resp.status_code == 400
        assert "PHI" in resp.json()["detail"]

    def test_missing_tenant_rejected(self):
        resp = self.client.post(
            "/api/v1/events/publish",
            json={"event_type": "io.medinovai.data.ingested", "data": {}},
        )
        assert resp.status_code == 422  # missing required header

    def test_list_event_types(self):
        resp = self.client.get(
            "/api/v1/events/types",
            headers={"X-Tenant-ID": "org-test"},
        )
        assert resp.status_code == 200
        assert resp.json()["count"] == 13


class TestBatchValidation:
    def setup_method(self):
        from fastapi import FastAPI
        app = FastAPI()
        app.include_router(router, prefix="/api/v1/events")
        self.client = TestClient(app, raise_server_exceptions=True)

    def test_batch_with_invalid_type_returns_error_count(self):
        with patch("app.api.events.get_event_producer") as mock_factory:
            mock_producer = AsyncMock()
            mock_producer.publish_batch = AsyncMock(return_value=[])
            mock_factory.return_value = mock_producer

            resp = self.client.post(
                "/api/v1/events/publish/batch",
                json={"events": [
                    {"event_type": "io.bad.type", "data": {}},
                    {"event_type": "io.medinovai.data.ingested",
                     "data": {"dataset_id": "ds-1"}},
                ]},
                headers={"X-Tenant-ID": "org-test"},
            )
        assert resp.status_code == 200
        body = resp.json()
        assert body["failed"] >= 1

    def test_empty_batch_rejected(self):
        resp = self.client.post(
            "/api/v1/events/publish/batch",
            json={"events": []},
            headers={"X-Tenant-ID": "org-test"},
        )
        assert resp.status_code == 422
