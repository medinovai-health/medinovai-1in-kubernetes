# 🛠️ MedinovAI Template Usage Guide

## 📋 Overview

This guide provides step-by-step instructions for using the MedinovAI templates to develop new healthcare modules. These templates ensure consistency, security, and compliance across all MedinovAI services.

**Templates Included:**
- FastAPI Service Template
- Kubernetes Deployment Template  
- Dockerfile Template
- Requirements Template
- Test Suite Template

---

## 🚀 Quick Start: Creating a New Service

### Step 1: Choose Service Category and Port

First, determine your service category and assign a port:

| Category | Port Range | Example Services |
|----------|------------|------------------|
| 🌐 API Services | 8000-8099 | patient-service (8010), appointment-service (8020) |
| 🎨 Frontend Services | 8100-8199 | patient-portal (8110), provider-dashboard (8120) |
| 🗄️ Database Services | 8200-8299 | patient-db (8210), analytics-db (8220) |
| 📊 Analytics Services | 8300-8399 | reporting-service (8310), metrics-service (8320) |
| 🤖 AI/ML Services | 8400-8499 | diagnosis-ai (8410), drug-checker (8420) |
| 🔗 Integration Services | 8500-8599 | hl7-service (8510), fhir-service (8520) |

### Step 2: Create Service Directory Structure

```bash
# Create service directory
mkdir medinovai-[service-name]
cd medinovai-[service-name]

# Create standard directory structure
mkdir -p {src,tests/{unit,integration},k8s,docs}
mkdir -p src/{models,services,utils,auth}
```

### Step 3: Copy and Customize Templates

```bash
# Copy templates from the infrastructure repository
cp ../medinovai-infrastructure/docs/templates/fastapi-service-template.py src/main.py
cp ../medinovai-infrastructure/docs/templates/requirements-template.txt requirements.txt
cp ../medinovai-infrastructure/docs/templates/Dockerfile-template Dockerfile
cp ../medinovai-infrastructure/docs/templates/k8s-deployment-template.yaml k8s/deployment.yaml
cp ../medinovai-infrastructure/docs/templates/pytest-template.py tests/test_main.py
```

### Step 4: Customize Templates

Replace placeholders in all templates:
- `[SERVICE_NAME]` → Your service name (e.g., `patient-service`)
- `[PORT]` → Your assigned port (e.g., `8010`)
- `[resource]` → Your main resource type (e.g., `patients`)

**Example for Patient Service:**
```bash
# Use sed to replace placeholders (macOS/Linux)
sed -i 's/\[SERVICE_NAME\]/patient-service/g' src/main.py k8s/deployment.yaml
sed -i 's/\[PORT\]/8010/g' src/main.py k8s/deployment.yaml Dockerfile
sed -i 's/\[resource\]/patients/g' src/main.py
```

---

## 📝 Detailed Template Customization

### 1. FastAPI Service Template (`main.py`)

#### Basic Customization
```python
# Replace these values at the top of main.py
SERVICE_NAME: str = "patient-service"  # Your service name
SERVICE_PORT: int = 8010               # Your assigned port

# Update the service description
app = FastAPI(
    title="MedinovAI Patient Service",
    version="2.0.0", 
    description="Comprehensive patient management for healthcare providers"
)
```

#### Add Service-Specific Models
```python
# Add to src/models/patient.py
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

class Patient(BaseModel):
    mrn: str = Field(..., description="Medical Record Number")
    first_name: str = Field(..., description="Patient first name")
    last_name: str = Field(..., description="Patient last name")
    date_of_birth: datetime = Field(..., description="Date of birth")
    phone: Optional[str] = Field(None, description="Phone number")
    email: Optional[str] = Field(None, description="Email address")
    
class PatientCreate(BaseModel):
    first_name: str
    last_name: str
    date_of_birth: datetime
    phone: Optional[str] = None
    email: Optional[str] = None

class PatientUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
```

#### Implement Service-Specific Endpoints
```python
# Replace the template endpoints with your actual implementation
@app.post("/api/v1/patients", response_model=Patient)
async def create_patient(
    patient: PatientCreate,
    current_user: Dict = Depends(require_healthcare_role)
):
    """Create a new patient record"""
    # Implement patient creation logic
    new_patient = Patient(
        mrn=generate_mrn(),
        **patient.dict()
    )
    
    # Save to database
    # Log audit event
    logger.info(
        "Patient created",
        user_id=current_user.get("sub"),
        patient_mrn=new_patient.mrn,
        audit_event=True
    )
    
    return new_patient
```

### 2. Kubernetes Deployment Template

#### Service-Specific Configuration
```yaml
# Update ConfigMap in k8s/deployment.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: patient-service-config
  namespace: medinovai
data:
  config.yaml: |
    service:
      name: patient-service
      version: "2.0.0"
      port: 8010
    
    # Add service-specific configuration
    patient_service:
      max_patients_per_provider: 1000
      mrn_format: "MRN{:08d}"
      consent_expiry_days: 365
```

