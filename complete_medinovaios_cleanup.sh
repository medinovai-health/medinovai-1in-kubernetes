#!/bin/bash
# complete_medinovaios_cleanup.sh - Complete cleanup of medinovaios by migrating remaining services

echo "🧹 Starting complete medinovaios cleanup..."
echo "Timestamp: $(date)"
echo "=========================================="

SOURCE_REPO="/Users/dev1/github/medinovaios"

# Define target repositories
AI_REPO="/Users/dev1/github/medinovai-AI-standards"
CLINICAL_REPO="/Users/dev1/github/medinovai-clinical-services"
SECURITY_REPO="/Users/dev1/github/medinovai-security-services"
DATA_REPO="/Users/dev1/github/medinovai-data-services"
INTEGRATION_REPO="/Users/dev1/github/medinovai-integration-services"
PATIENT_REPO="/Users/dev1/github/medinovai-patient-services"
BILLING_REPO="/Users/dev1/github/medinovai-billing"
COMPLIANCE_REPO="/Users/dev1/github/medinovai-compliance-services"
INFRASTRUCTURE_REPO="/Users/dev1/github/medinovai-infrastructure"
UI_REPO="/Users/dev1/github/medinovai-ui-components"
UTILITY_REPO="/Users/dev1/github/medinovai-healthcare-utilities"

# AI/ML Services to migrate
AI_SERVICES=(
    "ai-agent-orchestrator" "ai-agents" "ai-automation" "ai-autonomous-scheduling"
    "ai-clinical-decision" "ai-medication-management" "ai-models" "ai-native-ctms-specification-service"
    "ai-patient-communication" "ai-policy-guardrails-service" "ai-predictive-modeling" "ai-prompt-manager"
    "ai-real-time-monitoring" "ai-risk-stratification" "ai-scribe" "ai-visual-diagnosis"
    "ai-voice-triage" "ai-workflow-optimization" "ai-insights" "ai-dashboard"
    "ai-integration" "ai-monitoring" "ai-security" "ai-compliance"
    "ai-audit" "ai-reporting" "ai-optimization" "machine-learning"
    "ml-pipeline" "ml-training" "ml-validation" "deep-learning"
    "neural-network" "computer-vision" "nlp-service" "speech-recognition"
    "image-processing" "data-mining" "pattern-recognition" "predictive-analytics"
)

# Clinical Services to migrate
CLINICAL_SERVICES=(
    "clinical-decision" "clinical-workflow" "clinical-documentation" "clinical-reporting"
    "clinical-analytics" "clinical-monitoring" "clinical-alerts" "clinical-guidelines"
    "clinical-protocols" "clinical-trials" "clinical-research" "clinical-data"
    "clinical-integration" "clinical-interoperability" "clinical-standards" "clinical-compliance"
    "clinical-quality" "clinical-safety" "clinical-outcomes" "clinical-metrics"
    "clinical-dashboard" "clinical-portal" "clinical-mobile" "clinical-telehealth"
    "clinical-remote" "clinical-virtual" "clinical-digital" "anesthesia-management"
    "allergy-management" "medication-management" "treatment-planning" "care-coordination"
)

# Security Services to migrate
SECURITY_SERVICES=(
    "access-control" "access-review" "security-monitoring" "security-audit"
    "security-compliance" "security-policy" "security-management" "security-authentication"
    "security-authorization" "security-encryption" "security-key-management" "security-certificate"
    "security-token" "security-session" "security-access-control" "security-identity"
    "security-federation" "security-sso" "security-mfa" "security-biometric"
    "security-firewall" "security-intrusion" "security-vulnerability" "security-penetration"
    "security-incident" "audit-logger" "audit-logging" "audit-system"
    "audit-ledger-service" "auditpack-service" "bias-audit-service"
)

# Data Services to migrate
DATA_SERVICES=(
    "data-analytics" "data-catalog" "data-governance" "data-lineage" "data-retention"
    "data-services" "data-sync" "data-warehouse" "advanced-analytics" "behavioral-analytics"
    "business-intelligence" "healthcare-analytics-dashboard" "healthcare-cost-analytics"
    "real-time-analytics" "metrics-collector" "metrics-service" "anomaly-detection"
    "data-processing" "data-transformation" "data-validation" "data-quality"
)

