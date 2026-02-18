# ─── MedinovAI Deploy — Makefile ─────────────────────────────────────────────
# On-prem K3s deployment for the entire MedinovAI platform.
#
# Usage:
#   make help              Show all available commands
#   make setup             Full setup: prerequisites + instantiate
#   make deploy-all        Deploy all services to K3s cluster
#   make health            Full-stack health audit
# ─────────────────────────────────────────────────────────────────────────────

.PHONY: help setup prerequisites instantiate deploy-all deploy-tier deploy-service
.PHONY: health status agent-status gpu-status logs
.PHONY: init-network init-k3s-server init-k3s-worker init-dgx init-storage init-vault
.PHONY: embed-atlasos embed-atlasos-repo
.PHONY: rotate-secrets seed-secrets drift-check backup
.PHONY: validate validate-k8s validate-compliance smoke-test
.PHONY: start stop clean

DEPLOY_HOME ?= $(HOME)/.medinovai-deploy
KUBECONFIG  ?= $(DEPLOY_HOME)/kubeconfig.yaml
TIER        ?=
SVC         ?=
REPO        ?=
CATEGORY    ?=

export KUBECONFIG
export DEPLOY_HOME

# ─── Help ────────────────────────────────────────────────────────────────────

help: ## Show this help message
	@echo ""
	@echo "MedinovAI Deploy — On-Prem K3s Platform Deployment"
	@echo "===================================================="
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-28s\033[0m %s\n", $$1, $$2}'
	@echo ""

# ─── Bootstrap (from blank) ─────────────────────────────────────────────────

prerequisites: ## Check all required tools are installed
	bash scripts/bootstrap/prerequisites.sh

instantiate: ## Full greenfield instantiation (blank to running platform, ~70 min)
	bash scripts/bootstrap/instantiate.sh

instantiate-critical: ## Deploy critical-path only (~25 min)
	bash scripts/bootstrap/instantiate.sh --critical-path-only

instantiate-dry: ## Dry run — show what would be deployed
	bash scripts/bootstrap/instantiate.sh --dry-run

setup: prerequisites instantiate ## Full setup: prerequisites + instantiate

# ─── Infrastructure Bootstrap ────────────────────────────────────────────────

init-network: ## Set up Tailscale mesh networking
	bash scripts/bootstrap/init-network.sh

init-k3s-server: ## Install K3s server on Mac Studio (via OrbStack)
	bash scripts/bootstrap/init-orbstack.sh --role server

init-k3s-worker: ## Install K3s agent on MacBook Pro (via OrbStack)
	bash scripts/bootstrap/init-orbstack.sh --role agent

init-dgx: ## Set up DGX servers as GPU K3s workers
	bash scripts/bootstrap/init-dgx.sh --from-fleet

init-storage: ## Install Longhorn distributed storage
	bash scripts/bootstrap/init-storage.sh

init-vault: ## Deploy and initialize HashiCorp Vault
	bash scripts/bootstrap/init-vault.sh

add-node: ## Add a new node (TYPE=orbstack|dgx, IP=x.x.x.x for DGX)
	@if [ "$(TYPE)" = "orbstack" ]; then \
		bash scripts/bootstrap/init-orbstack.sh --role agent; \
	elif [ "$(TYPE)" = "dgx" ]; then \
		bash scripts/bootstrap/init-dgx.sh --ips "$(IP)"; \
	else \
		echo "Usage: make add-node TYPE=orbstack|dgx [IP=x.x.x.x]"; \
	fi

# ─── Service Deployment ─────────────────────────────────────────────────────

deploy-all: ## Deploy all services in tier order
	bash scripts/deploy/deploy_tier.sh all

deploy-tier: ## Deploy a specific tier (TIER=0|1|2|3|4|5|6|atlasos|gpu)
ifndef TIER
	$(error TIER required. Usage: make deploy-tier TIER=0)
endif
	bash scripts/deploy/deploy_tier.sh $(TIER)

deploy-critical: ## Deploy critical-path services only
	bash scripts/deploy/deploy_tier.sh 0 && \
	bash scripts/deploy/deploy_tier.sh atlasos

deploy-atlasos: ## Deploy AtlasOS services
	bash scripts/deploy/deploy_tier.sh atlasos

deploy-gpu: ## Deploy GPU workloads (Ollama, AIFactory)
	bash scripts/deploy/deploy_tier.sh gpu

deploy-node-agents: ## Deploy AtlasOS node agents (DaemonSet on all nodes)
	bash scripts/deploy/deploy_tier.sh node-agents

deploy-cluster-brain: ## Deploy AtlasOS cluster brain
	bash scripts/deploy/deploy_tier.sh cluster-brain

# ─── AtlasOS Embedding ──────────────────────────────────────────────────────

embed-atlasos: ## Embed AtlasOS agents in ALL MedinovAI repos
	bash scripts/agents/embed_atlasos.sh --all

embed-atlasos-commit: ## Embed + commit + push to all repos
	bash scripts/agents/embed_atlasos.sh --all --push

embed-atlasos-repo: ## Embed AtlasOS in a single repo (REPO=name)
ifndef REPO
	$(error REPO required. Usage: make embed-atlasos-repo REPO=medinovai-CTMS)
endif
	bash scripts/agents/embed_atlasos.sh --repo $(REPO)

embed-atlasos-category: ## Embed in all repos of a category (CATEGORY=clinical)
ifndef CATEGORY
	$(error CATEGORY required. Usage: make embed-atlasos-category CATEGORY=clinical)
endif
	bash scripts/agents/embed_atlasos.sh --category $(CATEGORY)

# ─── Gateway Operations ─────────────────────────────────────────────────────

start: ## Start the Atlas gateway
	atlas gateway --port 18789

stop: ## Stop the Atlas gateway
	@pkill -f "atlas gateway" 2>/dev/null && echo "Gateway stopped." || echo "Not running."

# ─── Health & Monitoring ─────────────────────────────────────────────────────

health: ## Full-stack health check (nodes, pods, vault, atlas)
	@echo "━━━ Nodes ━━━"
	@kubectl get nodes 2>/dev/null || echo "Cannot reach cluster"
	@echo ""
	@echo "━━━ Vault ━━━"
	@kubectl exec -n vault vault-0 -- vault status 2>/dev/null || echo "Vault not reachable"
	@echo ""
	@echo "━━━ AtlasOS Pods ━━━"
	@kubectl get pods -n medinovai-services -l component=atlasos 2>/dev/null || true
	@echo ""
	@echo "━━━ Failing Pods ━━━"
	@kubectl get pods -A --field-selector='status.phase!=Running,status.phase!=Succeeded' 2>/dev/null | head -15 || true

status: ## Quick cluster status
	@kubectl get nodes && echo "" && kubectl get pods -A --no-headers | wc -l | xargs -I{} echo "{} pods running"

agent-status: ## AtlasOS agent heartbeat status
	@echo "━━━ Node Agents ━━━"
	@kubectl get pods -n medinovai-system -l app=atlasos-node-agent 2>/dev/null || true
	@echo ""
	@echo "━━━ Cluster Brain ━━━"
	@kubectl get pods -n medinovai-system -l app=atlasos-cluster-brain 2>/dev/null || true
	@echo ""
	@echo "━━━ Service Sidecars ━━━"
	@kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}{"\n"}{end}' 2>/dev/null | grep -c sidecar || echo "0 sidecars"

