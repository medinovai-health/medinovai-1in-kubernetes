# Integration Testing: Real-Time Stream Bus

This document outlines the setup and execution of integration tests for the Real-Time Stream Bus.

## 1. Test Environment Setup

Integration tests are run in a Dockerized environment. To set up the test environment, run:

```bash
docker-compose -f tests/integration/docker-compose.yml up -d
```

## 2. Required Service Dependencies

The test environment includes the following services:

- A mock **Auth Service** that issues valid JWTs.
- A lightweight **Message Broker** (e.g., Redis Pub/Sub) for event handling.
- The **Real-Time Stream Bus** service itself.

## 3. Mock Service Configuration

The mock Auth Service is configured to accept any client credentials and issue a standard JWT. No special configuration is required.

## 4. Test Data Seeding

Before running the tests, the environment is seeded with a set of predefined streams and events. This is handled automatically by the test runner.

## 5. CI Pipeline Configuration

The integration tests are automatically executed on every pull request by the CI pipeline. The pipeline configuration can be found in `.github/workflows/integration-tests.yml`.
