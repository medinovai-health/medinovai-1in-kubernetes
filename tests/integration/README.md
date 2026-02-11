# Integration Test Scaffolding

## 1. Test Environment Setup

To run the integration tests, you will need:

- A running Kubernetes cluster (e.g., Minikube, Kind).
- `kubectl` configured to connect to the cluster.
- `helm` for deploying test dependencies.

## 2. Required Service Dependencies

- **Prometheus:** For metrics collection.
- **Mock-server:** For simulating external API dependencies.

## 3. Mock Service Configuration

The mock server is configured using the files in the `mock-data` directory. These files define the expected requests and responses for each mocked service.

## 4. Test Data Seeding

Before running the tests, the database needs to be seeded with test data. This can be done by running the `seed-data.sh` script.

## 5. CI Pipeline Configuration

The integration tests are automatically run as part of the CI pipeline. The pipeline is configured in the `.gitlab-ci.yml` file.
