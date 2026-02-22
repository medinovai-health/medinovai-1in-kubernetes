.DEFAULT_GOAL := help

# ─── MedinovAI Deploy — On-Prem K3s Makefile ─────────────────────────────────
# Single repo for deploying the ENTIRE MedinovAI platform on-prem.
# K3s via OrbStack (macOS) + bare metal (DGX). Vault for secrets.
# AtlasOS embedded in every repo for fully autonomous AI operations.
# ─────────────────────────────────────────────────────────────────────────────

# ─── Variables ────────────────────────────────────────────────────────────────
SHELL := /bin/bash
SCRIPTS := scripts
BOOTSTRAP := $(SCRIPTS)/bootstrap
DEPLOY := $(SCRIPTS)/deploy
AGENTS := $(SCRIPTS)/agents
MAINTENANCE := $(SCRIPTS)/maintenance
VALIDATION := $(SCRIPTS)/validation
K8S := infra/kubernetes
ENV ?= onprem-prod

.PHONY: help setup prerequisites init-network init-k3s init-k3s-agent init-dgx init-storage init-vault
.PHONY: seed-secrets instantiate instantiate-critical
.PHONY: deploy-all deploy-critical deploy-tier deploy-service deploy-atlasos deploy-gpu deploy-agents
.PHONY: embed-atlasos embed-atlasos-repo embed-atlasos-category register-agents register-crons
.PHONY: health gpu-status agent-status status vault-status
.PHONY: rotate-secrets drift-check backup cert-check docker-backup docker-backup-verify docker-restore
.PHONY: orchestrator-start orchestrator-stop orchestrator-update orchestrator-rollback orchestrator-logs orchestrator-status
.PHONY: ceo-stack ceo-stack-stop ceo-stack-update production-deploy
.PHONY: validate validate-k8s smoke-test dashboards logs

# ─── Help ───────────────────────────────────────────────────────────────────
help: ## Show this help
	@grep -E '^[-a-zA-Z0-9_]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-24s\033[0m %s\n", $$1, $$2}'

# ─── Bootstrap ────────────────────────────────────────────────────────────────
setup: prerequisites init-network init-k3s init-storage init-vault instantiate ## Full setup from blank

prerequisites: ## Check required tools
	@bash $(BOOTSTRAP)/prerequisites.sh

init-network: ## Set up Tailscale mesh
	@bash $(BOOTSTRAP)/init-network.sh

init-k3s: ## Set up K3s via OrbStack (Mac Studio server)
	@bash $(BOOTSTRAP)/init-orbstack.sh --role server

init-k3s-agent: ## Add K3s worker (MacBook Pro)
	@bash $(BOOTSTRAP)/init-orbstack.sh --role agent

init-dgx: ## Set up DGX GPU nodes
	@bash $(BOOTSTRAP)/init-dgx.sh

init-storage: ## Install Longhorn storage
	@bash $(BOOTSTRAP)/init-storage.sh

init-vault: ## Deploy and initialize Vault
	@bash $(BOOTSTRAP)/init-vault.sh

seed-secrets: ## Seed secrets into Vault
	@bash $(BOOTSTRAP)/init-vault.sh --seed

instantiate: ## Full platform instantiation (25 steps, ~70min)
	@bash $(BOOTSTRAP)/instantiate.sh

instantiate-critical: ## Critical path only (15 steps, ~25min)
	@bash $(BOOTSTRAP)/instantiate.sh --critical-path-only

# ─── Deploy ───────────────────────────────────────────────────────────────────
deploy-all: ## Deploy all services (tier 0-6)
	@bash $(DEPLOY)/deploy_tier.sh all

deploy-critical: ## Deploy critical path only
	@bash $(DEPLOY)/deploy_tier.sh all --critical-path-only

deploy-tier: ## Deploy specific tier (TIER=0-6)
	@bash $(DEPLOY)/deploy_tier.sh $(TIER)

deploy-service: ## Deploy single service (SVC=name)
	@bash $(DEPLOY)/deploy_service.sh --service $(SVC) --environment $(ENV)

deploy-atlasos: ## Deploy AtlasOS services
	@bash $(DEPLOY)/deploy_tier.sh atlasos

deploy-gpu: ## Deploy GPU/AI inference services
	@bash $(DEPLOY)/deploy_tier.sh gpu

deploy-agents: ## Deploy AtlasOS infrastructure agents
	@bash $(DEPLOY)/deploy_tier.sh agents

