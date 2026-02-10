# Testing Strategy

This document outlines the testing strategy for the `medinovai-canary-rollout-orchestrator` service.

## Testing Levels

Our testing strategy includes three levels of testing:

1.  **Unit Tests:** These tests focus on individual components or functions in isolation. They are written using a testing framework like Jest or Mocha and use mocks for external dependencies.

2.  **Integration Tests:** These tests verify the interaction between different components of the service, such as the API endpoints and the database. They may involve running a local instance of the service and its dependencies (e.g., Redis).

3.  **End-to-End (E2E) Tests:** These tests simulate real-world user scenarios and test the entire system, including the UI, API, and dependent services. They are run against a staging environment that closely resembles production.

## How to Run Tests

To run the tests, use the following command:

```bash
make test
```

This will execute all unit and integration tests.

## Code Coverage

We aim for a minimum of **80% code coverage** for all new code. Pull requests that do not meet this requirement will not be merged.

## Mocking Guidelines

-   **Unit Tests:** All external dependencies, including databases, external APIs, and other MedinovAI services, must be mocked.
-   **Integration Tests:** Use a real database (e.g., a local Redis instance) but mock external services that are not part of the integration test scope.
