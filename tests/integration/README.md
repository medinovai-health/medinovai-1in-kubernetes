- **`medinovai-identity-service`**: For minting test JWTs.
- **`medinovai-secrets-manager`**: To provide credentials for mock cloud provider interactions.
- **LocalStack or similar mock cloud provider**: To simulate AWS/Azure/GCP APIs without incurring costs.

## 3. Mock Service Configuration

Run the following command to start the required mock services:

```bash
cd tests/integration/docker
docker-compose up -d
```

## 4. Test Data Seeding

Before running the test suite, the mock `medinovai-secrets-manager` needs to be seeded with test credentials.

```bash
python3 tests/integration/seed_secrets.py
```

## 5. Running Tests

Execute the integration test suite using:

```bash
pytest tests/integration/
```

## 6. CI Pipeline Configuration (`.gitlab-ci.yml`)

```yaml
stages:
  - test

integration_test:
  stage: test
  image: python:3.11
  services:
    - name: localstack/localstack:latest
      alias: localstack
    - name: docker:dind
  before_script:
    - pip install -r requirements.txt
    - # Commands to start mock identity and secrets services
  script:
    - pytest tests/integration/
```
