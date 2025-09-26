# 🎯 MedinovAI Cursor Development Prompts

## 📋 Overview

This document provides comprehensive Cursor AI prompts for developing new modules within the MedinovAI ecosystem. These prompts ensure consistency, quality, and compliance with healthcare standards across all development activities.

**Version**: 2.0.0  
**Target**: Cursor IDE with Claude Sonnet/GPT-4  
**Architecture**: MedinovAI Microservices on Kubernetes

---

## 🚀 Master Development Prompt

### Primary Prompt for New Module Development

```markdown
# MedinovAI Module Development Assistant

You are an expert healthcare software architect developing a new module for the MedinovAI ecosystem. Follow these strict requirements:

## 🏥 HEALTHCARE CONTEXT
- **Domain**: Healthcare technology with HIPAA compliance
- **Users**: Doctors, nurses, patients, healthcare administrators
- **Data**: Protected Health Information (PHI) requiring encryption
- **Regulations**: HIPAA, HITECH, FDA (where applicable)

## 🏗️ ARCHITECTURE REQUIREMENTS
- **Pattern**: Microservices with FastAPI
- **Deployment**: Kubernetes with Istio service mesh
- **Database**: PostgreSQL primary, Redis caching
- **AI Integration**: Ollama-based healthcare AI models
- **Security**: JWT authentication, RBAC, audit logging

## 🔧 TECHNICAL STANDARDS
- **Language**: Python 3.11+ with type hints
- **Framework**: FastAPI with Pydantic models
- **Testing**: Pytest with >90% coverage
- **Logging**: Structured JSON logging with audit trails
- **Monitoring**: Prometheus metrics, health checks

## 📊 SERVICE CATEGORIES & PORTS
- API Services: 8000-8099
- Frontend: 8100-8199  
- Database: 8200-8299
- Analytics: 8300-8399
- AI/ML: 8400-8499
- Integration: 8500-8599

## 🔒 SECURITY REQUIREMENTS
- All endpoints require authentication except /health
- PHI data must be encrypted at rest and in transit
- Audit logging for all data access
- Role-based access control (doctor, nurse, patient, admin)
- Input validation and sanitization

## 🤖 AI INTEGRATION
- Default model: qwen2.5:32b for general healthcare
- Specialized models: qwen2.5:72b for complex diagnosis
- Healthcare-specific prompts with safety warnings
- Fallback responses when AI unavailable

## 📝 DEVELOPMENT PROCESS
1. Create service structure with templates
2. Implement core business logic
3. Add authentication and authorization
4. Integrate AI capabilities
5. Add comprehensive testing
6. Create Kubernetes deployment manifests
7. Implement monitoring and logging

## 🎯 QUALITY REQUIREMENTS
- Type hints for all functions
- Docstrings for all public methods
- Error handling with structured logging
- Comprehensive unit and integration tests
- HIPAA compliance validation
- Performance optimization for healthcare workflows

When I provide a module specification, generate a complete, production-ready implementation following these standards.
```

---

## 🎨 Specialized Development Prompts

### 1. API Service Development

```markdown
# MedinovAI API Service Generator

Create a new healthcare API service with the following specifications:

## SERVICE TEMPLATE
```python
# Service Name: [SPECIFY]
# Port: 80XX (API Services range)
# Purpose: [DESCRIBE HEALTHCARE FUNCTION]
# Users: [HEALTHCARE ROLES]

## REQUIRED ENDPOINTS
- GET /health - Kubernetes health check
- POST /api/auth/login - JWT authentication
- GET /api/v1/[resource] - List resources with pagination
- POST /api/v1/[resource] - Create new resource
- GET /api/v1/[resource]/{id} - Get specific resource
- PUT /api/v1/[resource]/{id} - Update resource
- DELETE /api/v1/[resource]/{id} - Delete resource

## HEALTHCARE-SPECIFIC FEATURES
- Patient consent validation
- PHI data encryption
- Audit logging for all operations
- Role-based access control
- Medical record number (MRN) support
- Integration with healthcare standards (HL7, FHIR)