#### Resource Requirements
```yaml
# Adjust resource requirements based on service needs
resources:
  requests:
    memory: "512Mi"    # Increase for data-heavy services
    cpu: "500m"        # Increase for AI services
  limits:
    memory: "1Gi"      # Set appropriate limits
    cpu: "1000m"
```

### 3. Dockerfile Customization

#### Service-Specific Dependencies
```dockerfile
# Add service-specific system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \    # For database services
    imagemagick \         # For image processing
    && rm -rf /var/lib/apt/lists/*
```

#### Build Arguments
```dockerfile
# Update build arguments
ARG SERVICE_NAME="patient-service"
ARG SERVICE_VERSION="2.0.0"
```

### 4. Requirements Template

#### Service-Specific Dependencies
```python
# Add to requirements.txt based on service needs

# For AI services, add:
torch==2.1.1
transformers==4.36.0
langchain==0.0.350

# For image processing services, add:
pillow==10.1.0
opencv-python==4.8.1.78

# For integration services, add:
python-hl7==0.3.4
fhir.resources==7.0.2
```

### 5. Test Template Customization

#### Service-Specific Test Cases
```python
# Update test_main.py with service-specific tests
class TestPatientService:
    """Test patient service specific functionality"""
    
    def test_create_patient_with_valid_data(self, client, healthcare_user_token, sample_patient_data):
        """Test patient creation with valid data"""
        headers = {"Authorization": f"Bearer {healthcare_user_token}"}
        response = client.post(
            "/api/v1/patients",
            json=sample_patient_data,
            headers=headers
        )
        assert response.status_code == 201
        data = response.json()
        assert "mrn" in data
        assert data["first_name"] == sample_patient_data["first_name"]
    
    def test_patient_mrn_uniqueness(self, client, healthcare_user_token, sample_patient_data):
        """Test that MRN is unique across patients"""
        headers = {"Authorization": f"Bearer {healthcare_user_token}"}
        
        # Create first patient
        response1 = client.post("/api/v1/patients", json=sample_patient_data, headers=headers)
        assert response1.status_code == 201
        
        # Try to create duplicate (should fail)
        response2 = client.post("/api/v1/patients", json=sample_patient_data, headers=headers)
        assert response2.status_code == 409  # Conflict
```

---

## 🔧 Development Workflow

### 1. Local Development Setup

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set environment variables
cp .env.example .env
# Edit .env with your local configuration

# Run locally
uvicorn src.main:app --host 0.0.0.0 --port 8010 --reload
```

### 2. Database Setup (if needed)

```bash
# Create database models
# src/models/database.py
from sqlalchemy import create_engine, Column, Integer, String, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

Base = declarative_base()

class Patient(Base):
    __tablename__ = "patients"
    
    id = Column(Integer, primary_key=True, index=True)
    mrn = Column(String, unique=True, index=True)
    first_name = Column(String, nullable=False)
    last_name = Column(String, nullable=False)
    # Add other fields...

# Run migrations
alembic init alembic
alembic revision --autogenerate -m "Initial migration"
alembic upgrade head
```

### 3. Testing

```bash
# Run all tests
pytest tests/ -v

# Run with coverage
pytest tests/ -v --cov=src --cov-report=html

# Run specific test categories
pytest tests/ -m "not load"      # Skip load tests
pytest tests/ -m "security"      # Security tests only
pytest tests/ -m "integration"   # Integration tests only
```

### 4. Docker Development

```bash
# Build image
docker build -t medinovai/patient-service:2.0.0 .

# Run container
docker run -d \
  --name patient-service \
  -p 8010:8010 \
  -e DATABASE_URL="postgresql://user:pass@host/db" \
  medinovai/patient-service:2.0.0

# Check logs
docker logs patient-service -f
```

### 5. Kubernetes Deployment

```bash
# Apply to cluster
kubectl apply -f k8s/deployment.yaml

# Check deployment status
kubectl get pods -n medinovai -l app=patient-service

# Check logs
kubectl logs -n medinovai -l app=patient-service -f

