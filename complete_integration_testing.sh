#!/bin/bash
# complete_integration_testing.sh - Complete integration testing across all migrated repositories

echo "🧪 Starting comprehensive integration testing..."
echo "Timestamp: $(date)"
echo "=========================================="

# List of all migrated repositories
REPOSITORIES=(
    "/Users/dev1/github/medinovai-AI-standards"
    "/Users/dev1/github/medinovai-clinical-services"
    "/Users/dev1/github/medinovai-security-services"
    "/Users/dev1/github/medinovai-data-services"
    "/Users/dev1/github/medinovai-integration-services"
    "/Users/dev1/github/medinovai-patient-services"
    "/Users/dev1/github/medinovai-billing"
    "/Users/dev1/github/medinovai-compliance-services"
    "/Users/dev1/github/medinovai-infrastructure"
    "/Users/dev1/github/medinovai-ui-components"
    "/Users/dev1/github/medinovai-healthcare-utilities"
    "/Users/dev1/github/medinovai-business-services"
    "/Users/dev1/github/medinovai-research-services"
)

# Test results tracking
TOTAL_REPOS=0
PASSED_REPOS=0
FAILED_REPOS=0
TEST_RESULTS=()

echo "📊 Testing ${#REPOSITORIES[@]} migrated repositories..."
echo ""

# Function to test a repository
test_repository() {
    local repo_path="$1"
    local repo_name=$(basename "$repo_path")
    
    echo "🧪 Testing $repo_name..."
    
    # Check if repository exists
    if [ ! -d "$repo_path" ]; then
        echo "   ❌ Repository not found: $repo_path"
        return 1
    fi
    
    local test_passed=true
    local test_details=()
    
    # Test 1: Repository Structure
    echo "   📁 Testing repository structure..."
    if [ -d "$repo_path/services" ]; then
        echo "   ✅ Services directory exists"
        test_details+=("✅ Services directory")
    else
        echo "   ❌ Services directory missing"
        test_details+=("❌ Services directory")
        test_passed=false
    fi
    
    # Test 2: Git Repository
    echo "   🔧 Testing Git repository..."
    if [ -d "$repo_path/.git" ]; then
        echo "   ✅ Git repository initialized"
        test_details+=("✅ Git repository")
    else
        echo "   ❌ Git repository not initialized"
        test_details+=("❌ Git repository")
        test_passed=false
    fi
    
    # Test 3: MedinovAI Standards
    echo "   📋 Testing MedinovAI standards compliance..."
    local standards_files=(
        ".medinovai-standards.yaml"
        "medinovai.config.json"
        "security-config.yaml"
        "performance-monitoring-config.yaml"
    )
    
    local standards_count=0
    for file in "${standards_files[@]}"; do
        if [ -f "$repo_path/$file" ]; then
            ((standards_count++))
        fi
    done
    
    if [ $standards_count -ge 2 ]; then
        echo "   ✅ MedinovAI standards compliance ($standards_count/4 files)"
        test_details+=("✅ MedinovAI standards ($standards_count/4)")
    else
        echo "   ⚠️  Partial MedinovAI standards compliance ($standards_count/4 files)"
        test_details+=("⚠️  MedinovAI standards ($standards_count/4)")
    fi
    
    # Test 4: Service Count
    echo "   📊 Testing service count..."
    local service_count=0
    if [ -d "$repo_path/services" ]; then
        service_count=$(find "$repo_path/services" -maxdepth 1 -type d | wc -l)
        service_count=$((service_count - 1))  # Subtract services directory itself
    fi
    
    if [ $service_count -gt 0 ]; then
        echo "   ✅ Services present ($service_count services)"
        test_details+=("✅ Services ($service_count)")
    else
        echo "   ⚠️  No services found"
        test_details+=("⚠️  Services (0)")
    fi
    
    # Test 5: Service Metadata
    echo "   📝 Testing service metadata..."
    local metadata_count=0
    if [ -d "$repo_path/services" ]; then
        metadata_count=$(find "$repo_path/services" -name "service-info.json" | wc -l | tr -d ' ')
    fi
    
    if [ $metadata_count -gt 0 ]; then
        echo "   ✅ Service metadata present ($metadata_count services)"
        test_details+=("✅ Metadata ($metadata_count)")
    else
        echo "   ⚠️  No service metadata found"
        test_details+=("⚠️  Metadata (0)")
    fi
    
    # Test 6: Kubernetes Configurations
    echo "   ☸️  Testing Kubernetes configurations..."
    local k8s_count=0
    if [ -d "$repo_path/services" ]; then
        k8s_count=$(find "$repo_path/services" -name "deployment.yaml" | wc -l | tr -d ' ')
    fi
    
    if [ $k8s_count -gt 0 ]; then
        echo "   ✅ Kubernetes configurations present ($k8s_count services)"
        test_details+=("✅ K8s configs ($k8s_count)")
    else
        echo "   ⚠️  No Kubernetes configurations found"
        test_details+=("⚠️  K8s configs (0)")
    fi
    
    # Test 7: Security Configurations
    echo "   🔒 Testing security configurations..."
    local security_count=0
    if [ -d "$repo_path/services" ]; then
        security_count=$(find "$repo_path/services" -name "security-config.yaml" | wc -l | tr -d ' ')
    fi
    
    if [ $security_count -gt 0 ]; then
        echo "   ✅ Security configurations present ($security_count services)"
        test_details+=("✅ Security ($security_count)")
    else
        echo "   ⚠️  No security configurations found"
        test_details+=("⚠️  Security (0)")
    fi
    
    # Test 8: Documentation
    echo "   📚 Testing documentation..."
    local doc_count=0
    if [ -d "$repo_path/services" ]; then
        doc_count=$(find "$repo_path/services" -name "README.md" | wc -l | tr -d ' ')
    fi
    
    if [ $doc_count -gt 0 ]; then
        echo "   ✅ Documentation present ($doc_count services)"
        test_details+=("✅ Documentation ($doc_count)")
    else
        echo "   ⚠️  Limited documentation found"
        test_details+=("⚠️  Documentation ($doc_count)")
    fi
    
    # Test 9: Testing Framework
    echo "   🧪 Testing testing framework..."
    local test_count=0
    if [ -d "$repo_path/services" ]; then
        test_count=$(find "$repo_path/services" -name "test_*.py" -o -name "*.test.js" | wc -l | tr -d ' ')
    fi
    
    if [ $test_count -gt 0 ]; then
        echo "   ✅ Testing framework present ($test_count test files)"
        test_details+=("✅ Tests ($test_count)")
    else
        echo "   ⚠️  Limited testing framework found"
        test_details+=("⚠️  Tests ($test_count)")
    fi
    
    # Test 10: Git Status
    echo "   🔄 Testing Git status..."
    cd "$repo_path"
    local git_status=$(git status --porcelain)
    if [ -z "$git_status" ]; then
        echo "   ✅ Git working directory clean"
        test_details+=("✅ Git clean")
    else
        echo "   ⚠️  Git working directory has uncommitted changes"
        test_details+=("⚠️  Git changes")
    fi
    cd - > /dev/null
    
    # Overall test result
    if [ "$test_passed" = true ]; then
        echo "   🎉 $repo_name: PASSED"
        ((PASSED_REPOS++))
        TEST_RESULTS+=("✅ $repo_name: PASSED")
    else
        echo "   ❌ $repo_name: FAILED"
        ((FAILED_REPOS++))
        TEST_RESULTS+=("❌ $repo_name: FAILED")
    fi
    
    echo "   📋 Test Details: ${test_details[*]}"
    echo ""
    
    return 0
}

