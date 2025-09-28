#!/bin/bash
# migrate_security_services.sh - Migrate Security services from medinovaios to medinovai-security-services

echo "🔒 Starting Security services migration..."
echo "Timestamp: $(date)"
echo "=========================================="

SOURCE_REPO="/Users/dev1/github/medinovaios"
TARGET_REPO="/Users/dev1/github/medinovai-security-services"

# List of Security services to migrate
SECURITY_SERVICES=(
    "access-control"
    "access-review"
    "audit-ledger-service"
    "audit-logger"
    "audit-logging"
    "audit-system"
    "audit-trail"
    "breach-detection"
    "breach-notification"
    "certificate-authority"
    "certificate-management"
    "encryption-service"
    "identity-management"
    "identity-provider"
    "key-management"
    "mfa-service"
    "password-policy"
    "penetration-testing"
    "phi-protection"
    "security"
    "security_enhancements"
    "threat-detection"
    "tokenization-vault"
    "vulnerability-scanning"
)

echo "Source: $SOURCE_REPO"
echo "Target: $TARGET_REPO"
echo "Services to migrate: ${#SECURITY_SERVICES[@]}"
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
    "category": "security",
    "migrated_from": "medinovaios",
    "migration_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "target_repository": "medinovai-security-services",
    "description": "Security service migrated from medinovaios"
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

# Migrate all Security services
SUCCESS_COUNT=0
TOTAL_COUNT=${#SECURITY_SERVICES[@]}

echo "🚀 Starting migration of $TOTAL_COUNT Security services..."
echo ""

for service in "${SECURITY_SERVICES[@]}"; do
    if migrate_service "$service"; then
        ((SUCCESS_COUNT++))
    fi
    echo ""
done

echo "=========================================="
echo "🎉 Security services migration completed!"
echo "✅ Successfully migrated: $SUCCESS_COUNT/$TOTAL_COUNT services"
echo "📅 Timestamp: $(date)"
echo ""

# Update target repository
echo "🔄 Updating target repository..."
cd "$TARGET_REPO"

# Add all changes
git add .

# Commit changes
git commit -m "Migrate $SUCCESS_COUNT Security services from medinovaios

- Migrated services: ${SECURITY_SERVICES[*]}
- Migration date: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- Source: medinovaios
- Target: medinovai-security-services"

echo "✅ Target repository updated"

echo ""
echo "📋 Migration Summary:"
echo "   - Services migrated: $SUCCESS_COUNT/$TOTAL_COUNT"
echo "   - Source: $SOURCE_REPO"
echo "   - Target: $TARGET_REPO"
echo "   - Migration date: $(date)"
echo ""
echo "🔄 Next step: Remove migrated services from medinovaios"
