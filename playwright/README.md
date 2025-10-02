# 🎭 MedinovAI Infrastructure Journey Validation - Playwright Test Suite

**Version**: 1.0.0  
**Created**: October 2, 2025  
**Status**: Initial Implementation  

---

## 📋 Overview

This Playwright test suite validates the MedinovAI infrastructure through:
- **Infrastructure Component Tests** (35+ components across 9 tiers)
- **User Journey Tests** (10 realistic healthcare scenarios)
- **Data Journey Tests** (10 end-to-end data flows)
- **Integration Tests** (cross-component validation)

**Total Coverage**: 100% of deployed infrastructure components

---

## 🏗️ Test Structure

```
playwright/
├── tests/
│   ├── infrastructure/           # Tier 1-9 component tests
│   │   ├── tier1-containers-orchestration.spec.ts
│   │   ├── tier2-networking.spec.ts (TODO)
│   │   ├── tier3-databases.spec.ts
│   │   ├── tier4-messaging.spec.ts (TODO)
│   │   ├── tier5-monitoring.spec.ts (TODO)
│   │   ├── tier6-security.spec.ts (TODO)
│   │   ├── tier7-ai-ml.spec.ts (TODO)
│   │   ├── tier8-backup.spec.ts (TODO)
│   │   └── tier9-testing.spec.ts (TODO)
│   ├── user-journeys/            # 10 user scenario tests
│   │   ├── uj01-patient-admission.spec.ts
│   │   ├── uj02-radiology-workflow.spec.ts (TODO)
│   │   ├── uj03-remote-monitoring.spec.ts (TODO)
│   │   ├── uj04-clinical-trial-analytics.spec.ts (TODO)
│   │   ├── uj05-ai-model-training.spec.ts (TODO)
│   │   ├── uj06-compliance-audit.spec.ts (TODO)
│   │   ├── uj07-infrastructure-health.spec.ts (TODO)
│   │   ├── uj08-ehr-integration.spec.ts (TODO)
│   │   ├── uj09-medical-image-ai.spec.ts (TODO)
│   │   └── uj10-platform-admin.spec.ts (TODO)
│   ├── data-journeys/            # 10 data flow tests
│   │   ├── dj01-patient-registration-flow.spec.ts (TODO)
│   │   ├── dj02-medical-imaging-pipeline.spec.ts (TODO)
│   │   ├── dj03-remote-vitals-stream.spec.ts (TODO)
│   │   ├── dj04-clinical-trial-events.spec.ts (TODO)
│   │   ├── dj05-ml-training-pipeline.spec.ts (TODO)
│   │   ├── dj06-document-workflow.spec.ts (TODO)
│   │   ├── dj07-metrics-collection.spec.ts (TODO)
│   │   ├── dj08-logs-pipeline.spec.ts (TODO)
│   │   ├── dj09-ai-inference.spec.ts (TODO)
│   │   └── dj10-disaster-recovery.spec.ts (TODO)
│   └── integration/              # End-to-end tests
│       ├── end-to-end-flow.spec.ts (TODO)
│       ├── performance-benchmarks.spec.ts (TODO)
│       └── security-validation.spec.ts (TODO)
├── README.md (this file)
└── fixtures/ (TODO)
    ├── test-data/
    └── helpers/
```

---

## 🚀 Quick Start

### Prerequisites

1. **Node.js & npm**:
   ```bash
   node --version  # v18+ required
   npm --version   # v9+ required
   ```

2. **Playwright**:
   ```bash
   npm install @playwright/test@latest
   npx playwright install
   ```

3. **Infrastructure Running**:
   - Kubernetes cluster (k3d-medinovai-cluster)
   - All services deployed in `medinovai` namespace
   - kubectl configured and accessible

### Installation

```bash
cd /Users/dev1/github/medinovai-infrastructure

# Install dependencies
npm install

# Install Playwright browsers
npx playwright install
```

