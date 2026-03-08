"""
Tests for the recursive PHI firewall — quality sweep addition.
Verifies that nested PHI is detected, not just top-level keys.
"""

import pytest
from fastapi import HTTPException
from app.api.events import _check_no_phi, _collect_keys_recursive


class TestCollectKeysRecursive:
    def test_flat_dict(self):
        keys = _collect_keys_recursive({"name": "x", "count": 1})
        assert "name" in keys
        assert "count" in keys

    def test_nested_dict(self):
        keys = _collect_keys_recursive({"outer": {"patient_name": "John"}})
        assert "patient_name" in keys
        assert "outer" in keys

    def test_list_of_dicts(self):
        keys = _collect_keys_recursive([{"ssn": "123"}, {"email": "test@test.com"}])
        assert "ssn" in keys
        assert "email" in keys

    def test_deeply_nested(self):
        deep = {"a": {"b": {"c": {"d": {"e": {"patient_name": "x"}}}}}}
        keys = _collect_keys_recursive(deep)
        assert "patient_name" in keys

    def test_depth_limit_prevents_infinite(self):
        """Depth > 5 should be ignored to prevent infinite recursion."""
        deep = {"l1": {"l2": {"l3": {"l4": {"l5": {"l6": {"ssn": "deep"}}}}}}}
        keys = _collect_keys_recursive(deep)
        # ssn is at depth 6, should be cut off
        assert "ssn" not in keys

    def test_non_dict_scalar_ignored(self):
        keys = _collect_keys_recursive("just a string")
        assert keys == set()

    def test_empty_dict(self):
        assert _collect_keys_recursive({}) == set()


class TestCheckNoPHI:
    def test_nested_phi_blocked(self):
        with pytest.raises(HTTPException) as exc_info:
            _check_no_phi(
                {"summary": {"patient_name": "John Doe"}},
                "io.medinovai.data.ingested",
            )
        assert exc_info.value.status_code == 400
        assert "patient_name" in exc_info.value.detail

    def test_phi_in_list_blocked(self):
        with pytest.raises(HTTPException):
            _check_no_phi(
                {"patients": [{"ssn": "123-45-6789"}]},
                "io.medinovai.data.ingested",
            )

    def test_clean_nested_payload_passes(self):
        _check_no_phi(
            {"summary": {"dataset_id": "ds-1", "counts": {"total": 100}}},
            "io.medinovai.data.ingested",
        )

    def test_new_phi_fields_added_in_sweep(self):
        """Verify fields added during quality sweep are blocked."""
        new_fields = ["npi", "birth_date", "death_date", "zip_code", "postal_code"]
        for field in new_fields:
            with pytest.raises(HTTPException, match="PHI"):
                _check_no_phi({field: "value"}, "io.medinovai.data.ingested")
