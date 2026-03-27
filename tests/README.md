# Tests — medinovai-canary-rollout-orchestrator

## Overview

This directory contains the test suite for `medinovai-canary-rollout-orchestrator`.

**Required minimum coverage:** 70%
**Standards:** [MedinovAI Testing Standards](https://github.com/medinovai-health/medinovai-Developer/tree/main/medinovai-ai-standards)

## Structure

```
tests/
├── unit/           # Unit tests — individual functions and classes
├── integration/    # Integration tests — service boundaries and APIs
├── e2e/            # End-to-end tests — full workflow scenarios
└── fixtures/       # Test fixtures and mock data (never real PHI)
```

## Running Tests

```bash
# Python
pytest tests/ --cov=. --cov-report=term-missing -v

# .NET
dotnet test --verbosity normal /p:CollectCoverage=true

# Node.js
npm test -- --coverage

# All (via CI)
# See .github/workflows/ci.yml
```

## Test Naming Convention

```
test_<function_name>_<scenario>_<expected_outcome>

Examples:
  test_create_patient_valid_data_returns_201
  test_create_patient_missing_required_field_raises_validation_error
  test_audit_trail_phi_access_writes_immutable_log
```

## Adding Tests

1. Place unit tests in `tests/unit/`
2. Use `mos_` prefix for local variables per MedinovAI coding standards
3. Mock all external services — no real API calls in unit tests
4. Never use real PHI/PII in test data — use `tests/fixtures/` with synthetic data
5. Ensure all tests pass before raising a PR

## Compliance Notes

- Test data must never contain real PHI/PII (HIPAA §164.514)
- Test coverage reports are preserved as CI artifacts for audit evidence
- All safety-critical paths must have explicit negative test cases
