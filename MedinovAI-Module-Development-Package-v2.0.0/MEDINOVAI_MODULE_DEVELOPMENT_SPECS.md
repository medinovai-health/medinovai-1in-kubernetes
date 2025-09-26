# 🏥 MedinovAI Module Development Specifications

## 📋 Executive Summary

This document provides comprehensive specifications for developing new modules within the MedinovAI ecosystem. It defines the architectural patterns, standards, templates, and development workflows required to maintain consistency and quality across all MedinovAI services.

**Version**: 2.0.0  
**Last Updated**: September 26, 2025  
**Target Environment**: MacStudio M4 Ultra with OrbStack, Kubernetes, Istio

---

## 🎯 Architecture Overview

### Core Principles

1. **Microservices Architecture**: Each module is a self-contained service
2. **Healthcare-First**: All services optimized for medical workflows
3. **AI-Integrated**: Native AI/ML capabilities using Ollama
4. **Cloud-Native**: Kubernetes-native with Istio service mesh
5. **Security-First**: HIPAA-compliant security at every layer
6. **Observable**: Comprehensive monitoring and logging

### Service Categories

| Category | Port Range | Purpose | Examples |
|----------|------------|---------|----------|
| 🌐 API Services | 8000-8099 | Core business logic | api-gateway, patient-service |
| 🎨 Frontend Services | 8100-8199 | User interfaces | dashboard, portal |
| 🗄️ Database Services | 8200-8299 | Data persistence | postgresql, redis |
| 📊 Analytics Services | 8300-8399 | Reporting & metrics | analytics, reporting |
| 🤖 AI/ML Services | 8400-8499 | AI capabilities | healthllm, diagnosis-ai |
| 🔗 Integration Services | 8500-8599 | External integrations | hl7, fhir, epic |

---

## 🏗️ Service Architecture Patterns

### 1. FastAPI Service Template

**Standard Structure:**
```
service-name/
├── main.py              # FastAPI application
├── auth.py              # Authentication logic
├── models/              # Pydantic models
├── services/            # Business logic
├── utils/               # Utility functions
├── config.py            # Configuration
├── requirements.txt     # Dependencies
├── Dockerfile           # Container definition
├── k8s-deployment.yaml  # Kubernetes deployment
└── tests/               # Test suite
```

**Core Dependencies:**
```python
# requirements.txt template
fastapi==0.104.1
uvicorn[standard]==0.24.0
pydantic==2.5.0
httpx==0.25.2
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6
prometheus-client==0.19.0
structlog==23.2.0
```

### 2. Healthcare-Specific Features

**Authentication & Authorization:**
- JWT-based authentication
- Role-based access control (RBAC)
- Healthcare professional verification
- Patient consent management

**Security Requirements:**
- HIPAA compliance
- Data encryption at rest and in transit
- Audit logging for all data access
- PHI (Protected Health Information) handling

**AI Integration:**
- Ollama model integration
- Healthcare-specialized prompts
- Medical knowledge validation
- Clinical decision support

---

## 🔧 Development Standards

### 1. Code Quality

**Python Standards:**
- Type hints for all functions
- Docstrings for all public methods
- PEP 8 compliance
- Error handling with structured logging

**Example Service Structure:**
```python
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List
import structlog

# Configure structured logging
logger = structlog.get_logger()

app = FastAPI(
    title="MedinovAI [Service Name]",
    version="2.0.0",
    description="Healthcare [service description]"
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://*.medinovai.local"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)

class HealthCheck(BaseModel):
    status: str
    service: str
    version: str

@app.get("/health", response_model=HealthCheck)
async def health_check():
    """Health check endpoint for Kubernetes probes"""
    return HealthCheck(
        status="healthy",
        service="[service-name]",
        version="2.0.0"
    )
```

### 2. Configuration Management

