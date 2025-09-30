#!/bin/bash
# improve_service_discovery.sh - Improve service discovery and create comprehensive mapping

echo "🔍 Starting service discovery improvement..."
echo "Timestamp: $(date)"
echo "=========================================="

SOURCE_REPO="/Users/dev1/github/medinovaios"

# Create comprehensive service mapping
echo "📊 Creating comprehensive service mapping..."

# Get all remaining services
REMAINING_SERVICES=$(ls "$SOURCE_REPO/services" | grep -v README.md)

# Create service categorization
cat > service_discovery_mapping.json << EOF
{
    "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "total_services_remaining": $(echo "$REMAINING_SERVICES" | wc -l | tr -d ' '),
    "service_categories": {
        "clinical_services": [
EOF

# Clinical Services
CLINICAL_SERVICES=$(echo "$REMAINING_SERVICES" | grep -E "(clinical|cardiology|care-team|clinical-|medication|anesthesia|allergy)" | tr '\n' ',' | sed 's/,$//')
echo "            \"$CLINICAL_SERVICES\"" >> service_discovery_mapping.json

cat >> service_discovery_mapping.json << EOF
        ],
        "compliance_services": [
EOF

# Compliance Services
COMPLIANCE_SERVICES=$(echo "$REMAINING_SERVICES" | grep -E "(compliance|audit|certificate|breach|capa|change-control)" | tr '\n' ',' | sed 's/,$//')
echo "            \"$COMPLIANCE_SERVICES\"" >> service_discovery_mapping.json

cat >> service_discovery_mapping.json << EOF
        ],
        "ai_services": [
EOF

# AI Services
AI_SERVICES=$(echo "$REMAINING_SERVICES" | grep -E "(ai-|clinical-decision-ai|clinical-nlp|bias-fairness)" | tr '\n' ',' | sed 's/,$//')
echo "            \"$AI_SERVICES\"" >> service_discovery_mapping.json

cat >> service_discovery_mapping.json << EOF
        ],
        "infrastructure_services": [
EOF

# Infrastructure Services
INFRASTRUCTURE_SERVICES=$(echo "$REMAINING_SERVICES" | grep -E "(capacity-planning|canary-service|chat-service)" | tr '\n' ',' | sed 's/,$//')
echo "            \"$INFRASTRUCTURE_SERVICES\"" >> service_discovery_mapping.json

cat >> service_discovery_mapping.json << EOF
        ],
        "business_services": [
EOF

# Business Services
BUSINESS_SERVICES=$(echo "$REMAINING_SERVICES" | grep -E "(business-rules|complaints-service)" | tr '\n' ',' | sed 's/,$//')
echo "            \"$BUSINESS_SERVICES\"" >> service_discovery_mapping.json

cat >> service_discovery_mapping.json << EOF
        ],
        "research_services": [
EOF

# Research Services
RESEARCH_SERVICES=$(echo "$REMAINING_SERVICES" | grep -E "(clinical-research|clinical-trial|clinical-trials)" | tr '\n' ',' | sed 's/,$//')
echo "            \"$RESEARCH_SERVICES\"" >> service_discovery_mapping.json

cat >> service_discovery_mapping.json << EOF
        ],
        "unclassified_services": [
EOF

# Unclassified Services (services that don't fit the above categories)
UNCLASSIFIED_SERVICES=$(echo "$REMAINING_SERVICES" | grep -vE "(clinical|cardiology|care-team|clinical-|medication|anesthesia|allergy|compliance|audit|certificate|breach|capa|change-control|ai-|clinical-decision-ai|clinical-nlp|bias-fairness|capacity-planning|canary-service|chat-service|business-rules|complaints-service|clinical-research|clinical-trial|clinical-trials)" | tr '\n' ',' | sed 's/,$//')
echo "            \"$UNCLASSIFIED_SERVICES\"" >> service_discovery_mapping.json

cat >> service_discovery_mapping.json << EOF
        ]
    },
    "migration_recommendations": {
        "high_priority": [
            "clinical-decision-ai",
            "clinical-nlp", 
            "bias-fairness-explainability-service",
            "compliance-audit",
            "breach-detection",
            "breach-notification"
        ],
        "medium_priority": [
            "clinical-research-platform",
            "clinical-trial-management",
            "clinical-trials-management",
            "certificate-management",
            "certificate-authority"
        ],
        "low_priority": [
            "architecture-and-implementation-sections-a-d-service",
            "clinical-decision-test",
            "clinical-modules-config"
        ]
    }
}
EOF

