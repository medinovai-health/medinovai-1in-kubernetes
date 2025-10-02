#!/bin/bash

# Phase 5: Complete Test Suite Validation with 5 Ollama Models
# Target: 10/10 score from each model (50/50 total)
# Approach: Brutally honest review with 3 iterations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALIDATION_DIR="$SCRIPT_DIR"
RESULTS_DIR="$VALIDATION_DIR/results"
PROMPTS_DIR="$VALIDATION_DIR/prompts"
DOCS_DIR="/Users/dev1/github/medinovai-infrastructure/docs"
TESTS_DIR="/Users/dev1/github/medinovai-infrastructure/playwright/tests"

mkdir -p "$RESULTS_DIR" "$PROMPTS_DIR"

echo "═══════════════════════════════════════════════════════════"
echo "🔍 PHASE 5: COMPLETE VALIDATION WITH 5 OLLAMA MODELS"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Models to use (best for healthcare + infrastructure)
declare -a MODELS=(
    "qwen2.5:72b"
    "deepseek-coder:33b"
    "llama3.1:70b"
    "mixtral:8x22b"
    "codellama:70b"
)

declare -a ROLES=(
    "Chief Solutions Architect"
    "Senior Code Reviewer"
    "Healthcare Compliance Expert"
    "Multi-Perspective Analyst"
    "Infrastructure Expert"
)

# Create comprehensive prompt for each model
create_model_prompt() {
    local model=$1
    local role=$2
    local model_safe="${model//:/-}"
    local prompt_file="$PROMPTS_DIR/${model_safe}-prompt.txt"
    
    cat > "$prompt_file" << PROMPT_EOF
You are a ${role} performing a BRUTALLY HONEST review of the MedinovAI infrastructure test suite.

Your task is to evaluate the COMPLETE test suite across all dimensions and provide a score out of 10.

## Evaluation Criteria (10-point scale)

1. **Architecture Soundness (0-2 points)**
   - Test coverage of all 9 infrastructure tiers
   - Integration test quality
   - System design validation
   
2. **Code Quality & Best Practices (0-2 points)**
   - TypeScript quality
   - Test structure and organization
   - Error handling
   - Documentation
   
3. **Healthcare Compliance (0-2 points)**
   - HIPAA validation
   - SOC2 requirements
   - PHI protection
   - Audit trail completeness
   
4. **Test Coverage & Completeness (0-2 points)**
   - Infrastructure components (35+)
   - User journeys (10)
   - Data journeys (10)
   - Integration scenarios
   
5. **Production Readiness (0-2 points)**
   - CI/CD integration
   - Error handling
   - Performance considerations
   - Operational excellence

## Test Suite Overview

### Infrastructure Tests (9 tiers, 35+ components)
- Tier 1: Container & Orchestration
- Tier 2: Service Mesh & Networking
- Tier 3: Databases & Data Stores
- Tier 4: Message Queues & Streaming
- Tier 5: Monitoring & Observability
- Tier 6: Security & Secrets Management
- Tier 7: AI/ML Infrastructure
- Tier 8: Backup & Disaster Recovery
- Tier 9: Testing & Validation

### User Journeys (10 workflows)
1. Patient Admission (ER Physician)
2. AI-Assisted Diagnosis (PCP)
3. Medication Administration (Nurse)
4. Lab Results Entry (Lab Tech)
5. Medical Image Analysis (Radiologist)
6. Claims Processing (Billing)
7. System Configuration (Admin)
8. Data Analytics (Researcher)
9. Patient Portal Access (Patient)
10. Prescription Processing (Pharmacist)

### Data Journeys (10 flows)
1. HL7 Ingestion → Data Lake
2. Real-Time Vitals → Alerting
3. Lab Results → FHIR Integration
4. Medical Images → AI Analysis
5. Prescription → Dispensing
6. Billing → Revenue Cycle
7. Clinical Notes → NLP
8. Research Query → De-identification
9. Audit Log → Compliance
10. Backup → Restore

### Integration Tests (5 scenarios)
1. End-to-End Patient Care
2. Multi-Service Data Flow
3. Security & Compliance
4. MLOps Lifecycle
5. Disaster Recovery

## Your Review Format

Provide your response in this EXACT format:

### OVERALL SCORE: X/10

### DETAILED SCORING:
1. Architecture Soundness: X/2
2. Code Quality: X/2
3. Healthcare Compliance: X/2
4. Test Coverage: X/2
5. Production Readiness: X/2

### TOP 5 STRENGTHS:
1. [Strength 1]
2. [Strength 2]
3. [Strength 3]
4. [Strength 4]
5. [Strength 5]

### TOP 5 IMPROVEMENTS NEEDED:
1. [Improvement 1]
2. [Improvement 2]
3. [Improvement 3]
4. [Improvement 4]
5. [Improvement 5]

### CRITICAL ISSUES (if any):
[List any blocking issues]

### RECOMMENDATION:
[APPROVE / NEEDS REVISION / REJECT]

---

Now review the test suite files and provide your brutally honest assessment.
PROMPT_EOF
    
    echo "$prompt_file"
}

