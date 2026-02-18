# ─── MedinovAI Deploy — Makefile ─────────────────────────────────────────────
# Autonomous deployment, instantiation, CI/CD, and monitoring for MedinovAI.
#
# ONE-SHOT INSTALL (new machine):
#   make up                        # install everything from zero
#   make up PRIMARY=true           # this machine hosts the shared DB
#   make up DB_HOST=100.x.x.x     # secondary machine pointing at primary
#
# Teardown:
#   make down                      # stop everything (data preserved)
#   make nuke                      # wipe and rebuild from scratch
# ─────────────────────────────────────────────────────────────────────────────

.PHONY: up down nuke
.PHONY: help setup prerequisites install deploy validate health status logs clean
.PHONY: plan apply drift-check deploy-service deploy-all rollback promote-canary
.PHONY: docker-instantiate docker-backup docker-restore docker-seed docker-up docker-down
.PHONY: rotate-secrets cert-check backup-verify cost-report validate-infra validate-k8s validate-compliance
.PHONY: test-unit test-integration test-e2e lint-json lint-yaml
.PHONY: addons-install addons-uninstall addons-ingress addons-dashboard addons-monitoring addons-argocd
.PHONY: dashboard-forward argocd-forward cluster-status k8s-status-full

ENV ?= staging
SVC ?=
CLOUD ?= aws
REGION ?= us-east-1

# ─── ONE-SHOT INSTALL ────────────────────────────────────────────────────────
# These are the only 3 commands you ever need.

up: ## ONE COMMAND: Install everything from zero (docker + k8s + addons)
	@ARGS=""; \
	[ "$(PRIMARY)" = "true" ] && ARGS="$$ARGS --primary"; \
	[ -n "$(DB_HOST)" ] && ARGS="$$ARGS --db-host $(DB_HOST)"; \
	bash scripts/bootstrap/bootstrap-all.sh $$ARGS

down: ## Stop everything gracefully (data preserved in volumes)
	@echo "Stopping cluster addons..."
	bash scripts/bootstrap/install-addons.sh --uninstall 2>/dev/null || true
	@echo "Stopping K8s services..."
	bash scripts/bootstrap/uninstall-k8s.sh 2>/dev/null || true
	@echo "Stopping Docker infra..."
	docker compose -f infra/docker/docker-compose.dev.yml stop 2>/dev/null || true
	@echo "Done. Data preserved. Run 'make up' to restart."

nuke: ## Wipe everything and rebuild from scratch (DESTROYS ALL DATA)
	@echo "WARNING: This will destroy all local data. Press Ctrl-C to cancel..."
	@sleep 5
	bash scripts/bootstrap/install-addons.sh --uninstall 2>/dev/null || true
	bash scripts/bootstrap/uninstall-k8s.sh 2>/dev/null || true
	bash scripts/seed.sh --reset 2>/dev/null || true
	make up

# ─── Help ────────────────────────────────────────────────────────────────────