# Integration Services to migrate
INTEGRATION_SERVICES=(
    "api" "api-documentation" "api-logging" "api-metrics" "api-throttling" "api-versioning"
    "cerner-integration" "epic-emr-integration" "epic-integration" "ehr-integration" "emr"
    "medinovai-emr" "hl7-integration" "hl7-interface" "interoperability-gateway" "lis-interface"
    "lis-system" "medinovai-lis" "pacs-integration" "radiology-integration" "united-healthcare-integration"
    "device-integration" "medical-device-integration" "system-integration" "data-integration"
)

# Patient Services to migrate
PATIENT_SERVICES=(
    "patient-portal" "patient-management" "patient-registration" "patient-scheduling"
    "patient-communication" "patient-engagement" "patient-monitoring" "patient-care-coordination"
    "patient-education" "patient-feedback" "patient-satisfaction" "patient-outcomes"
    "patient-safety" "patient-privacy" "patient-consent" "appointment-scheduler"
    "appointment-scheduling" "patient-access" "patient-advocacy" "patient-support"
)

# Billing Services to migrate
BILLING_SERVICES=(
    "billing" "billing-system" "billing-management" "payment-processing" "insurance-claims"
    "revenue-cycle" "financial-reporting" "cost-accounting" "budget-management"
    "financial-analytics" "reimbursement" "claims-processing" "payment-gateway"
)

# Compliance Services to migrate
COMPLIANCE_SERVICES=(
    "compliance" "compliance-monitoring" "audit-trail" "regulatory-reporting" "hipaa-compliance"
    "fda-compliance" "gdpr-compliance" "sox-compliance" "quality-assurance" "risk-management"
    "policy-management" "governance" "certification" "accreditation" "standards-compliance"
    "regulatory-framework" "compliance-dashboard" "compliance-alerts" "compliance-training"
    "compliance-documentation" "compliance-workflow" "compliance-analytics" "compliance-reporting"
    "audit-packs-regulatory-reporting-service" "regulatory-compliance" "quality-control"
)

# Infrastructure Services to migrate
INFRASTRUCTURE_SERVICES=(
    "infrastructure" "infrastructure-management" "deployment" "orchestration" "monitoring"
    "logging" "metrics" "alerting" "backup" "disaster-recovery" "scaling" "load-balancing"
    "service-mesh" "api-gateway" "advanced-monitoring" "auto-scaling" "backup-manager"
    "infrastructure-automation" "deployment-automation" "monitoring-automation"
)

# UI/UX Services to migrate
UI_SERVICES=(
    "ui-components" "user-interface" "frontend" "dashboard" "web-interface"
    "accessibility" "user-experience" "interface-design" "responsive-design"
)

# Utility Services to migrate
UTILITY_SERVICES=(
    "utilities" "utility-services" "common-services" "shared-services" "helper-services"
    "notification" "email-service" "sms-service" "file-service" "document-service"
    "reporting" "report-generator" "template-engine" "workflow-engine" "scheduler"
    "cron-service" "cache-service" "session-management" "user-management" "authentication"
    "authorization" "permission-service" "role-service" "config-service" "settings-service"
    "preference-service" "logging-service" "audit-service" "backup-service" "sync-service"
    "validation-service" "transformation-service" "conversion-service" "alert-service"
    "archive-service" "asset-tracking" "agent-management-dashboard" "agent-memory-service"
    "autonomous-agent-orchestrator"
)

echo "Source: $SOURCE_REPO"
echo "Target repositories: 11"
echo ""