# Collect all test files
collect_test_suite() {
    echo "📋 Collecting test suite files..."
    
    local suite_content=""
    
    # Infrastructure tests
    for file in "$TESTS_DIR/infrastructure"/*.spec.ts; do
        if [ -f "$file" ]; then
            suite_content+=$'\n'"### $(basename "$file")"$'\n'
            suite_content+='```typescript'$'\n'
            suite_content+=$(cat "$file")$'\n'
            suite_content+='```'$'\n'
        fi
    done
    
    # User journeys
    for file in "$TESTS_DIR/user-journeys"/*.spec.ts; do
        if [ -f "$file" ]; then
            suite_content+=$'\n'"### $(basename "$file")"$'\n'
            suite_content+='```typescript'$'\n'
            suite_content+=$(cat "$file")$'\n'
            suite_content+='```'$'\n'
        fi
    done
    
    # Data journeys
    for file in "$TESTS_DIR/data-journeys"/*.spec.ts; do
        if [ -f "$file" ]; then
            suite_content+=$'\n'"### $(basename "$file")"$'\n'
            suite_content+='```typescript'$'\n'
            suite_content+=$(cat "$file")$'\n'
            suite_content+='```'$'\n'
        fi
    done
    
    # Integration tests
    for file in "$TESTS_DIR/integration"/*.spec.ts; do
        if [ -f "$file" ]; then
            suite_content+=$'\n'"### $(basename "$file")"$'\n'
            suite_content+='```typescript'$'\n'
            suite_content+=$(cat "$file")$'\n'
            suite_content+='```'$'\n'
        fi
    done
    
    echo "$suite_content"
}

# Run validation with single model
validate_with_model() {
    local model=$1
    local role=$2
    local iteration=$3
    local model_safe="${model//:/-}"
    local result_file="$RESULTS_DIR/iter${iteration}-${model_safe}-result.txt"
    
    echo "═══════════════════════════════════════"
    echo "🤖 Model: $model"
    echo "👔 Role: $role"
    echo "🔄 Iteration: $iteration"
    echo "═══════════════════════════════════════"
    
    # Create prompt
    local prompt_file=$(create_model_prompt "$model" "$role")
    
    # Collect test suite
    local test_suite=$(collect_test_suite)
    
    # Create full prompt
    local full_prompt=$(cat "$prompt_file")
    full_prompt+=$'\n\n'
    full_prompt+="$test_suite"
    
    echo "📝 Running validation (this may take 5-10 minutes)..."
    local start_time=$(date +%s)
    
    # Execute Ollama
    echo "$full_prompt" | ollama run "$model" > "$result_file" 2>&1
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo "✅ Completed in ${duration}s"
    echo "📄 Result: $result_file"
    echo ""
}

# Main execution
main() {
    echo "Starting 3-iteration validation with 5 models..."
    echo ""
    
    for iteration in 1 2 3; do
        echo ""
        echo "╔═══════════════════════════════════════╗"
        echo "║     ITERATION $iteration OF 3                 ║"
        echo "╚═══════════════════════════════════════╝"
        echo ""
        
        for i in "${!MODELS[@]}"; do
            validate_with_model "${MODELS[$i]}" "${ROLES[$i]}" "$iteration"
        done
        
        if [ $iteration -lt 3 ]; then
            echo "⏸️  Pausing 30 seconds between iterations..."
            sleep 30
        fi
    done
    
    echo ""
    echo "═══════════════════════════════════════"
    echo "✅ ALL VALIDATIONS COMPLETE"
    echo "═══════════════════════════════════════"
    echo ""
    echo "Results directory: $RESULTS_DIR"
    echo ""
    echo "Next steps:"
    echo "1. Run: python $VALIDATION_DIR/analyze-validation-results.py"
    echo "2. Review aggregated scores"
    echo "3. Address any issues"
    echo "4. Re-run if needed"
}

main