**Environment Variables:**
```python
# config.py template
from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    # Service Configuration
    service_name: str = "medinovai-service"
    service_version: str = "2.0.0"
    
    # Database Configuration
    database_url: str = "postgresql://user:pass@localhost/db"
    redis_url: str = "redis://localhost:6379"
    
    # AI Configuration
    ollama_base_url: str = "http://ollama:11434"
    default_ai_model: str = "qwen2.5:32b"
    
    # Security Configuration
    jwt_secret_key: str
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    
    # CORS Configuration
    cors_origins: List[str] = ["https://*.medinovai.local"]
    
    class Config:
        env_file = ".env"

settings = Settings()
```

### 3. Database Integration

**PostgreSQL Pattern:**
```python
from sqlalchemy import create_engine, Column, Integer, String, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime

Base = declarative_base()

class BaseModel(Base):
    __abstract__ = True
    
    id = Column(Integer, primary_key=True, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    created_by = Column(String, nullable=False)

# Example healthcare model
class Patient(BaseModel):
    __tablename__ = "patients"
    
    mrn = Column(String, unique=True, index=True)  # Medical Record Number
    first_name = Column(String, nullable=False)
    last_name = Column(String, nullable=False)
    date_of_birth = Column(DateTime)
    phone = Column(String)
    email = Column(String)
```

---

## 🚀 Deployment Patterns

### 1. Kubernetes Deployment Template

```yaml
# k8s-deployment.yaml template
apiVersion: v1
kind: Namespace
metadata:
  name: medinovai
  labels:
    istio-injection: enabled
    pod-security.kubernetes.io/enforce: restricted

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: [service-name]-config
  namespace: medinovai
data:
  config.yaml: |
    database:
      host: postgresql.medinovai.svc.cluster.local
      port: 5432
    redis:
      host: redis.medinovai.svc.cluster.local
      port: 6379
    ollama:
      base_url: http://ollama.medinovai.svc.cluster.local:11434

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: [service-name]
  namespace: medinovai
  labels:
    app: [service-name]
    version: v1
spec:
  replicas: 3
  selector:
    matchLabels:
      app: [service-name]
  template:
    metadata:
      labels:
        app: [service-name]
        version: v1
      annotations:
        sidecar.istio.io/inject: "true"
    spec:
      serviceAccountName: medinovai-admin
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 2000
      containers:
      - name: [service-name]
        image: python:3.11-slim
        ports:
        - containerPort: 8000
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop: ["ALL"]
          seccompProfile:
            type: RuntimeDefault
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

---
apiVersion: v1
kind: Service
metadata:
  name: [service-name]
  namespace: medinovai
spec:
  selector:
    app: [service-name]
  ports:
  - port: 80
    targetPort: 8000
    name: http
```

### 2. Docker Configuration

```dockerfile
# Dockerfile template
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
RUN useradd --create-home --shell /bin/bash app \
    && chown -R app:app /app
USER app

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1

# Expose port
EXPOSE 8000

# Start application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## 🤖 AI Integration Patterns

### 1. Ollama Integration

```python
# AI service integration
import httpx
from typing import Dict, Optional

class AIService:
    def __init__(self, base_url: str = "http://ollama:11434"):
        self.base_url = base_url
        
    async def chat_completion(
        self, 
        message: str, 
        model: str = "qwen2.5:32b",
        system_prompt: Optional[str] = None
    ) -> Dict:
        """Send chat completion request to Ollama"""
        
        # Healthcare-specific system prompt
        default_prompt = """You are MedinovAI, a healthcare AI assistant.
        Provide accurate, evidence-based medical information.
        Always recommend consulting healthcare professionals for medical decisions.
        Maintain HIPAA compliance and patient confidentiality."""
        
        prompt = system_prompt or default_prompt
        
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                f"{self.base_url}/api/generate",
                json={
                    "model": model,
                    "prompt": f"System: {prompt}\n\nHuman: {message}\n\nAssistant:",
                    "stream": False,
                    "options": {
                        "temperature": 0.7,
                        "top_p": 0.9,
                        "num_ctx": 2048
                    }
                }
            )
            return response.json()
