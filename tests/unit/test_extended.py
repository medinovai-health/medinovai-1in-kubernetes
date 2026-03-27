"""
Expanded unit tests — Real-time Stream Bus (medinovai-real-time-stream-bus) — Tier 2
"""
import json
import pytest
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))


class TestErrorModule:
    """Tests for src/errors_extended.py."""

    def test_import_error_module(self):
        from src.errors_extended import MedinovAIBaseError, ValidationError, NotFoundError
        assert issubclass(ValidationError, MedinovAIBaseError)
        assert issubclass(NotFoundError, MedinovAIBaseError)

    def test_validation_error_status(self):
        from src.errors_extended import ValidationError
        err = ValidationError("bad input")
        assert err.mos_httpStatus == 400
        assert "REAL_TIM" in err.mos_code

    def test_not_found_error(self):
        from src.errors_extended import NotFoundError
        err = NotFoundError("resource", "id-123")
        assert err.mos_httpStatus == 404
        assert "not found" in err.mos_message

    def test_error_response_has_correlation_id(self):
        from src.errors_extended import ValidationError
        err = ValidationError("test")
        resp = err.to_response("corr-123")
        assert resp["correlation_id"] == "corr-123"
        assert "error_code" in resp

    def test_no_phi_in_error_response(self):
        from src.errors_extended import ValidationError
        err = ValidationError("test")
        resp = err.to_response()
        text = json.dumps(resp)
        assert "patient" not in text.lower()
        assert "ssn" not in text.lower()


class TestHealthModule:
    """Tests for src/health_wired.py."""

    @pytest.mark.asyncio
    async def test_health_check_returns_healthy(self):
        from src.health_wired import mos_healthCheck
        result = await mos_healthCheck()
        assert result["status"] == "healthy"
        assert result["service"] == "medinovai-real-time-stream-bus"

    @pytest.mark.asyncio
    async def test_liveness_returns_alive(self):
        from src.health_wired import mos_livenessCheck
        result = await mos_livenessCheck()
        assert result["status"] == "alive"

    @pytest.mark.asyncio
    async def test_readiness_includes_dependencies(self):
        from src.health_wired import mos_readinessCheck
        result = await mos_readinessCheck()
        assert "dependencies" in result
        assert "database" in result["dependencies"]
