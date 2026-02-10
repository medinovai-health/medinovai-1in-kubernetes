'''
# Testing Strategy

The testing strategy for the `medinovai-real-time-stream-bus` service is divided into three main categories:

1.  **Unit Tests:** These tests focus on verifying the functionality of individual components, such as utility functions and message handlers, in isolation.
2.  **Integration Tests:** These tests ensure that the service correctly interacts with external systems, including Redis for pub/sub functionality and the `medinovai-auth-service` for authentication.
3.  **End-to-End (E2E) Tests:** These tests simulate real-world scenarios by testing the entire data flow, from a client publishing a message to another client receiving it through a WebSocket connection.

## How to Run Tests

To run the tests, use the following command:

```bash
npm test
```

This will execute all unit, integration, and E2E tests.

## Coverage Requirements

All code must have a minimum of **80%** test coverage. Pull requests that do not meet this requirement will not be merged.

## Mocking Guidelines

- **Unit Tests:** All external dependencies should be mocked to ensure that the tests are fast and reliable.
- **Integration Tests:** Real instances of services like Redis can be used, but the `medinovai-auth-service` should be mocked to avoid dependencies on external systems during testing.
- **E2E Tests:** These tests should run against a real instance of the service, but may use a mock of the `medinovai-auth-service` for simplicity.
'''