gpu-status: ## GPU status across all DGX nodes
	@echo "━━━ GPU Nodes ━━━"
	@kubectl get nodes -l gpu=true 2>/dev/null || echo "No GPU nodes"
	@echo ""
	@echo "━━━ Ollama Pods ━━━"
	@kubectl get pods -n medinovai-ai -l app=ollama 2>/dev/null || true

logs: ## Follow AtlasOS cluster brain logs
	kubectl logs -n medinovai-system -l app=atlasos-cluster-brain -f 2>/dev/null

# ─── Secrets Management ──────────────────────────────────────────────────────

seed-secrets: ## Interactively seed secrets into Vault
	bash scripts/bootstrap/init-vault.sh --seed

rotate-secrets: ## Rotate expiring secrets via Vault
	bash scripts/maintenance/rotate_secrets.sh

# ─── Maintenance ─────────────────────────────────────────────────────────────

drift-check: ## Compare K3s state to Git manifests
	bash scripts/maintenance/drift_check.sh

backup: ## Snapshot Longhorn volumes + Vault
	@echo "Creating Longhorn snapshots..."
	@echo "TODO: Implement Longhorn backup via kubectl"
	@echo "Creating Vault snapshot..."
	@kubectl exec -n vault vault-0 -- vault operator raft snapshot save /vault/data/backup.snap 2>/dev/null || echo "Vault backup requires raft mode"

# ─── Validation ──────────────────────────────────────────────────────────────

validate: ## Full validation suite
	bash scripts/validation/validate_setup.sh

validate-k8s: ## Validate Kubernetes manifests
	@echo "Validating Kustomize overlays..."
	@kubectl kustomize infra/kubernetes/overlays/onprem-dev/ > /dev/null && echo "  ✓ onprem-dev" || echo "  ✗ onprem-dev"
	@kubectl kustomize infra/kubernetes/overlays/onprem-prod/ > /dev/null && echo "  ✓ onprem-prod" || echo "  ✗ onprem-prod"

validate-compliance: ## Check GOV-01 through GOV-10 compliance
	bash scripts/validation/validate_compliance.sh

smoke-test: ## Run post-deploy smoke tests
	bash scripts/validation/smoke_test.sh

# ─── Testing ─────────────────────────────────────────────────────────────────

lint-yaml: ## Validate all YAML files
	@echo "Checking YAML files..."
	@PASS=0; FAIL=0; \
	for f in $$(find infra -name '*.yaml' -o -name '*.yml' 2>/dev/null); do \
		if python3 -c "import yaml; yaml.safe_load(open('$$f'))" 2>/dev/null; then \
			PASS=$$((PASS + 1)); \
		else \
			echo "  ✗ $$f"; FAIL=$$((FAIL + 1)); \
		fi; \
	done; \
	echo "Results: $$PASS valid, $$FAIL invalid"; [ "$$FAIL" -eq 0 ] || exit 1

# ─── Cleanup ─────────────────────────────────────────────────────────────────

clean: ## Remove generated artifacts (logs, outputs)
	@echo "Cleaning generated artifacts..."
	@find agents -type d -name 'logs' -exec rm -rf {} + 2>/dev/null || true
	@rm -rf tmp/ outputs/
	@echo "Done."