help: ## Show this help message
	@echo ""
	@echo "MedinovAI Deploy — Available Commands"
	@echo "=========================================="
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-24s\033[0m %s\n", $$1, $$2}'
	@echo ""

# ─── Setup & Installation ────────────────────────────────────────────────────

prerequisites: ## Check all required tools are installed
	bash scripts/bootstrap/prerequisites.sh

install: ## Install Atlas globally (requires Node.js 22+)
	bash scripts/bootstrap/install_atlas.sh

deploy-config: ## Deploy gateway config + agent workspaces to ~/.atlas/
	bash scripts/deploy/deploy_config.sh

agents: ## Register all deploy agents with Atlas
	bash scripts/agents/create_agents.sh

crons: ## Register all monitoring cron jobs
	bash scripts/agents/register_crons.sh

setup: prerequisites install deploy-config validate ## Full setup: prerequisites + install + deploy + validate
	@echo ""
	@echo "Setup complete! Next steps:"
	@echo "  1. Edit ~/.atlas/.env with real tokens"
	@echo "  2. Update channel IDs in ~/.atlas/atlas.json"
	@echo "  3. Run: make start"

# ─── Greenfield Instantiation ────────────────────────────────────────────────

instantiate: ## Full greenfield instantiation (zero to running platform)
	bash scripts/bootstrap/instantiate.sh \
		--cloud $(CLOUD) \
		--region $(REGION) \
		--environment $(ENV)

init-cloud: ## Initialize cloud account (state bucket, IAM bootstrap)
	bash scripts/bootstrap/init-cloud-account.sh \
		--cloud $(CLOUD) \
		--region $(REGION)

# ─── Docker Local Deployment ───────────────────────────────────────────────────

COMPOSE_FILE ?= infra/docker/docker-compose.dev.yml

docker-instantiate: ## Full Docker greenfield instantiation (local machine)
	bash scripts/bootstrap/instantiate-docker.sh

docker-backup: ## Backup DB + volumes to ~/medinovai-backups/medinovai-Deploy/
	bash scripts/backup.sh

docker-restore: ## Restore from latest backup
	bash scripts/restore.sh --from-latest

docker-seed: ## Seed fresh environment (scripts/seed.sh)
	bash scripts/seed.sh

docker-up: ## Start Docker stack
	docker compose -f $(COMPOSE_FILE) up -d

docker-down: ## Stop Docker stack (preserves volumes)
	docker compose -f $(COMPOSE_FILE) down

k8s-install: ## Clean K8s install on Docker Desktop (Tailscale-aware)
	bash scripts/bootstrap/install-k8s.sh --context docker-desktop

k8s-install-primary: ## Install as Tailscale primary (hosts postgres/redis)
	bash scripts/bootstrap/install-k8s.sh --context docker-desktop --primary

k8s-uninstall: ## Remove all MedinovAI K8s resources (preserves Docker Compose infra)
	bash scripts/bootstrap/uninstall-k8s.sh --context docker-desktop

k8s-reinstall: ## Full clean reinstall (uninstall + install)
	bash scripts/bootstrap/uninstall-k8s.sh --context docker-desktop && bash scripts/bootstrap/install-k8s.sh --context docker-desktop

k8s-status: ## Show all pod and service status across namespaces
	kubectl get pods -n medinovai-services -o wide && kubectl get pods -n medinovai-ai -o wide

tailscale-config: ## Configure Tailscale networking (run before install)
	bash scripts/bootstrap/tailscale-config.sh

k8s-status-full: ## Show all pods, services, and ingresses across every namespace
	@echo "=== PODS ==="
	@kubectl get pods -A
	@echo ""
	@echo "=== SERVICES ==="
	@kubectl get svc -A | grep -v kube-system
	@echo ""
	@echo "=== INGRESSES ==="
	@kubectl get ingress -A 2>/dev/null || echo "(none)"

# ─── Cluster Addons (local, no cloud accounts) ───────────────────────────────

addons-install: ## Install all cluster addons (ingress, dashboard, kube-state-metrics, argocd)
	bash scripts/bootstrap/install-addons.sh

addons-ingress: ## Install NGINX Ingress Controller only
	bash scripts/bootstrap/install-addons.sh --ingress

addons-dashboard: ## Install Kubernetes Dashboard only
	bash scripts/bootstrap/install-addons.sh --dashboard

addons-monitoring: ## Install kube-state-metrics only
	bash scripts/bootstrap/install-addons.sh --monitoring

addons-argocd: ## Install ArgoCD only
	bash scripts/bootstrap/install-addons.sh --argocd

addons-uninstall: ## Remove all cluster addons
	bash scripts/bootstrap/install-addons.sh --uninstall

dashboard-forward: ## Port-forward Kubernetes Dashboard to localhost:8443 (background)
	@echo "Opening Kubernetes Dashboard at https://localhost:8443"
	@echo "Token: $$(cat .dashboard-token 2>/dev/null || kubectl -n kubernetes-dashboard get secret medinovai-dashboard-admin-token -o jsonpath='{.data.token}' | base64 --decode)"
	kubectl port-forward -n kubernetes-dashboard svc/kubernetes-dashboard 8443:443 &

argocd-forward: ## Port-forward ArgoCD to localhost:8080 (background)
	@echo "Opening ArgoCD at http://localhost:8080"
	@echo "Password: $$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 --decode)"
	kubectl port-forward svc/argocd-server -n argocd 8080:80 &

cluster-status: ## Full cluster health check — all namespaces, addons, ingresses
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "CLUSTER STATUS — $$(date)"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "[ MedinovAI Services ]"
	@kubectl get pods -n medinovai-services -o wide 2>/dev/null || echo "namespace not found"
	@echo ""
	@echo "[ MedinovAI AI ]"
	@kubectl get pods -n medinovai-ai -o wide 2>/dev/null || echo "namespace not found"
	@echo ""
	@echo "[ Addons ]"
	@kubectl get pods -n ingress-nginx 2>/dev/null | tail -n +1 || echo "(ingress-nginx: not installed)"
	@kubectl get pods -n kubernetes-dashboard 2>/dev/null | tail -n +1 || echo "(kubernetes-dashboard: not installed)"
	@kubectl get pods -n medinovai-monitoring 2>/dev/null | tail -n +1 || echo "(monitoring: not installed)"
	@kubectl get pods -n argocd 2>/dev/null | tail -n +1 || echo "(argocd: not installed)"
	@echo ""
	@echo "[ Ingresses ]"
	@kubectl get ingress -A 2>/dev/null || echo "(none)"
	@echo ""
	@echo "[ NodePorts ]"
	@kubectl get svc -A --field-selector spec.type=NodePort 2>/dev/null

# ─── Infrastructure (Terraform) ──────────────────────────────────────────────

plan: ## Terraform plan for target environment
	cd infra/terraform/environments/$(ENV) && \
		terraform init -upgrade && \
		terraform plan -out=tfplan

apply: ## Terraform apply for target environment (requires approval)
	cd infra/terraform/environments/$(ENV) && \
		terraform apply tfplan

drift-check: ## Check for IaC drift across all environments
	bash scripts/maintenance/drift_check.sh

# ─── Service Deployment ──────────────────────────────────────────────────────

deploy-service: ## Deploy a single service (SVC=name ENV=target)
ifndef SVC
	$(error SVC is required. Usage: make deploy-service SVC=api-gateway ENV=staging)
endif
	bash scripts/deploy/deploy_service.sh --service $(SVC) --environment $(ENV)

deploy-all: ## Deploy all services in dependency order
	bash scripts/deploy/deploy_all.sh --environment $(ENV)

rollback: ## Rollback a service to previous version
ifndef SVC
	$(error SVC is required. Usage: make rollback SVC=api-gateway ENV=staging)
endif
	bash scripts/deploy/rollback_service.sh --service $(SVC) --environment $(ENV)

promote-canary: ## Promote canary deployment to full rollout
ifndef SVC
	$(error SVC is required. Usage: make promote-canary SVC=api-gateway ENV=production)
endif
	bash scripts/deploy/promote_canary.sh --service $(SVC) --environment $(ENV)

# ─── Gateway Operations ──────────────────────────────────────────────────────

start: ## Start the Atlas gateway
	atlas gateway --port 18789

stop: ## Stop the Atlas gateway
	@echo "Sending stop signal to gateway..."
	@pkill -f "atlas gateway" 2>/dev/null && echo "Gateway stopped." || echo "Gateway not running."

status: ## Check Atlas gateway status
	atlas status --all

logs: ## Follow Atlas deploy logs
	atlas logs --follow

# ─── Monitoring & Health ─────────────────────────────────────────────────────

health: ## Full-stack health audit
	bash scripts/monitoring/health_check_all.sh

setup-monitoring: ## Deploy monitoring stack (Prometheus, Grafana, Alertmanager, Loki)
	bash scripts/monitoring/setup_monitoring.sh --environment $(ENV)

setup-alerting: ## Configure alert rules and routing
	bash scripts/monitoring/setup_alerting.sh --environment $(ENV)

# ─── Maintenance ─────────────────────────────────────────────────────────────

rotate-secrets: ## Rotate expiring secrets
	bash scripts/maintenance/rotate_secrets.sh

cert-check: ## Check certificate expiry status
	bash scripts/maintenance/cert_renewal.sh --check-only

cert-renew: ## Renew expiring certificates
	bash scripts/maintenance/cert_renewal.sh --renew

backup: ## Run database backup
	bash scripts/maintenance/db_backup.sh --environment $(ENV)

backup-verify: ## Verify backup integrity
	bash scripts/maintenance/db_backup.sh --verify --environment $(ENV)

restore: ## Restore database from backup (DANGEROUS — requires confirmation)
	bash scripts/maintenance/db_restore.sh --environment $(ENV)

cost-report: ## Generate cloud cost report
	bash scripts/maintenance/cost_report.sh

cleanup: ## Clean orphaned cloud resources
	bash scripts/maintenance/cleanup_resources.sh --environment $(ENV) --dry-run

# ─── Validation & Testing ────────────────────────────────────────────────────

validate: ## Full validation suite (configs, infra, manifests, compliance)
	bash scripts/validation/validate_setup.sh

validate-infra: ## Validate Terraform configurations
	bash scripts/validation/validate_infra.sh

validate-k8s: ## Validate Kubernetes manifests
	bash scripts/validation/validate_manifests.sh

validate-secrets: ## Scan for exposed secrets
	bash scripts/validation/validate_secrets.sh

validate-compliance: ## Check GOV-01 through GOV-10 compliance
	bash scripts/validation/validate_compliance.sh

smoke-test: ## Run post-deploy smoke tests
	bash scripts/validation/smoke_test.sh --environment $(ENV)

test-unit: ## Run unit tests
	cd tests && python3 -m pytest unit/ -v

test-integration: ## Run integration tests
	cd tests && bash integration/test_deploy_pipeline.sh

test-e2e: ## Run end-to-end tests
	cd tests && bash e2e/test_greenfield_instantiation.sh --dry-run

lint-json: ## Validate all JSON/JSON5 config files
	@echo "Checking JSON files..."
	@PASS=0; FAIL=0; \
	for f in $$(find config agents services -name '*.json' -o -name '*.json5' 2>/dev/null); do \
		if python3 -c "import json; json.load(open('$$f'))" 2>/dev/null; then \
			echo "  ✓ $$f"; \
			PASS=$$((PASS + 1)); \
		else \
			echo "  ✗ $$f — INVALID"; \
			FAIL=$$((FAIL + 1)); \
		fi; \
	done; \
	echo "Results: $$PASS valid, $$FAIL invalid"; \
	[ "$$FAIL" -eq 0 ] || exit 1

lint-yaml: ## Validate all YAML files
	@echo "Checking YAML files..."
	@PASS=0; FAIL=0; \
	for f in $$(find infra -name '*.yaml' -o -name '*.yml' 2>/dev/null); do \
		if python3 -c "import yaml; yaml.safe_load(open('$$f'))" 2>/dev/null; then \
			echo "  ✓ $$f"; \
			PASS=$$((PASS + 1)); \
		else \
			echo "  ✗ $$f — INVALID"; \
			FAIL=$$((FAIL + 1)); \
		fi; \
	done; \
	echo "Results: $$PASS valid, $$FAIL invalid"; \
	[ "$$FAIL" -eq 0 ] || exit 1

test-scripts: ## Verify all Python scripts have valid syntax
	@echo "Testing Python scripts..."
	@PASS=0; FAIL=0; \
	for script in $$(find scripts agents -name '*.py' -type f 2>/dev/null); do \
		if python3 -c "import ast; ast.parse(open('$$script').read())" 2>/dev/null; then \
			echo "  ✓ $$script"; \
			PASS=$$((PASS + 1)); \
		else \
			echo "  ✗ $$script — SYNTAX ERROR"; \
			FAIL=$$((FAIL + 1)); \
		fi; \
	done; \
	echo "Results: $$PASS passed, $$FAIL failed"; \
	[ "$$FAIL" -eq 0 ] || exit 1

# ─── Cleanup ─────────────────────────────────────────────────────────────────

clean: ## Remove generated artifacts (logs, outputs) — does NOT touch ~/.atlas/
	@echo "Cleaning generated artifacts..."
	find agents -type d -name 'logs' -exec rm -rf {} + 2>/dev/null || true
	find agents -type d -name 'outputs' -exec rm -rf {} + 2>/dev/null || true
	rm -rf tmp/ outputs/
	@echo "Done. Agent config and skills are preserved."