## AI INTEGRATION
- Ollama model integration for healthcare insights
- Medical terminology validation
- Clinical decision support features
- Natural language processing for medical text

Generate complete implementation including:
1. FastAPI application with all endpoints
2. Pydantic models with healthcare validations
3. Authentication and authorization
4. Database models with PHI protection
5. AI service integration
6. Comprehensive test suite
7. Kubernetes deployment manifests
8. Prometheus metrics and logging
```

### 2. AI/ML Service Development

```markdown
# MedinovAI AI Service Generator

Create a healthcare AI service with advanced medical capabilities:

## AI SERVICE REQUIREMENTS
- **Base Framework**: FastAPI with async support
- **AI Backend**: Ollama integration with healthcare models
- **Specialized Models**: qwen2.5:72b, deepseek-coder, codellama
- **Healthcare Focus**: Medical diagnosis, drug interactions, clinical support

## CORE CAPABILITIES
1. **Medical Chat**: General healthcare Q&A with safety warnings
2. **Diagnosis Assistant**: Differential diagnosis with evidence
3. **Drug Interaction Checker**: Medication safety analysis
4. **Clinical Documentation**: Medical note generation and analysis
5. **Medical Coding**: ICD-10, CPT code assistance
6. **Patient Education**: Health information in plain language

## SAFETY FEATURES
- Always recommend consulting healthcare professionals
- Include medical disclaimers in all responses
- Validate against medical knowledge bases
- Implement confidence scoring for recommendations
- Audit all AI interactions for compliance

## PERFORMANCE REQUIREMENTS
- Response time: <3 seconds for standard queries
- Fallback responses when AI unavailable
- Model switching based on query complexity
- Caching for common medical queries
- Rate limiting to prevent abuse

## INTEGRATION FEATURES
- RESTful API for other MedinovAI services
- WebSocket support for real-time interactions
- Batch processing for multiple queries
- Integration with electronic health records
- Support for medical imaging analysis

Generate complete AI service with:
1. Multi-model Ollama integration
2. Healthcare-specialized endpoints
3. Safety and compliance features
4. Performance optimization
5. Comprehensive testing with medical scenarios
6. Deployment configuration
```

### 3. Database Service Development

```markdown
# MedinovAI Database Service Generator

Create a HIPAA-compliant database service for healthcare data:

## DATABASE REQUIREMENTS
- **Primary**: PostgreSQL 15+ with encryption at rest
- **Caching**: Redis with PHI-safe configurations
- **Backup**: Automated encrypted backups
- **Compliance**: HIPAA, audit logging, data retention

## DATA MODELS
1. **Patient Management**
   - Patient demographics with PHI encryption
   - Medical record numbers (MRN)
   - Insurance information
   - Emergency contacts

2. **Clinical Data**
   - Medical history and conditions
   - Medications and allergies
   - Vital signs and measurements
   - Lab results and imaging

3. **Healthcare Providers**
   - Provider credentials and specialties
   - Licensing information
   - Hospital affiliations
   - Schedule and availability

4. **Audit and Compliance**
   - Data access logs
   - PHI access tracking
   - Consent management
   - Retention policies

## SECURITY FEATURES
- Field-level encryption for PHI
- Row-level security based on user roles
- Audit triggers for all data changes
- Automated PHI anonymization
- Secure backup and recovery

## PERFORMANCE OPTIMIZATION
- Indexing strategies for healthcare queries
- Partitioning for large datasets
- Connection pooling and caching
- Query optimization for medical workflows
- Real-time replication for high availability

Generate complete database service with:
1. PostgreSQL schema with healthcare models
2. PHI encryption and security features
3. Redis caching layer
4. Backup and recovery procedures
5. Performance monitoring and optimization
6. Kubernetes StatefulSet configuration
```

### 4. Frontend Service Development

```markdown
# MedinovAI Frontend Service Generator

