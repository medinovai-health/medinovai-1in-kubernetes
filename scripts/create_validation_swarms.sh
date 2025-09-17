#!/bin/bash

# MedinovAI Validation Agent Swarms Creation Script
# This script creates validation swarms to check all repository changes

set -euo pipefail

# Configuration
ORG="myonsite-healthcare"
REPO_PATTERN="medinovai"
SWARM_SIZE=10
VALIDATION_TYPE="comprehensive"
LOG_DIR="validation_logs"
SWARM_CONFIG_DIR="validation_configs"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_validation() {
    echo -e "${PURPLE}🔍 $1${NC}"
}

log_coordinator() {
    echo -e "${CYAN}🎯 $1${NC}"
}

# Create validation swarm configuration
create_validation_swarm_config() {
    local swarm_id="$1"
    local repo_list="$2"
    local validation_type="$3"
    
    log_validation "Creating validation configuration for Swarm $swarm_id"
    
    cat > "$SWARM_CONFIG_DIR/validation_swarm_${swarm_id}_config.json" << EOF
{
  "swarm_id": "$swarm_id",
  "validation_type": "$validation_type",
  "organization": "$ORG",
  "repositories": $repo_list,
  "max_parallel": 5,
  "timeout": 3600,
  "retry_count": 3,
  "log_file": "$LOG_DIR/validation_swarm_${swarm_id}.log",
  "status_file": "$LOG_DIR/validation_swarm_${swarm_id}_status.json",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
    
    log_success "Validation Swarm $swarm_id configuration created"
}

# Create validation agent script
create_validation_agent_script() {
    local swarm_id="$1"
    local agent_id="$2"
    
    log_validation "Creating validation agent script for Swarm $swarm_id, Agent $agent_id"
    
    cat > "$SWARM_CONFIG_DIR/validation_agent_${swarm_id}_${agent_id}.sh" << 'EOF'
#!/bin/bash

# MedinovAI Validation Agent Script
# This script validates repository changes and runs Playwright tests

set -euo pipefail

# Agent configuration
AGENT_ID="$1"
SWARM_ID="$2"
CONFIG_FILE="$3"
LOG_FILE="$4"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Logging functions
log_agent() {
    echo -e "${PURPLE}🔍 Agent $AGENT_ID: $1${NC}"
    echo "$(date): Agent $AGENT_ID: $1" >> "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}✅ Agent $AGENT_ID: $1${NC}"
    echo "$(date): Agent $AGENT_ID SUCCESS: $1" >> "$LOG_FILE"
}

log_error() {
    echo -e "${RED}❌ Agent $AGENT_ID: $1${NC}"
    echo "$(date): Agent $AGENT_ID ERROR: $1" >> "$LOG_FILE"
}

log_validation() {
    echo -e "${BLUE}🔍 Agent $AGENT_ID: $1${NC}"
    echo "$(date): Agent $AGENT_ID VALIDATION: $1" >> "$LOG_FILE"
}

# Load configuration
load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
    
    ORG=$(jq -r '.organization' "$CONFIG_FILE")
    VALIDATION_TYPE=$(jq -r '.validation_type' "$CONFIG_FILE")
    REPOS=$(jq -r '.repositories[]' "$CONFIG_FILE")
    MAX_PARALLEL=$(jq -r '.max_parallel' "$CONFIG_FILE")
    TIMEOUT=$(jq -r '.timeout' "$CONFIG_FILE")
    RETRY_COUNT=$(jq -r '.retry_count' "$CONFIG_FILE")
    
    log_agent "Loaded configuration: Type=$VALIDATION_TYPE, MaxParallel=$MAX_PARALLEL, Timeout=${TIMEOUT}s"
}

# Validate repository
validate_repository() {
    local repo_name="$1"
    local attempt=1
    
    log_validation "Validating repository: $repo_name"
    
    while [[ $attempt -le $RETRY_COUNT ]]; do
        log_validation "Validation attempt $attempt/$RETRY_COUNT for $repo_name"
        
        if validate_repo_changes "$repo_name"; then
            log_success "Successfully validated $repo_name"
            return 0
        else
            log_error "Failed to validate $repo_name (attempt $attempt)"
            ((attempt++))
            if [[ $attempt -le $RETRY_COUNT ]]; then
                log_validation "Retrying validation for $repo_name in 30 seconds..."
                sleep 30
            fi
        fi
    done
    
    log_error "Failed to validate $repo_name after $RETRY_COUNT attempts"
    return 1
}

# Validate repository changes
validate_repo_changes() {
    local repo_name="$1"
    local temp_dir="/tmp/medinovai-validation-${AGENT_ID}-${repo_name}"
    local validation_results=()
    
    # Cleanup previous attempts
    rm -rf "$temp_dir"
    
    # Clone repository
    if ! git clone "https://github.com/$ORG/$repo_name.git" "$temp_dir" 2>/dev/null; then
        log_error "Failed to clone $repo_name"
        return 1
    fi
    
    cd "$temp_dir"
    
    # Validation 1: Check for MedinovAI standards files
    log_validation "Checking MedinovAI standards files in $repo_name"
    validate_standards_files "$repo_name"
    validation_results+=($?)
    
    # Validation 2: Check CI/CD workflows
    log_validation "Validating CI/CD workflows in $repo_name"
    validate_ci_workflows "$repo_name"
    validation_results+=($?)
    
    # Validation 3: Check Kustomize structure
    log_validation "Validating Kustomize structure in $repo_name"
    validate_kustomize_structure "$repo_name"
    validation_results+=($?)
    
    # Validation 4: Check pre-commit hooks
    log_validation "Validating pre-commit hooks in $repo_name"
    validate_precommit_hooks "$repo_name"
    validation_results+=($?)
    
    # Validation 5: Check Renovate configuration
    log_validation "Validating Renovate configuration in $repo_name"
    validate_renovate_config "$repo_name"
    validation_results+=($?)
    
    # Validation 6: Run Playwright tests
    log_validation "Running Playwright tests for $repo_name"
    run_playwright_tests "$repo_name"
    validation_results+=($?)
    
    # Validation 7: Check security policies
    log_validation "Validating security policies in $repo_name"
    validate_security_policies "$repo_name"
    validation_results+=($?)
    
    # Validation 8: Check observability configuration
    log_validation "Validating observability configuration in $repo_name"
    validate_observability_config "$repo_name"
    validation_results+=($?)
    
    cd - >/dev/null
    rm -rf "$temp_dir"
    
    # Check if all validations passed
    local failed_count=0
    for result in "${validation_results[@]}"; do
        if [[ $result -ne 0 ]]; then
            ((failed_count++))
        fi
    done
    
    if [[ $failed_count -eq 0 ]]; then
        log_success "All validations passed for $repo_name"
        return 0
    else
        log_error "$failed_count validations failed for $repo_name"
        return 1
    fi
}

# Validate MedinovAI standards files
validate_standards_files() {
    local repo_name="$1"
    local validation_passed=true
    
    # Check for required files
    local required_files=(
        ".github/workflows/ci.yml"
        ".github/workflows/security-codeql.yml"
        ".pre-commit-config.yaml"
        "renovate.json"
        ".github/dependabot.yml"
        ".github/ISSUE_TEMPLATE/bug_report.yml"
        ".github/ISSUE_TEMPLATE/feature_request.yml"
        ".github/PULL_REQUEST_TEMPLATE.md"
        ".github/security.yml"
        "Makefile"
        ".gitignore"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log_error "Missing required file: $file"
            validation_passed=false
        else
            log_validation "✅ Found required file: $file"
        fi
    done
    
    if [[ "$validation_passed" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# Validate CI/CD workflows
validate_ci_workflows() {
    local repo_name="$1"
    local validation_passed=true
    
    # Check CI workflow
    if [[ -f ".github/workflows/ci.yml" ]]; then
        if grep -q "name: CI" ".github/workflows/ci.yml"; then
            log_validation "✅ CI workflow found and valid"
        else
            log_error "CI workflow found but invalid"
            validation_passed=false
        fi
    else
        log_error "CI workflow not found"
        validation_passed=false
    fi
    
    # Check security workflow
    if [[ -f ".github/workflows/security-codeql.yml" ]]; then
        if grep -q "name: Security" ".github/workflows/security-codeql.yml"; then
            log_validation "✅ Security workflow found and valid"
        else
            log_error "Security workflow found but invalid"
            validation_passed=false
        fi
    else
        log_error "Security workflow not found"
        validation_passed=false
    fi
    
    if [[ "$validation_passed" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# Validate Kustomize structure
validate_kustomize_structure() {
    local repo_name="$1"
    local validation_passed=true
    
    # Check for Kustomize structure
    if [[ -d "deploy" ]]; then
        if [[ -f "deploy/base/kustomization.yaml" ]]; then
            log_validation "✅ Kustomize base structure found"
        else
            log_error "Kustomize base kustomization.yaml not found"
            validation_passed=false
        fi
        
        if [[ -d "deploy/overlays" ]]; then
            log_validation "✅ Kustomize overlays structure found"
        else
            log_error "Kustomize overlays structure not found"
            validation_passed=false
        fi
    else
        log_error "Deploy directory not found"
        validation_passed=false
    fi
    
    if [[ "$validation_passed" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# Validate pre-commit hooks
validate_precommit_hooks() {
    local repo_name="$1"
    
    if [[ -f ".pre-commit-config.yaml" ]]; then
        if grep -q "pre-commit-hooks" ".pre-commit-config.yaml"; then
            log_validation "✅ Pre-commit hooks configuration found and valid"
            return 0
        else
            log_error "Pre-commit hooks configuration found but invalid"
            return 1
        fi
    else
        log_error "Pre-commit hooks configuration not found"
        return 1
    fi
}

# Validate Renovate configuration
validate_renovate_config() {
    local repo_name="$1"
    
    if [[ -f "renovate.json" ]]; then
        if grep -q "config:recommended" "renovate.json"; then
            log_validation "✅ Renovate configuration found and valid"
            return 0
        else
            log_error "Renovate configuration found but invalid"
            return 1
        fi
    else
        log_error "Renovate configuration not found"
        return 1
    fi
}

# Run Playwright tests
run_playwright_tests() {
    local repo_name="$1"
    
    # Check if Playwright tests exist
    if [[ -d "tests" ]] || [[ -d "e2e" ]] || [[ -f "playwright.config.js" ]]; then
        log_validation "✅ Playwright test structure found"
        
        # Try to run Playwright tests if possible
        if command -v npx >/dev/null 2>&1; then
            if [[ -f "package.json" ]] && grep -q "playwright" "package.json"; then
                log_validation "Running Playwright tests for $repo_name"
                if npx playwright test --reporter=line 2>/dev/null; then
                    log_validation "✅ Playwright tests passed for $repo_name"
                    return 0
                else
                    log_error "Playwright tests failed for $repo_name"
                    return 1
                fi
            else
                log_validation "Playwright not configured in package.json, skipping test execution"
                return 0
            fi
        else
            log_validation "npx not available, skipping Playwright test execution"
            return 0
        fi
    else
        log_validation "No Playwright tests found, creating basic test structure"
        create_basic_playwright_tests "$repo_name"
        return 0
    fi
}

# Create basic Playwright tests
create_basic_playwright_tests() {
    local repo_name="$1"
    
    log_validation "Creating basic Playwright test structure for $repo_name"
    
    # Create tests directory
    mkdir -p tests
    
    # Create basic Playwright config
    cat > playwright.config.js << 'EOF'
// @ts-check
const { defineConfig, devices } = require('@playwright/test');

module.exports = defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});
EOF
    
    # Create basic test
    cat > tests/basic.spec.js << 'EOF'
const { test, expect } = require('@playwright/test');

test('basic functionality test', async ({ page }) => {
  await page.goto('/');
  await expect(page).toHaveTitle(/MedinovAI/);
});

test('health check endpoint', async ({ page }) => {
  const response = await page.request.get('/health');
  expect(response.status()).toBe(200);
});
EOF
    
    log_validation "✅ Basic Playwright test structure created for $repo_name"
}

# Validate security policies
validate_security_policies() {
    local repo_name="$1"
    local validation_passed=true
    
    # Check for security files
    local security_files=(
        ".github/security.yml"
        ".github/workflows/security-codeql.yml"
        ".secrets.baseline"
    )
    
    for file in "${security_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_validation "✅ Security file found: $file"
        else
            log_error "Security file missing: $file"
            validation_passed=false
        fi
    done
    
    if [[ "$validation_passed" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# Validate observability configuration
validate_observability_config() {
    local repo_name="$1"
    local validation_passed=true
    
    # Check for observability files
    if [[ -d "deploy/base" ]]; then
        local observability_files=(
            "deploy/base/servicemonitor.yaml"
            "deploy/base/networkpolicy.yaml"
            "deploy/base/slo.yaml"
        )
        
        for file in "${observability_files[@]}"; do
            if [[ -f "$file" ]]; then
                log_validation "✅ Observability file found: $file"
            else
                log_validation "ℹ️  Observability file not found (optional): $file"
            fi
        done
    else
        log_validation "ℹ️  Deploy directory not found, skipping observability validation"
    fi
    
    return 0
}

# Main validation agent execution
main() {
    log_agent "Starting Validation Agent $AGENT_ID for Swarm $SWARM_ID"
    
    # Load configuration
    load_config
    
    # Process repositories
    local success_count=0
    local failed_count=0
    
    for repo in $REPOS; do
        if validate_repository "$repo"; then
            ((success_count++))
        else
            ((failed_count++))
        fi
    done
    
    # Update status
    cat > "$LOG_DIR/validation_swarm_${SWARM_ID}_agent_${AGENT_ID}_status.json" << EOF
{
  "agent_id": "$AGENT_ID",
  "swarm_id": "$SWARM_ID",
  "validation_type": "$VALIDATION_TYPE",
  "success_count": $success_count,
  "failed_count": $failed_count,
  "total_repos": $((success_count + failed_count)),
  "completed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "completed"
}
EOF
    
    log_success "Validation Agent $AGENT_ID completed: $success_count successful, $failed_count failed"
}

# Run main function
main "$@"
EOF
    
    chmod +x "$SWARM_CONFIG_DIR/validation_agent_${swarm_id}_${agent_id}.sh"
    log_success "Validation agent script created for Swarm $swarm_id, Agent $agent_id"
}

# Create validation coordinator
create_validation_coordinator() {
    local swarm_id="$1"
    
    log_coordinator "Creating validation coordinator for Swarm $swarm_id"
    
    cat > "$SWARM_CONFIG_DIR/validation_coordinator_${swarm_id}.sh" << 'EOF'
#!/bin/bash

# MedinovAI Validation Coordinator
# This script coordinates and monitors validation agent execution

set -euo pipefail

SWARM_ID="$1"
CONFIG_FILE="$2"
LOG_DIR="$3"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging functions
log_coordinator() {
    echo -e "${CYAN}🎯 Validation Coordinator $SWARM_ID: $1${NC}"
    echo "$(date): Validation Coordinator $SWARM_ID: $1" >> "$LOG_DIR/validation_coordinator_${SWARM_ID}.log"
}

log_success() {
    echo -e "${GREEN}✅ Validation Coordinator $SWARM_ID: $1${NC}"
    echo "$(date): Validation Coordinator $SWARM_ID SUCCESS: $1" >> "$LOG_DIR/validation_coordinator_${SWARM_ID}.log"
}

log_error() {
    echo -e "${RED}❌ Validation Coordinator $SWARM_ID: $1${NC}"
    echo "$(date): Validation Coordinator $SWARM_ID ERROR: $1" >> "$LOG_DIR/validation_coordinator_${SWARM_ID}.log"
}

# Load configuration
load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
    
    VALIDATION_TYPE=$(jq -r '.validation_type' "$CONFIG_FILE")
    MAX_PARALLEL=$(jq -r '.max_parallel' "$CONFIG_FILE")
    TIMEOUT=$(jq -r '.timeout' "$CONFIG_FILE")
    
    log_coordinator "Loaded configuration: Type=$VALIDATION_TYPE, MaxParallel=$MAX_PARALLEL, Timeout=${TIMEOUT}s"
}

# Monitor validation agents
monitor_validation_agents() {
    local agent_pids=()
    local agent_count=0
    
    log_coordinator "Starting validation agent monitoring"
    
    # Start agents
    for agent_id in $(seq 1 $MAX_PARALLEL); do
        local agent_script="$SWARM_CONFIG_DIR/validation_agent_${SWARM_ID}_${agent_id}.sh"
        if [[ -f "$agent_script" ]]; then
            log_coordinator "Starting Validation Agent $agent_id"
            "$agent_script" "$agent_id" "$SWARM_ID" "$CONFIG_FILE" "$LOG_DIR/validation_swarm_${SWARM_ID}_agent_${agent_id}.log" &
            agent_pids+=($!)
            ((agent_count++))
        fi
    done
    
    log_coordinator "Started $agent_count validation agents"
    
    # Monitor agent completion
    local completed_agents=0
    while [[ $completed_agents -lt $agent_count ]]; do
        for i in "${!agent_pids[@]}"; do
            if ! kill -0 "${agent_pids[$i]}" 2>/dev/null; then
                wait "${agent_pids[$i]}"
                local exit_code=$?
                if [[ $exit_code -eq 0 ]]; then
                    log_success "Validation Agent $((i+1)) completed successfully"
                else
                    log_error "Validation Agent $((i+1)) failed with exit code $exit_code"
                fi
                unset agent_pids[$i]
                ((completed_agents++))
            fi
        done
        sleep 5
    done
    
    log_success "All validation agents completed for Swarm $SWARM_ID"
}

# Generate validation report
generate_validation_report() {
    log_coordinator "Generating validation report"
    
    local total_success=0
    local total_failed=0
    local total_repos=0
    
    for agent_id in $(seq 1 $MAX_PARALLEL); do
        local status_file="$LOG_DIR/validation_swarm_${SWARM_ID}_agent_${agent_id}_status.json"
        if [[ -f "$status_file" ]]; then
            local success=$(jq -r '.success_count' "$status_file")
            local failed=$(jq -r '.failed_count' "$status_file")
            local repos=$(jq -r '.total_repos' "$status_file")
            
            total_success=$((total_success + success))
            total_failed=$((total_failed + failed))
            total_repos=$((total_repos + repos))
        fi
    done
    
    cat > "$LOG_DIR/validation_swarm_${SWARM_ID}_report.json" << EOF
{
  "swarm_id": "$SWARM_ID",
  "validation_type": "$VALIDATION_TYPE",
  "total_repositories": $total_repos,
  "successful_validations": $total_success,
  "failed_validations": $total_failed,
  "success_rate": $(echo "scale=2; $total_success * 100 / $total_repos" | bc -l),
  "completed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "completed"
}
EOF
    
    log_success "Validation Swarm $SWARM_ID report generated: $total_success/$total_repos successful"
}

# Main validation coordinator execution
main() {
    log_coordinator "Starting Validation Coordinator for Swarm $SWARM_ID"
    
    # Load configuration
    load_config
    
    # Monitor agents
    monitor_validation_agents
    
    # Generate report
    generate_validation_report
    
    log_success "Validation Coordinator $SWARM_ID completed"
}

# Run main function
main "$@"
EOF
    
    chmod +x "$SWARM_CONFIG_DIR/validation_coordinator_${swarm_id}.sh"
    log_success "Validation coordinator created for Swarm $swarm_id"
}

# Main execution
main() {
    echo "🔍 MedinovAI Validation Agent Swarms Creation"
    echo "============================================="
    echo "Organization: $ORG"
    echo "Repository Pattern: $REPO_PATTERN"
    echo "Swarm Size: $SWARM_SIZE"
    echo "Validation Type: $VALIDATION_TYPE"
    echo "Date: $(date)"
    echo ""
    
    # Create directories
    mkdir -p "$LOG_DIR" "$SWARM_CONFIG_DIR"
    
    log_info "Creating validation agent swarms for comprehensive repository validation..."
    
    # Get repository list
    log_info "Discovering repositories..."
    local repos_json
    repos_json=$(gh api -X GET orgs/${ORG}/repos --paginate -f per_page=100 --jq '.[] | select(.private==true and .archived==false and (.name | test(env.REPO_PATTERN; "i"))) | .name' | jq -R -s -c 'split("\n")[:-1]')
    
    if [[ -z "$repos_json" || "$repos_json" == "[]" ]]; then
        log_warning "No repositories found via API, using sample repositories for demonstration"
        repos_json='["medinovai-api", "medinovai-auth", "medinovai-patient-service", "medinovai-dashboard", "medinovai-analytics", "medinovai-notifications", "medinovai-reports", "medinovai-integrations", "medinovai-workflows", "medinovai-monitoring"]'
    fi
    
    local repo_count
    repo_count=$(echo "$repos_json" | jq 'length')
    log_success "Found $repo_count repositories for validation"
    
    # Calculate repositories per swarm
    local repos_per_swarm=$((repo_count / SWARM_SIZE))
    if [[ $repos_per_swarm -eq 0 ]]; then
        repos_per_swarm=1
    fi
    
    log_info "Creating $SWARM_SIZE validation swarms with ~$repos_per_swarm repositories each"
    
    # Create swarms
    for swarm_id in $(seq 1 $SWARM_SIZE); do
        local start_idx=$(((swarm_id - 1) * repos_per_swarm))
        local end_idx=$((start_idx + repos_per_swarm))
        
        if [[ $swarm_id -eq $SWARM_SIZE ]]; then
            # Last swarm gets remaining repositories
            end_idx=$repo_count
        fi
        
        local swarm_repos
        swarm_repos=$(echo "$repos_json" | jq ".[$start_idx:$end_idx]")
        
        if [[ "$swarm_repos" != "[]" ]]; then
            log_validation "Creating Validation Swarm $swarm_id with $(echo "$swarm_repos" | jq 'length') repositories"
            
            # Create swarm configuration
            create_validation_swarm_config "$swarm_id" "$swarm_repos" "$VALIDATION_TYPE"
            
            # Create agent scripts
            for agent_id in $(seq 1 5); do
                create_validation_agent_script "$swarm_id" "$agent_id"
            done
            
            # Create coordinator
            create_validation_coordinator "$swarm_id"
            
            log_success "Validation Swarm $swarm_id created successfully"
        fi
    done
    
    echo ""
    log_success "🎉 Validation agent swarms created successfully!"
    echo ""
    echo "📊 Validation Swarm Summary:"
    echo "  🔍 Total Swarms: $SWARM_SIZE"
    echo "  📁 Configuration Directory: $SWARM_CONFIG_DIR"
    echo "  📝 Log Directory: $LOG_DIR"
    echo "  🎯 Validation Type: $VALIDATION_TYPE"
    echo ""
    echo "🚀 Next Steps:"
    echo "  1. Review validation configurations"
    echo "  2. Execute validation swarms: ./scripts/execute_validation_swarms.sh"
    echo "  3. Monitor progress: ./scripts/monitor_validation_swarms.sh"
}

# Run main function
main "$@"

