_This document is a placeholder and should be updated with the actual testing strategy for the services deployed by this infrastructure._

# Testing Strategy

Our testing strategy for the MedinovAI LIS infrastructure is multi-layered to ensure the reliability, security, and performance of the platform.

## Unit Tests

- **Scope:** Individual components and functions.
- **Framework:** Jest
- **Location:** Alongside the source code.

## Integration Tests

- **Scope:** Interactions between different components and services.
- **Framework:** Pytest
- **Location:** `tests/integration`

## End-to-End (E2E) Tests

- **Scope:** User workflows and critical paths.
- **Framework:** Cypress
- **Location:** `tests/e2e`

# How to Run Tests

## Unit Tests

```bash
npm test
```

## Integration Tests

```bash
pytest tests/integration
```

## E2E Tests

```bash
npm run cy:run
```

# Code Coverage

We have a minimum code coverage requirement of **80%**. Pull requests that do not meet this requirement will not be merged.

# Mocking Guidelines

- **Unit Tests:** Use Jest's built-in mocking capabilities to isolate components.
- **Integration Tests:** Use `unittest.mock` to mock external services and dependencies.
- **E2E Tests:** Avoid mocking as much as possible to test the system in a production-like environment.
