"""
Smoke Tests — medinovai-canary-rollout-orchestrator
Domain: Canary Rollout Orchestrator Service
Tier: 3 (NON-REGULATED) | Coverage target: 70%
Focus: Basic functionality, error handling

Run: pytest tests/test_smoke.py -v
"""
import os
import sys
import importlib
import pytest

# Allow imports from project root
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))


class TestErrorModule:
    """Verify shared/errors.py implements E_SAFE_DEFAULT pattern."""

    def test_error_module_exists(self):
        """Error module must exist for MedinovAI compliance."""
        mos_errorPath = os.path.join(
            os.path.dirname(__file__), "..", "shared", "errors.py"
        )
        assert os.path.isfile(mos_errorPath), (
            f"shared/errors.py not found at {mos_errorPath}"
        )

    def test_error_codes_defined(self):
        """All MED-XXXX error codes must be present."""
        try:
            from shared.errors import E_ERROR_CODE
            assert hasattr(E_ERROR_CODE, "E_SAFE_DEFAULT")
            assert hasattr(E_ERROR_CODE, "E_VALIDATION")
            assert hasattr(E_ERROR_CODE, "E_AUTH_FAILED")
            assert E_ERROR_CODE.E_SAFE_DEFAULT.value == "MED-9999"
        except ImportError:
            pytest.skip("shared.errors not importable yet")

    def test_safe_default_decorator(self):
        """@mos_safeDefault must catch and wrap unhandled exceptions."""
        try:
            from shared.errors import mos_safeDefault, SafeDefaultError

            @mos_safeDefault
            def mos_failingFunc():
                raise RuntimeError("boom")

            with pytest.raises(SafeDefaultError):
                mos_failingFunc()
        except ImportError:
            pytest.skip("shared.errors not importable yet")

    def test_error_response_no_phi(self):
        """Error responses must not leak PHI."""
        try:
            from shared.errors import MedinovAIError
            mos_err = MedinovAIError(mos_message="Test error")
            mos_resp = mos_err.to_response()
            assert "error" in mos_resp
            assert "code" in mos_resp["error"]
            assert "correlationId" in mos_resp["error"]
            # No PHI fields
            mos_responseStr = str(mos_resp)
            assert "patient" not in mos_responseStr.lower()
            assert "ssn" not in mos_responseStr.lower()
        except ImportError:
            pytest.skip("shared.errors not importable yet")


class TestProjectStructure:
    """Verify required MedinovAI project files exist."""

    E_REQUIRED_FILES = [
        "CLAUDE.md",
        "SECURITY.md",
        ".gitignore",
        "medinovai.manifest.yaml",
        "CONTRIBUTING.md",
        "CHANGELOG.md",
    ]

    @pytest.mark.parametrize("mos_file", E_REQUIRED_FILES)
    def test_required_file_exists(self, mos_file):
        mos_path = os.path.join(os.path.dirname(__file__), "..", mos_file)
        assert os.path.isfile(mos_path), f"Required file missing: {mos_file}"

    def test_gitignore_blocks_env(self):
        """Ensure .env files are gitignored (HIPAA/credential safety)."""
        mos_path = os.path.join(os.path.dirname(__file__), "..", ".gitignore")
        if os.path.isfile(mos_path):
            with open(mos_path) as f:
                mos_content = f.read()
            assert ".env" in mos_content, ".env must be in .gitignore"


class TestHealthCheck:
    """Verify health check endpoint module exists (Tier 1+2)."""

    @pytest.mark.skipif(
        3 > 2,
        reason="Health check only required for Tier 1+2"
    )
    def test_health_module_exists(self):
        mos_candidates = [
            os.path.join(os.path.dirname(__file__), "..", "src", "health.py"),
            os.path.join(os.path.dirname(__file__), "..", "app", "health.py"),
        ]
        mos_found = any(os.path.isfile(p) for p in mos_candidates)
        assert mos_found, "Health check module required for Tier 1+2 services"


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
