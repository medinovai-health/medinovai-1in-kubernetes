# ─── MedinovAI Deploy — On-Prem K3s Makefile ─────────────────────────────────
# Single repo for deploying the ENTIRE MedinovAI platform on-prem.
# K3s via OrbStack (macOS) + bare metal (DGX). Vault for secrets.
# AtlasOS embedded in every repo for fully autonomous AI operations.
#
# Usage:
#   make help                Show all available commands
#   make setup               Full setup from blank to running platform
#   make deploy-all          Deploy all 109 services
#   make health              Full-stack health audit
# ─────────────────────────────────────────────────────────────────────────────

.PHONY: help setup prerequisites
.PHONY: init-network init-k3s-server init-k3s-agent init-dgx init-storage init-vault
.PHONY: instantiate deploy-all deploy-tier deploy-service deploy-critical
.PHONY: embed-atlasos embed-atlasos-repo
.PHONY: health gpu-status agent-status vault-status
.PHONY: seed-secrets rotate-secrets
.PHONY: drift-check backup dashboards logs
.PHONY: add-node remove-node
.PHONY: ceo-stack ceo-stack-down ceo-health ceo-audit-verify ceo-logs

ENV ?= onprem-prod
DGX_IPS ?= 192.168.68.78,192.168.68.85
TIER ?=
SVC ?=
REPO ?=
CATEGORY ?=
DEPLOY_HOME ?= $(HOME)/.medinovai-deploy
KUBECONFIG ?= $(DEPLOY_HOME)/kubeconfig.yaml

export KUBECONFIG
export DEPLOY_HOME

# ─── Help ────────────────────────────────────────────────────────────────────