```

### 2. Healthcare-Specific AI Features

```python
# Healthcare AI specializations
class HealthcareAI:
    
    async def medical_diagnosis_assistant(self, symptoms: str, patient_history: str = ""):
        """AI-powered diagnosis assistance"""
        prompt = f"""
        Medical Consultation Analysis:
        
        Symptoms: {symptoms}
        Patient History: {patient_history}
        
        Please provide:
        1. Differential diagnosis considerations
        2. Recommended tests or evaluations
        3. Red flags requiring immediate attention
        4. Patient education points
        
        Remember: This is for healthcare professional assistance only.
        """
        return await self.chat_completion(prompt, model="qwen2.5:72b")
    
    async def drug_interaction_check(self, medications: List[str], conditions: List[str] = []):
        """Check for drug interactions and contraindications"""
        meds_str = ", ".join(medications)
        conditions_str = ", ".join(conditions)
        
        prompt = f"""
        Drug Interaction Analysis:
        
        Medications: {meds_str}
        Medical Conditions: {conditions_str}
        
        Analyze for:
        1. Drug-drug interactions
        2. Drug-condition contraindications
        3. Dosage considerations
        4. Monitoring requirements
        5. Alternative options if interactions exist
        """
        return await self.chat_completion(prompt, model="qwen2.5:32b")
```

---

## 🔒 Security Standards

### 1. Authentication Implementation

```python
# auth.py template
from fastapi import HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from passlib.context import CryptContext
from datetime import datetime, timedelta
from typing import Optional, Dict

# Security configuration
SECRET_KEY = "your-secret-key"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
security = HTTPBearer()

def create_access_token(data: Dict, expires_delta: Optional[timedelta] = None):
    """Create JWT access token"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def verify_token(token: str) -> Dict:
    """Verify and decode JWT token"""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise HTTPException(status_code=401, detail="Invalid token")
        return payload
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Get current user from JWT token"""
    return verify_token(credentials.credentials)

# Healthcare-specific authorization
def require_healthcare_professional(current_user: Dict = Depends(get_current_user)):
    """Require healthcare professional role"""
    if current_user.get("role") not in ["doctor", "nurse", "pharmacist", "admin"]:
        raise HTTPException(status_code=403, detail="Healthcare professional access required")
    return current_user

def require_patient_access(patient_id: str, current_user: Dict = Depends(get_current_user)):
    """Require patient access authorization"""
    user_role = current_user.get("role")
    user_id = current_user.get("sub")
    
    # Patients can only access their own data
    if user_role == "patient" and user_id != patient_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    # Healthcare professionals need proper authorization
    if user_role in ["doctor", "nurse"] and not has_patient_access(user_id, patient_id):
        raise HTTPException(status_code=403, detail="Patient access not authorized")
    
    return current_user
```

### 2. Data Protection

```python
# data_protection.py
from cryptography.fernet import Fernet
import hashlib
from typing import Any, Dict