# ─── AtlasOS Embedding ───────────────────────────────────────────────────────
embed-atlasos: ## Embed AtlasOS in all ~162 repos
	@bash $(AGENTS)/embed_atlasos.sh --all

embed-atlasos-repo: ## Embed AtlasOS in single repo (REPO=name)
	@bash $(AGENTS)/embed_atlasos.sh --repo $(REPO)

embed-atlasos-category: ## Embed AtlasOS in category (CAT=clinical)
	@bash $(AGENTS)/embed_atlasos.sh --category $(CAT)

register-agents: ## Register Atlas agents
	@bash $(AGENTS)/create_agents.sh

register-crons: ## Register agent cron jobs
	@bash $(AGENTS)/register_crons.sh

# ─── Health & Status ──────────────────────────────────────────────────────────
health: ## Full-stack health check
	@echo "─── Cluster ───" && kubectl get nodes
	@echo "─── Vault ───" && kubectl exec vault-0 -n vault -- vault status 2>/dev/null || echo "Vault unreachable"
	@echo "─── Pods ───" && kubectl get pods --all-namespaces --field-selector=status.phase!=Running 2>/dev/null | head -20
	@echo "─── AtlasOS ───" && kubectl get pods -n medinovai-services -l app.kubernetes.io/part-of=atlasos 2>/dev/null

gpu-status: ## Show GPU status across DGX nodes
	@kubectl get nodes -l gpu=true -o wide
	@echo "─── GPU Resources ───"
	@kubectl describe nodes -l gpu=true | grep -A5 "Allocated resources" || true

agent-status: ## Show AtlasOS agent status
	@kubectl get pods -n medinovai-atlasos 2>/dev/null
	@kubectl get pods -n medinovai-services -l app.kubernetes.io/part-of=atlasos 2>/dev/null

status: ## Quick cluster status
	@kubectl get nodes && echo "" && kubectl get pods --all-namespaces | grep -v Running | grep -v Completed | head -20

# ─── Secrets ──────────────────────────────────────────────────────────────────
rotate-secrets: ## Rotate secrets via Vault
	@bash $(MAINTENANCE)/rotate_secrets.sh

vault-status: ## Check Vault status
	@bash $(BOOTSTRAP)/init-vault.sh --status

# ─── Maintenance ──────────────────────────────────────────────────────────────
drift-check: ## Check for K8s drift vs Git manifests
	@bash $(MAINTENANCE)/drift_check.sh

backup: ## Run K8s/Longhorn backups
	@bash $(MAINTENANCE)/db_backup.sh

docker-backup: ## Backup Docker Compose production stack (all volumes + DBs)
	@bash $(MAINTENANCE)/docker_backup.sh

docker-backup-verify: ## Verify latest Docker backup integrity
	@bash $(MAINTENANCE)/docker_backup.sh --verify

docker-restore: ## Interactive restore from a Docker backup snapshot
	@bash $(MAINTENANCE)/docker_backup.sh --restore

cert-check: ## Check certificate expiry
	@bash $(MAINTENANCE)/cert_renewal.sh --check-only

# ─── Orchestrator (medinovai-orchestrator) ────────────────────────────────────
ORCHESTRATOR_COMPOSE := infra/docker/docker-compose.orchestrator.yml
ATLASOS_PATH ?= /Users/mayanktrivedi/Github/medinovai-health/medinovai-Atlas

orchestrator-start: ## Start medinovai-orchestrator from canonical compose
	@ATLASOS_PATH=$(ATLASOS_PATH) docker compose -f $(ORCHESTRATOR_COMPOSE) up -d
	@echo "Orchestrator started. Logs: make orchestrator-logs"

orchestrator-stop: ## Stop medinovai-orchestrator
	@docker compose -f $(ORCHESTRATOR_COMPOSE) stop medinovai-orchestrator
	@echo "Orchestrator stopped. Data volumes preserved."

orchestrator-update: ## Safe update: backup → pull → rebuild → restart
	@echo "Step 1/3: Pre-update backup..."
	@bash $(MAINTENANCE)/docker_backup.sh || (echo "✗ Backup failed — aborting update for safety" && exit 1)
	@echo "Step 2/3: Verifying backup..."
	@bash $(MAINTENANCE)/docker_backup.sh --verify || (echo "✗ Backup verification failed — aborting" && exit 1)
	@echo "Step 3/3: Rebuilding and restarting orchestrator..."
	@cd $(ATLASOS_PATH) && git pull --ff-only origin main 2>/dev/null || true
	@ATLASOS_PATH=$(ATLASOS_PATH) docker compose -f $(ORCHESTRATOR_COMPOSE) up -d --build medinovai-orchestrator
	@echo "✓ Orchestrator updated. Previous data preserved."

