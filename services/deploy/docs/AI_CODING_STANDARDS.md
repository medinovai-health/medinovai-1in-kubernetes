# MedinovAI AI Coding Standards and Cursor Rules
## Enterprise Healthcare & Life Sciences Development Standards

**Version:** 3.0.0  
**Last Updated:** 2025-01-01  
**Organization:** MedinovAI  
**Compliance:** FDA 510(k), EU MDR, ISO 13485, IEC 62304, HIPAA, GDPR  
**Distribution:** All MedinovAI Repositories  

---

## CRITICAL NOTICE FOR ALL AI MODELS

**YOU ARE ASSISTING IN THE DEVELOPMENT OF MEDICAL SOFTWARE WHERE LIVES DEPEND ON CODE QUALITY.**  
**EVERY LINE OF CODE YOU GENERATE OR MODIFY MUST MEET REGULATORY STANDARDS.**  
**PATIENT SAFETY IS THE ABSOLUTE PRIORITY - NO EXCEPTIONS.**

---

## Table of Contents

1. [Repository Structure](#repository-structure)
2. [Foundational Directives](#section-1-foundational-directives)
3. [Code Scanning Requirements](#section-2-code-scanning-and-analysis)
4. [Healthcare Coding Standards](#section-3-healthcare-coding-standards)
5. [Documentation Standards](#section-4-documentation-standards)
6. [Technology-Specific Guidelines](#section-5-technology-specific-guidelines)
7. [Safety Patterns](#section-6-safety-critical-patterns)
8. [Testing Requirements](#section-7-testing-requirements)
9. [Deployment Standards](#section-8-deployment-standards)
10. [AI Agent Configuration](#section-9-ai-agent-configuration)

---

## Repository Structure

### Central Configuration Approach

```
medinovai/
├── medinovai-ai-standards/           # Central AI standards repository
│   ├── .cursorrules                  # Master Cursor configuration
│   ├── CLAUDE.md                     # Claude AI instructions
│   ├── README.md                     # This document
│   ├── templates/                    # Template files for repos
│   │   ├── .cursorrules.template
│   │   ├── CLAUDE.md.template
│   │   └── .vscode/settings.json
│   └── scripts/
│       ├── deploy-standards.sh       # Deployment script
│       └── validate-compliance.py    # Compliance validator
│
├── medinovai-developer/              # Developer tools and utilities
│   ├── .cursorrules -> ../medinovai-ai-standards/.cursorrules
│   └── CLAUDE.md -> ../medinovai-ai-standards/CLAUDE.md
│
└── [other-128-repos]/               # All other repositories
    ├── .cursorrules                  # Repo-specific + import central
    └── CLAUDE.md                     # Repo-specific + import central
```

### Deployment Strategy

#### Option 1: Git Submodule (Recommended)

In each repository, add the standards as a submodule:

```bash
# In each repository root
git submodule add https://github.com/medinovai/medinovai-ai-standards.git .ai-standards
git submodule update --init --recursive

# Create local .cursorrules that imports central
echo 'import: .ai-standards/.cursorrules' > .cursorrules
echo '# Repository-specific rules below' >> .cursorrules
```

#### Option 2: Symbolic Links (For Monorepo)

```bash
# From repository root
ln -s ../medinovai-ai-standards/.cursorrules .cursorrules
ln -s ../medinovai-ai-standards/CLAUDE.md CLAUDE.md
```

#### Option 3: Reference Import

Create minimal `.cursorrules` in each repo:

```markdown
# Import MedinovAI Central Standards
@import https://raw.githubusercontent.com/medinovai/medinovai-ai-standards/main/.cursorrules

# Repository-Specific Configuration
repository_context:
  name: "specific-repo-name"
  type: "clinical-api|ml-model|frontend|infrastructure"
  compliance_level: "FDA-CLASS-II|FDA-CLASS-III"
  
# Additional repo-specific rules below...
```

---

## SECTION 1: FOUNDATIONAL DIRECTIVES

### 1.1 Core Identity and Purpose

You are a specialized AI coding assistant for MedinovAI's healthcare and life sciences software development. Your primary responsibility is ensuring patient safety through code quality and regulatory compliance.

### 1.2 MedinovAI Standards

```yaml
organization: MedinovAI
domains:
  - Clinical Decision Support Systems
  - Medical Device Software
  - Healthcare Data Analytics
  - Laboratory Information Systems
  - Telemedicine Platforms
  - AI/ML Medical Models

compliance_framework:
  fda:
    - 21 CFR Part 11 (Electronic Records)
    - 21 CFR Part 820 (Quality System Regulation)
    - FDA Software as Medical Device (SaMD)
    - FDA 510(k) Premarket Notification
  
  international:
    - ISO 13485:2016 (Medical Device QMS)
    - IEC 62304:2015 (Medical Device Software Lifecycle)
    - IEC 62366-1:2015 (Usability Engineering)
    - ISO 14971:2019 (Risk Management)
  
  data_protection:
    - HIPAA (US)
    - GDPR (EU)
    - PIPEDA (Canada)
    - DPDP Act 2023 (India)
    - UK Data Protection Act 2018
    - GCC Data Protection Regulations
  
  interoperability:
    - HL7 FHIR R4
    - DICOM 3.0
    - IHE Profiles
    - LOINC
    - SNOMED CT
    - ICD-10/ICD-11
```

### 1.3 MedinovAI Technology Stack

```yaml
primary_languages:
  backend:
    - .NET Core 8.0 / C# 12
    - Rust (safety-critical components)
    - Python 3.11+ (ML/AI models)
    - Go 1.21+ (high-performance services)
  
  frontend:
    - TypeScript 5.0+
    - React 18+
    - Swift (iOS)
    - Kotlin (Android)
  
infrastructure:
  cloud:
    - AWS (primary): ECS, Lambda, SageMaker, HealthLake
    - Azure (secondary): AKS, Functions, Cognitive Services
    - GCP (tertiary): GKE, Cloud Run, Healthcare API
  
  containers:
    - Docker
    - Kubernetes
    - AWS ECS/Fargate
  
  messaging:
    - Apache Kafka
    - AWS SQS/SNS
    - Azure Service Bus
    - RabbitMQ
  
databases:
  relational:
    - PostgreSQL 15+
    - MySQL 8.0+
    - SQL Server 2022
  
  nosql:
    - MongoDB 6.0+
    - Redis 7.0+
    - Elasticsearch 8.0+
    - AWS DynamoDB
  
  specialized:
    - TimescaleDB (time-series)
    - InfluxDB (metrics)
    - Neo4j (graph)
    - FHIR Server (clinical data)
```

---

## SECTION 2: CODE SCANNING AND ANALYSIS

### 2.1 Automatic Repository Analysis

Upon opening ANY MedinovAI repository or file:

```python
# AI must execute this mental checklist
def analyze_medinovai_code():
    """
    Comprehensive code analysis for MedinovAI repositories
    """
    
    # 1. Identify repository type
    repo_type = identify_repository_type()  # clinical|ml|frontend|infra
    
    # 2. Scan for compliance markers
    compliance_markers = scan_for_markers([
        "SAFETY-CRITICAL",
        "FDA-COMPLIANCE",
        "HIPAA-SENSITIVE", 
        "CLINICAL-VALIDATION",
        "AUDIT-REQUIRED",
        "MEDINOVAI-STANDARD"
    ])
    
    # 3. Check existing documentation
    documentation = check_documentation([
        "@regulatory",
        "@safety",
        "@validation",
        "@audit",
        "@clinical",
        "@medinovai"
    ])
    
    # 4. Assess risk level
    risk_level = assess_risk_level()  # A|B|C
    
    # 5. Verify MedinovAI patterns
    patterns = verify_patterns([
        "mos_variableName",  # MedinovAI variable pattern
        "E_CONSTANT_NAME",   # MedinovAI constant pattern
        "40_line_limit",     # Code block limit
        "comprehensive_docs" # Documentation requirement
    ])
    
    return ComplianceReport(repo_type, compliance_markers, documentation, risk_level, patterns)
```

### 2.2 MedinovAI-Specific Patterns

```typescript
// MedinovAI code patterns that AI must recognize and enforce

interface MedinovAIPatterns {
    // Naming conventions
    constants: /^E_[A_Z_]+$/;           // E_MAX_HEART_RATE
    variables: /^mos_[a-z][a-zA-Z]+$/;  // mos_patientRecord
    classes: /^[A-Z][a-zA-Z]+$/;        // PatientValidator
    interfaces: /^I[A-Z][a-zA-Z]+$/;    // IPatientService
    
    // File organization
    maxLinesPerFunction: 40;
    maxLinesPerFile: 500;
    maxCyclomaticComplexity: 10;
    
    // Documentation requirements
    requiresJsDoc: true;
    requiresRegulatoryTags: true;
    requiresSafetyComments: true;
    requiresAuditTrail: true;
}
```

---

## SECTION 3: HEALTHCARE CODING STANDARDS

### 3.1 MedinovAI Variable Naming Convention

```csharp
// C# Example - MedinovAI Standards
namespace MedinovAI.Clinical.Validation
{
    public class VitalSignsValidator
    {
        // Constants with E_ prefix (regulatory/safety limits)
        private const int E_MIN_HEART_RATE = 30;
        private const int E_MAX_HEART_RATE = 250;
        private const double E_MIN_OXYGEN_SATURATION = 70.0;
        
        // MedinovAI Object Storage with mos_ prefix
        private PatientRecord mos_currentPatient;
        private VitalSigns mos_latestVitals;
        private ValidationResult mos_validationResult;
        
        // Regular member variables (no prefix)
        private readonly ILogger<VitalSignsValidator> _logger;
        private readonly IAuditService _auditService;
        
        public ValidationResult ValidateVitalSigns(VitalSigns mos_vitals)
        {
            // Method implementation following 40-line limit
            try
            {
                // Validation logic here
                if (mos_vitals.HeartRate < E_MIN_HEART_RATE || 
                    mos_vitals.HeartRate > E_MAX_HEART_RATE)
                {
                    return new ValidationResult
                    {
                        IsValid = false,
                        FailureReason = "Heart rate out of safe range",
                        RequiresAlert = true
                    };
                }
                
                // Additional validation...
                return new ValidationResult { IsValid = true };
            }
            catch (Exception ex)
            {
                _logger.LogCritical(ex, "Critical error in vital signs validation");
                // Always fail safe
                return new ValidationResult
                {
                    IsValid = false,
                    FailureReason = "System error - manual review required",
                    RequiresAlert = true
                };
            }
        }
    }
}
```

### 3.2 MedinovAI Comment Structure

Every function in MedinovAI code handling patient data MUST include:

```python
def calculate_medication_dosage(
    mos_patientWeight: float,
    mos_drugConcentration: float,
    mos_patientAge: int
) -> DosageResult:
    """
    Calculate pediatric medication dosage with safety validation
    
    @medinovai:
        repository: medinovai-clinical-algorithms
        component: medication-calculator
        version: 2.1.0
    
    @regulatory:
        fda_ref: "FDA Guidance UCM070248 - Pediatric Dosing"
        eu_mdr: "MDR 2017/745 Annex II"
        iso_13485: "Section 7.3.3 - Design and Development Inputs"
        iec_62304: "Class B - Non-life-threatening injury possible"
    
    @safety:
        risk_level: "B"
        failure_mode: "Overdose or underdose possible"
        mitigation: "Triple validation with pharmacy review"
        clinical_impact: "Medication effectiveness and safety"
    
    @clinical:
        evidence: "Based on Nelson Textbook of Pediatrics, 21st Edition"
        validation_study: "NCT04567890 (n=5000)"
        accuracy: "99.2% agreement with clinical pharmacist review"
    
    @validation:
        test_protocol: "VAL-2024-MED-001"
        last_validated: "2024-12-15"
        next_review: "2025-06-15"
    
    @audit:
        logging: "All calculations logged with input parameters"
        retention: "7 years per FDA 21 CFR Part 11"
        phi_handling: "Patient ID anonymized in logs"
    
    @integration:
        hl7_fhir: "MedicationRequest, MedicationAdministration"
        external_systems: "Pharmacy Information System, CPOE"
        
    Args:
        mos_patientWeight: Patient weight in kilograms
        mos_drugConcentration: Drug concentration in mg/ml
        mos_patientAge: Patient age in years
        
    Returns:
        DosageResult: Calculated dosage with safety validations
        
    Raises:
        InvalidWeightException: If weight outside valid range (0.5-200kg)
        SafetyLimitExceededException: If calculated dose exceeds safety limit
    """
    # Implementation follows...
```

---

## SECTION 4: DOCUMENTATION STANDARDS

### 4.1 MedinovAI Repository Files

Every MedinovAI repository MUST contain:

```markdown
medinovai-[repository-name]/
├── .cursorrules                 # AI coding rules
├── CLAUDE.md                    # Claude-specific instructions
├── MEDINOVAI.md                # MedinovAI-specific context
├── REGULATORY.md               # Regulatory compliance documentation
├── SAFETY.md                   # Safety-critical components
├── CLINICAL.md                 # Clinical validation documentation
├── ARCHITECTURE.md             # System architecture
├── API.md                      # API documentation
├── DEPLOYMENT.md               # Deployment procedures
├── INCIDENT-RESPONSE.md        # Incident response procedures
├── .github/
│   ├── CODEOWNERS             # Code ownership
│   ├── workflows/
│   │   ├── compliance-check.yml
│   │   ├── safety-validation.yml
│   │   └── clinical-tests.yml
│   └── PULL_REQUEST_TEMPLATE.md
```

### 4.2 MEDINOVAI.md Template

```markdown
# MedinovAI Repository Context

## Repository Information
- **Name**: medinovai-[specific-name]
- **Type**: [Clinical API | ML Model | Frontend | Infrastructure]
- **Criticality**: [High | Medium | Low]
- **Regulatory Class**: [FDA Class II | FDA Class III | Non-regulated]

## MedinovAI Standards Applied
- Variable Naming: mos_ prefix for medical object storage
- Constant Naming: E_ prefix for regulatory limits
- Code Block Limit: 40 lines maximum
- Test Coverage: Minimum 95% for safety-critical code

## Clinical Context
- **Medical Domain**: [Cardiology | Radiology | Laboratory | etc.]
- **Patient Impact**: [Direct | Indirect | None]
- **Clinical Workflow**: [Description of clinical use]
- **Safety Considerations**: [Key safety requirements]

## Compliance Requirements
- FDA: [Specific FDA requirements]
- EU MDR: [Specific EU requirements]
- HIPAA: [PHI handling requirements]
- Clinical Standards: [HL7 FHIR profiles used]

## Integration Points
- External Systems: [List of integrated systems]
- APIs: [Key API endpoints]
- Data Sources: [Clinical data sources]
- Export Formats: [HL7, DICOM, etc.]

## Development Guidelines
- Primary Language: [.NET Core | Python | Rust | etc.]
- Testing Framework: [xUnit | pytest | etc.]
- Deployment Target: [AWS ECS | Kubernetes | etc.]
- Performance Requirements: [Latency, throughput targets]

## AI Coding Instructions
When modifying this repository:
1. Always maintain MedinovAI naming conventions
2. Ensure comprehensive error handling for patient safety
3. Add audit trail for all data modifications
4. Maintain regulatory compliance documentation
5. Update clinical validation tests
```

---

## SECTION 5: TECHNOLOGY-SPECIFIC GUIDELINES

### 5.1 .NET Core / C# Guidelines

```csharp
// MedinovAI .NET Core Standards
#region MedinovAI-AI-Context
/*
 * AI Assistant Context for MedinovAI .NET Development:
 * - Framework: .NET Core 8.0, C# 12
 * - Architecture: Clean Architecture with CQRS
 * - Testing: xUnit with FluentAssertions
 * - ORM: Entity Framework Core 8.0
 * - API: ASP.NET Core Web API with OpenAPI
 * - Security: HIPAA-compliant with JWT authentication
 * - Logging: Serilog with ELK Stack
 * - Patterns: Repository, Unit of Work, Mediator
 */
#endregion

namespace MedinovAI.Clinical.Services
{
    /// <summary>
    /// Patient data service with MedinovAI compliance
    /// </summary>
    [MedinovAICompliance("FDA-CFR-11", "HIPAA")]
    [ServiceLifetime(ServiceLifetime.Scoped)]
    public class PatientDataService : IPatientDataService
    {
        private readonly ILogger<PatientDataService> _logger;
        private readonly IMedinovAIAuditService _auditService;
        private readonly IPatientRepository _repository;
        
        // MedinovAI pattern: Constructor injection with guard clauses
        public PatientDataService(
            ILogger<PatientDataService> logger,
            IMedinovAIAuditService auditService,
            IPatientRepository repository)
        {
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
            _auditService = auditService ?? throw new ArgumentNullException(nameof(auditService));
            _repository = repository ?? throw new ArgumentNullException(nameof(repository));
        }
        
        public async Task<PatientRecord> GetPatientDataAsync(
            string mos_patientId,
            CancellationToken cancellationToken = default)
        {
            // MedinovAI pattern: Always use structured logging
            using var activity = Activity.StartActivity("GetPatientData");
            _logger.LogInformation("Retrieving patient data for {PatientId}", mos_patientId);
            
            try
            {
                // MedinovAI pattern: Audit before data access
                await _auditService.LogDataAccessAsync(new AuditEntry
                {
                    Action = "PatientDataAccess",
                    EntityId = mos_patientId,
                    Timestamp = DateTime.UtcNow,
                    UserId = _currentUser.Id
                });
                
                var mos_patientData = await _repository
                    .GetByIdAsync(mos_patientId, cancellationToken)
                    .ConfigureAwait(false);
                
                if (mos_patientData == null)
                {
                    _logger.LogWarning("Patient not found: {PatientId}", mos_patientId);
                    throw new PatientNotFoundException(mos_patientId);
                }
                
                return mos_patientData;
            }
            catch (Exception ex) when (!(ex is PatientNotFoundException))
            {
                _logger.LogError(ex, "Error retrieving patient data for {PatientId}", mos_patientId);
                throw new MedinovAIDataException("Failed to retrieve patient data", ex);
            }
        }
    }
}
```

### 5.2 Python ML/AI Guidelines

```python
"""
MedinovAI Python ML/AI Development Standards

AI Context:
- Python Version: 3.11+
- ML Framework: TensorFlow 2.14+ / PyTorch 2.0+
- Data Processing: pandas, numpy, scikit-learn
- Medical Imaging: SimpleITK, pydicom
- FHIR: fhirclient, fhir.resources
- Testing: pytest with hypothesis
- Type Checking: mypy with strict mode
- Code Quality: black, ruff, isort
"""

import logging
from typing import Optional, Tuple, Dict, Any
from dataclasses import dataclass, field
import numpy as np
import pandas as pd
from datetime import datetime

# MedinovAI logging configuration
logging.basicConfig(
    format='%(asctime)s - MedinovAI - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)
logger = logging.getLogger(__name__)

# MedinovAI constants
E_MIN_CONFIDENCE_THRESHOLD = 0.85
E_MAX_PREDICTION_LATENCY_MS = 500
E_MIN_TRAINING_SAMPLES = 1000


@dataclass
class MedinovAIPrediction:
    """
    MedinovAI standard prediction structure
    
    @medinovai: Standard prediction format for all ML models
    @regulatory: FDA SaMD Level II compliant structure
    """
    patient_id: str
    prediction: Any
    confidence: float
    timestamp: datetime = field(default_factory=datetime.utcnow)
    model_version: str = ""
    feature_importance: Dict[str, float] = field(default_factory=dict)
    clinical_explanation: str = ""
    requires_review: bool = False
    
    def __post_init__(self):
        """Validate prediction on initialization"""
        if self.confidence < 0 or self.confidence > 1:
            raise ValueError(f"Invalid confidence: {self.confidence}")
        
        if self.confidence < E_MIN_CONFIDENCE_THRESHOLD:
            self.requires_review = True
            logger.warning(
                f"Low confidence prediction for patient {self.patient_id}: "
                f"{self.confidence:.2f}"
            )


class MedinovAIModel:
    """
    Base class for all MedinovAI ML models
    
    @medinovai: Base class enforcing standards for all models
    @regulatory: FDA 21 CFR Part 11 compliant model management
    @clinical: Requires clinical validation before deployment
    """
    
    def __init__(
        self,
        model_name: str,
        model_version: str,
        regulatory_class: str = "FDA_CLASS_II"
    ):
        self.model_name = model_name
        self.model_version = model_version
        self.regulatory_class = regulatory_class
        self.mos_model = None  # MedinovAI pattern: mos_ prefix
        self.mos_preprocessor = None
        self.mos_postprocessor = None
        
        logger.info(
            f"Initializing MedinovAI Model: {model_name} v{model_version} "
            f"[{regulatory_class}]"
        )
    
    def predict(
        self,
        mos_patientData: pd.DataFrame,
        **kwargs
    ) -> MedinovAIPrediction:
        """
        Make prediction with MedinovAI safety checks
        
        @medinovai: Standard prediction interface
        @safety: Multiple validation layers
        @audit: All predictions logged
        """
        # Pre-prediction validation
        self._validate_input(mos_patientData)
        
        # Feature extraction with safety checks
        mos_features = self._extract_features(mos_patientData)
        
        # Prediction with timeout
        import signal
        
        def timeout_handler(signum, frame):
            raise TimeoutError("Prediction timeout exceeded")
        
        signal.signal(signal.SIGALRM, timeout_handler)
        signal.alarm(E_MAX_PREDICTION_LATENCY_MS // 1000)
        
        try:
            raw_prediction = self.mos_model.predict(mos_features)
            confidence = self._calculate_confidence(raw_prediction)
        finally:
            signal.alarm(0)
        
        # Post-processing and safety checks
        prediction = self._postprocess(raw_prediction, confidence)
        
        # Create MedinovAI standard prediction
        result = MedinovAIPrediction(
            patient_id=mos_patientData.get('patient_id', 'unknown'),
            prediction=prediction,
            confidence=confidence,
            model_version=self.model_version,
            feature_importance=self._get_feature_importance(),
            clinical_explanation=self._generate_explanation(prediction)
        )
        
        # Audit logging
        self._log_prediction(result)
        
        return result
    
    def _validate_input(self, data: pd.DataFrame) -> None:
        """MedinovAI input validation"""
        if data is None or data.empty:
            raise ValueError("Empty patient data provided")
        
        required_columns = self._get_required_columns()
        missing = set(required_columns) - set(data.columns)
        if missing:
            raise ValueError(f"Missing required columns: {missing}")
    
    def _log_prediction(self, prediction: MedinovAIPrediction) -> None:
        """MedinovAI audit logging"""
        logger.info(
            f"Prediction logged - Patient: {prediction.patient_id}, "
            f"Confidence: {prediction.confidence:.2f}, "
            f"Review Required: {prediction.requires_review}"
        )
```

### 5.3 Rust Safety-Critical Components

```rust
//! MedinovAI Rust Safety-Critical Component Standards
//! 
//! AI Context:
//! - Rust Version: 1.75+
//! - Safety: No unsafe code in medical components
//! - Testing: 100% coverage required
//! - Performance: Real-time guarantees required

#![forbid(unsafe_code)]
#![deny(clippy::all)]
#![warn(clippy::pedantic)]

use std::time::{Duration, Instant};
use thiserror::Error;
use serde::{Deserialize, Serialize};

/// MedinovAI constants following E_ prefix convention
const E_MAX_RESPONSE_TIME: Duration = Duration::from_millis(100);
const E_MIN_SENSOR_CONFIDENCE: f64 = 0.95;
const E_MAX_RETRY_ATTEMPTS: u32 = 3;

/// MedinovAI error types with safety focus
#[derive(Error, Debug)]
pub enum MedinovAIError {
    #[error("Critical safety violation: {0}")]
    SafetyViolation(String),
    
    #[error("Sensor reading out of range: {0}")]
    SensorOutOfRange(String),
    
    #[error("Response timeout exceeded: {0:?}")]
    TimeoutExceeded(Duration),
    
    #[error("Data validation failed: {0}")]
    ValidationFailed(String),
}

/// MedinovAI vital signs structure
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VitalSigns {
    /// MedinovAI pattern: mos_ prefix for medical object storage
    pub mos_patient_id: String,
    pub mos_heart_rate: Option<u16>,
    pub mos_blood_pressure: Option<BloodPressure>,
    pub mos_oxygen_saturation: Option<u8>,
    pub mos_temperature_celsius: Option<f32>,
    pub mos_timestamp: Instant,
}

impl VitalSigns {
    /// Validate vital signs with MedinovAI safety rules
    pub fn validate(&self) -> Result<(), MedinovAIError> {
        // Heart rate validation
        if let Some(hr) = self.mos_heart_rate {
            if hr < 30 || hr > 250 {
                return Err(MedinovAIError::SensorOutOfRange(
                    format!("Heart rate {} bpm out of safe range", hr)
                ));
            }
        }
        
        // Oxygen saturation validation
        if let Some(spo2) = self.mos_oxygen_saturation {
            if spo2 < 70 {
                return Err(MedinovAIError::SafetyViolation(
                    format!("Critical: SpO2 {} below safe threshold", spo2)
                ));
            }
        }
        
        Ok(())
    }
}

/// MedinovAI monitoring service
pub struct MedinovAIMonitor {
    mos_active_patients: Vec<String>,
    mos_alert_threshold: Duration,
}

impl MedinovAIMonitor {
    /// Process vital signs with MedinovAI safety guarantees
    pub fn process_vitals(&mut self, vitals: VitalSigns) -> Result<(), MedinovAIError> {
        let start = Instant::now();
        
        // Validate input
        vitals.validate()?;
        
        // Process with timeout enforcement
        let result = self.process_with_timeout(vitals, E_MAX_RESPONSE_TIME)?;
        
        // Verify timing constraint
        let elapsed = start.elapsed();
        if elapsed > E_MAX_RESPONSE_TIME {
            return Err(MedinovAIError::TimeoutExceeded(elapsed));
        }
        
        Ok(result)
    }
    
    fn process_with_timeout(
        &mut self,
        vitals: VitalSigns,
        timeout: Duration
    ) -> Result<(), MedinovAIError> {
        // MedinovAI processing logic here
        // Always fail safe on any error
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_vital_signs_validation() {
        // MedinovAI test pattern: comprehensive safety validation
        let vitals = VitalSigns {
            mos_patient_id: "TEST001".to_string(),
            mos_heart_rate: Some(75),
            mos_blood_pressure: None,
            mos_oxygen_saturation: Some(98),
            mos_temperature_celsius: Some(37.0),
            mos_timestamp: Instant::now(),
        };
        
        assert!(vitals.validate().is_ok());
    }
}
```

---

## SECTION 6: SAFETY-CRITICAL PATTERNS

### 6.1 Fail-Safe Design Pattern

```typescript
// MedinovAI TypeScript/JavaScript Safety Patterns

/**
 * MedinovAI Fail-Safe Wrapper
 * @medinovai Always fails to the safest state
 */
class MedinovAIFailSafe<T> {
    private readonly E_DEFAULT_SAFE_VALUE: T;
    private readonly E_MAX_RETRIES = 3;
    private readonly E_RETRY_DELAY_MS = 100;
    
    constructor(
        private readonly operation: () => Promise<T>,
        private readonly safeDefault: T,
        private readonly validator: (result: T) => boolean,
        private readonly logger: ILogger
    ) {
        this.E_DEFAULT_SAFE_VALUE = safeDefault;
    }
    
    async execute(): Promise<T> {
        let lastError: Error | null = null;
        
        // Try with retries
        for (let attempt = 1; attempt <= this.E_MAX_RETRIES; attempt++) {
            try {
                const result = await this.operation();
                
                // Validate result
                if (this.validator(result)) {
                    return result;
                } else {
                    this.logger.warn(
                        `MedinovAI validation failed on attempt ${attempt}`
                    );
                }
            } catch (error) {
                lastError = error as Error;
                this.logger.error(
                    `MedinovAI operation failed on attempt ${attempt}:`,
                    error
                );
                
                if (attempt < this.E_MAX_RETRIES) {
                    await this.delay(this.E_RETRY_DELAY_MS * attempt);
                }
            }
        }
        
        // All attempts failed - return safe default
        this.logger.critical(
            'MedinovAI: All attempts failed, returning safe default',
            { lastError, safeDefault: this.E_DEFAULT_SAFE_VALUE }
        );
        
        // Trigger alert for manual intervention
        await this.triggerSafetyAlert(lastError);
        
        return this.E_DEFAULT_SAFE_VALUE;
    }
    
    private delay(ms: number): Promise<void> {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
    
    private async triggerSafetyAlert(error: Error | null): Promise<void> {
        // MedinovAI pattern: Always alert on safety fallback
        await this.logger.sendAlert({
            level: 'CRITICAL',
            component: 'MedinovAIFailSafe',
            message: 'System fell back to safe default',
            error: error?.message,
            timestamp: new Date().toISOString(),
            requiresAcknowledgment: true
        });
    }
}

// Usage Example
const medicationCalculator = new MedinovAIFailSafe(
    async () => calculateDosage(patientData),
    0, // Safe default: no medication
    (dosage) => dosage >= 0 && dosage <= E_MAX_SAFE_DOSAGE,
    logger
);

const mos_calculatedDosage = await medicationCalculator.execute();
```

### 6.2 Audit Trail Pattern

```python
# MedinovAI Python Audit Trail Pattern

from functools import wraps
from typing import Any, Callable, TypeVar, cast
import json
import hashlib
from datetime import datetime
import asyncio

T = TypeVar('T')

class MedinovAIAuditTrail:
    """
    MedinovAI Audit Trail Implementation
    
    @medinovai: FDA 21 CFR Part 11 compliant audit trail
    @regulatory: Immutable, time-stamped, attributable
    """
    
    def __init__(self, service_name: str):
        self.service_name = service_name
        self.E_RETENTION_YEARS = 7  # FDA requirement
    
    def audit(self, 
              operation: str,
              risk_level: str = 'B') -> Callable:
        """
        Decorator for MedinovAI audit trail
        
        @medinovai: Apply to all data modification functions
        """
        def decorator(func: Callable[..., T]) -> Callable[..., T]:
            @wraps(func)
            async def async_wrapper(*args: Any, **kwargs: Any) -> T:
                # Pre-execution audit
                audit_entry = self._create_audit_entry(
                    operation, func.__name__, args, kwargs
                )
                
                try:
                    # Execute operation
                    result = await func(*args, **kwargs)
                    
                    # Post-execution audit
                    audit_entry['result'] = 'SUCCESS'
                    audit_entry['output_hash'] = self._hash_output(result)
                    
                    return result
                    
                except Exception as e:
                    # Audit failure
                    audit_entry['result'] = 'FAILURE'
                    audit_entry['error'] = str(e)
                    audit_entry['error_type'] = type(e).__name__
                    
                    # Re-raise for proper error handling
                    raise
                    
                finally:
                    # Always log audit entry
                    audit_entry['end_timestamp'] = datetime.utcnow().isoformat()
                    await self._persist_audit_entry(audit_entry)
            
            @wraps(func)
            def sync_wrapper(*args: Any, **kwargs: Any) -> T:
                # Synchronous version
                audit_entry = self._create_audit_entry(
                    operation, func.__name__, args, kwargs
                )
                
                try:
                    result = func(*args, **kwargs)
                    audit_entry['result'] = 'SUCCESS'
                    return result
                except Exception as e:
                    audit_entry['result'] = 'FAILURE'
                    audit_entry['error'] = str(e)
                    raise
                finally:
                    audit_entry['end_timestamp'] = datetime.utcnow().isoformat()
                    # Use sync persist method
                    self._persist_audit_entry_sync(audit_entry)
            
            # Return appropriate wrapper
            if asyncio.iscoroutinefunction(func):
                return cast(Callable[..., T], async_wrapper)
            else:
                return cast(Callable[..., T], sync_wrapper)
        
        return decorator
    
    def _create_audit_entry(self, operation: str, 
                           func_name: str,
                           args: tuple, 
                           kwargs: dict) -> dict:
        """Create MedinovAI audit entry"""
        return {
            'audit_id': self._generate_audit_id(),
            'service': self.service_name,
            'operation': operation,
            'function': func_name,
            'timestamp': datetime.utcnow().isoformat(),
            'user_id': self._get_current_user(),
            'session_id': self._get_session_id(),
            'input_hash': self._hash_inputs(args, kwargs),
            'medinovai_version': '3.0.0'
        }
    
    def _hash_inputs(self, args: tuple, kwargs: dict) -> str:
        """Create hash of inputs for integrity"""
        # Remove sensitive data before hashing
        safe_args = self._remove_phi(args)
        safe_kwargs = self._remove_phi(kwargs)
        
        combined = json.dumps({
            'args': safe_args,
            'kwargs': safe_kwargs
        }, sort_keys=True, default=str)
        
        return hashlib.sha256(combined.encode()).hexdigest()

# Usage Example
audit_trail = MedinovAIAuditTrail('PatientService')

@audit_trail.audit('PATIENT_DATA_UPDATE', risk_level='A')
async def update_patient_record(mos_patientId: str, 
                                mos_updates: dict) -> bool:
    """
    Update patient record with MedinovAI audit trail
    
    @medinovai: All modifications tracked
    @regulatory: FDA 21 CFR Part 11 compliance
    """
    # Implementation here
    pass
```

---

## SECTION 7: TESTING REQUIREMENTS

### 7.1 MedinovAI Test Standards

```python
# MedinovAI Testing Framework

import pytest
from hypothesis import given, strategies as st
from typing import List, Dict, Any
import coverage

class MedinovAITestFramework:
    """
    MedinovAI Comprehensive Testing Framework
    
    @medinovai: Enforces 95% coverage for safety-critical code
    @regulatory: IEC 62304 Section 5.5 - Software Unit Testing
    """
    
    # MedinovAI test requirements
    E_MIN_COVERAGE_SAFETY_CRITICAL = 95  # Percentage
    E_MIN_COVERAGE_STANDARD = 85         # Percentage
    E_MAX_TEST_EXECUTION_TIME = 300      # Seconds
    
    @staticmethod
    def generate_test_suite(module_name: str) -> str:
        """Generate MedinovAI-compliant test suite"""
        
        return f'''
import pytest
import numpy as np
from unittest.mock import Mock, patch, MagicMock
from hypothesis import given, strategies as st
from freezegun import freeze_time

# MedinovAI Test Patterns
class Test{module_name}MedinovAI:
    """
    MedinovAI Test Suite for {module_name}
    
    @medinovai: Comprehensive testing per MedinovAI standards
    @regulatory: IEC 62304 compliant unit tests
    @coverage: Minimum 95% for safety-critical paths
    """
    
    # Test Configuration
    E_TEST_TIMEOUT = 30  # seconds per test
    E_MAX_MEMORY_MB = 512
    
    @pytest.fixture(autouse=True)
    def setup_medinovai_test(self):
        """MedinovAI test setup"""
        # Initialize test data
        self.mos_validTestData = self.load_validated_test_data()
        self.mos_edgeCases = self.load_edge_cases()
        self.mos_errorCases = self.load_error_cases()
        
        # Setup mocks
        self.mock_audit = Mock()
        self.mock_logger = Mock()
        
        # Configure test environment
        self.configure_test_environment()
        
        yield
        
        # Cleanup
        self.cleanup_test_environment()
    
    # CATEGORY 1: Normal Operation Tests
    
    @pytest.mark.safety_critical
    def test_normal_operation_with_valid_data(self):
        """Test normal operation with validated clinical data"""
        # Arrange
        mos_input = self.mos_validTestData['normal_case']
        expected_output = self.get_expected_output('normal_case')
        
        # Act
        result = self.execute_function(mos_input)
        
        # Assert - MedinovAI comprehensive assertions
        assert result is not None, "Result should not be None"
        assert self.is_clinically_valid(result), "Result must be clinically valid"
        assert self.meets_safety_requirements(result), "Safety requirements not met"
        assert self.has_audit_trail(result), "Audit trail missing"
        assert result == expected_output, f"Expected {{expected_output}}, got {{result}}"
    
    # CATEGORY 2: Boundary Condition Tests
    
    @pytest.mark.parametrize("boundary_case", [
        ("minimum_valid", E_MIN_HEART_RATE),
        ("maximum_valid", E_MAX_HEART_RATE),
        ("threshold_exact", E_THRESHOLD_VALUE),
    ])
    def test_boundary_conditions(self, boundary_case):
        """Test MedinovAI boundary conditions"""
        case_name, value = boundary_case
        
        # Test at boundary
        result = self.process_value(value)
        assert self.is_safe_value(result), f"Unsafe at boundary: {{case_name}}"
        
        # Test beyond boundary if applicable
        if case_name == "minimum_valid":
            with pytest.raises(MedinovAIValidationError):
                self.process_value(value - 1)
        elif case_name == "maximum_valid":
            with pytest.raises(MedinovAIValidationError):
                self.process_value(value + 1)
    
    # CATEGORY 3: Error Handling Tests
    
    @pytest.mark.safety_critical
    def test_comprehensive_error_handling(self):
        """Test MedinovAI error handling"""
        error_scenarios = [
            'null_patient_data',
            'corrupted_sensor_reading',
            'network_timeout',
            'database_connection_lost',
            'invalid_clinical_range',
            'missing_required_fields',
            'concurrent_modification',
            'encryption_failure',
            'audit_system_failure'
        ]
        
        for scenario in error_scenarios:
            with self.subTest(scenario=scenario):
                # Arrange
                error_input = self.generate_error_input(scenario)
                
                # Act & Assert
                result = self.execute_with_error_handling(error_input)
                
                # MedinovAI safety assertions
                assert self.is_fail_safe_response(result), \\
                    f"Not fail-safe for {{scenario}}"
                assert self.error_was_logged(scenario), \\
                    f"Error not logged for {{scenario}}"
                assert self.alert_was_triggered_if_critical(scenario), \\
                    f"Critical alert not triggered for {{scenario}}"
    
    # CATEGORY 4: Property-Based Tests
    
    @given(
        heart_rate=st.integers(min_value=0, max_value=300),
        spo2=st.floats(min_value=0, max_value=100),
        temperature=st.floats(min_value=30, max_value=45)
    )
    def test_property_based_vital_signs(self, heart_rate, spo2, temperature):
        """Property-based testing for MedinovAI vital signs"""
        
        # Property 1: Output always within safe ranges
        result = self.process_vital_signs(heart_rate, spo2, temperature)
        assert self.is_within_safe_range(result), \\
            f"Output outside safe range for inputs: {{heart_rate}}, {{spo2}}, {{temperature}}"
        
        # Property 2: Never throws unhandled exception
        try:
            self.process_vital_signs(heart_rate, spo2, temperature)
        except MedinovAISafetyException:
            # Expected for unsafe values
            pass
        except Exception as e:
            pytest.fail(f"Unhandled exception: {{e}}")
        
        # Property 3: Always produces audit trail
        assert self.has_audit_entry(heart_rate, spo2, temperature), \\
            "Audit trail missing"
    
    # CATEGORY 5: Clinical Validation Tests
    
    @pytest.mark.clinical_validation
    def test_clinical_accuracy(self):
        """Test clinical accuracy per MedinovAI standards"""
        
        # Load clinical validation dataset
        clinical_cases = self.load_clinical_validation_cases()
        
        correct_predictions = 0
        total_cases = len(clinical_cases)
        
        for case in clinical_cases:
            prediction = self.make_clinical_prediction(case['input'])
            if self.is_clinically_equivalent(prediction, case['expected']):
                correct_predictions += 1
        
        accuracy = correct_predictions / total_cases
        
        # MedinovAI clinical accuracy requirement
        assert accuracy >= 0.95, \\
            f"Clinical accuracy {{accuracy:.2%}} below MedinovAI requirement of 95%"
    
    # CATEGORY 6: Performance Tests
    
    @pytest.mark.performance
    @pytest.mark.timeout(E_MAX_RESPONSE_TIME_MS / 1000)
    def test_response_time_requirements(self):
        """Test MedinovAI performance requirements"""
        import time
        
        # Prepare large dataset
        large_dataset = self.generate_large_dataset(10000)
        
        # Measure processing time
        start_time = time.time()
        result = self.process_dataset(large_dataset)
        end_time = time.time()
        
        processing_time_ms = (end_time - start_time) * 1000
        
        # MedinovAI performance assertions
        assert processing_time_ms < E_MAX_RESPONSE_TIME_MS, \\
            f"Processing time {{processing_time_ms}}ms exceeds limit"
        assert result is not None, "Result should not be None"
        assert len(result) == len(large_dataset), "All data should be processed"
    
    # CATEGORY 7: Integration Tests
    
    @pytest.mark.integration
    def test_hl7_fhir_integration(self):
        """Test HL7 FHIR integration per MedinovAI standards"""
        
        # Create FHIR resource
        fhir_patient = self.create_fhir_patient_resource()
        
        # Process through MedinovAI system
        result = self.process_fhir_resource(fhir_patient)
        
        # Validate FHIR compliance
        assert self.is_valid_fhir_resource(result), "Invalid FHIR resource"
        assert self.contains_required_profiles(result), "Missing required profiles"
        assert self.is_us_core_compliant(result), "Not US Core compliant"
    
    # CATEGORY 8: Security Tests
    
    @pytest.mark.security
    def test_hipaa_compliance(self):
        """Test HIPAA compliance per MedinovAI standards"""
        
        # Test encryption at rest
        stored_data = self.store_patient_data(self.mos_validTestData)
        assert self.is_encrypted(stored_data), "Data not encrypted at rest"
        
        # Test encryption in transit
        transmission = self.transmit_patient_data(self.mos_validTestData)
        assert self.uses_tls_1_3(transmission), "Not using TLS 1.3"
        
        # Test access controls
        unauthorized_access = self.attempt_unauthorized_access()
        assert unauthorized_access is False, "Unauthorized access permitted"
        
        # Test audit logging
        assert self.audit_log_complete(), "Audit log incomplete"
'''

    @staticmethod
    def validate_test_coverage(module_path: str) -> Dict[str, Any]:
        """Validate test coverage meets MedinovAI standards"""
        
        cov = coverage.Coverage()
        cov.start()
        
        # Run tests
        pytest.main([module_path, '-v'])
        
        cov.stop()
        cov.save()
        
        # Generate report
        report = cov.report()
        
        # Check MedinovAI requirements
        if 'safety_critical' in module_path:
            required_coverage = MedinovAITestFramework.E_MIN_COVERAGE_SAFETY_CRITICAL
        else:
            required_coverage = MedinovAITestFramework.E_MIN_COVERAGE_STANDARD
        
        return {
            'coverage': report,
            'meets_requirements': report >= required_coverage,
            'required': required_coverage,
            'actual': report
        }
```

---

## SECTION 8: DEPLOYMENT STANDARDS

### 8.1 MedinovAI Deployment Checklist

```yaml
# medinovai_deployment_checklist.yaml

medinovai_deployment:
  environment_validation:
    development:
      - [ ] Unit tests passing (>95% coverage)
      - [ ] Integration tests passing
      - [ ] Code review completed
      - [ ] Security scan clean
      - [ ] Documentation updated
    
    staging:
      - [ ] Deployment to staging successful
      - [ ] Smoke tests passing
      - [ ] Performance benchmarks met
      - [ ] Clinical validation tests passing
      - [ ] Regulatory compliance verified
    
    production:
      - [ ] Change advisory board approval
      - [ ] Rollback plan documented
      - [ ] On-call team notified
      - [ ] Monitoring alerts configured
      - [ ] Backup verification completed
  
  medinovai_specific:
    compliance:
      - [ ] FDA documentation updated
      - [ ] EU MDR compliance verified
      - [ ] HIPAA controls validated
      - [ ] Audit trail tested
      - [ ] Clinical validation completed
    
    safety:
      - [ ] Fail-safe mechanisms tested
      - [ ] Error recovery verified
      - [ ] Alert systems operational
      - [ ] Manual override available
      - [ ] Clinical staff trained
    
    performance:
      - [ ] Response time < 500ms (P95)
      - [ ] Throughput > 1000 TPS
      - [ ] CPU utilization < 70%
      - [ ] Memory usage < 80%
      - [ ] Error rate < 0.1%
  
  deployment_strategy:
    canary:
      initial_percentage: 5
      duration_hours: 24
      success_criteria:
        error_rate: "< 0.1%"
        response_time_p95: "< 500ms"
        clinical_accuracy: "> 95%"
    
    progressive:
      stages:
        - percentage: 25
          duration_hours: 24
        - percentage: 50
          duration_hours: 24
        - percentage: 75
          duration_hours: 24
        - percentage: 100
          duration_hours: 0
    
    rollback:
      automatic_triggers:
        - error_rate > 1%
        - response_time_p95 > 1000ms
        - clinical_accuracy < 90%
        - critical_alerts > 0
      
      manual_triggers:
        - clinical_staff_report
        - regulatory_concern
        - data_integrity_issue
```

### 8.2 MedinovAI CI/CD Pipeline

```yaml
# .github/workflows/medinovai_pipeline.yml

name: MedinovAI CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  MEDINOVAI_STANDARDS_VERSION: "3.0.0"
  MIN_COVERAGE_SAFETY_CRITICAL: 95
  MIN_COVERAGE_STANDARD: 85

jobs:
  compliance-check:
    name: MedinovAI Compliance Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Load MedinovAI Standards
        run: |
          git submodule update --init --recursive
          cp .ai-standards/.cursorrules .
          cp .ai-standards/CLAUDE.md .
      
      - name: Validate Naming Conventions
        run: |
          python .ai-standards/scripts/validate_naming.py
          # Check for mos_ prefix and E_ constants
      
      - name: Check Documentation
        run: |
          python .ai-standards/scripts/check_documentation.py
          # Verify @medinovai, @regulatory, @safety tags
      
      - name: Validate Safety Patterns
        run: |
          python .ai-standards/scripts/validate_safety.py
          # Check fail-safe mechanisms
  
  security-scan:
    name: Security and Vulnerability Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: HIPAA Compliance Scan
        run: |
          docker run --rm -v "$PWD":/src \
            medinovai/hipaa-scanner:latest /src
      
      - name: Dependency Vulnerability Scan
        run: |
          pip install safety
          safety check --json
      
      - name: SAST Analysis
        uses: github/super-linter@v4
        env:
          VALIDATE_ALL_CODEBASE: true
          VALIDATE_JAVASCRIPT_ES: true
          VALIDATE_PYTHON_BLACK: true
          VALIDATE_CSHARP: true
  
  test-and-validate:
    name: Testing and Clinical Validation
    runs-on: ubuntu-latest
    strategy:
      matrix:
        test-type: [unit, integration, clinical, performance]
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Test Environment
        run: |
          docker-compose -f docker-compose.test.yml up -d
          sleep 10
      
      - name: Run ${{ matrix.test-type }} Tests
        run: |
          if [ "${{ matrix.test-type }}" == "unit" ]; then
            pytest tests/unit --cov --cov-report=xml
            coverage_percent=$(coverage report | grep TOTAL | awk '{print $4}' | sed 's/%//')
            if (( $(echo "$coverage_percent < $MIN_COVERAGE_SAFETY_CRITICAL" | bc -l) )); then
              echo "Coverage $coverage_percent% below required $MIN_COVERAGE_SAFETY_CRITICAL%"
              exit 1
            fi
          elif [ "${{ matrix.test-type }}" == "clinical" ]; then
            python tests/clinical/validation_suite.py
          elif [ "${{ matrix.test-type }}" == "performance" ]; then
            locust -f tests/performance/load_test.py --headless \
              --users 100 --spawn-rate 10 --run-time 60s
          fi
      
      - name: Upload Test Results
        uses: actions/upload-artifact@v3
        with:
          name: test-results-${{ matrix.test-type }}
          path: test-results/
  
  build-and-push:
    name: Build and Push Docker Images
    needs: [compliance-check, security-scan, test-and-validate]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Build MedinovAI Image
        run: |
          docker build \
            --build-arg MEDINOVAI_VERSION=${{ env.MEDINOVAI_STANDARDS_VERSION }} \
            --label "medinovai.compliance=FDA-21CFR11" \
            --label "medinovai.risk-level=B" \
            -t medinovai/${{ github.repository }}:${{ github.sha }} \
            -t medinovai/${{ github.repository }}:latest \
            .
      
      - name: Scan Image for Vulnerabilities
        run: |
          trivy image medinovai/${{ github.repository }}:${{ github.sha }}
      
      - name: Push to Registry
        run: |
          docker push medinovai/${{ github.repository }}:${{ github.sha }}
          docker push medinovai/${{ github.repository }}:latest
  
  deploy:
    name: Deploy to MedinovAI Infrastructure
    needs: [build-and-push]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
      - name: Deploy to Staging
        run: |
          # Deploy to MedinovAI staging environment
          kubectl --context=medinovai-staging apply -f k8s/staging/
      
      - name: Run Post-Deployment Validation
        run: |
          # Wait for deployment
          sleep 60
          
          # Run smoke tests
          python tests/smoke/staging_validation.py
      
      - name: Clinical Validation in Staging
        run: |
          # Run clinical validation suite
          python tests/clinical/staging_clinical_validation.py
      
      - name: Request Production Approval
        if: success()
        uses: trstringer/manual-approval@v1
        with:
          approvers: clinical-team,regulatory-team
          secret: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Deploy to Production (Canary)
        run: |
          # Deploy 5% canary
          kubectl --context=medinovai-prod apply -f k8s/production/canary.yaml
          
          # Monitor for 1 hour
          python scripts/monitor_canary.py --duration 3600
      
      - name: Progressive Production Rollout
        run: |
          # Progressive rollout: 25%, 50%, 75%, 100%
          for percentage in 25 50 75 100; do
            kubectl --context=medinovai-prod set image \
              deployment/app app=medinovai/${{ github.repository }}:${{ github.sha }} \
              --record
            
            kubectl --context=medinovai-prod patch deployment app \
              -p '{"spec":{"strategy":{"rollingUpdate":{"maxSurge":"'$percentage'%"}}}}'
            
            # Monitor each stage
            python scripts/monitor_rollout.py --percentage $percentage
            
            if [ $percentage -lt 100 ]; then
              sleep 3600  # Wait 1 hour between stages
            fi
          done
```

---

## SECTION 9: AI AGENT CONFIGURATION

### 9.1 Cursor Configuration (.cursorrules)

```markdown
# MedinovAI Cursor Rules
# Version: 3.0.0
# Organization: MedinovAI
# Compliance: FDA 21 CFR Part 11, EU MDR, ISO 13485

## CRITICAL: MEDICAL SOFTWARE DEVELOPMENT
You are developing medical software where patient safety is paramount.
Every line of code can impact patient lives.
NO shortcuts, NO assumptions, ALWAYS validate.

## MedinovAI Naming Conventions
ENFORCE WITHOUT EXCEPTION:
- Constants: E_VARIABLE_NAME (uppercase with E_ prefix)
- Medical Object Storage: mos_variableName (camelCase with mos_ prefix)
- Classes: PascalCase
- Interfaces: IPascalCase
- Methods: camelCase
- Files: kebab-case.ts or snake_case.py

## Code Quality Standards
- Maximum 40 lines per function
- Maximum 500 lines per file
- Cyclomatic complexity < 10
- Test coverage >= 95% for safety-critical code
- Test coverage >= 85% for standard code

## Required Documentation
EVERY function handling patient data MUST include:
- @medinovai: Repository and component info
- @regulatory: FDA/EU MDR references
- @safety: Risk level and failure modes
- @clinical: Evidence and validation
- @audit: Logging requirements
- @integration: External systems

## Safety Requirements
ALWAYS implement:
1. Input validation on ALL external data
2. Fail-safe defaults for ALL error conditions
3. Audit trail for ALL data modifications
4. Timeout handling for ALL external calls
5. Retry logic with exponential backoff
6. Circuit breakers for external services
7. Health checks for all services
8. Graceful degradation patterns

## Technology-Specific Rules

### .NET Core / C#
- Use dependency injection
- Implement repository pattern
- Use async/await properly
- Handle CancellationToken
- Use structured logging with Serilog
- Implement CQRS where appropriate

### Python
- Type hints required
- Use dataclasses for DTOs
- Implement proper error handling
- Use async where beneficial
- Follow PEP 8 with MedinovAI extensions
- Use pytest for testing

### TypeScript/JavaScript  
- Strict mode enabled
- No any types
- Proper error boundaries in React
- Use functional components with hooks
- Implement proper state management
- Use React Query for API calls

### Rust
- No unsafe code in medical components
- Use Result<T, E> for all fallible operations
- Implement proper error types with thiserror
- Use serde for serialization
- 100% test coverage required

## Regulatory Compliance
- FDA 21 CFR Part 11 for electronic records
- EU MDR 2017/745 for medical devices
- ISO 13485:2016 for quality management
- IEC 62304:2015 for software lifecycle
- HIPAA for PHI protection
- GDPR for EU data protection

## Integration Standards
- HL7 FHIR R4 for clinical data
- DICOM 3.0 for medical imaging
- Use OpenAPI 3.0 for API documentation
- Implement OAuth 2.0 / OIDC for authentication
- Use mTLS for service-to-service communication

## Testing Requirements
- Unit tests for all public methods
- Integration tests for all APIs
- Clinical validation tests for algorithms
- Performance tests for critical paths
- Security tests for all endpoints
- Chaos engineering for resilience

## Performance Requirements
- API response time < 500ms (P95)
- Batch processing < 100ms per item
- Real-time monitoring < 100ms latency
- Database queries < 200ms
- Frontend interaction < 100ms

## Security Requirements
- Encrypt PHI at rest (AES-256)
- Encrypt PHI in transit (TLS 1.3)
- Implement rate limiting
- Use parameterized queries
- Validate all inputs
- Implement CSP headers
- Regular security scanning

## Deployment Requirements
- Blue-green deployments
- Canary releases for critical changes
- Automated rollback triggers
- Health checks before traffic
- Graceful shutdown handling
- Zero-downtime deployments

## Monitoring Requirements
- Application metrics (Prometheus)
- Distributed tracing (OpenTelemetry)
- Centralized logging (ELK Stack)
- Error tracking (Sentry)
- APM (Application Insights)
- Custom clinical metrics

## AI Coding Behavior
When generating code:
1. ALWAYS check MedinovAI standards first
2. ALWAYS include comprehensive error handling
3. ALWAYS add appropriate documentation
4. ALWAYS consider patient safety
5. NEVER skip validation
6. NEVER ignore edge cases
7. NEVER bypass security checks
8. NEVER remove audit trails

## Model-Specific Instructions

### Claude
- Use "think harder" for complex medical logic
- Request step-by-step validation
- Ask for safety analysis

### GPT-4
- Focus on API design and documentation
- Generate comprehensive test cases
- Create integration examples

### Gemini
- Handle medical imaging tasks
- Process multi-modal clinical data
- Optimize batch processing

## Review Checklist
Before accepting any code:
☐ MedinovAI naming conventions followed
☐ Documentation complete
☐ Error handling comprehensive
☐ Tests written and passing
☐ Performance requirements met
☐ Security scan clean
☐ Regulatory compliance verified
☐ Clinical validation completed
```

### 9.2 Claude-Specific Instructions (CLAUDE.md)

```markdown
# Claude AI Instructions - MedinovAI

## Your Identity
You are a senior medical software engineer at MedinovAI, specializing in FDA-compliant healthcare systems.
You have deep expertise in clinical software development and patient safety.

## Critical Instructions
1. **Patient Safety First**: Every decision must prioritize patient safety
2. **Think Deeply**: Use "think harder" mode for any clinical algorithm
3. **Validate Everything**: Never assume, always validate
4. **Document Thoroughly**: Every function needs complete documentation

## MedinovAI Context
- Organization: MedinovAI
- Domain: Healthcare & Life Sciences
- Products: Clinical Decision Support, Medical Devices, Healthcare Analytics
- Markets: US, EU, Canada, India, UK, GCC

## When Writing Code

### Before Starting
1. Read MEDINOVAI.md for repository context
2. Check REGULATORY.md for compliance requirements
3. Review SAFETY.md for critical components
4. Understand existing patterns in the codebase

### During Development
1. Follow MedinovAI naming conventions (mos_, E_)
2. Implement fail-safe patterns
3. Add comprehensive error handling
4. Include audit trails for data changes
5. Write tests alongside code
6. Keep functions under 40 lines

### After Coding
1. Verify regulatory compliance
2. Check test coverage (>95% for safety-critical)
3. Validate clinical accuracy
4. Review performance metrics
5. Ensure documentation is complete

## Safety Checklist
For EVERY piece of code, ask yourself:
- What happens if this fails?
- How does this affect patient care?
- Is there a safer alternative?
- Have I handled all error cases?
- Is the audit trail complete?
- Will this pass regulatory review?

## Common Patterns

### Error Handling
```python
try:
    result = perform_medical_operation()
    validate_result(result)
    return result
except CriticalError as e:
    log_critical(e)
    trigger_alert(e)
    return SAFE_DEFAULT
except Exception as e:
    log_error(e)
    return SAFE_DEFAULT
finally:
    audit_trail.record(operation)
```

### Validation
```python
def validate_medical_data(data):
    # Always validate input
    if not data:
        raise ValidationError("Empty data")
    
    # Check required fields
    required = ['patient_id', 'timestamp', 'values']
    missing = [f for f in required if f not in data]
    if missing:
        raise ValidationError(f"Missing fields: {missing}")
    
    # Validate ranges
    if not (0 <= data['value'] <= E_MAX_VALUE):
        raise RangeError(f"Value {data['value']} out of range")
    
    return True
```

## Regulatory Awareness
Always consider:
- FDA 21 CFR Part 11 (Electronic Records)
- EU MDR 2017/745 (Medical Devices)
- ISO 13485 (Quality Management)
- IEC 62304 (Software Lifecycle)
- HIPAA (Privacy)
- GDPR (Data Protection)

## Response Format
When asked to write code:

1. **Acknowledge the medical context**
   "I understand this is for [specific medical use case] which requires [specific safety considerations]."

2. **Identify regulatory requirements**
   "This component must comply with [specific regulations]."

3. **Provide the solution with:**
   - Complete error handling
   - Comprehensive documentation
   - Test cases
   - Clinical validation approach

4. **Highlight safety considerations**
   "Key safety points: [list critical safety aspects]"

## Remember
You are building software that healthcare professionals rely on to save lives.
There are no acceptable shortcuts.
Quality, safety, and compliance are non-negotiable.
When in doubt, choose the safer option.
Always think: "Would I want this code running when my family member is the patient?"
```

---

## APPENDIX A: Quick Reference

### MedinovAI Variable Quick Reference

```python
# Constants (Regulatory/Safety Limits)
E_MAX_HEART_RATE = 250
E_MIN_OXYGEN_LEVEL = 90
E_TIMEOUT_SECONDS = 30

# Medical Object Storage
mos_patientRecord = load_patient()
mos_vitalSigns = read_vitals()
mos_medication = get_medication()

# Regular Variables
logger = get_logger()
service = create_service()
result = process_data()
```

### MedinovAI Documentation Tags

```python
"""
@medinovai: Component identifier
@regulatory: Compliance references  
@safety: Risk and mitigation
@clinical: Medical evidence
@validation: Testing protocol
@audit: Logging requirements
@integration: External systems
"""
```

### MedinovAI Risk Levels

- **Level A**: Direct patient harm possible (life support, medication)
- **Level B**: Indirect patient impact (diagnosis support, monitoring)
- **Level C**: Administrative functions (billing, scheduling)

---

## APPENDIX B: Deployment Script

```bash
#!/bin/bash
# deploy_medinovai_standards.sh
# Deploy MedinovAI standards across all repositories

set -e

STANDARDS_REPO="https://github.com/medinovai/medinovai-ai-standards.git"
REPOS_FILE="medinovai_repos.txt"

echo "MedinovAI Standards Deployment Script v3.0.0"
echo "==========================================="

# Clone or update standards repository
if [ -d "medinovai-ai-standards" ]; then
    echo "Updating standards repository..."
    cd medinovai-ai-standards && git pull && cd ..
else
    echo "Cloning standards repository..."
    git clone $STANDARDS_REPO
fi

# Read repository list
if [ ! -f "$REPOS_FILE" ]; then
    echo "Error: $REPOS_FILE not found!"
    echo "Create a file with one repository path per line"
    exit 1
fi

# Deploy to each repository
while IFS= read -r repo; do
    echo "Processing: $repo"
    
    if [ ! -d "$repo" ]; then
        echo "  Warning: $repo not found, skipping..."
        continue
    fi
    
    cd "$repo"
    
    # Add standards as submodule if not present
    if [ ! -d ".ai-standards" ]; then
        git submodule add $STANDARDS_REPO .ai-standards
        git submodule update --init --recursive
    fi
    
    # Create .cursorrules with import
    cat > .cursorrules << EOF
# Import MedinovAI Central Standards
@import .ai-standards/.cursorrules

# Repository-Specific Configuration
repository: $(basename $repo)
EOF
    
    # Create CLAUDE.md with import
    cat > CLAUDE.md << EOF
# Claude AI Instructions - $(basename $repo)

## Import Central Standards
@import .ai-standards/CLAUDE.md

## Repository-Specific Context
This repository is part of MedinovAI's healthcare platform.
Repository: $(basename $repo)
EOF
    
    # Commit changes
    git add .cursorrules CLAUDE.md .gitmodules .ai-standards
    git commit -m "Update MedinovAI AI standards to v3.0.0" || true
    
    cd ..
    echo "  ✓ Completed"
done < "$REPOS_FILE"

echo ""
echo "Deployment complete!"
echo "Next steps:"
echo "1. Review changes in each repository"
echo "2. Push changes to remote repositories"
echo "3. Notify team members to pull latest changes"
echo "4. Update Cursor IDE settings"
```

---

## APPENDIX C: Repository List File

Create `medinovai_repos.txt`:

```
medinovai-clinical-api
medinovai-patient-portal
medinovai-ml-models
medinovai-imaging-service
medinovai-lab-integration
medinovai-pharmacy-system
medinovai-billing-service
medinovai-appointment-scheduler
medinovai-telemedicine-platform
medinovai-analytics-dashboard
medinovai-mobile-ios
medinovai-mobile-android
medinovai-data-pipeline
medinovai-fhir-server
medinovai-dicom-viewer
# ... add all 130 repositories
```

---

## Implementation Status

✅ **SETUP COMPLETE!**

The MedinovAI AI Standards system has been successfully configured in this repository.

### What's Been Created:

1. **Central Standards Repository** (`medinovai-ai-standards/`)
   - Master `.cursorrules` with all MedinovAI standards
   - `CLAUDE.md` with AI-specific instructions
   - Templates for repository deployment
   - Deployment and validation scripts

2. **Current Repository Configuration**
   - `.cursorrules` - Imports central standards + repo-specific rules
   - `CLAUDE.md` - AI instructions for this repository
   - `MEDINOVAI.md` - Repository context and patterns
   - `.ai-standards` - Link to central standards

3. **Team Resources**
   - `MEDINOVAI-TEAM-SETUP.md` - Comprehensive setup guide
   - `MEDINOVAI-QUICK-REFERENCE.md` - Quick reference card
   - `medinovai-repos.txt` - Repository list for bulk updates

### Next Steps for You:

1. **Review and customize** the files created for your specific needs
2. **Share** the setup guide with your team: `MEDINOVAI-TEAM-SETUP.md`
3. **Add** your other repositories to `medinovai-repos.txt`
4. **Run** compliance check: `python medinovai-ai-standards/scripts/validate-compliance.py .`

### For Your Team Members:

Direct them to run:
```bash
cd medinovai-ai-standards
./scripts/setup-developer-environment.sh
```

This will automatically configure their development environment with all MedinovAI standards.

---

## Version History

- **v3.0.0** (2025-01-01): Major update with comprehensive MedinovAI standards
- **v2.5.0** (2024-10-15): Added multi-region compliance
- **v2.0.0** (2024-07-01): Introduced safety-critical patterns
- **v1.0.0** (2024-01-01): Initial MedinovAI standards

---

## Contact & Support

- **Standards Committee**: standards@medinovai.com
- **Compliance Team**: compliance@medinovai.com
- **Engineering Support**: engineering@medinovai.com
- **Emergency Hotline**: +1-800-MEDNOVA

---

## License & Compliance

This document contains proprietary information of MedinovAI.
Distribution is limited to authorized MedinovAI personnel and partners.
All code must comply with applicable medical device regulations.

© 2025 MedinovAI - Advancing Healthcare Through Technology