Create a healthcare web application with modern UI/UX:

## FRONTEND REQUIREMENTS
- **Framework**: React 18+ with TypeScript
- **Styling**: Tailwind CSS with healthcare design system
- **State Management**: Redux Toolkit or Zustand
- **Authentication**: JWT with role-based UI
- **Accessibility**: WCAG 2.1 AA compliance

## HEALTHCARE UI COMPONENTS
1. **Patient Dashboard**
   - Medical record summary
   - Appointment scheduling
   - Test results display
   - Medication tracking

2. **Provider Interface**
   - Patient list with search/filter
   - Clinical documentation tools
   - AI-powered diagnosis assistance
   - Prescription management

3. **Administrative Tools**
   - User management and roles
   - Audit log viewing
   - System monitoring dashboards
   - Compliance reporting

## ACCESSIBILITY FEATURES
- Screen reader compatibility
- Keyboard navigation support
- High contrast mode for visual impairments
- Font size adjustment
- Voice input support for hands-free operation

## SECURITY FEATURES
- Automatic session timeout
- PHI data masking in UI
- Secure form handling
- Content Security Policy (CSP)
- XSS and CSRF protection

## INTEGRATION FEATURES
- Real-time updates via WebSocket
- Offline capability for critical functions
- Mobile-responsive design
- Print-friendly medical forms
- Export capabilities (PDF, CSV)

Generate complete frontend application with:
1. React components with TypeScript
2. Healthcare-specific UI patterns
3. Authentication and authorization
4. API integration with error handling
5. Comprehensive testing (Jest, React Testing Library)
6. Docker containerization
7. Kubernetes deployment
```

---

## 🔄 Development Workflow Prompts

### 1. Initial Setup Prompt

```markdown
# MedinovAI Module Setup Assistant

Set up a new MedinovAI module with complete project structure:

## PROJECT INITIALIZATION
```bash
# Module Name: [SPECIFY]
# Service Type: [API/Frontend/Database/AI/Integration]
# Port Assignment: [FROM APPROPRIATE RANGE]

## DIRECTORY STRUCTURE
Create the following structure:
```
[module-name]/
├── src/
│   ├── main.py              # FastAPI application
│   ├── models/              # Pydantic models
│   ├── services/            # Business logic
│   ├── auth/                # Authentication
│   ├── utils/               # Utilities
│   └── config.py            # Configuration
├── tests/
│   ├── unit/                # Unit tests
│   ├── integration/         # Integration tests
│   └── conftest.py          # Test configuration
├── k8s/
│   ├── deployment.yaml      # Kubernetes deployment
│   ├── service.yaml         # Kubernetes service
│   ├── configmap.yaml       # Configuration
│   └── secrets.yaml         # Secrets
├── docker/
│   ├── Dockerfile           # Container definition
│   └── docker-compose.yml   # Local development
├── docs/
│   ├── API.md               # API documentation
│   └── DEPLOYMENT.md        # Deployment guide
├── requirements.txt         # Python dependencies
├── pyproject.toml          # Project configuration
├── README.md               # Project overview
└── .env.example            # Environment template
```

## INITIAL FILES
Generate these files with MedinovAI standards:
1. FastAPI application with health endpoint
2. Basic authentication setup
3. Database connection configuration
4. Docker configuration for development
5. Kubernetes manifests for deployment
6. Test configuration and sample tests
7. Documentation templates

## DEVELOPMENT ENVIRONMENT
Set up local development with:
- Docker Compose for dependencies
- Hot reload for development
- Test database configuration
- Mock AI services for testing
- Local Kubernetes deployment
```

### 2. Testing Strategy Prompt

