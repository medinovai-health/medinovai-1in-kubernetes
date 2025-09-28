#!/bin/bash
# migrate_patient_services.sh - Migrate Patient services from medinovaios to medinovai-patient-services

echo "👤 Starting Patient services migration..."
echo "Timestamp: $(date)"
echo "=========================================="

SOURCE_REPO="/Users/dev1/github/medinovaios"
TARGET_REPO="/Users/dev1/github/medinovai-patient-services"

# List of Patient services to migrate
PATIENT_SERVICES=(
    "patient-portal"
    "patient-management"
    "patient-registration"
    "patient-scheduling"
    "patient-communication"
    "patient-engagement"
    "patient-monitoring"
    "patient-care-coordination"
    "patient-education"
    "patient-feedback"
    "patient-satisfaction"
    "patient-outcomes"
    "patient-safety"
    "patient-privacy"
    "patient-consent"
)

echo "Source: $SOURCE_REPO"
echo "Target: $TARGET_REPO"
echo "Services to migrate: ${#PATIENT_SERVICES[@]}"
echo ""

# Check if source repository exists
if [ ! -d "$SOURCE_REPO" ]; then
    echo "❌ Source repository not found: $SOURCE_REPO"
    exit 1
fi

# Check if target repository exists
if [ ! -d "$TARGET_REPO" ]; then
    echo "❌ Target repository not found: $TARGET_REPO"
    exit 1
fi

# Create services directory in target if it doesn't exist
mkdir -p "$TARGET_REPO/services"

# Function to migrate a service
migrate_service() {
    local service=$1
    local source_path="$SOURCE_REPO/services/$service"
    local target_path="$TARGET_REPO/services/$service"
    
    echo "📁 Migrating $service..."
    
    # Check if service exists in source
    if [ ! -d "$source_path" ]; then
        echo "   ⚠️  Service $service not found in source repository"
        return 1
    fi
    
    # Check if service already exists in target
    if [ -d "$target_path" ]; then
        echo "   ⚠️  Service $service already exists in target repository"
        return 1
    fi
    
    # Copy service to target repository
    echo "   📋 Copying $service to target repository..."
    if cp -r "$source_path" "$target_path"; then
        echo "   ✅ Successfully copied $service"
        
        # Update service configuration if needed
        echo "   🔧 Updating service configuration..."
        
        # Create or update service metadata
        cat > "$target_path/service-info.json" << EOF
{
    "service_name": "$service",
    "category": "patient",
    "migrated_from": "medinovaios",
    "migration_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "target_repository": "medinovai-patient-services",
    "description": "Patient service migrated from medinovaios"
}
EOF
        
        echo "   ✅ Service configuration updated"
        echo "   🎉 Successfully migrated $service"
        return 0
    else
        echo "   ❌ Failed to copy $service"
        return 1
    fi
}

# Migrate all Patient services
SUCCESS_COUNT=0
TOTAL_COUNT=${#PATIENT_SERVICES[@]}

echo "🚀 Starting migration of $TOTAL_COUNT Patient services..."
echo ""

for service in "${PATIENT_SERVICES[@]}"; do
    if migrate_service "$service"; then
        ((SUCCESS_COUNT++))
    fi
    echo ""
done

echo "=========================================="
echo "🎉 Patient services migration completed!"
echo "✅ Successfully migrated: $SUCCESS_COUNT/$TOTAL_COUNT services"
echo "📅 Timestamp: $(date)"
echo ""

# Update target repository
echo "🔄 Updating target repository..."
cd "$TARGET_REPO"

# Add all changes
git add .

# Commit changes
git commit -m "Migrate $SUCCESS_COUNT Patient services from medinovaios

- Migrated services: ${PATIENT_SERVICES[*]}
- Migration date: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- Source: medinovaios
- Target: medinovai-patient-services"

echo "✅ Target repository updated"

echo ""
echo "📋 Migration Summary:"
echo "   - Services migrated: $SUCCESS_COUNT/$TOTAL_COUNT"
echo "   - Source: $SOURCE_REPO"
echo "   - Target: $TARGET_REPO"
echo "   - Migration date: $(date)"
echo ""
echo "🔄 Next step: Remove migrated services from medinovaios"
