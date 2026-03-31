# MedinovAI Developer DevKit - Complete Development Guide

## Table of Contents

1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Architecture Overview](#architecture-overview)
4. [Development Environment Setup](#development-environment-setup)
5. [Core Development Practices](#core-development-practices)
6. [API Development](#api-development)
7. [Agent Mesh Development](#agent-mesh-development)
8. [UI/UX Development](#uiux-development)
9. [Testing Strategies](#testing-strategies)
10. [Security & Compliance](#security--compliance)
11. [Deployment & Operations](#deployment--operations)
12. [Troubleshooting](#troubleshooting)
13. [Best Practices](#best-practices)
14. [Reference Materials](#reference-materials)

---

## 1. Introduction

### What is the MedinovAI Developer DevKit?

The MedinovAI Developer DevKit is a comprehensive AI-powered development platform designed specifically for healthcare applications. It provides:

- **AI-Powered Code Analysis & Generation**: Automated code review, generation, and optimization
- **Conversational Interface**: Natural language interaction with development tools
- **Enterprise Compliance**: Built-in HIPAA, SOC 2, FDA compliance
- **Agent Mesh Architecture**: Specialized AI agents for different development tasks
- **Platform Integration**: Seamless integration with MedinovAI Suite services

### Key Benefits

- **70% faster development** through AI automation
- **100% compliance** with healthcare regulations
- **Enterprise-grade security** and audit trails
- **Scalable architecture** supporting 1000+ concurrent users
- **Comprehensive testing** with >85% coverage requirements

---

## 2. Getting Started

### Prerequisites

- Docker 28.3.3+ (OrbStack recommended for macOS)
- Docker Compose 2.39.1+
- Python 3.11+
- Node.js 18+ (for UI development)
- 8GB RAM minimum (16GB recommended)

### Quick Start

```bash
# Clone the repository
git clone https://github.com/medinovai/medinovai-0br-developer.git
cd medinovai-0br-developer

# Deploy with OrbStack (recommended for M4 Macs)
chmod +x deploy-orbstack.sh
./deploy-orbstack.sh

# Or standard deployment
chmod +x deploy-permanent.sh
./deploy-permanent.sh
```

### Access Services

| Service | URL | Credentials |
|---------|-----|-------------|
| Grafana Dashboard | http://localhost:3000 | admin / medinovai_admin_2024 |
| Core API | http://localhost:8000 | - |
| API Documentation | http://localhost:8000/docs | - |
| Prometheus | http://localhost:9090 | - |

---

## 3. Architecture Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    MedinovAI DevKit                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐    │
│  │  Nginx  │──│Core API │──│ Ollama  │──│  Redis  │    │
│  │   :80   │  │  :8000  │  │ :11434  │  │  :6380  │    │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘    │
│       │            │                          │          │
│       │       ┌─────────┐                    │          │
│       │       │PostgreSQL│                   │          │
│       │       │  :5433   │                   │          │
│       │       └─────────┘                    │          │
│       │                                       │          │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐    │
│  │ Grafana │──│Prometheus│──│ Metrics │──│  CI/CD  │    │
│  │  :3000  │  │  :9090  │  │  :8001  │  │  :8002  │    │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Agent Mesh Architecture

```
┌─────────────────────────────────────────────────────────┐
│                 Router Agent (Orchestrator)              │
├─────────────────────────────────────────────────────────┤
│  CRUD Agent  │  Query/BI Agent  │  Security Agent      │
│  Workflow    │  LLM Ops Agent   │  Subscription Agent  │
│  Doc Agent   │  Geo/Schedule    │  UI Agent            │
│  Audit Agent │  (Compliance)    │                      │
└─────────────────────────────────────────────────────────┘
```

### Service Dependencies

- **medinovai-data-services**: Centralized data persistence
- **medinovai-security**: Authentication via Keycloak
- **medinovai-subscription**: Entitlement management
- **medinovai-healthLLM**: AI/ML orchestration

---

## 4. Development Environment Setup

### Local Development Setup

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements-dev.txt

# Set environment variables
export DATA_SERVICE_URL="http://localhost:8001"
export SECURITY_SERVICE_URL="http://localhost:8002"
export SUBSCRIPTION_SERVICE_URL="http://localhost:8003"
export HEALTHLLM_SERVICE_URL="http://localhost:8004"
export OLLAMA_URL="http://localhost:11434"

# Run the service
python core_app_fixed.py
```

### Docker Development

```bash
# Build development image
docker build -f Dockerfile.core -t medinovai-devkit:dev .

# Run with development configuration
docker-compose -f docker-compose.dev.yml up
```

### IDE Configuration

#### VS Code Settings

```json
{
  "python.defaultInterpreterPath": "./venv/bin/python",
  "python.linting.enabled": true,
  "python.linting.pylintEnabled": true,
  "python.formatting.provider": "black",
  "python.testing.pytestEnabled": true,
  "python.testing.pytestArgs": ["tests/"]
}
```

#### PyCharm Configuration

1. Set Python interpreter to virtual environment
2. Configure code style: Black formatter
3. Enable pytest as test runner
4. Set up Docker integration

---

## 5. Core Development Practices

### Repository Structure

```
medinovai-0br-developer/
├── core_app_fixed.py          # Main FastAPI application
├── requirements.txt           # Production dependencies
├── requirements-dev.txt       # Development dependencies
├── Dockerfile.core           # Container configuration
├── docker-compose.yml        # Service orchestration
├── docs/                     # Documentation
│   ├── ARCHITECTURE-REPO-BOUNDARIES.md
│   └── system-diagrams/
├── tests/                    # Test suite
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── data-contracts/           # API contracts
├── boundary-enforcement/     # Compliance tools
└── ui-integration/          # UI integration guides
```

### Code Organization

#### Service Layer Structure

```python
# core_app_fixed.py structure
from fastapi import FastAPI, Depends, HTTPException
from pydantic import BaseModel
import httpx
import structlog

# Configuration
SERVICE_NAME = "medinovai-developer"
SERVICE_VERSION = "2.0.0"

# Pydantic Models
class CodeAnalysisRequest(BaseModel):
    code: str
    language: str
    analysis_type: str = "security"
    context: Optional[str] = None

# Authentication Middleware
async def get_current_user(request: Request):
    # JWT validation via medinovai-security
    pass

# Business Logic
@app.post("/api/code/analyze")
async def analyze_code(request: CodeAnalysisRequest, user: dict = Depends(get_current_user)):
    # Implementation
    pass
```

### Development Workflow

1. **Feature Development**
   ```bash
   # Create feature branch
   git checkout -b feature/your-feature-name
   
   # Make changes
   # Run tests
   pytest tests/
   
   # Run linting
   black .
   flake8 .
   
   # Commit changes
   git add .
   git commit -m "feat: add your feature"
   ```

2. **Code Review Process**
   - All changes require PR review
   - Automated boundary checking
   - Security scanning
   - Test coverage validation

3. **Deployment Process**
   - Automated CI/CD pipeline
   - Blue-green deployment
   - Health checks and monitoring

---

## 6. API Development

### API Design Principles

1. **RESTful Design**: Follow REST conventions
2. **Consistent Response Format**: Standardized JSON responses
3. **Comprehensive Error Handling**: Detailed error messages
4. **Input Validation**: Pydantic model validation
5. **Authentication**: JWT token validation
6. **Audit Logging**: All operations logged

### API Endpoints

#### Code Analysis API

```python
@app.post("/api/code/analyze", response_model=CodeAnalysisResponse)
async def analyze_code(
    request: CodeAnalysisRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    Analyze code for issues and improvements
    
    - **code**: Code to analyze
    - **language**: Programming language
    - **analysis_type**: Type of analysis (security, performance, best_practices)
    - **context**: Additional context for analysis
    """
    # Validate subscription
    await validate_subscription(current_user, "code_analysis")
    
    # Call medinovai-healthLLM for analysis
    llm_response = await app.state.healthllm_client.post(
        "/api/analyze/code",
        json=request.dict()
    )
    
    # Store results and return response
    return CodeAnalysisResponse(...)
```

#### Code Generation API

```python
@app.post("/api/code/generate", response_model=CodeGenerationResponse)
async def generate_code(
    request: CodeGenerationRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    Generate code based on requirements
    
    - **requirements**: Code requirements description
    - **language**: Target programming language
    - **framework**: Framework to use (optional)
    - **context**: Additional context (optional)
    """
    # Implementation
    pass
```

### Request/Response Models

```python
class CodeAnalysisRequest(BaseModel):
    code: str = Field(..., description="Code to analyze")
    language: str = Field(..., description="Programming language")
    analysis_type: str = Field(default="security", description="Type of analysis")
    context: Optional[str] = Field(None, description="Additional context")

class CodeAnalysisResponse(BaseModel):
    analysis_id: str = Field(..., description="Unique analysis ID")
    issues: List[Dict[str, Any]] = Field(default_factory=list)
    suggestions: List[str] = Field(default_factory=list)
    compliance_status: str = Field(..., description="Compliance status")
    audit_trail: Dict[str, Any] = Field(..., description="Audit trail")
```

### Error Handling

```python
# Standard error responses
@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": {
                "code": exc.status_code,
                "message": exc.detail,
                "timestamp": datetime.utcnow().isoformat(),
                "request_id": request.state.request_id
            }
        }
    )
```

---

## 7. Agent Mesh Development

### Agent Architecture

Each agent in the mesh follows a standard pattern:

```python
class BaseAgent:
    def __init__(self, agent_type: str):
        self.agent_type = agent_type
        self.logger = structlog.get_logger()
    
    async def process_request(self, request: AgentRequest) -> AgentResponse:
        """Process agent request"""
        pass
    
    async def validate_input(self, input_data: dict) -> bool:
        """Validate input data"""
        pass
    
    async def execute_action(self, action: str, params: dict) -> dict:
        """Execute specific action"""
        pass
```

### Specialized Agents

#### CRUD Agent

```python
class CRUDAgent(BaseAgent):
    def __init__(self):
        super().__init__("crud")
        self.data_client = httpx.AsyncClient(base_url=DATA_SERVICE_URL)
    
    async def create_entity(self, entity_type: str, data: dict) -> dict:
        """Create new entity"""
        response = await self.data_client.post(f"/api/{entity_type}", json=data)
        return response.json()
    
    async def read_entity(self, entity_type: str, entity_id: str) -> dict:
        """Read entity by ID"""
        response = await self.data_client.get(f"/api/{entity_type}/{entity_id}")
        return response.json()
    
    async def update_entity(self, entity_type: str, entity_id: str, data: dict) -> dict:
        """Update entity"""
        response = await self.data_client.put(f"/api/{entity_type}/{entity_id}", json=data)
        return response.json()
    
    async def delete_entity(self, entity_type: str, entity_id: str) -> bool:
        """Delete entity"""
        response = await self.data_client.delete(f"/api/{entity_type}/{entity_id}")
        return response.status_code == 204
```

#### Query/BI Agent

```python
class QueryBIAgent(BaseAgent):
    def __init__(self):
        super().__init__("query_bi")
        self.data_client = httpx.AsyncClient(base_url=DATA_SERVICE_URL)
    
    async def execute_query(self, query: str, params: dict) -> dict:
        """Execute SQL query"""
        response = await self.data_client.post("/api/query/execute", json={
            "query": query,
            "params": params
        })
        return response.json()
    
    async def generate_chart(self, data: dict, chart_type: str) -> dict:
        """Generate chart data"""
        response = await self.data_client.post("/api/charts/generate", json={
            "data": data,
            "chart_type": chart_type
        })
        return response.json()
```

### Router Agent

```python
class RouterAgent:
    def __init__(self):
        self.agents = {
            "crud": CRUDAgent(),
            "query_bi": QueryBIAgent(),
            "security": SecurityAgent(),
            "subscription": SubscriptionAgent(),
            "workflow": WorkflowAgent(),
            "llm_ops": LLMOpsAgent(),
            "doc": DocAgent(),
            "geo_schedule": GeoScheduleAgent(),
            "ui": UIAgent(),
            "audit": AuditAgent()
        }
    
    async def route_request(self, intent: str, entity: str, action: str) -> dict:
        """Route request to appropriate agent"""
        agent_type = self.determine_agent(intent, entity, action)
        agent = self.agents[agent_type]
        return await agent.process_request(intent, entity, action)
    
    def determine_agent(self, intent: str, entity: str, action: str) -> str:
        """Determine which agent should handle the request"""
        # Implementation based on intent mapping
        pass
```

---

## 8. UI/UX Development

### Design System

The DevKit uses a unified design system with:

- **Design Tokens**: Consistent colors, typography, spacing
- **Component Library**: Reusable React components
- **Accessibility**: WCAG AA compliance
- **Responsive Design**: Mobile-first approach

### Kayak-Style Interface

```typescript
// Main layout component
const MedinovAIPortal: React.FC = () => {
  return (
    <div className="medinovai-portal">
      <Omnibox />
      <div className="main-layout">
        <FacetPanel />
        <ListView />
        <DetailPanel />
      </div>
    </div>
  );
};

// Omnibox command palette
const Omnibox: React.FC = () => {
  const [isOpen, setIsOpen] = useState(false);
  const [query, setQuery] = useState('');
  
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        setIsOpen(true);
      }
    };
    
    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, []);
  
  return (
    <CommandPalette
      isOpen={isOpen}
      onClose={() => setIsOpen(false)}
      query={query}
      onQueryChange={setQuery}
    />
  );
};
```

### Component Development

```typescript
// Example component with design system
interface OrderListProps {
  orders: Order[];
  onOrderSelect: (order: Order) => void;
  filters: OrderFilters;
}

const OrderList: React.FC<OrderListProps> = ({ orders, onOrderSelect, filters }) => {
  return (
    <div className="order-list">
      <VirtualizedList
        items={orders}
        itemHeight={60}
        renderItem={(order) => (
          <OrderListItem
            order={order}
            onClick={() => onOrderSelect(order)}
            className="order-list-item"
          />
        )}
      />
    </div>
  );
};
```

---

## 9. Testing Strategies

### Testing Pyramid

1. **Unit Tests** (70%): Test individual functions and components
2. **Integration Tests** (20%): Test service interactions
3. **E2E Tests** (10%): Test complete user workflows

### Unit Testing

```python
# test_code_analysis.py
import pytest
from fastapi.testclient import TestClient
from core_app_fixed import app

client = TestClient(app)

def test_analyze_code_success():
    """Test successful code analysis"""
    response = client.post(
        "/api/code/analyze",
        json={
            "code": "def hello(): print('world')",
            "language": "python",
            "analysis_type": "security"
        },
        headers={"Authorization": "Bearer valid_token"}
    )
    assert response.status_code == 200
    assert "analysis_id" in response.json()
    assert "issues" in response.json()

def test_analyze_code_invalid_language():
    """Test invalid language parameter"""
    response = client.post(
        "/api/code/analyze",
        json={
            "code": "def hello(): print('world')",
            "language": "invalid",
            "analysis_type": "security"
        },
        headers={"Authorization": "Bearer valid_token"}
    )
    assert response.status_code == 422
```

### Integration Testing

```python
# test_service_integration.py
import pytest
import httpx
from unittest.mock import AsyncMock

@pytest.mark.asyncio
async def test_healthllm_integration():
    """Test integration with medinovai-healthLLM"""
    mock_response = {
        "issues": [{"severity": "medium", "message": "Potential security issue"}],
        "suggestions": ["Add input validation"],
        "compliance_status": "compliant"
    }
    
    with httpx.Client() as client:
        # Mock the healthllm service response
        client.post = AsyncMock(return_value=httpx.Response(200, json=mock_response))
        
        response = await analyze_code_internal(
            code="def process(data): return data",
            language="python",
            analysis_type="security"
        )
        
        assert response["compliance_status"] == "compliant"
        assert len(response["issues"]) == 1
```

### E2E Testing

```typescript
// e2e/code-analysis.spec.ts
import { test, expect } from '@playwright/test';

test('complete code analysis workflow', async ({ page }) => {
  // Navigate to the application
  await page.goto('http://localhost:8000');
  
  // Login
  await page.fill('[data-testid="username"]', 'testuser');
  await page.fill('[data-testid="password"]', 'testpass');
  await page.click('[data-testid="login-button"]');
  
  // Open code analysis
  await page.click('[data-testid="code-analysis-tab"]');
  
  // Enter code
  await page.fill('[data-testid="code-input"]', 'def hello(): print("world")');
  await page.selectOption('[data-testid="language-select"]', 'python');
  
  // Submit analysis
  await page.click('[data-testid="analyze-button"]');
  
  // Verify results
  await expect(page.locator('[data-testid="analysis-results"]')).toBeVisible();
  await expect(page.locator('[data-testid="compliance-status"]')).toContainText('compliant');
});
```

### Test Coverage Requirements

- **Minimum 85% code coverage**
- **All public APIs must have tests**
- **All error conditions must be tested**
- **All security-critical paths must be tested**

```bash
# Run tests with coverage
pytest --cov=. --cov-report=html --cov-report=term

# Run specific test types
pytest tests/unit/          # Unit tests only
pytest tests/integration/   # Integration tests only
pytest tests/e2e/          # E2E tests only
```

---

## 10. Security & Compliance

### Authentication & Authorization

```python
# JWT token validation
async def get_current_user(request: Request):
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing authorization header")
    
    token = auth_header.split(" ")[1]
    
    # Validate with medinovai-security service
    response = await app.state.security_client.get(
        "/api/auth/validate",
        headers={"Authorization": f"Bearer {token}"}
    )
    
    if response.status_code != 200:
        raise HTTPException(status_code=401, detail="Invalid token")
    
    return response.json()

# Role-based access control
async def require_role(required_role: str):
    def role_checker(current_user: dict = Depends(get_current_user)):
        if required_role not in current_user.get("roles", []):
            raise HTTPException(status_code=403, detail="Insufficient permissions")
        return current_user
    return role_checker
```

### Data Protection

```python
# PHI/PII redaction
def redact_sensitive_data(data: dict) -> dict:
    """Redact sensitive information from data"""
    sensitive_fields = ["ssn", "dob", "phone", "email", "address"]
    
    for field in sensitive_fields:
        if field in data:
            data[field] = "[REDACTED]"
    
    return data

# Audit logging
async def log_audit_event(user: dict, action: str, resource_type: str, resource_id: str, details: dict):
    """Log audit event for compliance"""
    audit_event = {
        "user_id": user["user_id"],
        "action": action,
        "resource_type": resource_type,
        "resource_id": resource_id,
        "details": details,
        "timestamp": datetime.utcnow().isoformat(),
        "ip_address": "127.0.0.1",  # Get from request
        "user_agent": "MedinovAI-Developer/2.0.0"
    }
    
    await app.state.data_client.post("/api/audit-logs", json=audit_event)
```

### Compliance Requirements

#### HIPAA Compliance
- **PHI Protection**: All PHI encrypted at rest and in transit
- **Access Controls**: Role-based access with audit trails
- **Breach Notification**: Automated breach detection and notification
- **Data Minimization**: Only collect necessary data

#### SOC 2 Compliance
- **Security Controls**: Comprehensive security measures
- **Availability**: 99.9% uptime requirement
- **Processing Integrity**: Data processing validation
- **Confidentiality**: Sensitive data protection

#### 21 CFR Part 11 Compliance
- **Electronic Signatures**: Digital signature validation
- **Audit Trails**: Immutable change tracking
- **Data Integrity**: Tamper-proof data storage
- **Validation**: System validation procedures

---

## 11. Deployment & Operations

### Docker Configuration

```dockerfile
# Dockerfile.core
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create non-root user
RUN useradd --create-home --shell /bin/bash app
USER app

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Expose port
EXPOSE 8000

# Run application
CMD ["python", "core_app_fixed.py"]
```

### Kubernetes Deployment

```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: medinovai-developer
  labels:
    app: medinovai-developer
spec:
  replicas: 3
  selector:
    matchLabels:
      app: medinovai-developer
  template:
    metadata:
      labels:
        app: medinovai-developer
    spec:
      containers:
      - name: medinovai-developer
        image: medinovai/developer:latest
        ports:
        - containerPort: 8000
        env:
        - name: DATA_SERVICE_URL
          value: "http://medinovai-data-services:8000"
        - name: SECURITY_SERVICE_URL
          value: "http://medinovai-security:8000"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
```

### CI/CD Pipeline

```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      
      - name: Install dependencies
        run: |
          pip install -r requirements-dev.txt
      
      - name: Run linting
        run: |
          black --check .
          flake8 .
          mypy .
      
      - name: Run security scan
        run: |
          bandit -r .
          safety check
      
      - name: Run tests
        run: |
          pytest --cov=. --cov-report=xml
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage.xml
  
  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Build Docker image
        run: |
          docker build -f Dockerfile.core -t medinovai/developer:${{ github.sha }} .
      
      - name: Push to registry
        run: |
          echo ${{ secrets.DOCKER_PASSWORD }} | docker login -u ${{ secrets.DOCKER_USERNAME }} --password-stdin
          docker push medinovai/developer:${{ github.sha }}
  
  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Deploy to production
        run: |
          # Deployment steps
```

### Monitoring & Observability

```python
# Metrics collection
from prometheus_client import Counter, Histogram, generate_latest

REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint'])
REQUEST_DURATION = Histogram('http_request_duration_seconds', 'HTTP request duration')

@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    start_time = time.time()
    
    response = await call_next(request)
    
    duration = time.time() - start_time
    REQUEST_COUNT.labels(method=request.method, endpoint=request.url.path).inc()
    REQUEST_DURATION.observe(duration)
    
    return response

@app.get("/metrics")
async def metrics():
    return Response(generate_latest(), media_type="text/plain")
```

---

## 12. Troubleshooting

### Common Issues

#### Service Connection Issues

```bash
# Check service health
curl http://localhost:8000/health

# Check service dependencies
docker-compose ps

# View service logs
docker-compose logs medinovai-core
```

#### Authentication Issues

```python
# Debug authentication
import jwt
import requests

def debug_token(token: str):
    try:
        # Decode without verification to see payload
        payload = jwt.decode(token, options={"verify_signature": False})
        print(f"Token payload: {payload}")
        
        # Check with security service
        response = requests.get(
            "http://localhost:8002/api/auth/validate",
            headers={"Authorization": f"Bearer {token}"}
        )
        print(f"Validation response: {response.status_code}")
        
    except Exception as e:
        print(f"Token debug error: {e}")
```

#### Performance Issues

```python
# Performance monitoring
import time
import asyncio

async def monitor_performance():
    start_time = time.time()
    
    # Your operation
    result = await some_operation()
    
    duration = time.time() - start_time
    if duration > 2.0:  # Alert if > 2 seconds
        logger.warning(f"Slow operation detected: {duration}s")
    
    return result
```

### Debug Mode

```bash
# Enable debug logging
export LOG_LEVEL=DEBUG
export DEBUG=true

# Run with debug mode
python core_app_fixed.py --debug
```

### Health Checks

```python
# Comprehensive health check
@app.get("/health")
async def health_check():
    health_status = {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "service": SERVICE_NAME,
        "version": SERVICE_VERSION,
        "dependencies": {}
    }
    
    # Check each dependency
    dependencies = [
        ("data_service", DATA_SERVICE_URL),
        ("security_service", SECURITY_SERVICE_URL),
        ("subscription_service", SUBSCRIPTION_SERVICE_URL),
        ("healthllm_service", HEALTHLLM_SERVICE_URL),
        ("ollama", OLLAMA_URL)
    ]
    
    for name, url in dependencies:
        try:
            response = await httpx.get(f"{url}/health", timeout=5.0)
            health_status["dependencies"][name] = "healthy" if response.status_code == 200 else "unhealthy"
        except Exception as e:
            health_status["dependencies"][name] = f"unhealthy: {str(e)}"
            health_status["status"] = "degraded"
    
    return health_status
```

---

## 13. Best Practices

### Code Quality

1. **Follow PEP 8**: Use Black formatter and flake8 linter
2. **Type Hints**: Use type hints for all functions
3. **Docstrings**: Document all public functions and classes
4. **Error Handling**: Comprehensive error handling with proper HTTP status codes
5. **Logging**: Use structured logging with correlation IDs

### Security Best Practices

1. **Input Validation**: Validate all inputs with Pydantic models
2. **Authentication**: Always validate JWT tokens
3. **Authorization**: Check permissions for all operations
4. **Audit Logging**: Log all sensitive operations
5. **Data Protection**: Encrypt sensitive data and redact PHI/PII

### Performance Best Practices

1. **Async Operations**: Use async/await for I/O operations
2. **Connection Pooling**: Use connection pools for database connections
3. **Caching**: Cache frequently accessed data
4. **Pagination**: Implement pagination for large datasets
5. **Rate Limiting**: Implement rate limiting to prevent abuse

### Testing Best Practices

1. **Test Coverage**: Maintain >85% test coverage
2. **Test Isolation**: Each test should be independent
3. **Mock External Services**: Mock external dependencies in tests
4. **Test Data**: Use consistent test data fixtures
5. **Performance Tests**: Include performance tests for critical paths

---

## 14. Reference Materials

### API Documentation

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **OpenAPI Spec**: `/data-contracts/openapi-schema.yaml`

### Architecture Documentation

- **System Diagrams**: `/docs/system-diagrams/`
- **Repository Boundaries**: `/docs/ARCHITECTURE-REPO-BOUNDARIES.md`
- **Security Policies**: `/SECURITY.md`

### Development Resources

- **Contributing Guide**: `/CONTRIBUTING.md`
- **Code of Conduct**: `/CODE_OF_CONDUCT.md`
- **Changelog**: `/CHANGELOG.md`

### External Resources

- **FastAPI Documentation**: https://fastapi.tiangolo.com/
- **Pydantic Documentation**: https://pydantic-docs.helpmanual.io/
- **Docker Documentation**: https://docs.docker.com/
- **Kubernetes Documentation**: https://kubernetes.io/docs/

### Support Contacts

- **Architecture Team**: architecture@medinovai.com
- **Security Team**: security@medinovai.com
- **Backend Team**: backend@medinovai.com
- **DevOps Team**: devops@medinovai.com

---

## Conclusion

The MedinovAI Developer DevKit provides a comprehensive platform for healthcare application development with AI-powered assistance, enterprise-grade security, and regulatory compliance. By following this guide, your development team can effectively utilize the DevKit to build secure, compliant, and high-quality healthcare applications.

Remember to:
- Follow the established patterns and practices
- Maintain high code quality and test coverage
- Ensure compliance with healthcare regulations
- Use the agent mesh architecture effectively
- Leverage the conversational interface capabilities

For additional support or questions, please refer to the documentation links above or contact the appropriate team members.

---

**Document Version**: 1.0  
**Last Updated**: December 2024  
**Next Review**: January 2025