```markdown
# MedinovAI Testing Strategy Generator

Create comprehensive test suite for healthcare module:

## TESTING REQUIREMENTS
- **Coverage**: Minimum 90% code coverage
- **Types**: Unit, integration, security, performance
- **Healthcare Focus**: PHI protection, HIPAA compliance
- **AI Testing**: Model responses, fallback scenarios

## TEST CATEGORIES

### 1. Unit Tests
```python
# Test all business logic functions
# Mock external dependencies (database, AI services)
# Validate healthcare-specific calculations
# Test error handling and edge cases
```

### 2. Integration Tests
```python
# Test API endpoints with authentication
# Validate database operations with PHI
# Test AI service integration
# Verify service-to-service communication
```

### 3. Security Tests
```python
# Authentication and authorization
# PHI data encryption/decryption
# Input validation and sanitization
# SQL injection prevention
# XSS and CSRF protection
```

### 4. Compliance Tests
```python
# HIPAA audit logging
# Data retention policies
# Consent management
# Access control validation
# PHI anonymization
```

### 5. Performance Tests
```python
# API response times
# Database query performance
# AI model response times
# Concurrent user handling
# Memory and CPU usage
```

## HEALTHCARE TEST SCENARIOS
Create tests for:
- Patient data access by different roles
- Medical record creation and updates
- AI-powered diagnosis scenarios
- Drug interaction checking
- Emergency access procedures
- Data breach response procedures

Generate complete test suite with:
1. Pytest configuration and fixtures
2. Mock healthcare data generators
3. Security test cases
4. Performance benchmarks
5. CI/CD pipeline integration
6. Test reporting and coverage
```

### 3. Deployment Automation Prompt

```markdown
# MedinovAI Deployment Automation Generator

Create automated deployment pipeline for healthcare module:

## DEPLOYMENT REQUIREMENTS
- **Environment**: Kubernetes with Istio service mesh
- **Security**: Pod security standards, network policies
- **Monitoring**: Prometheus metrics, health checks
- **Compliance**: Audit logging, data protection

## KUBERNETES MANIFESTS

### 1. Namespace and Security
```yaml
# Namespace with Istio injection
# Pod security policies
# Network policies for isolation
# Service accounts with minimal permissions
```

### 2. Application Deployment
```yaml
# Deployment with healthcare-specific configurations
# ConfigMaps for non-sensitive configuration
# Secrets for PHI encryption keys and database credentials
# PersistentVolumes for data storage
```

### 3. Service and Networking
```yaml
# Service definitions with appropriate ports
# Istio VirtualService and DestinationRule
# NetworkPolicy for secure communication
# Ingress configuration with TLS
```

### 4. Monitoring and Observability
```yaml
# ServiceMonitor for Prometheus scraping
# PodMonitor for detailed metrics
# Grafana dashboard configuration
# Alert rules for healthcare-specific issues
```

## CI/CD PIPELINE
Create GitHub Actions/GitLab CI pipeline:

### 1. Build Stage
- Code quality checks (linting, formatting)
- Security scanning (SAST, dependency check)
- Unit test execution with coverage
- Docker image building with security scanning

### 2. Test Stage
- Integration tests with test database
- Security tests for HIPAA compliance
- Performance tests with benchmarks
- AI model validation tests

### 3. Deploy Stage
- Kubernetes manifest validation
- Deployment to staging environment
- Smoke tests and health checks
- Production deployment with blue-green strategy

### 4. Post-Deploy
- Monitoring setup and validation
- Audit log verification
- Performance monitoring
- Security compliance checks

Generate complete deployment automation with:
1. Kubernetes manifests with security hardening
2. CI/CD pipeline configuration
3. Monitoring and alerting setup
4. Backup and recovery procedures
5. Disaster recovery planning
6. Compliance validation scripts
```

---

## 🎯 Specialized Use Case Prompts

### 1. Patient Management System