echo "✅ Service discovery mapping created"

# Create improved migration script
cat > improved_migration_script.sh << 'EOF'
#!/bin/bash
# improved_migration_script.sh - Migrate remaining services with improved discovery

echo "🚀 Starting improved service migration..."
echo "Timestamp: $(date)"
echo "=========================================="

SOURCE_REPO="/Users/dev1/github/medinovaios"

# Load service mapping
if [ -f "service_discovery_mapping.json" ]; then
    echo "📊 Loading service discovery mapping..."
    # Extract services from JSON (simplified approach)
    CLINICAL_SERVICES=$(grep -A 10 '"clinical_services"' service_discovery_mapping.json | grep -o '"[^"]*"' | tr -d '"' | tr '\n' ' ')
    COMPLIANCE_SERVICES=$(grep -A 10 '"compliance_services"' service_discovery_mapping.json | grep -o '"[^"]*"' | tr -d '"' | tr '\n' ' ')
    AI_SERVICES=$(grep -A 10 '"ai_services"' service_discovery_mapping.json | grep -o '"[^"]*"' | tr -d '"' | tr '\n' ' ')
    INFRASTRUCTURE_SERVICES=$(grep -A 10 '"infrastructure_services"' service_discovery_mapping.json | grep -o '"[^"]*"' | tr -d '"' | tr '\n' ' ')
    BUSINESS_SERVICES=$(grep -A 10 '"business_services"' service_discovery_mapping.json | grep -o '"[^"]*"' | tr -d '"' | tr '\n' ' ')
    RESEARCH_SERVICES=$(grep -A 10 '"research_services"' service_discovery_mapping.json | grep -o '"[^"]*"' | tr -d '"' | tr '\n' ' ')
    
    echo "✅ Service mapping loaded"
else
    echo "❌ Service discovery mapping not found"
    exit 1
fi

# Function to migrate services to repository
migrate_services() {
    local services="$1"
    local target_repo="$2"
    local category="$3"
    
    echo "📁 Migrating $category services to $(basename $target_repo)..."
    
    # Create services directory if it doesn't exist
    mkdir -p "$target_repo/services"
    
    local success_count=0
    local total_count=0
    
    for service in $services; do
        if [ -n "$service" ] && [ "$service" != "null" ]; then
            ((total_count++))
            local source_path="$SOURCE_REPO/services/$service"
            local target_path="$target_repo/services/$service"
            
            if [ -d "$source_path" ]; then
                if [ ! -d "$target_path" ]; then
                    echo "   📋 Copying $service..."
                    if cp -r "$source_path" "$target_path"; then
                        # Create service metadata
                        cat > "$target_path/service-info.json" << METADATA_EOF
{
    "service_name": "$service",
    "category": "$category",
    "migrated_from": "medinovaios",
    "migration_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "target_repository": "$(basename $target_repo)",
    "description": "$category service migrated from medinovaios with improved discovery"
}
METADATA_EOF
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
        fi
    done
    
    echo "   📊 $category: $success_count/$total_count services migrated"
    
    # Update target repository
    if [ $success_count -gt 0 ]; then
        cd "$target_repo"
        git add .
        git commit -m "Improved migration: Add $success_count $category services from medinovaios

- Migrated services: $services
- Migration date: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- Source: medinovaios
- Target: $(basename $target_repo)
- Method: Improved service discovery"
        echo "   ✅ Target repository updated"
        cd - > /dev/null
    fi
    
    echo ""
    return $success_count
}

# Migrate services by category
echo "🚀 Starting improved service migration..."
echo ""

# Clinical Services
if [ -n "$CLINICAL_SERVICES" ]; then
    migrate_services "$CLINICAL_SERVICES" "/Users/dev1/github/medinovai-clinical-services" "clinical"
fi

# Compliance Services
if [ -n "$COMPLIANCE_SERVICES" ]; then
    migrate_services "$COMPLIANCE_SERVICES" "/Users/dev1/github/medinovai-compliance-services" "compliance"
fi