class DataProtection:
    """HIPAA-compliant data protection utilities"""
    
    def __init__(self, encryption_key: bytes):
        self.cipher = Fernet(encryption_key)
    
    def encrypt_phi(self, data: str) -> str:
        """Encrypt Protected Health Information"""
        return self.cipher.encrypt(data.encode()).decode()
    
    def decrypt_phi(self, encrypted_data: str) -> str:
        """Decrypt Protected Health Information"""
        return self.cipher.decrypt(encrypted_data.encode()).decode()
    
    def hash_identifier(self, identifier: str) -> str:
        """Create irreversible hash of patient identifiers"""
        return hashlib.sha256(identifier.encode()).hexdigest()
    
    def anonymize_data(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Remove or hash identifying information"""
        sensitive_fields = ['ssn', 'phone', 'email', 'address', 'name']
        anonymized = data.copy()
        
        for field in sensitive_fields:
            if field in anonymized:
                if field in ['ssn', 'phone']:
                    anonymized[field] = self.hash_identifier(str(anonymized[field]))
                else:
                    del anonymized[field]
        
        return anonymized
```

---

## 📊 Monitoring & Observability

### 1. Metrics Collection

```python
# metrics.py
from prometheus_client import Counter, Histogram, Gauge, generate_latest
from fastapi import Request
import time

# Define metrics
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
REQUEST_DURATION = Histogram('http_request_duration_seconds', 'HTTP request duration')
ACTIVE_CONNECTIONS = Gauge('active_connections', 'Active connections')
AI_REQUESTS = Counter('ai_requests_total', 'Total AI requests', ['model', 'status'])
PATIENT_OPERATIONS = Counter('patient_operations_total', 'Patient operations', ['operation', 'status'])

class MetricsMiddleware:
    def __init__(self, app):
        self.app = app
    
    async def __call__(self, scope, receive, send):
        if scope["type"] == "http":
            start_time = time.time()
            
            # Process request
            await self.app(scope, receive, send)
            
            # Record metrics
            duration = time.time() - start_time
            method = scope["method"]
            path = scope["path"]
            
            REQUEST_DURATION.observe(duration)
            REQUEST_COUNT.labels(method=method, endpoint=path, status="200").inc()
        
        else:
            await self.app(scope, receive, send)

@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint"""
    return generate_latest()
```

### 2. Structured Logging

```python
# logging_config.py
import structlog
import logging
from typing import Dict, Any

def configure_logging():
    """Configure structured logging for healthcare compliance"""
    
    structlog.configure(
        processors=[
            structlog.stdlib.filter_by_level,
            structlog.stdlib.add_logger_name,
            structlog.stdlib.add_log_level,
            structlog.stdlib.PositionalArgumentsFormatter(),
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.UnicodeDecoder(),
            structlog.processors.JSONRenderer()
        ],
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        wrapper_class=structlog.stdlib.BoundLogger,
        cache_logger_on_first_use=True,
    )

class HealthcareLogger:
    """HIPAA-compliant logging utilities"""
    
    def __init__(self):
        self.logger = structlog.get_logger()
    
    def log_patient_access(self, user_id: str, patient_id: str, operation: str, success: bool):
        """Log patient data access for audit compliance"""
        self.logger.info(
            "patient_access",
            user_id=user_id,
            patient_id=patient_id,
            operation=operation,
            success=success,
            audit_event=True
        )
    
    def log_phi_operation(self, user_id: str, operation: str, data_type: str, success: bool):
        """Log PHI operations for compliance"""
        self.logger.info(
            "phi_operation",
            user_id=user_id,
            operation=operation,
            data_type=data_type,
            success=success,
            audit_event=True,
            phi_involved=True
        )
    
    def log_ai_interaction(self, user_id: str, model: str, query_type: str, success: bool):
        """Log AI interactions for audit trail"""
        self.logger.info(
            "ai_interaction",
            user_id=user_id,
            model=model,
            query_type=query_type,
            success=success,
            audit_event=True
        )
```

---

## 🧪 Testing Standards

### 1. Test Structure

```python
# tests/test_main.py
import pytest
from fastapi.testclient import TestClient
from unittest.mock import Mock, patch
from main import app

client = TestClient(app)

class TestHealthEndpoints:
    """Test health check endpoints"""
    
    def test_health_check(self):
        """Test health check returns correct status"""
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json()["status"] == "healthy"
    
    def test_root_endpoint(self):
        """Test root endpoint returns service info"""
        response = client.get("/")
        assert response.status_code == 200
        assert "MedinovAI" in response.json()["message"]

class TestAuthentication:
    """Test authentication and authorization"""
    
    def test_protected_endpoint_without_token(self):
        """Test protected endpoint rejects unauthenticated requests"""
        response = client.get("/api/v1/patients")
        assert response.status_code == 401
    
    @patch('auth.verify_token')
    def test_protected_endpoint_with_valid_token(self, mock_verify):
        """Test protected endpoint accepts valid token"""
        mock_verify.return_value = {"sub": "test_user", "role": "doctor"}
        
        response = client.get(
            "/api/v1/patients",
            headers={"Authorization": "Bearer valid_token"}
        )
        assert response.status_code == 200

class TestAIIntegration:
    """Test AI service integration"""
    
    @patch('httpx.AsyncClient.post')
    async def test_ai_chat_success(self, mock_post):
        """Test successful AI chat interaction"""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"response": "AI response"}
        mock_post.return_value = mock_response
        
        # Test implementation
        pass
    
    @patch('httpx.AsyncClient.post')
    async def test_ai_chat_timeout(self, mock_post):
        """Test AI chat timeout handling"""
        mock_post.side_effect = httpx.TimeoutException("Timeout")
        
        # Test fallback response
        pass