```markdown
# Patient Management System Generator

Create a comprehensive patient management system for MedinovAI:

## SYSTEM REQUIREMENTS
- **Core Function**: Complete patient lifecycle management
- **Users**: Patients, doctors, nurses, administrators
- **Compliance**: HIPAA, HITECH, state healthcare regulations
- **Integration**: EHR systems, insurance providers, labs

## FEATURE SPECIFICATIONS

### 1. Patient Registration
- Demographic information collection
- Insurance verification
- Medical history intake
- Consent management
- Emergency contact registration

### 2. Medical Records Management
- Electronic health record (EHR) integration
- Medical history tracking
- Medication management
- Allergy and adverse reaction tracking
- Imaging and lab result management

### 3. Appointment Management
- Scheduling with provider availability
- Reminder notifications (SMS, email)
- Waitlist management
- Telemedicine appointment support
- Insurance authorization tracking

### 4. Clinical Workflows
- Visit documentation
- Diagnosis coding (ICD-10)
- Procedure coding (CPT)
- Prescription management
- Care plan development

### 5. AI-Powered Features
- Symptom assessment and triage
- Diagnosis assistance for providers
- Drug interaction checking
- Patient education content generation
- Predictive analytics for care management

## TECHNICAL ARCHITECTURE
- **API Service**: Patient data management (Port 8010)
- **Frontend**: Patient and provider portals (Port 8110)
- **AI Service**: Clinical decision support (Port 8410)
- **Database**: Encrypted patient data storage
- **Integration**: HL7 FHIR for healthcare interoperability

Generate complete patient management system with all components.
```

### 2. AI Diagnostic Assistant

```markdown
# AI Diagnostic Assistant Generator

Create an AI-powered diagnostic assistance system for healthcare providers:

## SYSTEM REQUIREMENTS
- **Purpose**: Support clinical decision-making with AI insights
- **Models**: Multiple specialized healthcare AI models
- **Safety**: Always recommend professional medical consultation
- **Evidence**: Provide evidence-based recommendations

## AI CAPABILITIES

### 1. Symptom Analysis
- Natural language processing of patient complaints
- Symptom clustering and pattern recognition
- Severity assessment and urgency scoring
- Red flag identification for immediate care

### 2. Differential Diagnosis
- Generate differential diagnosis lists
- Probability scoring based on symptoms
- Evidence-based reasoning for each diagnosis
- Recommendation for confirmatory tests

### 3. Treatment Recommendations
- Evidence-based treatment protocols
- Medication suggestions with dosing
- Alternative treatment options
- Contraindication checking

### 4. Drug Interaction Analysis
- Comprehensive drug-drug interaction checking
- Drug-condition contraindication analysis
- Dosage adjustment recommendations
- Alternative medication suggestions

### 5. Clinical Documentation
- SOAP note generation assistance
- ICD-10 and CPT code suggestions
- Clinical summary generation
- Discharge planning assistance

## MODEL CONFIGURATION
- **Primary**: qwen2.5:72b for complex diagnostic reasoning
- **Secondary**: qwen2.5:32b for routine clinical queries
- **Specialized**: Custom medical models for specific conditions
- **Fallback**: Rule-based system when AI unavailable

## SAFETY FEATURES
- Medical disclaimer on all responses
- Confidence scoring for recommendations
- Integration with medical knowledge bases
- Audit logging for all AI interactions
- Provider override capabilities

Generate complete AI diagnostic assistant with medical safety features.
```

### 3. Healthcare Analytics Platform