orchestrator-rollback: ## Rollback orchestrator to a previous image tag (TAG=sha-abc123)
	@[ -n "$(TAG)" ] || (echo "Usage: make orchestrator-rollback TAG=sha-abc123" && exit 1)
	@echo "Rolling back orchestrator to tag: $(TAG)"
	@ATLASOS_PATH=$(ATLASOS_PATH) ORCHESTRATOR_TAG=$(TAG) \
		docker compose -f $(ORCHESTRATOR_COMPOSE) up -d medinovai-orchestrator
	@echo "✓ Orchestrator rolled back to $(TAG)"

orchestrator-logs: ## Follow orchestrator logs
	@docker logs -f medinovai-orchestrator

orchestrator-status: ## Show orchestrator health and restart count
	@docker inspect medinovai-orchestrator \
		--format 'Status={{.State.Status}} Restarts={{.RestartCount}} Health={{.State.Health.Status}}' \
		2>/dev/null || echo "Orchestrator not running"

# ─── CEO Stack (Co-CEO Command Center) ───────────────────────────────────────
CEO_COMPOSE := infra/docker/docker-compose.ceo.yml

ceo-stack: ## Start the full CEO intelligence stack
	@ATLASOS_PATH=$(ATLASOS_PATH) docker compose -f $(CEO_COMPOSE) up -d
	@echo "CEO stack started on ports 41000-41999"

ceo-stack-stop: ## Stop CEO stack (preserves all volumes/data)
	@docker compose -f $(CEO_COMPOSE) stop
	@echo "CEO stack stopped. All data preserved."

ceo-stack-update: ## Safe update CEO stack: backup → pull → restart
	@echo "Step 1/2: Pre-update backup..."
	@bash $(MAINTENANCE)/docker_backup.sh || (echo "✗ Backup failed — aborting" && exit 1)
	@echo "Step 2/2: Updating CEO stack..."
	@ATLASOS_PATH=$(ATLASOS_PATH) docker compose -f $(CEO_COMPOSE) pull --quiet 2>/dev/null || true
	@ATLASOS_PATH=$(ATLASOS_PATH) docker compose -f $(CEO_COMPOSE) up -d --remove-orphans
	@echo "✓ CEO stack updated"

# ─── Full Production Deploy ───────────────────────────────────────────────────
production-deploy: docker-backup docker-backup-verify ceo-stack-update orchestrator-update ## Full safe production deploy (backup → update all)
	@echo ""
	@echo "✓ Full production deployment complete"
	@echo "  Run 'make docker-status' to verify all services"

docker-status: ## Show status of all Docker Compose production services
	@echo "=== CEO Stack ==="
	@docker compose -f $(CEO_COMPOSE) ps 2>/dev/null || echo "  Not running"
	@echo ""
	@echo "=== Orchestrator ==="
	@docker compose -f $(ORCHESTRATOR_COMPOSE) ps 2>/dev/null || echo "  Not running"
	@echo ""
	@echo "=== Resource Usage ==="
	@docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null | \
		grep -E "(ceo-|atlas-|medinovai-)" | head -20

# ─── Validation ───────────────────────────────────────────────────────────────
validate: ## Full validation suite
	@bash $(VALIDATION)/validate_setup.sh

validate-k8s: ## Validate K8s manifests
	@kubectl kustomize $(K8S)/base > /dev/null && echo "Base: OK"
	@kubectl kustomize $(K8S)/services/tier0 > /dev/null && echo "Tier 0: OK"
	@kubectl kustomize $(K8S)/services/atlasos > /dev/null && echo "AtlasOS: OK"

smoke-test: ## Run smoke tests
	@bash $(VALIDATION)/smoke_test.sh

# ─── Monitoring ───────────────────────────────────────────────────────────────
dashboards: ## Open Grafana dashboards
	@echo "Port-forwarding Grafana..."
	@kubectl port-forward svc/grafana -n medinovai-monitoring 3000:3000 &
	@echo "Grafana: http://localhost:3000"

logs: ## Follow deploy logs
	@kubectl logs -f -n medinovai-services -l app.kubernetes.io/part-of=atlasos --tail=50
