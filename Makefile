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
.PHONY: rotate-secrets drift-check backup cert-check
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

backup: ## Run backups (Longhorn snapshots + Vault)
	@bash $(MAINTENANCE)/db_backup.sh

cert-check: ## Check certificate expiry
	@bash $(MAINTENANCE)/cert_renewal.sh --check-only

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
