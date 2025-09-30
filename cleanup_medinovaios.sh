#!/bin/bash
# cleanup_medinovaios.sh - Remove migrated services from medinovaios

echo "🧹 Starting medinovaios cleanup..."
echo "Timestamp: $(date)"
echo "=========================================="

SOURCE_REPO="/Users/dev1/github/medinovaios"

# List of all migrated services to remove
MIGRATED_SERVICES=(
    # AI/ML Services (28)
    "ai-model-service" "ai-prediction" "ai-recommendation" "ai-training" "ai-validation"
    "machine-learning" "ml-pipeline" "ml-training" "ml-validation" "deep-learning"
    "neural-network" "computer-vision" "nlp-service" "speech-recognition" "image-processing"
    "data-mining" "pattern-recognition" "predictive-analytics" "ai-insights" "ai-dashboard"
    "model-management" "ai-workflow" "ai-integration" "ai-monitoring" "ai-security"
    "ai-compliance" "ai-audit" "ai-reporting" "ai-optimization"
    
    # Clinical Services (27)
    "clinical-decision-support" "clinical-workflow" "clinical-documentation" "clinical-reporting"
    "clinical-analytics" "clinical-monitoring" "clinical-alerts" "clinical-guidelines"
    "clinical-protocols" "clinical-trials" "clinical-research" "clinical-data"
    "clinical-integration" "clinical-interoperability" "clinical-standards" "clinical-compliance"
    "clinical-quality" "clinical-safety" "clinical-outcomes" "clinical-metrics"
    "clinical-dashboard" "clinical-portal" "clinical-mobile" "clinical-telehealth"
    "clinical-remote" "clinical-virtual" "clinical-digital"
    
    # Security Services (24)
    "security" "security-monitoring" "security-audit" "security-compliance" "security-policy"
    "security-management" "security-authentication" "security-authorization" "security-encryption"
    "security-key-management" "security-certificate" "security-token" "security-session"
    "security-access-control" "security-identity" "security-federation" "security-sso"
    "security-mfa" "security-biometric" "security-firewall" "security-intrusion"
    "security-vulnerability" "security-penetration" "security-incident"
    
    # Data Services (16)
    "data-analytics" "data-catalog" "data-governance" "data-lineage" "data-retention"
    "data-services" "data-sync" "data-warehouse" "advanced-analytics" "behavioral-analytics"
    "business-intelligence" "healthcare-analytics-dashboard" "healthcare-cost-analytics"
    "real-time-analytics" "metrics-collector" "metrics-service"
    
    # Integration Services (17)
    "cerner-integration" "epic-emr-integration" "epic-integration" "ehr-integration" "emr"
    "medinovai-emr" "hl7-integration" "hl7-interface" "interoperability-gateway" "lis-interface"
    "lis-system" "medinovai-lis" "pacs-integration" "radiology-integration" "united-healthcare-integration"
    "device-integration" "medical-device-integration"
    
    # Patient Services (15)
    "patient-portal" "patient-management" "patient-registration" "patient-scheduling"
    "patient-communication" "patient-engagement" "patient-monitoring" "patient-care-coordination"
    "patient-education" "patient-feedback" "patient-satisfaction" "patient-outcomes"
    "patient-safety" "patient-privacy" "patient-consent"
    
    # Billing Services (10)
    "billing" "billing-system" "payment-processing" "insurance-claims" "revenue-cycle"
    "financial-reporting" "cost-accounting" "budget-management" "financial-analytics" "reimbursement"
    
    # Compliance Services (23)
    "compliance" "compliance-monitoring" "audit-trail" "regulatory-reporting" "hipaa-compliance"
    "fda-compliance" "gdpr-compliance" "sox-compliance" "quality-assurance" "risk-management"
    "policy-management" "governance" "certification" "accreditation" "standards-compliance"
    "regulatory-framework" "compliance-dashboard" "compliance-alerts" "compliance-training"
    "compliance-documentation" "compliance-workflow" "compliance-analytics" "compliance-reporting"
    
    # Infrastructure Services (14)
    "infrastructure" "infrastructure-management" "deployment" "orchestration" "monitoring"
    "logging" "metrics" "alerting" "backup" "disaster-recovery" "scaling" "load-balancing"
    "service-mesh" "api-gateway"
    
    # UI/UX Services (5)
    "ui-components" "user-interface" "frontend" "dashboard" "web-interface"
    
    # Utility Services (33)
    "utilities" "utility-services" "common-services" "shared-services" "helper-services"
    "notification" "email-service" "sms-service" "file-service" "document-service"
    "reporting" "report-generator" "template-engine" "workflow-engine" "scheduler"
    "cron-service" "cache-service" "session-management" "user-management" "authentication"
    "authorization" "permission-service" "role-service" "config-service" "settings-service"
    "preference-service" "logging-service" "audit-service" "backup-service" "sync-service"
    "validation-service" "transformation-service" "conversion-service"
)

echo "Source: $SOURCE_REPO"
echo "Services to remove: ${#MIGRATED_SERVICES[@]}"
echo ""

# Check if source repository exists
if [ ! -d "$SOURCE_REPO" ]; then
    echo "❌ Source repository not found: $SOURCE_REPO"
    exit 1
fi

# Function to remove a service
remove_service() {
    local service=$1
    local service_path="$SOURCE_REPO/services/$service"
    
    echo "🗑️  Removing $service..."
    
    # Check if service exists
    if [ ! -d "$service_path" ]; then
        echo "   ⚠️  Service $service not found in source repository"
        return 1
    fi
    
    # Remove service directory
    echo "   🗑️  Removing $service directory..."
    if rm -rf "$service_path"; then
        echo "   ✅ Successfully removed $service"
        return 0
    else
        echo "   ❌ Failed to remove $service"
        return 1
    fi
}

# Remove all migrated services
SUCCESS_COUNT=0
TOTAL_COUNT=${#MIGRATED_SERVICES[@]}

echo "🚀 Starting cleanup of $TOTAL_COUNT migrated services..."
echo ""

for service in "${MIGRATED_SERVICES[@]}"; do
    if remove_service "$service"; then
        ((SUCCESS_COUNT++))
    fi
    echo ""
done

echo "=========================================="
echo "🎉 medinovaios cleanup completed!"
echo "✅ Successfully removed: $SUCCESS_COUNT/$TOTAL_COUNT services"
echo "📅 Timestamp: $(date)"
echo ""

# Update medinovaios repository
echo "🔄 Updating medinovaios repository..."
cd "$SOURCE_REPO"

# Add all changes
git add .

# Commit changes
git commit -m "Cleanup: Remove $SUCCESS_COUNT migrated services from medinovaios

- Removed services: ${MIGRATED_SERVICES[*]}
- Cleanup date: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- Services migrated to specialized repositories
- medinovaios now contains only core orchestration components"

echo "✅ medinovaios repository updated"

echo ""
echo "📋 Cleanup Summary:"
echo "   - Services removed: $SUCCESS_COUNT/$TOTAL_COUNT"
echo "   - Source: $SOURCE_REPO"
echo "   - Cleanup date: $(date)"
echo ""
echo "🔄 Next step: Validate migration results and test all repositories"