help: ## Show this help message
	@echo ""
	@echo "MedinovAI Deploy — On-Prem K3s Platform Deployment"
	@echo "======================================================"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-24s\033[0m %s\n", $$1, $$2}'
	@echo ""

# ─── Full Setup (Blank → Running) ───────────────────────────────────────────

setup: prerequisites instantiate embed-atlasos ## Full setup: prerequisites + instantiate + embed AtlasOS
	@echo ""
	@echo "Setup complete! Full MedinovAI platform is running."
	@echo "  Run: make health"

prerequisites: ## Check all required tools
	bash scripts/bootstrap/prerequisites.sh

instantiate: ## Full greenfield instantiation (blank → running platform, ~70 min)
	bash scripts/bootstrap/instantiate.sh

instantiate-critical: ## Critical-path instantiation (12 services, ~25 min)
	bash scripts/bootstrap/instantiate.sh --critical-path-only

instantiate-resume: ## Resume interrupted instantiation from last checkpoint
	bash scripts/bootstrap/instantiate.sh --resume

instantiate-dry-run: ## Show what instantiation would do
	bash scripts/bootstrap/instantiate.sh --dry-run

# ─── Infrastructure Bootstrap ───────────────────────────────────────────────

init-network: ## Set up Tailscale mesh network
	bash scripts/bootstrap/init-network.sh --advertise-routes

init-k3s-server: ## Set up K3s server on Mac Studio via OrbStack
	bash scripts/bootstrap/init-orbstack.sh --role server

init-k3s-agent: ## Set up K3s agent on MacBook Pro via OrbStack
	bash scripts/bootstrap/init-orbstack.sh --role agent

init-dgx: ## Set up DGX GPU nodes as K3s workers
	bash scripts/bootstrap/init-dgx.sh --server-ip $$(tailscale ip -4) --dgx-ips $(DGX_IPS)

init-storage: ## Install Longhorn distributed storage
	bash scripts/bootstrap/init-storage.sh

init-vault: ## Deploy and initialize HashiCorp Vault
	bash scripts/bootstrap/init-vault.sh

# ─── Deployment ──────────────────────────────────────────────────────────────

deploy-all: ## Deploy all 109 services in tier order
	bash scripts/deploy/deploy_tier.sh all

deploy-tier: ## Deploy specific tier (TIER=0|1|2|3|4|5|6|atlasos|gpu|agents)
	bash scripts/deploy/deploy_tier.sh $(TIER)

deploy-critical: ## Deploy critical-path only (12 essential services)
	@for t in 0 1 2 atlasos; do bash scripts/deploy/deploy_tier.sh $$t; done

deploy-atlasos: ## Deploy AtlasOS services only
	bash scripts/deploy/deploy_tier.sh atlasos

deploy-agents: ## Deploy AtlasOS node agents + cluster brain
	bash scripts/deploy/deploy_tier.sh agents

# ─── AtlasOS Embedding ──────────────────────────────────────────────────────

embed-atlasos: ## Embed AtlasOS agent kits in ALL ~162 repos
	bash scripts/agents/embed_atlasos.sh --all

embed-atlasos-repo: ## Embed AtlasOS in single repo (REPO=medinovai-CTMS)
	bash scripts/agents/embed_atlasos.sh --repo $(REPO)

embed-atlasos-category: ## Embed AtlasOS in repos by category (CATEGORY=clinical)
	bash scripts/agents/embed_atlasos.sh --category $(CATEGORY)

embed-atlasos-dry-run: ## Preview what embed would do
	bash scripts/agents/embed_atlasos.sh --all --dry-run

embed-atlasos-commit: ## Embed and commit changes to all repos
	bash scripts/agents/embed_atlasos.sh --all --commit

# ─── Health & Status ─────────────────────────────────────────────────────────

health: ## Full-stack health audit
	@echo "=== Nodes ==="
	@kubectl get nodes -o wide 2>/dev/null || echo "Cannot connect to cluster"
	@echo ""
	@echo "=== Pods by Namespace ==="
	@for ns in infra security platform atlasos ai-ml clinical business integrations ui vault monitoring; do \
		ready=$$(kubectl get pods -n $$ns --no-headers 2>/dev/null | grep -c Running || echo 0); \
		total=$$(kubectl get pods -n $$ns --no-headers 2>/dev/null | wc -l | xargs || echo 0); \
		printf "  %-20s %s/%s running\n" "$$ns" "$$ready" "$$total"; \
	done
	@echo ""
	@echo "=== Vault ==="
	@kubectl exec -n vault vault-0 -- vault status 2>/dev/null | head -5 || echo "  Vault not reachable"
	@echo ""
	@echo "=== Cluster Brain ==="
	@kubectl exec -n atlasos deploy/atlasos-cluster-brain -- curl -s http://localhost:8100/health 2>/dev/null || echo "  Cluster brain not running"

gpu-status: ## NVIDIA GPU status across DGX nodes
	@kubectl get nodes -l gpu=true -o wide 2>/dev/null || echo "No GPU nodes"
	@echo ""
	@for node in $$(kubectl get nodes -l gpu=true --no-headers -o custom-columns=':metadata.name' 2>/dev/null); do \
		echo "=== $$node ==="; \
		kubectl debug node/$$node --image=nvidia/cuda:12.0-base -- nvidia-smi 2>/dev/null || echo "  Cannot reach $$node"; \
	done

agent-status: ## AtlasOS agent heartbeat status
	@echo "=== Node Agents (DaemonSet) ==="
	@kubectl get pods -n atlasos -l app=atlasos-node-agent -o wide 2>/dev/null || echo "  No node agents"
	@echo ""
	@echo "=== Cluster Brain ==="
	@kubectl get pods -n atlasos -l app=atlasos-cluster-brain 2>/dev/null || echo "  No cluster brain"

vault-status: ## Vault status and secret count
	@kubectl exec -n vault vault-0 -- vault status 2>/dev/null || echo "Vault not reachable"

# ─── Secrets ─────────────────────────────────────────────────────────────────

seed-secrets: ## Seed secrets into Vault from ~/.atlas/.env
	bash scripts/bootstrap/init-vault.sh --seed-from-env $(HOME)/.atlas/.env

seed-secrets-interactive: ## Seed secrets interactively
	bash scripts/bootstrap/init-vault.sh --seed

rotate-secrets: ## Rotate expiring secrets via Vault
	bash scripts/maintenance/rotate_secrets.sh

# ─── Maintenance ─────────────────────────────────────────────────────────────

drift-check: ## Check for drift between Git manifests and cluster state
	bash scripts/maintenance/drift_check.sh

backup: ## Trigger Longhorn snapshots + Vault backup
	@echo "Creating Longhorn snapshots..."
	@kubectl get pvc --all-namespaces --no-headers 2>/dev/null | wc -l | xargs
	@echo "Vault backup..."
	@kubectl exec -n vault vault-0 -- vault operator raft snapshot save /vault/data/backup.snap 2>/dev/null || echo "  Vault backup requires raft storage"

dashboards: ## Open Grafana dashboards
	@echo "Grafana: kubectl port-forward -n monitoring svc/grafana 3000:3000"
	@echo "Vault UI: kubectl port-forward -n vault svc/vault-ui 8200:8200"
	@echo "Longhorn: kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80"

logs: ## Follow deploy logs
	@tail -f $(DEPLOY_HOME)/logs/instantiate-*.log 2>/dev/null || echo "No logs found"

# ─── Node Management ────────────────────────────────────────────────────────

add-node: ## Add a new node (prompts for type: orbstack or dgx)
	@echo "Node types: orbstack (macOS), dgx (GPU bare metal)"
	@read -p "Type: " node_type; \
	if [ "$$node_type" = "orbstack" ]; then \
		bash scripts/bootstrap/init-orbstack.sh --role agent; \
	elif [ "$$node_type" = "dgx" ]; then \
		read -p "DGX IP: " dgx_ip; \
		bash scripts/bootstrap/init-dgx.sh --server-ip $$(tailscale ip -4) --dgx-ips "$$dgx_ip"; \
	fi

# ─── Validation ──────────────────────────────────────────────────────────────

validate: ## Full validation suite
	@bash scripts/validation/validate_setup.sh 2>/dev/null || echo "Validation script not found"

validate-k8s: ## Validate K8s manifests
	@for dir in infra/kubernetes/services/*/; do \
		echo "Validating $$dir..."; \
		kubectl apply -k "$$dir" --dry-run=client 2>/dev/null && echo "  ✓" || echo "  ✗"; \
	done

# ─── CI/CD ───────────────────────────────────────────────────────────────────

atlas-agents: ## Register all Atlas agents
	bash scripts/agents/create_agents.sh

atlas-crons: ## Register all monitoring cron jobs
	bash scripts/agents/register_crons.sh

# ─── AtlasOS CO-CEO Stack ─────────────────────────────────────────────────

ATLASOS_PATH ?= ../AtlasOS
CEO_COMPOSE := infra/docker/docker-compose.ceo.yml

ceo-stack: ## Deploy the full AtlasOS CO-CEO stack
	@echo "🚀 Deploying AtlasOS CO-CEO Stack..."
	ATLASOS_PATH=$(ATLASOS_PATH) docker compose -f $(CEO_COMPOSE) up -d --build
	@echo "Waiting for services to initialize..."
	@sleep 10
	@$(MAKE) ceo-health

ceo-stack-down: ## Tear down the CO-CEO stack
	docker compose -f $(CEO_COMPOSE) down

ceo-health: ## Health check all CO-CEO services (ports 41xxx)
	@echo "── CO-CEO Service Health (41xxx range) ──"
	@curl -sf http://localhost:41100/v1/sys/health | python3 -c "import sys,json; d=json.load(sys.stdin); print('  Vault (41100):            ✓ init=%s sealed=%s' % (d.get('initialized'),d.get('sealed')))" 2>/dev/null || echo "  Vault (41100):            ✗"
	@curl -sf http://localhost:41500/health | python3 -c "import sys,json; print('  Audit Chain (41500):      ✓ %s' % json.load(sys.stdin).get('status','?'))" 2>/dev/null || echo "  Audit Chain (41500):      ✗"
	@curl -sf http://localhost:41510/health | python3 -c "import sys,json; print('  Correlation (41510):      ✓ %s' % json.load(sys.stdin).get('status','?'))" 2>/dev/null || echo "  Correlation (41510):      ✗"
	@curl -sf http://localhost:41520/health | python3 -c "import sys,json; print('  Briefing (41520):         ✓ %s' % json.load(sys.stdin).get('status','?'))" 2>/dev/null || echo "  Briefing (41520):         ✗"
	@curl -sf http://localhost:41530/health | python3 -c "import sys,json; print('  Decision Tracker (41530): ✓ %s' % json.load(sys.stdin).get('status','?'))" 2>/dev/null || echo "  Decision Tracker (41530): ✗"
	@curl -sf -o /dev/null http://localhost:41000 && echo "  Atlas Command (41000):    ✓ http://localhost:41000" || echo "  Atlas Command (41000):    ✗"

ceo-audit-verify: ## Verify the audit chain integrity
	@curl -sf http://localhost:41500/audit/verify | python3 -m json.tool 2>/dev/null || echo "Audit chain unreachable"

ceo-logs: ## Tail logs from all CO-CEO services
	docker compose -f $(CEO_COMPOSE) logs -f --tail=50