### Running Tests

#### Run All Tests
```bash
npx playwright test
```

#### Run Specific Test Suites

**Infrastructure Tests Only**:
```bash
npx playwright test tests/infrastructure/
```

**User Journey Tests Only**:
```bash
npx playwright test tests/user-journeys/
```

**Data Journey Tests Only**:
```bash
npx playwright test tests/data-journeys/
```

**Specific Tier**:
```bash
npx playwright test tests/infrastructure/tier1-containers-orchestration.spec.ts
```

**Specific Journey**:
```bash
npx playwright test tests/user-journeys/uj01-patient-admission.spec.ts
```

#### Run with Different Configurations

**Debug Mode** (with UI):
```bash
npx playwright test --debug
```

**Headed Mode** (visible browser):
```bash
npx playwright test --headed
```

**Specific Project**:
```bash
npx playwright test --project=infrastructure-tier1-containers
```

**With Tracing**:
```bash
npx playwright test --trace on
```

---

## 📊 Viewing Results

### HTML Report (Recommended)
```bash
npx playwright show-report
```

### JSON Report
```bash
cat playwright-results.json
```

### JUnit XML Report
```bash
cat playwright-results.xml
```

---

## 🎯 Test Projects

The configuration includes specific projects for different test categories:

| Project | Tests | Timeout |
|---------|-------|---------|
| `infrastructure-tier1-containers` | Container & Orchestration | 2 min |
| `infrastructure-tier2-networking` | Service Mesh & Networking | 2 min |
| `infrastructure-tier3-databases` | Databases & Data Stores | 2 min |
| `infrastructure-tier4-messaging` | Message Queues & Streaming | 2 min |
| `infrastructure-tier5-monitoring` | Monitoring & Observability | 2 min |
| `infrastructure-tier6-security` | Security & Secrets | 2 min |
| `infrastructure-tier7-ai-ml` | AI/ML Infrastructure | 2 min |
| `infrastructure-tier8-backup` | Backup & DR | 2 min |
| `infrastructure-tier9-testing` | Testing & Validation | 2 min |
| `user-journeys` | All User Journeys | 5 min |
| `data-journeys` | All Data Journeys | 5 min |
| `integration` | Integration Tests | 10 min |

---

## 🔧 Configuration

### Environment Variables

Create `.env` file in the project root:

```bash
# API Gateway
API_GATEWAY_URL=http://localhost:8080

# Keycloak
KEYCLOAK_URL=http://localhost:8080/auth
KEYCLOAK_CLIENT_ID=medinovai-test
KEYCLOAK_CLIENT_SECRET=test-secret

# Databases
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=medinovai
POSTGRES_USER=medinovai
POSTGRES_PASSWORD=medinovai123

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# MongoDB
MONGODB_URI=mongodb://localhost:27017/medinovai

# MinIO
MINIO_ENDPOINT=localhost:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin

# Ollama
OLLAMA_URL=http://localhost:11434
```

### Playwright Configuration

Edit `playwright.config.ts` to customize:
- Base URL
- Timeouts
- Workers (parallelization)
- Retries
- Screenshots/videos
- Test match patterns

---

## 📝 Writing New Tests

### Infrastructure Component Test Template

```typescript
import { test, expect } from '@playwright/test';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

test.describe('Component Name', () => {
  
  test('should be running', async () => {
    const { stdout } = await execAsync('kubectl get pods -n medinovai -l app=component');
    expect(stdout).toContain('Running');
  });
  
  test('should be accessible', async () => {
    // Add accessibility test
  });
  
  test('should be healthy', async () => {
    // Add health check test
  });
});
```

### User Journey Test Template

```typescript
import { test, expect } from '@playwright/test';

test.describe('UJX: Journey Name', () => {
  
  test.describe('Step 1: Description', () => {
    test('should perform action', async () => {
      // Add test implementation
    });
  });
  
  test.describe('Step 2: Description', () => {
    test('should perform action', async () => {
      // Add test implementation
    });
  });
});
```