class TestHealthcareCompliance:
    """Test HIPAA and healthcare compliance features"""
    
    def test_phi_encryption(self):
        """Test PHI data encryption"""
        from data_protection import DataProtection
        
        key = Fernet.generate_key()
        dp = DataProtection(key)
        
        phi_data = "John Doe SSN: 123-45-6789"
        encrypted = dp.encrypt_phi(phi_data)
        decrypted = dp.decrypt_phi(encrypted)
        
        assert encrypted != phi_data
        assert decrypted == phi_data
    
    def test_audit_logging(self):
        """Test audit logging for compliance"""
        from logging_config import HealthcareLogger
        
        logger = HealthcareLogger()
        
        # Test that audit events are properly logged
        with patch.object(logger.logger, 'info') as mock_log:
            logger.log_patient_access("user123", "patient456", "read", True)
            mock_log.assert_called_once()
            
            call_args = mock_log.call_args
            assert call_args[1]["audit_event"] is True
```

### 2. Integration Tests

```python
# tests/test_integration.py
import pytest
import asyncio
from httpx import AsyncClient
from main import app

@pytest.mark.asyncio
class TestServiceIntegration:
    """Integration tests for service interactions"""
    
    async def test_full_patient_workflow(self):
        """Test complete patient management workflow"""
        async with AsyncClient(app=app, base_url="http://test") as client:
            # 1. Authenticate
            auth_response = await client.post("/api/auth/login", json={
                "username": "test_doctor",
                "password": "test_password"
            })
            assert auth_response.status_code == 200
            token = auth_response.json()["access_token"]
            
            headers = {"Authorization": f"Bearer {token}"}
            
            # 2. Create patient
            patient_data = {
                "first_name": "John",
                "last_name": "Doe",
                "date_of_birth": "1980-01-01",
                "mrn": "MRN123456"
            }
            create_response = await client.post(
                "/api/v1/patients", 
                json=patient_data, 
                headers=headers
            )
            assert create_response.status_code == 201
            
            # 3. Retrieve patient
            patient_id = create_response.json()["id"]
            get_response = await client.get(
                f"/api/v1/patients/{patient_id}",
                headers=headers
            )
            assert get_response.status_code == 200
            assert get_response.json()["mrn"] == "MRN123456"
    
    async def test_ai_diagnosis_workflow(self):
        """Test AI-powered diagnosis workflow"""
        async with AsyncClient(app=app, base_url="http://test") as client:
            # Mock authentication
            headers = {"Authorization": "Bearer test_token"}
            
            # Test diagnosis request
            diagnosis_request = {
                "message": "Patient presents with chest pain and shortness of breath",
                "model": "qwen2.5:72b"
            }
            
            response = await client.post(
                "/api/v1/ai/diagnose",
                json=diagnosis_request,
                headers=headers
            )
            
            assert response.status_code == 200
            result = response.json()
            assert "response" in result
            assert "differential" in result["response"].lower()
```

---

## 📚 Usage Examples

### 1. Creating a New Healthcare Service

```bash
# 1. Create service directory
mkdir medinovai-appointment-service
cd medinovai-appointment-service

# 2. Copy templates
cp ../templates/main.py .
cp ../templates/requirements.txt .
cp ../templates/Dockerfile .
cp ../templates/k8s-deployment.yaml .

# 3. Customize for appointment service
# Edit files to implement appointment-specific logic