```markdown
# Healthcare Analytics Platform Generator

Create a comprehensive analytics platform for healthcare insights:

## PLATFORM REQUIREMENTS
- **Data Sources**: EHR, claims, lab results, patient surveys
- **Analytics**: Population health, quality metrics, financial analysis
- **Visualization**: Real-time dashboards, custom reports
- **Compliance**: HIPAA-compliant data processing and storage

## ANALYTICS CAPABILITIES

### 1. Population Health Analytics
- Disease prevalence and trends
- Risk stratification of patient populations
- Social determinants of health analysis
- Preventive care gap identification
- Chronic disease management metrics

### 2. Quality Metrics and Reporting
- HEDIS quality measures
- CMS quality reporting
- Patient safety indicators
- Clinical outcome metrics
- Provider performance analytics

### 3. Financial Analytics
- Revenue cycle analysis
- Cost per episode of care
- Payer mix analysis
- Denial rate tracking
- Resource utilization metrics

### 4. Operational Analytics
- Patient flow and throughput
- Staff productivity metrics
- Equipment utilization
- Appointment scheduling efficiency
- Emergency department metrics

### 5. Predictive Analytics
- Patient readmission risk scoring
- Disease progression modeling
- Resource demand forecasting
- Clinical deterioration prediction
- Population health trend analysis

## AI-POWERED INSIGHTS
- Machine learning models for predictive analytics
- Natural language processing for clinical notes
- Anomaly detection for quality issues
- Automated report generation
- Intelligent alerting and notifications

## TECHNICAL ARCHITECTURE
- **Data Pipeline**: Real-time and batch data processing
- **Storage**: Data lake with healthcare data models
- **Processing**: Distributed computing for large datasets
- **Visualization**: Interactive dashboards and reports
- **API**: RESTful API for data access and integration

Generate complete healthcare analytics platform with AI insights.
```

---

## 🔧 Maintenance and Optimization Prompts

### 1. Performance Optimization

```markdown
# MedinovAI Performance Optimization Assistant

Optimize existing MedinovAI module for healthcare performance requirements:

## PERFORMANCE TARGETS
- **API Response Time**: <500ms for 95th percentile
- **AI Response Time**: <3 seconds for diagnostic queries
- **Database Queries**: <100ms for patient lookups
- **Concurrent Users**: Support 1000+ concurrent healthcare workers

## OPTIMIZATION AREAS

### 1. Database Optimization
- Index optimization for healthcare queries
- Query performance analysis and tuning
- Connection pooling configuration
- Read replica setup for reporting
- Partitioning strategies for large datasets

### 2. API Performance
- Response caching for static healthcare data
- Async processing for long-running operations
- Request batching for bulk operations
- Connection pooling and keep-alive
- Compression for large payloads

### 3. AI Model Optimization
- Model selection based on query complexity
- Response caching for common medical queries
- Batch processing for multiple requests
- Model warm-up strategies
- Fallback mechanisms for high load

### 4. Kubernetes Optimization
- Resource requests and limits tuning
- Horizontal Pod Autoscaler configuration
- Vertical Pod Autoscaler for right-sizing
- Node affinity for optimal placement
- Network policies for efficient communication

## MONITORING AND METRICS
- Application Performance Monitoring (APM)
- Database performance metrics
- AI model response time tracking
- User experience metrics
- Resource utilization monitoring

Analyze current performance and generate optimization recommendations.
```

### 2. Security Hardening

```markdown
# MedinovAI Security Hardening Assistant

Enhance security posture of MedinovAI module for healthcare compliance:

## SECURITY REQUIREMENTS
- **HIPAA Compliance**: Full PHI protection and audit logging
- **Zero Trust**: Assume breach, verify everything
- **Defense in Depth**: Multiple security layers
- **Incident Response**: Rapid detection and response

## SECURITY ENHANCEMENTS

### 1. Application Security
- Input validation and sanitization
- SQL injection prevention
- XSS and CSRF protection
- Secure session management
- API rate limiting and throttling

### 2. Data Protection
- Field-level encryption for PHI
- Encryption in transit (TLS 1.3)
- Key management and rotation
- Data masking for non-production
- Secure data disposal

### 3. Authentication and Authorization
- Multi-factor authentication (MFA)
- Single sign-on (SSO) integration
- Role-based access control (RBAC)
- Principle of least privilege
- Regular access reviews

### 4. Infrastructure Security
- Container image scanning
- Pod security standards
- Network segmentation
- Secret management
- Vulnerability management

### 5. Monitoring and Incident Response
- Security event logging
- Anomaly detection
- Threat intelligence integration
- Automated incident response
- Forensic capabilities

## COMPLIANCE VALIDATION
- HIPAA security rule compliance
- SOC 2 Type II requirements
- NIST Cybersecurity Framework
- Healthcare-specific security standards
- Regular security assessments

Generate comprehensive security hardening plan with implementation steps.
```

