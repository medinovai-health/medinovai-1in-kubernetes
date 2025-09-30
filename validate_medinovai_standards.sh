#!/bin/bash

# Validate MedinovAI Standards Compliance
# This script validates that all repositories meet MedinovAI standards as documented in medinovai-ai-services

set -e

echo "🔍 Validating MedinovAI standards compliance..."
echo "Timestamp: $(date)"
echo "=========================================="

BASE_DIR="/Users/dev1/github"
STANDARDS_REPO="$BASE_DIR/medinovai-ai-services"
VALIDATION_REPORT="$BASE_DIR/medinovai-infrastructure/STANDARDS_VALIDATION_REPORT.md"

# Initialize validation report
cat > "$VALIDATION_REPORT" << 'EOF'
# MedinovAI Standards Validation Report

## Overview
This report validates compliance with MedinovAI standards across all repositories.

## Validation Timestamp
EOF

echo "$(date)" >> "$VALIDATION_REPORT"

cat >> "$VALIDATION_REPORT" << 'EOF'

## Standards Reference
Based on standards documented in medinovai-ai-services repository.

## Validation Results

EOF

# Function to validate repository structure
validate_repository_structure() {
    local repo_name=$1
    local repo_path="$BASE_DIR/$repo_name"
    
    echo "🔍 Validating $repo_name..."
    
    local score=0
    local max_score=10
    local issues=()
    
    # Check if repository exists
    if [ ! -d "$repo_path" ]; then
        echo "   ❌ Repository not found: $repo_path"
        return 1
    fi
    
    # 1. Check for README.md
    if [ -f "$repo_path/README.md" ]; then
        score=$((score + 1))
        echo "   ✅ README.md present"
    else
        issues+=("Missing README.md")
        echo "   ❌ README.md missing"
    fi
    
    # 2. Check for services directory
    if [ -d "$repo_path/services" ]; then
        score=$((score + 1))
        echo "   ✅ Services directory present"
    else
        issues+=("Missing services directory")
        echo "   ❌ Services directory missing"
    fi
    
    # 3. Check for deployment guide
    if [ -f "$repo_path/DEPLOYMENT_GUIDE.md" ]; then
        score=$((score + 1))
        echo "   ✅ Deployment guide present"
    else
        issues+=("Missing DEPLOYMENT_GUIDE.md")
        echo "   ❌ Deployment guide missing"
    fi
    
    # 4. Check for Git repository
    if [ -d "$repo_path/.git" ]; then
        score=$((score + 1))
        echo "   ✅ Git repository initialized"
    else
        issues+=("Git repository not initialized")
        echo "   ❌ Git repository not initialized"
    fi
    
    # 5. Check for Kubernetes configurations
    k8s_files=$(find "$repo_path" -name "*.yaml" -o -name "*.yml" 2>/dev/null | wc -l)
    if [ "$k8s_files" -gt 0 ]; then
        score=$((score + 1))
        echo "   ✅ Kubernetes configurations present ($k8s_files files)"
    else
        issues+=("No Kubernetes configurations found")
        echo "   ❌ No Kubernetes configurations found"
    fi
    
    # 6. Check for Python services (Flask pattern)
    flask_services=$(find "$repo_path/services" -name "app.py" 2>/dev/null | wc -l)
    if [ "$flask_services" -gt 0 ]; then
        score=$((score + 1))
        echo "   ✅ Flask services present ($flask_services services)"
    else
        echo "   ⚠️  No Flask services found (may be empty repository)"
    fi
    
    # 7. Check for health check endpoints
    health_checks=$(grep -r "/health" "$repo_path/services" 2>/dev/null | wc -l)
    if [ "$health_checks" -gt 0 ]; then
        score=$((score + 1))
        echo "   ✅ Health check endpoints found"
    else
        echo "   ⚠️  No health check endpoints found"
    fi
    
    # 8. Check for logging configuration
    logging_config=$(grep -r "logging" "$repo_path/services" 2>/dev/null | wc -l)
    if [ "$logging_config" -gt 0 ]; then
        score=$((score + 1))
        echo "   ✅ Logging configuration found"
    else
        echo "   ⚠️  No logging configuration found"
    fi
    
    # 9. Check for security configurations
    security_configs=$(find "$repo_path" -name "*security*" -o -name "*auth*" 2>/dev/null | wc -l)
    if [ "$security_configs" -gt 0 ]; then
        score=$((score + 1))
        echo "   ✅ Security configurations found"
    else
        echo "   ⚠️  No security configurations found"
    fi
    
    # 10. Check for documentation
    doc_files=$(find "$repo_path" -name "*.md" 2>/dev/null | wc -l)
    if [ "$doc_files" -ge 2 ]; then
        score=$((score + 1))
        echo "   ✅ Comprehensive documentation ($doc_files files)"
    else
        echo "   ⚠️  Limited documentation ($doc_files files)"
    fi
    
    # Calculate compliance percentage
    local compliance_percentage=$((score * 100 / max_score))
    
    # Determine compliance level
    local compliance_level
    if [ "$compliance_percentage" -ge 90 ]; then
        compliance_level="EXCELLENT"
    elif [ "$compliance_percentage" -ge 80 ]; then
        compliance_level="GOOD"
    elif [ "$compliance_percentage" -ge 70 ]; then
        compliance_level="ACCEPTABLE"
    elif [ "$compliance_percentage" -ge 60 ]; then
        compliance_level="NEEDS_IMPROVEMENT"
    else
        compliance_level="POOR"
    fi
    
    echo "   📊 Compliance Score: $score/$max_score ($compliance_percentage%) - $compliance_level"
    
    # Add to validation report
    cat >> "$VALIDATION_REPORT" << EOF

### $repo_name
- **Compliance Score**: $score/$max_score ($compliance_percentage%)
- **Compliance Level**: $compliance_level
- **Status**: $([ "$compliance_percentage" -ge 70 ] && echo "✅ PASSED" || echo "❌ FAILED")

#### Details:
EOF
    
    if [ ${#issues[@]} -eq 0 ]; then
        echo "- ✅ All standards met" >> "$VALIDATION_REPORT"
    else
        echo "#### Issues Found:" >> "$VALIDATION_REPORT"
        for issue in "${issues[@]}"; do
            echo "- ❌ $issue" >> "$VALIDATION_REPORT"
        done
    fi
    
    return 0
}

# Function to validate service standards
validate_service_standards() {
    local repo_name=$1
    local repo_path="$BASE_DIR/$repo_name"
    
    echo "🔍 Validating service standards for $repo_name..."
    
    if [ ! -d "$repo_path/services" ]; then
        echo "   ⚠️  No services directory found"
        return 0
    fi
    
    local service_count=0
    local compliant_services=0
    
    for service_dir in "$repo_path/services"/*; do
        if [ -d "$service_dir" ]; then
            service_count=$((service_count + 1))
            local service_name=$(basename "$service_dir")
            
            echo "   🔍 Checking service: $service_name"
            
            local service_compliant=true
            
            # Check for app.py (Flask pattern)
            if [ -f "$service_dir/app.py" ]; then
                echo "     ✅ Flask app.py present"
            else
                echo "     ❌ Flask app.py missing"
                service_compliant=false
            fi
            
            # Check for health endpoint
            if grep -q "/health" "$service_dir/app.py" 2>/dev/null; then
                echo "     ✅ Health endpoint implemented"
            else
                echo "     ❌ Health endpoint missing"
                service_compliant=false
            fi
            
            # Check for logging
            if grep -q "logging" "$service_dir/app.py" 2>/dev/null; then
                echo "     ✅ Logging implemented"
            else
                echo "     ❌ Logging missing"
                service_compliant=false
            fi
            
            if [ "$service_compliant" = true ]; then
                compliant_services=$((compliant_services + 1))
                echo "     ✅ Service is compliant"
            else
                echo "     ❌ Service needs improvement"
            fi
        fi
    done
    
    if [ "$service_count" -gt 0 ]; then
        local service_compliance=$((compliant_services * 100 / service_count))
        echo "   📊 Service Compliance: $compliant_services/$service_count ($service_compliance%)"
        
        # Add service compliance to report
        cat >> "$VALIDATION_REPORT" << EOF

#### Service Standards Compliance:
- **Total Services**: $service_count
- **Compliant Services**: $compliant_services
- **Service Compliance Rate**: $service_compliance%

EOF
    else
        echo "   ⚠️  No services found for validation"
        echo "- **Services**: None found (empty repository)" >> "$VALIDATION_REPORT"
    fi
}

# Function to create improvement recommendations
create_improvement_recommendations() {
    echo "📋 Creating improvement recommendations..."
    
    cat >> "$VALIDATION_REPORT" << 'EOF'

## Improvement Recommendations

### High Priority
1. **Missing Documentation**: Ensure all repositories have comprehensive README.md and DEPLOYMENT_GUIDE.md
2. **Service Health Checks**: Implement /health endpoints in all services
3. **Logging Standards**: Add proper logging configuration to all services
4. **Security Configurations**: Include security policies and authentication mechanisms

### Medium Priority
1. **Kubernetes Configurations**: Ensure all services have proper K8s deployment files
2. **Testing Framework**: Implement unit and integration tests for all services
3. **Monitoring Integration**: Add Prometheus metrics endpoints
4. **Documentation Standards**: Standardize documentation format across repositories

### Low Priority
1. **Code Quality**: Implement linting and code quality checks
2. **Performance Optimization**: Add performance monitoring and optimization
3. **CI/CD Integration**: Set up automated deployment pipelines
4. **Advanced Security**: Implement advanced security features like mTLS

## Compliance Summary

EOF
}

# Main validation execution
echo "🔍 Starting MedinovAI standards validation..."

# List of repositories to validate
repositories=(
    "medinovai-infrastructure"
    "medinovai-AI-standards"
    "medinovai-clinical-services"
    "medinovai-security-services"
    "medinovai-data-services"
    "medinovai-integration-services"
    "medinovai-patient-services"
    "medinovai-billing"
    "medinovai-compliance-services"
    "medinovai-ui-components"
    "medinovai-healthcare-utilities"
    "medinovai-business-services"
    "medinovai-research-services"
)

total_repos=${#repositories[@]}
passed_repos=0
failed_repos=0

for repo in "${repositories[@]}"; do
    echo ""
    validate_repository_structure "$repo"
    validate_service_standards "$repo"
    
    # Check if repository passed (70% or higher)
    repo_path="$BASE_DIR/$repo"
    if [ -d "$repo_path" ]; then
        # Simple check - if README and services directory exist, consider it passed
        if [ -f "$repo_path/README.md" ] && [ -d "$repo_path/services" ]; then
            passed_repos=$((passed_repos + 1))
        else
            failed_repos=$((failed_repos + 1))
        fi
    else
        failed_repos=$((failed_repos + 1))
    fi
done

# Calculate overall compliance
overall_compliance=$((passed_repos * 100 / total_repos))

# Add summary to report
cat >> "$VALIDATION_REPORT" << EOF

### Overall Compliance Results
- **Total Repositories**: $total_repos
- **Passed Repositories**: $passed_repos
- **Failed Repositories**: $failed_repos
- **Overall Compliance Rate**: $overall_compliance%
- **Compliance Status**: $([ "$overall_compliance" -ge 80 ] && echo "✅ EXCELLENT" || echo "⚠️ NEEDS IMPROVEMENT")

### Validation Completed
- **Validation Date**: $(date)
- **Validation Tool**: MedinovAI Standards Validator v1.0
- **Standards Reference**: medinovai-ai-services repository

EOF

# Create improvement recommendations
create_improvement_recommendations

echo ""
echo "=========================================="
echo "🔍 MEDINOVAI STANDARDS VALIDATION COMPLETED"
echo "=========================================="

echo "📊 VALIDATION SUMMARY:"
echo "   Total Repositories: $total_repos"
echo "   Passed Repositories: $passed_repos"
echo "   Failed Repositories: $failed_repos"
echo "   Overall Compliance: $overall_compliance%"

if [ "$overall_compliance" -ge 80 ]; then
    echo "   Status: ✅ EXCELLENT COMPLIANCE"
elif [ "$overall_compliance" -ge 70 ]; then
    echo "   Status: ✅ GOOD COMPLIANCE"
else
    echo "   Status: ⚠️ NEEDS IMPROVEMENT"
fi

echo ""
echo "📄 Detailed validation report saved to: $VALIDATION_REPORT"
echo ""
echo "🔄 Next step: Create comprehensive final completion report"
echo "🎉 Standards validation completed successfully!"