# 4. Build and deploy
docker build -t medinovai-appointment-service:2.0.0 .
kubectl apply -f k8s-deployment.yaml
```

### 2. Implementing AI-Powered Feature

```python
# Example: AI-powered appointment scheduling
from ai_service import HealthcareAI

class AppointmentAI:
    def __init__(self):
        self.ai = HealthcareAI()
    
    async def suggest_appointment_time(
        self, 
        patient_preferences: str, 
        doctor_schedule: List[str],
        appointment_type: str
    ) -> Dict:
        """AI-powered appointment scheduling"""
        
        prompt = f"""
        Appointment Scheduling Assistant:
        
        Patient Preferences: {patient_preferences}
        Doctor Available Times: {', '.join(doctor_schedule)}
        Appointment Type: {appointment_type}
        
        Please suggest the best appointment time considering:
        1. Patient preferences and constraints
        2. Doctor availability
        3. Appointment type requirements (duration, preparation)
        4. Optimal scheduling for patient care
        
        Provide reasoning for your recommendation.
        """
        
        return await self.ai.chat_completion(prompt, model="qwen2.5:32b")
```

---

## 🔄 Development Workflow

### 1. Service Development Lifecycle

1. **Planning Phase**
   - Define service requirements
   - Choose appropriate service category and port
   - Design API endpoints and data models
   - Plan AI integration requirements

2. **Development Phase**
   - Use service templates as starting point
   - Implement business logic
   - Add healthcare-specific features
   - Integrate with Ollama AI services
   - Implement security and compliance features

3. **Testing Phase**
   - Unit tests for all functions
   - Integration tests with other services
   - Security testing for HIPAA compliance
   - AI functionality testing
   - Performance testing

4. **Deployment Phase**
   - Build Docker container
   - Deploy to Kubernetes cluster
   - Configure Istio service mesh
   - Set up monitoring and alerting
   - Validate deployment

5. **Monitoring Phase**
   - Monitor service health and performance
   - Track AI model usage and performance
   - Ensure compliance with healthcare regulations
   - Collect user feedback and metrics

### 2. Quality Gates

**Before Deployment:**
- [ ] All tests pass (unit, integration, security)
- [ ] Code review completed
- [ ] HIPAA compliance verified
- [ ] AI integration tested
- [ ] Performance benchmarks met
- [ ] Security scan passed
- [ ] Documentation updated

**Post-Deployment:**
- [ ] Health checks passing
- [ ] Metrics being collected
- [ ] Logs structured and compliant
- [ ] Service mesh integration verified
- [ ] AI services responding correctly

---

## 🛠️ Troubleshooting Guide

### Common Issues

1. **Service Won't Start**
   - Check environment variables
   - Verify database connections
   - Review container logs
   - Validate Kubernetes resources

2. **AI Integration Failures**
   - Verify Ollama service availability
   - Check model availability
   - Review timeout settings
   - Validate prompts and responses

3. **Authentication Issues**
   - Verify JWT configuration
   - Check token expiration
   - Review RBAC settings
   - Validate user roles

4. **Performance Issues**
   - Review resource limits
   - Check database query performance
   - Monitor AI response times
   - Analyze service dependencies

### Debugging Commands

```bash
# Check service status
kubectl get pods -n medinovai
kubectl describe pod <pod-name> -n medinovai

# View logs
kubectl logs <pod-name> -n medinovai -f

# Check service connectivity
kubectl exec -it <pod-name> -n medinovai -- curl http://service-name/health

# Monitor metrics
kubectl port-forward svc/prometheus 9090:9090 -n monitoring
```

---

## 📖 Additional Resources

- **MedinovAI Standards Repository**: https://github.com/medinovai/MedinovAI-AI-Standards-2
- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **Istio Service Mesh**: https://istio.io/latest/docs/
- **FastAPI Documentation**: https://fastapi.tiangolo.com/
- **HIPAA Compliance Guide**: [Internal Documentation]
- **Ollama Integration Guide**: https://ollama.ai/docs

---

**Document Version**: 2.0.0  
**Last Updated**: September 26, 2025  
**Next Review**: October 26, 2025
