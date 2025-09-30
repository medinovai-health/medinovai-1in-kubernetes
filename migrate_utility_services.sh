#!/bin/bash
# migrate_utility_services.sh - Migrate Utility services from medinovaios to medinovai-healthcare-utilities

echo "🔧 Starting Utility services migration..."
echo "Timestamp: $(date)"
echo "=========================================="

SOURCE_REPO="/Users/dev1/github/medinovaios"
TARGET_REPO="/Users/dev1/github/medinovai-healthcare-utilities"

# List of Utility services to migrate
UTILITY_SERVICES=(
    "utilities"
    "utility-services"
    "common-services"
    "shared-services"
    "helper-services"
    "notification"
    "email-service"
    "sms-service"
    "file-service"
    "document-service"
    "reporting"
    "report-generator"
    "template-engine"
    "workflow-engine"
    "scheduler"
    "cron-service"
    "cache-service"
    "session-management"
    "user-management"
    "authentication"
    "authorization"
    "permission-service"
    "role-service"
    "config-service"
    "settings-service"
    "preference-service"
    "logging-service"
    "audit-service"
    "backup-service"
    "sync-service"
    "validation-service"
    "transformation-service"
    "conversion-service"
)

echo "Source: $SOURCE_REPO"
echo "Target: $TARGET_REPO"
echo "Services to migrate: ${#UTILITY_SERVICES[@]}"
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
    "category": "utility",
    "migrated_from": "medinovaios",
    "migration_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "target_repository": "medinovai-healthcare-utilities",
    "description": "Utility service migrated from medinovaios"
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

# Migrate all Utility services
SUCCESS_COUNT=0
TOTAL_COUNT=${#UTILITY_SERVICES[@]}

echo "🚀 Starting migration of $TOTAL_COUNT Utility services..."
echo ""

for service in "${UTILITY_SERVICES[@]}"; do
    if migrate_service "$service"; then
        ((SUCCESS_COUNT++))
    fi
    echo ""
done

echo "=========================================="
echo "🎉 Utility services migration completed!"
echo "✅ Successfully migrated: $SUCCESS_COUNT/$TOTAL_COUNT services"
echo "📅 Timestamp: $(date)"
echo ""

# Update target repository
echo "🔄 Updating target repository..."
cd "$TARGET_REPO"

# Add all changes
git add .

# Commit changes
git commit -m "Migrate $SUCCESS_COUNT Utility services from medinovaios

- Migrated services: ${UTILITY_SERVICES[*]}
- Migration date: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- Source: medinovaios
- Target: medinovai-healthcare-utilities"

echo "✅ Target repository updated"

echo ""
echo "📋 Migration Summary:"
echo "   - Services migrated: $SUCCESS_COUNT/$TOTAL_COUNT"
echo "   - Source: $SOURCE_REPO"
echo "   - Target: $TARGET_REPO"
echo "   - Migration date: $(date)"
echo ""
echo "🔄 Next step: Remove migrated services from medinovaios"