# Function to migrate services to a specific repository
migrate_services_to_repo() {
    local services=("$@")
    local target_repo="${services[-1]}"
    unset 'services[-1]'
    local category_name="${services[-1]}"
    unset 'services[-1]'
    
    echo "📁 Migrating $category_name services to $(basename $target_repo)..."
    
    # Create services directory if it doesn't exist
    mkdir -p "$target_repo/services"
    
    local success_count=0
    local total_count=${#services[@]}
    
    for service in "${services[@]}"; do
        local source_path="$SOURCE_REPO/services/$service"
        local target_path="$target_repo/services/$service"
        
        if [ -d "$source_path" ]; then
            if [ ! -d "$target_path" ]; then
                echo "   📋 Copying $service..."
                if cp -r "$source_path" "$target_path"; then
                    # Create service metadata
                    cat > "$target_path/service-info.json" << EOF
{
    "service_name": "$service",
    "category": "$category_name",
    "migrated_from": "medinovaios",
    "migration_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "target_repository": "$(basename $target_repo)",
    "description": "$category_name service migrated from medinovaios"
}
EOF
                    echo "   ✅ Successfully migrated $service"
                    ((success_count++))
                else
                    echo "   ❌ Failed to copy $service"
                fi
            else
                echo "   ⚠️  Service $service already exists in target"
            fi
        else
            echo "   ⚠️  Service $service not found in source"
        fi
    done
    
    echo "   📊 $category_name: $success_count/$total_count services migrated"
    
    # Update target repository
    if [ $success_count -gt 0 ]; then
        cd "$target_repo"
        git add .
        git commit -m "Complete migration: Add $success_count $category_name services from medinovaios

- Migrated services: ${services[*]}
- Migration date: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- Source: medinovaios
- Target: $(basename $target_repo)"
        echo "   ✅ Target repository updated"
    fi
    
    echo ""
    return $success_count
}

# Migrate all service categories
echo "🚀 Starting complete service migration..."
echo ""

# AI Services
migrate_services_to_repo "${AI_SERVICES[@]}" "ai_ml" "$AI_REPO"

# Clinical Services  
migrate_services_to_repo "${CLINICAL_SERVICES[@]}" "clinical" "$CLINICAL_REPO"

# Security Services
migrate_services_to_repo "${SECURITY_SERVICES[@]}" "security" "$SECURITY_REPO"

# Data Services
migrate_services_to_repo "${DATA_SERVICES[@]}" "data" "$DATA_REPO"

# Integration Services
migrate_services_to_repo "${INTEGRATION_SERVICES[@]}" "integration" "$INTEGRATION_REPO"

# Patient Services
migrate_services_to_repo "${PATIENT_SERVICES[@]}" "patient" "$PATIENT_REPO"

# Billing Services
migrate_services_to_repo "${BILLING_SERVICES[@]}" "billing" "$BILLING_REPO"

# Compliance Services
migrate_services_to_repo "${COMPLIANCE_SERVICES[@]}" "compliance" "$COMPLIANCE_REPO"

# Infrastructure Services
migrate_services_to_repo "${INFRASTRUCTURE_SERVICES[@]}" "infrastructure" "$INFRASTRUCTURE_REPO"

# UI Services
migrate_services_to_repo "${UI_SERVICES[@]}" "ui_ux" "$UI_REPO"

# Utility Services
migrate_services_to_repo "${UTILITY_SERVICES[@]}" "utility" "$UTILITY_REPO"

echo "=========================================="
echo "🎉 Complete medinovaios cleanup completed!"
echo "📅 Timestamp: $(date)"
echo ""

# Final cleanup of medinovaios
echo "🧹 Performing final cleanup of medinovaios..."
cd "$SOURCE_REPO"

# Remove migrated services
ALL_MIGRATED_SERVICES=(
    "${AI_SERVICES[@]}" "${CLINICAL_SERVICES[@]}" "${SECURITY_SERVICES[@]}"
    "${DATA_SERVICES[@]}" "${INTEGRATION_SERVICES[@]}" "${PATIENT_SERVICES[@]}"
    "${BILLING_SERVICES[@]}" "${COMPLIANCE_SERVICES[@]}" "${INFRASTRUCTURE_SERVICES[@]}"
    "${UI_SERVICES[@]}" "${UTILITY_SERVICES[@]}"
)

removed_count=0
for service in "${ALL_MIGRATED_SERVICES[@]}"; do
    if [ -d "services/$service" ]; then
        rm -rf "services/$service"
        ((removed_count++))
    fi
done

echo "🗑️  Removed $removed_count services from medinovaios"

# Commit cleanup
git add .
git commit -m "Complete cleanup: Remove $removed_count migrated services from medinovaios

- Removed services: ${ALL_MIGRATED_SERVICES[*]}
- Cleanup date: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- Services migrated to specialized repositories
- medinovaios now contains only core orchestration components"

echo "✅ medinovaios cleanup completed"

echo ""
echo "📋 Final Summary:"
echo "   - Services migrated: $removed_count"
echo "   - Target repositories: 11"
echo "   - Source: $SOURCE_REPO"
echo "   - Cleanup date: $(date)"
echo ""
echo "🔄 Next step: Validate final migration results"