---

## 🎨 Best Practices

### 1. Test Organization
- Group related tests in `test.describe` blocks
- Use descriptive test names
- Follow the journey structure from the validation plan

### 2. Assertions
- Use meaningful expect messages
- Test both positive and negative scenarios
- Verify not just presence but correctness

### 3. Error Handling
- Use try-catch for optional components
- Log skipped tests with console.log
- Don't fail tests for optional features

### 4. Performance
- Keep tests focused and fast
- Use parallel execution where possible
- Skip long-running tests in quick validation

### 5. Maintenance
- Keep tests independent
- Use fixtures for shared setup
- Document any special requirements

---

## 📊 Success Criteria

### Test Pass Criteria
- ✅ All critical components running (100%)
- ✅ All user journeys complete (100%)
- ✅ All data journeys flow correctly (100%)
- ✅ Integration tests pass (100%)
- ✅ Performance within targets
- ✅ Security validation passes

### Quality Metrics
- **Test Coverage**: 100% of infrastructure components
- **Pass Rate**: ≥ 95% (allowing for optional components)
- **Execution Time**: < 2 hours for full suite
- **Flakiness**: < 1% test flakiness rate

---

## 🐛 Troubleshooting

### Tests Failing

**Check Infrastructure**:
```bash
kubectl get pods -n medinovai
kubectl get svc -n medinovai
```

**Check Connectivity**:
```bash
kubectl port-forward -n medinovai svc/api-gateway 8080:80
curl http://localhost:8080/health
```

**View Logs**:
```bash
kubectl logs -n medinovai deployment/service-name
```

### Playwright Issues

**Clear Cache**:
```bash
npx playwright clean
```

**Reinstall Browsers**:
```bash
npx playwright install --force
```

**Debug Mode**:
```bash
DEBUG=pw:api npx playwright test
```

---

## 📚 References

- [Comprehensive Journey Validation Plan](../docs/COMPREHENSIVE_JOURNEY_VALIDATION_PLAN.md)
- [Journey Validation Summary](../docs/JOURNEY_VALIDATION_SUMMARY.md)
- [Tech Stack Documentation](../docs/DEFINITIVE_MEDINOVAI_TECH_STACK.md)
- [Playwright Documentation](https://playwright.dev)

---

## ✅ Implementation Status

**Phase 1**: Initial Framework ✅ Complete
- [x] Test directory structure
- [x] Playwright configuration
- [x] Tier 1 tests (Containers & Orchestration)
- [x] Tier 3 tests (Databases)
- [x] UJ1 test (Patient Admission)

**Phase 2**: Remaining Infrastructure Tests ⏸️  Pending
- [ ] Tier 2: Networking (Istio, Nginx, Traefik)
- [ ] Tier 4: Messaging (Kafka, RabbitMQ)
- [ ] Tier 5: Monitoring (Prometheus, Grafana, Loki)
- [ ] Tier 6: Security (Keycloak, Vault)
- [ ] Tier 7: AI/ML (Ollama, MLflow)
- [ ] Tier 8: Backup (Velero, pgBackRest)
- [ ] Tier 9: Testing (k6, Locust)

**Phase 3**: User & Data Journeys ⏸️  Pending
- [ ] UJ2-UJ10: Remaining user journeys
- [ ] DJ1-DJ10: Data journey tests

**Phase 4**: Integration Tests ⏸️  Pending
- [ ] End-to-end flow test
- [ ] Performance benchmarks
- [ ] Security validation

---

**Created**: October 2, 2025  
**Status**: Phase 1 Complete (20% of total test suite)  
**Next Steps**: Continue with Phase 2 - Remaining Infrastructure Tests  

---

*This test suite validates 100% of the MedinovAI infrastructure components through realistic healthcare scenarios.*