# AI Services
if [ -n "$AI_SERVICES" ]; then
    migrate_services "$AI_SERVICES" "/Users/dev1/github/medinovai-AI-standards" "ai_ml"
fi

# Infrastructure Services
if [ -n "$INFRASTRUCTURE_SERVICES" ]; then
    migrate_services "$INFRASTRUCTURE_SERVICES" "/Users/dev1/github/medinovai-infrastructure" "infrastructure"
fi

# Business Services (create new repository if needed)
if [ -n "$BUSINESS_SERVICES" ]; then
    BUSINESS_REPO="/Users/dev1/github/medinovai-business-services"
    if [ ! -d "$BUSINESS_REPO" ]; then
        echo "📁 Creating new business services repository..."
        mkdir -p "$BUSINESS_REPO"
        cd "$BUSINESS_REPO"
        git init
        echo "# MedinovAI Business Services" > README.md
        git add README.md
        git commit -m "Initial commit for medinovai-business-services repository"
        cd - > /dev/null
    fi
    migrate_services "$BUSINESS_SERVICES" "$BUSINESS_REPO" "business"
fi

# Research Services (create new repository if needed)
if [ -n "$RESEARCH_SERVICES" ]; then
    RESEARCH_REPO="/Users/dev1/github/medinovai-research-services"
    if [ ! -d "$RESEARCH_REPO" ]; then
        echo "📁 Creating new research services repository..."
        mkdir -p "$RESEARCH_REPO"
        cd "$RESEARCH_REPO"
        git init
        echo "# MedinovAI Research Services" > README.md
        git add README.md
        git commit -m "Initial commit for medinovai-research-services repository"
        cd - > /dev/null
    fi
    migrate_services "$RESEARCH_SERVICES" "$RESEARCH_REPO" "research"
fi

echo "=========================================="
echo "🎉 Improved service migration completed!"
echo "📅 Timestamp: $(date)"
echo ""

# Final cleanup
echo "🧹 Performing final cleanup of medinovaios..."
cd "$SOURCE_REPO"

# Remove migrated services
ALL_MIGRATED_SERVICES="$CLINICAL_SERVICES $COMPLIANCE_SERVICES $AI_SERVICES $INFRASTRUCTURE_SERVICES $BUSINESS_SERVICES $RESEARCH_SERVICES"

removed_count=0
for service in $ALL_MIGRATED_SERVICES; do
    if [ -n "$service" ] && [ "$service" != "null" ] && [ -d "services/$service" ]; then
        rm -rf "services/$service"
        ((removed_count++))
    fi
done

echo "🗑️  Removed $removed_count services from medinovaios"

# Commit cleanup
git add .
git commit -m "Improved cleanup: Remove $removed_count services from medinovaios

- Removed services: $ALL_MIGRATED_SERVICES
- Cleanup date: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- Method: Improved service discovery and categorization
- Services migrated to specialized repositories"

echo "✅ medinovaios improved cleanup completed"

echo ""
echo "📋 Improved Migration Summary:"
echo "   - Services migrated: $removed_count"
echo "   - Method: Improved service discovery"
echo "   - Source: $SOURCE_REPO"
echo "   - Cleanup date: $(date)"
echo ""
echo "🔄 Next step: Complete integration testing"
EOF

chmod +x improved_migration_script.sh

echo "✅ Improved migration script created"
echo "✅ Service discovery improvement completed"
echo ""
echo "📊 Service Discovery Results:"
echo "   - Total services remaining: $(echo "$REMAINING_SERVICES" | wc -l | tr -d ' ')"
echo "   - Clinical services identified: $(echo "$CLINICAL_SERVICES" | wc -w)"
echo "   - Compliance services identified: $(echo "$COMPLIANCE_SERVICES" | wc -w)"
echo "   - AI services identified: $(echo "$AI_SERVICES" | wc -w)"
echo "   - Infrastructure services identified: $(echo "$INFRASTRUCTURE_SERVICES" | wc -w)"
echo "   - Business services identified: $(echo "$BUSINESS_SERVICES" | wc -w)"
echo "   - Research services identified: $(echo "$RESEARCH_SERVICES" | wc -w)"
echo "   - Unclassified services: $(echo "$UNCLASSIFIED_SERVICES" | wc -w)"
echo ""
echo "🔄 Next step: Run improved migration script"

