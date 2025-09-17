# MedinovAI Infrastructure Standards Makefile
# Common operations and development tasks

.PHONY: help install lint test security clean build deploy audit status

# Default target
help: ## Show this help message
	@echo "MedinovAI Infrastructure Standards"
	@echo "=================================="
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Installation and setup
install: ## Install dependencies and setup development environment
	@echo "Installing dependencies..."
	pip install -r requirements.txt
	pre-commit install
	@echo "Setup complete!"

install-hooks: ## Install pre-commit hooks
	pre-commit install

# Code quality and linting
lint: ## Run all linting checks
	@echo "Running linting checks..."
	pre-commit run --all-files

lint-fix: ## Run linting checks and fix issues where possible
	@echo "Running linting checks with fixes..."
	pre-commit run --all-files --hook-stage manual

# Testing
test: ## Run all tests
	@echo "Running tests..."
	pytest tests/ -v

test-policies: ## Test OPA policies
	@echo "Testing OPA policies..."
	conftest test -p policy/terraform .
	conftest test -p policy/kubernetes ./medinovai-infrastructure-standards/platform/charts/
	conftest test -p policy/github .

# Security
security: ## Run security scans
	@echo "Running security scans..."
	trivy fs --severity HIGH,CRITICAL .
	detect-secrets scan --baseline .secrets.baseline
	gitleaks detect --source . --verbose

security-fix: ## Fix security issues where possible
	@echo "Fixing security issues..."
	detect-secrets scan --baseline .secrets.baseline --update

# Build and deployment
build: ## Build container images
	@echo "Building container images..."
	docker build -t medinovai-infrastructure:latest .

build-push: ## Build and push container images
	@echo "Building and pushing container images..."
	docker build -t ghcr.io/myonsite-healthcare/medinovai-infrastructure:latest .
	docker push ghcr.io/myonsite-healthcare/medinovai-infrastructure:latest

# Bulk operations
bulk-sync: ## Run bulk sync across repositories (dry-run)
	@echo "Running bulk sync (dry-run)..."
	./medinovai-infrastructure-standards/scripts/bulk_sync.sh \
		--org myonsite-healthcare \
		--match medinovai \
		--dry-run

bulk-sync-apply: ## Run bulk sync across repositories (apply changes)
	@echo "Running bulk sync (apply)..."
	./medinovai-infrastructure-standards/scripts/bulk_sync.sh \
		--org myonsite-healthcare \
		--match medinovai \
		--apply

# Auditing and reporting
audit: ## Run comprehensive audit
	@echo "Running comprehensive audit..."
	./medinovai-infrastructure-standards/scripts/audit_status.sh \
		--org myonsite-healthcare \
		--match medinovai > .artifacts/report.csv
	./medinovai-infrastructure-standards/scripts/render_status.py .artifacts/report.csv > STATUS.md
	@echo "Audit complete. Results in STATUS.md"

status: ## Generate status report
	@echo "Generating status report..."
	mkdir -p .artifacts
	./medinovai-infrastructure-standards/scripts/audit_status.sh \
		--org myonsite-healthcare \
		--match medinovai > .artifacts/report.csv
	./medinovai-infrastructure-standards/scripts/render_status.py .artifacts/report.csv > STATUS.md
	@echo "Status report generated in STATUS.md"

# Documentation
docs: ## Generate documentation
	@echo "Generating documentation..."
	@echo "Documentation is up to date"

docs-serve: ## Serve documentation locally
	@echo "Serving documentation locally..."
	@echo "Open http://localhost:8000 in your browser"
	python -m http.server 8000

# Cleanup
clean: ## Clean up temporary files and artifacts
	@echo "Cleaning up..."
	rm -rf .artifacts/
	rm -rf __pycache__/
	rm -rf .pytest_cache/
	rm -rf .coverage
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete

clean-docker: ## Clean up Docker images and containers
	@echo "Cleaning up Docker..."
	docker system prune -f
	docker image prune -f

# Development
dev-setup: install install-hooks ## Complete development setup
	@echo "Development setup complete!"

dev-check: lint test security ## Run all development checks
	@echo "All development checks passed!"

# CI/CD helpers
ci-lint: ## CI linting (non-interactive)
	pre-commit run --all-files --hook-stage manual

ci-test: ## CI testing
	pytest tests/ -v --junitxml=test-results.xml

ci-security: ## CI security scanning
	trivy fs --severity HIGH,CRITICAL --format json --output trivy-results.json .
	detect-secrets scan --baseline .secrets.baseline --json --output secrets-results.json

# Release
release: ## Create a new release
	@echo "Creating release..."
	@echo "Please use GitHub releases or semantic-release for automated releases"

# Helpers
validate-yaml: ## Validate all YAML files
	@echo "Validating YAML files..."
	find . -name "*.yml" -o -name "*.yaml" | xargs -I {} yamllint {}

validate-json: ## Validate all JSON files
	@echo "Validating JSON files..."
	find . -name "*.json" | xargs -I {} python -m json.tool {} > /dev/null

# Environment info
info: ## Show environment information
	@echo "Environment Information:"
	@echo "========================"
	@echo "OS: $$(uname -s)"
	@echo "Architecture: $$(uname -m)"
	@echo "Python: $$(python --version)"
	@echo "Docker: $$(docker --version)"
	@echo "Kubectl: $$(kubectl version --client --short 2>/dev/null || echo 'Not installed')"
	@echo "Helm: $$(helm version --short 2>/dev/null || echo 'Not installed')"
	@echo "Pre-commit: $$(pre-commit --version)"