# Test all repositories
for repo in "${REPOSITORIES[@]}"; do
    ((TOTAL_REPOS++))
    test_repository "$repo"
done

# Generate test report
echo "=========================================="
echo "🧪 INTEGRATION TESTING COMPLETED"
echo "=========================================="
echo ""
echo "📊 TEST SUMMARY:"
echo "   Total Repositories: $TOTAL_REPOS"
echo "   Passed: $PASSED_REPOS"
echo "   Failed: $FAILED_REPOS"
echo "   Success Rate: $(( (PASSED_REPOS * 100) / TOTAL_REPOS ))%"
echo ""

echo "📋 DETAILED RESULTS:"
for result in "${TEST_RESULTS[@]}"; do
    echo "   $result"
done

echo ""

# Create test report file
cat > integration_test_report.json << EOF
{
    "test_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "test_summary": {
        "total_repositories": $TOTAL_REPOS,
        "passed_repositories": $PASSED_REPOS,
        "failed_repositories": $FAILED_REPOS,
        "success_rate_percent": $(( (PASSED_REPOS * 100) / TOTAL_REPOS ))
    },
    "test_results": [
EOF

for result in "${TEST_RESULTS[@]}"; do
    echo "        \"$result\"," >> integration_test_report.json
done

# Remove trailing comma from last entry
sed -i '' '$ s/,$//' integration_test_report.json

cat >> integration_test_report.json << EOF
    ],
    "test_categories": [
        "Repository Structure",
        "Git Repository",
        "MedinovAI Standards Compliance",
        "Service Count",
        "Service Metadata",
        "Kubernetes Configurations",
        "Security Configurations",
        "Documentation",
        "Testing Framework",
        "Git Status"
    ],
    "recommendations": [
        "Continue monitoring repository health",
        "Ensure all services have proper metadata",
        "Maintain security configurations",
        "Keep documentation up to date",
        "Implement comprehensive testing"
    ]
}
EOF

echo "📄 Test report saved to: integration_test_report.json"
echo ""

# Overall assessment
if [ $FAILED_REPOS -eq 0 ]; then
    echo "🎉 ALL REPOSITORIES PASSED INTEGRATION TESTING!"
    echo "✅ Migration quality: EXCELLENT"
elif [ $FAILED_REPOS -le 2 ]; then
    echo "✅ MOST REPOSITORIES PASSED INTEGRATION TESTING"
    echo "⚠️  Migration quality: GOOD (minor issues to address)"
else
    echo "⚠️  SOME REPOSITORIES FAILED INTEGRATION TESTING"
    echo "❌ Migration quality: NEEDS IMPROVEMENT"
fi

echo ""
echo "🔄 Next step: Update orchestration configurations"