# Port forward for testing
kubectl port-forward -n medinovai svc/patient-service 8010:80
```

---

## 🎯 Service-Specific Examples

### Example 1: Patient Management Service

**Service Details:**
- Name: `patient-service`
- Port: `8010`
- Purpose: Comprehensive patient data management

**Key Features:**
```python
# Patient-specific endpoints
@app.post("/api/v1/patients")                    # Create patient
@app.get("/api/v1/patients")                     # List patients
@app.get("/api/v1/patients/{patient_id}")        # Get patient
@app.put("/api/v1/patients/{patient_id}")        # Update patient
@app.delete("/api/v1/patients/{patient_id}")     # Delete patient
@app.get("/api/v1/patients/{patient_id}/history") # Medical history
@app.post("/api/v1/patients/{patient_id}/consent") # Consent management
```

### Example 2: AI Diagnosis Service

**Service Details:**
- Name: `diagnosis-ai`
- Port: `8410`
- Purpose: AI-powered diagnostic assistance

**Key Features:**
```python
# AI-specific endpoints
@app.post("/api/v1/diagnose")                    # Diagnosis assistance
@app.post("/api/v1/differential-diagnosis")     # Differential diagnosis
@app.post("/api/v1/symptom-analysis")           # Symptom analysis
@app.post("/api/v1/drug-interactions")          # Drug interaction check
@app.get("/api/v1/models")                      # Available AI models
```

**AI Integration:**
```python
class DiagnosisAI:
    async def analyze_symptoms(self, symptoms: List[str], patient_history: str = ""):
        """Analyze symptoms for potential diagnoses"""
        prompt = f"""
        Medical Symptom Analysis:
        
        Symptoms: {', '.join(symptoms)}
        Patient History: {patient_history}
        
        Please provide:
        1. Most likely differential diagnoses
        2. Recommended diagnostic tests
        3. Red flags requiring immediate attention
        4. Patient education points
        
        Always recommend consulting a healthcare professional.
        """
        
        return await self.ai_service.chat_completion(
            message=prompt,
            model="qwen2.5:72b"  # Use large model for complex diagnosis
        )
```

### Example 3: Integration Service (HL7/FHIR)

**Service Details:**
- Name: `hl7-integration`
- Port: `8510`  
- Purpose: Healthcare data integration

**Key Features:**
```python
# Integration-specific endpoints
@app.post("/api/v1/hl7/inbound")                 # Receive HL7 messages
@app.post("/api/v1/hl7/outbound")                # Send HL7 messages
@app.get("/api/v1/fhir/patients/{patient_id}")   # FHIR patient resource
@app.post("/api/v1/fhir/observations")          # FHIR observations
@app.get("/api/v1/integration/status")          # Integration status
```

---

## 🔒 Security and Compliance Checklist

### Before Deployment:
- [ ] All PHI data is encrypted
- [ ] Audit logging is implemented
- [ ] Authentication/authorization is working
- [ ] Input validation is comprehensive
- [ ] SQL injection prevention is tested
- [ ] XSS prevention is implemented
- [ ] CORS is properly configured
- [ ] Rate limiting is enabled
- [ ] Error handling doesn't leak information
- [ ] Security headers are set

### HIPAA Compliance:
- [ ] PHI access is logged
- [ ] Data retention policies are implemented
- [ ] Consent management is working
- [ ] Data anonymization is available
- [ ] Breach notification procedures are documented
- [ ] Business Associate Agreements are in place

### AI Safety:
- [ ] Medical disclaimers are included
- [ ] Fallback responses are implemented
- [ ] Model responses are validated
- [ ] Confidence scoring is available
- [ ] Human oversight is maintained

---

## 🐛 Troubleshooting Common Issues

### Issue 1: Service Won't Start
```bash
# Check logs
kubectl logs -n medinovai -l app=[service-name]

# Common fixes:
# - Check environment variables
# - Verify database connectivity  
# - Check port conflicts
# - Review resource limits
```

### Issue 2: Database Connection Issues
```bash
# Test database connectivity
kubectl exec -it [pod-name] -n medinovai -- psql $DATABASE_URL -c "SELECT 1;"

# Common fixes:
# - Check database credentials
# - Verify network policies
# - Check SSL/TLS configuration
# - Review connection pool settings
```

### Issue 3: AI Service Integration Issues
```bash
# Test Ollama connectivity
kubectl exec -it [pod-name] -n medinovai -- curl http://ollama:11434/api/tags

# Common fixes:
# - Check Ollama service status
# - Verify model availability
# - Review timeout settings
# - Check network connectivity
```

### Issue 4: Authentication Problems
```bash
# Test JWT token
curl -H "Authorization: Bearer [token]" http://localhost:8010/api/v1/patients

# Common fixes:
# - Check JWT secret configuration
# - Verify token expiration
# - Review RBAC settings
# - Check user permissions
```

---

## 📚 Additional Resources

- **MedinovAI Development Specs**: `/docs/MEDINOVAI_MODULE_DEVELOPMENT_SPECS.md`
- **Cursor Development Prompts**: `/docs/CURSOR_DEVELOPMENT_PROMPTS.md`
- **Architecture Documentation**: `/docs/architecture/`
- **Security Guidelines**: `/docs/security/`
- **Deployment Guides**: `/docs/deployment/`

---

## 🎉 Next Steps

1. **Choose your service type** and assign a port
2. **Copy and customize templates** for your specific needs
3. **Implement business logic** following healthcare best practices
4. **Add comprehensive tests** including security and compliance
5. **Deploy to Kubernetes** using the provided manifests
6. **Monitor and maintain** using the built-in observability features

**Remember**: Always validate compliance with healthcare regulations and security requirements before deploying to production.

---

**Document Version**: 2.0.0  
**Last Updated**: September 26, 2025  
**Next Review**: October 26, 2025