### 3. Disaster Recovery Planning

```markdown
# MedinovAI Disaster Recovery Assistant

Create comprehensive disaster recovery plan for healthcare systems:

## RECOVERY REQUIREMENTS
- **RTO (Recovery Time Objective)**: <4 hours for critical systems
- **RPO (Recovery Point Objective)**: <15 minutes data loss
- **Availability**: 99.99% uptime for patient care systems
- **Compliance**: Maintain HIPAA compliance during recovery

## DISASTER RECOVERY COMPONENTS

### 1. Data Backup and Replication
- Automated encrypted backups
- Cross-region data replication
- Point-in-time recovery capabilities
- Backup validation and testing
- PHI-compliant backup procedures

### 2. System Redundancy
- Multi-region deployment strategy
- Database clustering and failover
- Load balancer redundancy
- DNS failover configuration
- Network redundancy planning

### 3. Recovery Procedures
- Automated failover processes
- Manual recovery procedures
- Data validation after recovery
- Service dependency management
- Communication protocols

### 4. Business Continuity
- Critical system prioritization
- Alternative workflow procedures
- Staff notification and training
- Vendor and partner coordination
- Patient care continuity plans

### 5. Testing and Validation
- Regular disaster recovery testing
- Tabletop exercises
- Recovery time measurement
- Process improvement based on tests
- Documentation updates

## HEALTHCARE-SPECIFIC CONSIDERATIONS
- Patient safety during outages
- Emergency access procedures
- Regulatory notification requirements
- Medical device integration
- Telemedicine backup plans

Generate complete disaster recovery plan with healthcare-specific procedures.
```

---

## 📚 Documentation Generation Prompts

### 1. API Documentation

```markdown
# MedinovAI API Documentation Generator

Generate comprehensive API documentation for healthcare module:

## DOCUMENTATION REQUIREMENTS
- **OpenAPI 3.0**: Complete specification with examples
- **Healthcare Context**: Medical use cases and workflows
- **Security**: Authentication and authorization details
- **Compliance**: HIPAA and regulatory considerations

## DOCUMENTATION SECTIONS

### 1. API Overview
- Service purpose and healthcare use cases
- Authentication and authorization methods
- Base URLs and versioning strategy
- Rate limiting and usage policies
- Error handling and status codes

### 2. Endpoint Documentation
- Complete endpoint descriptions
- Request/response schemas with healthcare examples
- Authentication requirements
- Role-based access information
- Healthcare workflow integration

### 3. Data Models
- Pydantic model documentation
- Healthcare-specific field descriptions
- Validation rules and constraints
- PHI handling requirements
- Data relationships and dependencies

### 4. Security Documentation
- Authentication flow diagrams
- Authorization matrix by role
- PHI protection mechanisms
- Audit logging requirements
- Compliance considerations

### 5. Integration Guides
- Healthcare system integration examples
- HL7 FHIR compatibility
- EHR integration patterns
- Third-party service connections
- SDK and client library usage

Generate complete API documentation with healthcare-specific examples.
```

### 2. Deployment Guide

```markdown
# MedinovAI Deployment Guide Generator

Create comprehensive deployment documentation for healthcare module:

## DEPLOYMENT DOCUMENTATION
- **Environment Setup**: Complete infrastructure requirements
- **Security Configuration**: HIPAA-compliant deployment
- **Monitoring Setup**: Healthcare-specific monitoring
- **Troubleshooting**: Common issues and solutions

## GUIDE SECTIONS

### 1. Prerequisites
- Infrastructure requirements
- Security prerequisites
- Compliance requirements
- Network and connectivity needs
- Resource allocation guidelines

### 2. Installation Steps
- Kubernetes cluster setup
- Database deployment and configuration
- Application deployment procedures
- Security hardening steps
- Monitoring and logging setup

### 3. Configuration
- Environment variable configuration
- Database connection setup
- AI model configuration
- Security policy implementation
- Compliance feature activation

### 4. Validation
- Deployment verification procedures
- Security testing protocols
- Performance validation tests
- Compliance audit procedures
- User acceptance testing

### 5. Operations
- Backup and recovery procedures
- Monitoring and alerting setup
- Log management configuration
- Incident response procedures
- Maintenance and update processes

Generate complete deployment guide with healthcare-specific procedures.
```

