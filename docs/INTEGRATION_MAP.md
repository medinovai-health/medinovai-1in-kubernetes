- **Service Name**: `medinovai-infrastructure`

## 2. Upstream Dependencies

- **`medinovai-identity-service`**: For authenticating all API requests and service-to-service calls.
- **`medinovai-secrets-manager`**: For securely storing and retrieving cloud provider credentials, API keys, and other secrets.
- **Cloud Provider APIs (AWS, Azure, GCP)**: Direct integration with cloud provider control planes for resource provisioning.
- **HashiCorp Vault**: As a fallback or secondary secrets management system.

## 3. Downstream Consumers

- **All MedinovAI Application Services**: Any service requiring dedicated infrastructure (e.g., `medinovai-api-gateway`, `medinovai-data-services`, `medinovai-ml-training`).
- **CI/CD System (Jenkins/GitLab)**: To programmatically create ephemeral environments for integration testing.
- **`medinovai-deployment-service`**: To orchestrate the deployment of applications onto the provisioned infrastructure.

## 4. Event Bus Integration (Kafka)

- **Topics Published To**:
  - `infrastructure.provisioning.success`: Emits event when a resource is successfully created.
  - `infrastructure.provisioning.failure`: Emits event on provisioning failure.
  - `infrastructure.decommission.success`: Emits event when a resource is successfully removed.
  - `infrastructure.health.status`: Periodically emits health status of managed resources.
- **Topics Consumed From**:
  - `orchestration.provision.request`: Listens for requests to provision new infrastructure stacks.

## 5. Shared Data Models

- **`InfrastructureProvisionRequest`**: Standardized model for requesting new resources.
- **`ResourceStatus`**: Common model for reporting the state and health of a resource.
- **`CloudProviderCredentials`**: Schema for credentials consumed from the secrets manager.

## 6. Resilience and Fault Tolerance

- **Circuit Breaker Configuration**: 
  - **Target**: Calls to external Cloud Provider APIs.
  - **Threshold**: 5 consecutive failures.
  - **Reset Timeout**: 60 seconds.
- **Retry Policies**:
  - **Operations**: Idempotent operations like status checks or read-only calls.
  - **Strategy**: Exponential backoff (1s, 2s, 4s) with a maximum of 3 retries.

## 7. Health Check Dependencies

The service's overall health (`/health/live`) is dependent on:
- Connectivity to the primary database.
- Ability to communicate with the `medinovai-identity-service`.
- Health of the connection to the primary cloud provider's metadata service (e.g., AWS EC2 metadata endpoint).