---

## 🎯 Quality Assurance Prompts

### 1. Code Review Checklist

```markdown
# MedinovAI Code Review Assistant

Perform comprehensive code review for healthcare module:

## REVIEW CRITERIA

### 1. Healthcare Compliance
- [ ] HIPAA compliance implemented
- [ ] PHI data properly encrypted
- [ ] Audit logging for all data access
- [ ] Role-based access control
- [ ] Input validation and sanitization

### 2. Security Review
- [ ] Authentication and authorization
- [ ] SQL injection prevention
- [ ] XSS and CSRF protection
- [ ] Secure session management
- [ ] Error handling without information disclosure

### 3. Code Quality
- [ ] Type hints for all functions
- [ ] Comprehensive docstrings
- [ ] Error handling with structured logging
- [ ] Unit test coverage >90%
- [ ] Integration tests for critical paths

### 4. Performance Review
- [ ] Database query optimization
- [ ] Async processing where appropriate
- [ ] Caching strategy implementation
- [ ] Resource usage optimization
- [ ] Scalability considerations

### 5. AI Integration Review
- [ ] Proper model selection and usage
- [ ] Healthcare-specific prompts
- [ ] Fallback mechanisms
- [ ] Safety warnings and disclaimers
- [ ] Performance optimization

Generate detailed code review report with specific recommendations.
```

### 2. Security Assessment

```markdown
# MedinovAI Security Assessment Assistant

Conduct comprehensive security assessment for healthcare module:

## SECURITY ASSESSMENT SCOPE
- **Application Security**: Code-level vulnerabilities
- **Data Protection**: PHI handling and encryption
- **Access Control**: Authentication and authorization
- **Infrastructure**: Kubernetes and network security
- **Compliance**: HIPAA and regulatory requirements

## ASSESSMENT AREAS

### 1. Vulnerability Assessment
- Static application security testing (SAST)
- Dynamic application security testing (DAST)
- Dependency vulnerability scanning
- Container image security scanning
- Infrastructure security assessment

### 2. PHI Protection Review
- Data encryption at rest and in transit
- Key management practices
- Data access logging and monitoring
- Data retention and disposal
- Anonymization and de-identification

### 3. Access Control Evaluation
- Authentication mechanism strength
- Authorization implementation
- Role-based access control (RBAC)
- Principle of least privilege
- Session management security

### 4. Infrastructure Security
- Kubernetes security configuration
- Network segmentation and policies
- Secret management practices
- Container security hardening
- Monitoring and logging security

### 5. Compliance Validation
- HIPAA Security Rule compliance
- HITECH Act requirements
- State healthcare regulations
- Industry best practices
- Audit readiness assessment

Generate comprehensive security assessment report with remediation priorities.
```

---

## 🎉 Conclusion

These prompts provide a comprehensive framework for developing high-quality, HIPAA-compliant healthcare modules within the MedinovAI ecosystem. Each prompt is designed to ensure consistency, security, and compliance while leveraging the full power of AI-assisted development.

**Usage Instructions:**
1. Copy the relevant prompt based on your development needs
2. Customize the specific requirements and parameters
3. Provide to Cursor AI for implementation
4. Review and validate the generated code
5. Follow the quality assurance procedures

**Remember:** Always validate AI-generated code for healthcare compliance and security requirements before deployment.

---

**Document Version**: 2.0.0  
**Last Updated**: September 26, 2025  
**Next Review**: October 26, 2025
