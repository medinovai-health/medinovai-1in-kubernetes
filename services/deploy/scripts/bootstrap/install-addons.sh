#!/usr/bin/env bash
# ============================================================
# install-addons.sh — Deploy cluster addons to docker-desktop K8s
#
# Addons (all fully local, no cloud accounts required):
#   1. NGINX Ingress Controller  → localhost:30800 (HTTP) / :30843 (HTTPS)
#   2. Kubernetes Dashboard      → localhost:8443 via port-forward
#   3. Monitoring stack          → kube-state-metrics + Prometheus + Loki + Grafana
#   4. ArgoCD                    → localhost:8080 via port-forward (GitOps)
#   5. Ollama + Open WebUI       → localhost:31434 / :30090
#   6. Atlas Agent Gateway       → localhost:31789
#
# Usage:
#   bash scripts/bootstrap/install-addons.sh              # install all
#   bash scripts/bootstrap/install-addons.sh --ingress    # ingress only
#   bash scripts/bootstrap/install-addons.sh --dashboard  # dashboard only
#   bash scripts/bootstrap/install-addons.sh --monitoring # full monitoring stack
#   bash scripts/bootstrap/install-addons.sh --argocd     # argocd only
#   bash scripts/bootstrap/install-addons.sh --ollama     # ollama + webui
#   bash scripts/bootstrap/install-addons.sh --atlas      # atlas gateway
#   bash scripts/bootstrap/install-addons.sh --uninstall  # remove all addons
# ============================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ADDON_DIR="$REPO_ROOT/infra/kubernetes/addons"

G="\033[0;32m"; Y="\033[1;33m"; R="\033[0;31m"; B="\033[0;34m"; NC="\033[0m"
log()  { echo -e "${G}[addons]${NC} $*"; }
step() { echo -e "${B}[addons]${NC} $*"; }
warn() { echo -e "${Y}[addons]${NC} $*"; }
err()  { echo -e "${R}[addons]${NC} $*" >&2; }

INSTALL_INGRESS=false
INSTALL_DASHBOARD=false
INSTALL_MONITORING=false
INSTALL_ARGOCD=false
INSTALL_OLLAMA=false
INSTALL_ATLAS=false
UNINSTALL=false
ALL=true

for arg in "$@"; do
  case "$arg" in
    --ingress)    INSTALL_INGRESS=true;    ALL=false ;;
    --dashboard)  INSTALL_DASHBOARD=true;  ALL=false ;;
    --monitoring) INSTALL_MONITORING=true; ALL=false ;;
    --argocd)     INSTALL_ARGOCD=true;     ALL=false ;;
    --ollama)     INSTALL_OLLAMA=true;     ALL=false ;;
    --atlas)      INSTALL_ATLAS=true;      ALL=false ;;
    --uninstall)  UNINSTALL=true;          ALL=false ;;
    *) err "Unknown flag: $arg"; exit 1 ;;
  esac
done

if $ALL; then
  INSTALL_INGRESS=true
  INSTALL_DASHBOARD=true
  INSTALL_MONITORING=true
  INSTALL_ARGOCD=true
  INSTALL_OLLAMA=true
  INSTALL_ATLAS=true
fi

# ── Prerequisites ─────────────────────────────────────────────────────────────
check_prereqs() {
  local missing=0
  for cmd in kubectl helm curl base64; do
    command -v "$cmd" &>/dev/null || { err "Missing required tool: $cmd"; missing=1; }
  done
  [[ $missing -eq 0 ]] || exit 2

  if ! kubectl cluster-info --request-timeout=5s &>/dev/null; then
    err "Cannot reach Kubernetes cluster. Is Docker Desktop Kubernetes enabled?"
    exit 2
  fi

  local ctx
  ctx=$(kubectl config current-context 2>/dev/null || echo "none")
  if [[ "$ctx" != "docker-desktop" ]]; then
    warn "Context is '$ctx' (expected docker-desktop). Proceeding anyway."
  fi
}

# ── Helm repos ────────────────────────────────────────────────────────────────
setup_helm_repos() {
  log "Updating Helm repositories..."
  helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx 2>/dev/null || true
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
  helm repo add argo https://argoproj.github.io/argo-helm 2>/dev/null || true
  helm repo update >/dev/null
}

# ── Uninstall all ─────────────────────────────────────────────────────────────
uninstall_all() {
  local MONITORING_DIR="$REPO_ROOT/infra/kubernetes/monitoring"
  warn "Removing all cluster addons..."

  # ArgoCD + applications
  helm uninstall argocd -n argocd 2>/dev/null || true

  # Monitoring stack (full)
  helm uninstall kube-state-metrics -n medinovai-monitoring 2>/dev/null || true
  kubectl delete -f "$MONITORING_DIR/grafana/grafana.yaml" 2>/dev/null || true
  kubectl delete -f "$MONITORING_DIR/prometheus/prometheus.yaml" 2>/dev/null || true
  kubectl delete -f "$MONITORING_DIR/loki/loki.yaml" 2>/dev/null || true

  # Dashboard
  kubectl delete -f "$ADDON_DIR/dashboard/dashboard-admin.yaml" 2>/dev/null || true
  kubectl delete -f "$ADDON_DIR/dashboard/install.yaml" 2>/dev/null || true

  # Ingress
  kubectl delete -f "$ADDON_DIR/ingress-nginx/ingress-medinovai.yaml" 2>/dev/null || true
  helm uninstall ingress-nginx -n ingress-nginx 2>/dev/null || true

  # Atlas
  kubectl delete deployment atlas -n medinovai-system 2>/dev/null || true
  kubectl delete service atlas -n medinovai-system 2>/dev/null || true
  kubectl delete configmap atlas-config -n medinovai-system 2>/dev/null || true
  kubectl delete pvc atlas-state atlas-workspaces -n medinovai-system 2>/dev/null || true

  # Namespaces
  kubectl delete namespace argocd ingress-nginx kubernetes-dashboard \
    medinovai-ai-local medinovai-monitoring medinovai-system 2>/dev/null || true

  rm -f "$REPO_ROOT/.dashboard-token"
  log "All addons removed."
  warn "NOTE: Ollama model data (PVC) is preserved. Delete manually if desired:"
  warn "  kubectl delete pvc ollama-data open-webui-data -n medinovai-ai-local"
  warn "NOTE: Grafana dashboard data (PVC) is preserved. Delete manually if desired:"
  warn "  kubectl delete pvc grafana-data -n medinovai-monitoring"
  warn "Atlas workspaces preserved. Delete manually if desired:"
  warn "  kubectl delete pvc atlas-state atlas-workspaces -n medinovai-system"
}

# ── 1. NGINX Ingress ──────────────────────────────────────────────────────────
install_ingress() {
  step "1/4 NGINX Ingress Controller..."
  kubectl create namespace ingress-nginx 2>/dev/null || true
  helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx \
    --values "$ADDON_DIR/ingress-nginx/values.yaml" \
    --wait --timeout 3m
  kubectl apply -f "$ADDON_DIR/ingress-nginx/ingress-medinovai.yaml"
  log "✓ NGINX Ingress → http://localhost:30800 | https://localhost:30843"
}

# ── 2. Kubernetes Dashboard ───────────────────────────────────────────────────
install_dashboard() {
  step "2/4 Kubernetes Dashboard..."
  kubectl create namespace kubernetes-dashboard 2>/dev/null || true
  kubectl apply -f "$ADDON_DIR/dashboard/install.yaml"
  kubectl apply -f "$ADDON_DIR/dashboard/dashboard-admin.yaml"
  kubectl rollout status deployment/kubernetes-dashboard -n kubernetes-dashboard --timeout=2m

  local token
  token=$(kubectl -n kubernetes-dashboard get secret medinovai-dashboard-admin-token \
    -o jsonpath="{.data.token}" 2>/dev/null | base64 --decode || echo "")
  if [[ -n "$token" ]]; then
    echo "$token" > "$REPO_ROOT/.dashboard-token"
    log "  Token saved to .dashboard-token (gitignored)"
  fi
  log "✓ Dashboard → kubectl port-forward -n kubernetes-dashboard svc/kubernetes-dashboard 8443:443"
  log "            → https://localhost:8443"
}

# ── 3. Full monitoring stack (kube-state-metrics + Prometheus + Loki + Grafana) ──
install_monitoring() {
  local MONITORING_DIR="$REPO_ROOT/infra/kubernetes/monitoring"
  step "3/6 Monitoring stack (kube-state-metrics · Prometheus · Loki · Promtail · Grafana)..."
  kubectl create namespace medinovai-monitoring 2>/dev/null || true

  # kube-state-metrics (Helm)
  log "  Installing kube-state-metrics..."
  helm upgrade --install kube-state-metrics prometheus-community/kube-state-metrics \
    --namespace medinovai-monitoring \
    --values "$ADDON_DIR/kube-state-metrics/values.yaml" \
    --wait --timeout 2m
  log "  ✓ kube-state-metrics"

  # Prometheus
  log "  Deploying Prometheus..."
  kubectl apply -f "$MONITORING_DIR/prometheus/prometheus.yaml"
  kubectl rollout status deployment/prometheus -n medinovai-monitoring --timeout=2m
  log "  ✓ Prometheus → http://localhost:9090 (via port-forward)"

  # Loki + Promtail (log aggregation)
  log "  Deploying Loki + Promtail..."
  kubectl apply -f "$MONITORING_DIR/loki/loki.yaml"
  kubectl rollout status deployment/loki -n medinovai-monitoring --timeout=2m
  log "  ✓ Loki (log aggregation) → medinovai-monitoring:3100"
  log "  ✓ Promtail (DaemonSet) collecting logs from all pods"

  # Grafana (with Prometheus + Loki datasources)
  log "  Deploying Grafana..."
  kubectl apply -f "$MONITORING_DIR/grafana/grafana.yaml"
  kubectl rollout status deployment/grafana -n medinovai-monitoring --timeout=3m
  log "  ✓ Grafana → kubectl port-forward svc/grafana -n medinovai-monitoring 3000:3000"
  log "            → http://localhost:3000  (admin / admin — change on first login)"

  log "✓ Full monitoring stack deployed"
  log "  Prometheus: kubectl port-forward svc/prometheus -n medinovai-monitoring 9090:9090"
  log "  Grafana:    make monitoring-forward"
}

# ── 4. ArgoCD ────────────────────────────────────────────────────────────────
install_argocd() {
  step "4/5 ArgoCD..."
  kubectl create namespace argocd 2>/dev/null || true
  helm upgrade --install argocd argo/argo-cd \
    --namespace argocd \
    --values "$ADDON_DIR/argocd/values.yaml" \
    --wait --timeout 5m

  kubectl wait --for=condition=established crd/applications.argoproj.io --timeout=60s 2>/dev/null || true

  # Apply App-of-Apps (root application that manages all other repo Applications)
  kubectl apply -f "$ADDON_DIR/argocd/app-of-apps.yaml"
  # Apply the core platform app directly (it's the deploy repo itself)
  kubectl apply -f "$ADDON_DIR/argocd/medinovai-app.yaml"

  local pw
  pw=$(kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" 2>/dev/null | base64 --decode || echo "see: kubectl -n argocd get secret argocd-initial-admin-secret")

  log "✓ ArgoCD → kubectl port-forward svc/argocd-server -n argocd 8080:80"
  log "         → http://localhost:8080  |  admin / $pw"
  log "  medinovai-platform app syncing from: main branch"
}

# ── 5. Ollama + Open WebUI ────────────────────────────────────────────────────
install_ollama() {
  step "5/5 Ollama + Open WebUI (local LLM inference)..."
  local OLLAMA_DIR="$ADDON_DIR/ollama"

  kubectl apply -f "$OLLAMA_DIR/namespace.yaml"
  kubectl apply -f "$OLLAMA_DIR/ollama-deployment.yaml"
  kubectl apply -f "$OLLAMA_DIR/ollama-service.yaml"

  log "  Waiting for Ollama to be ready..."
  kubectl rollout status deployment/ollama -n medinovai-ai-local --timeout=3m

  kubectl apply -f "$OLLAMA_DIR/open-webui-deployment.yaml"
  kubectl apply -f "$OLLAMA_DIR/open-webui-service.yaml"

  log "  Waiting for Open WebUI to be ready..."
  kubectl rollout status deployment/open-webui -n medinovai-ai-local --timeout=3m

  # Pull default model (non-blocking — runs as background job)
  log "  Pulling default model (qwen2.5:1.5b) in background..."
  # Delete old job if present so we can re-apply idempotently
  kubectl delete job ollama-pull-default -n medinovai-ai-local 2>/dev/null || true
  kubectl apply -f "$OLLAMA_DIR/model-pull-job.yaml"

  log "✓ Ollama     → http://localhost:31434  (NodePort)"
  log "✓ Open WebUI → http://localhost:30090  (NodePort)"
  log "  Watch model pull: kubectl logs -n medinovai-ai-local -l job-name=ollama-pull-default -f"
  log "  Shortcut:         make webui-forward  → http://localhost:8090"
}

# ── 6. Atlas Agent Gateway ────────────────────────────────────────────────────
install_atlas() {
  step "6/6 Atlas Agent Gateway..."
  local ATLAS_DIR="$ADDON_DIR/atlas"

  # Build the Atlas UI image locally (docker-desktop uses local images directly)
  # Image name must match atlas-deployment.yaml: medinovai-atlas-ui:local
  if docker image inspect medinovai-atlas-ui:local &>/dev/null; then
    log "  ✓ medinovai-atlas-ui:local image already built"
  else
    log "  Building medinovai-atlas-ui:local image..."
    docker build -f "$REPO_ROOT/Dockerfile.atlas" \
      -t medinovai-atlas-ui:local \
      --build-arg ATLAS_UI_SRC="${HOME}/.medinovai/atlas/ui" \
      "$REPO_ROOT" 2>&1 | tail -5
    log "  ✓ Image built"
  fi

  # Sync Atlas config into the ConfigMap (uses deploy.json5 as source of truth)
  log "  Syncing Atlas config to ConfigMap..."
  kubectl create configmap atlas-config \
    -n medinovai-system \
    --from-file=atlas.json="$REPO_ROOT/config/deploy.json5" \
    --dry-run=client -o yaml | kubectl apply -f -

  # Apply deployment and service
  kubectl apply -f "$ATLAS_DIR/atlas-deployment.yaml"
  kubectl apply -f "$ATLAS_DIR/atlas-service.yaml"

  # Check if secrets exist; warn if not
  if ! kubectl get secret atlas-secrets -n medinovai-system &>/dev/null; then
    warn ""
    warn "  ⚠  Atlas secrets not configured. Atlas will start but Slack/APIs won't work."
    warn "  To configure secrets, run:"
    warn "    kubectl create secret generic atlas-secrets -n medinovai-system \\"
    warn "      --from-literal=ANTHROPIC_API_KEY=sk-ant-... \\"
    warn "      --from-literal=SLACK_APP_TOKEN=xapp-... \\"
    warn "      --from-literal=SLACK_BOT_TOKEN=xoxb-... \\"
    warn "      --from-literal=HOOKS_TOKEN=\$(openssl rand -hex 32)"
    warn "  Or: kubectl create secret generic atlas-secrets -n medinovai-system \\"
    warn "      --from-env-file=infra/docker/.env"
    warn ""
  fi

  kubectl rollout status deployment/atlas -n medinovai-system --timeout=3m || true

  log "✓ Atlas gateway → http://localhost:31789  (NodePort)"
  log "  Check status:   kubectl logs -n medinovai-system -l app=atlas -f"
  log "  Shortcut:       make atlas-forward  → http://localhost:18789"
}

# ── Summary ───────────────────────────────────────────────────────────────────
print_summary() {
  echo ""
  echo -e "${G}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${G}║  Cluster addons ready — all fully local, no cloud accounts  ║${NC}"
  echo -e "${G}╠══════════════════════════════════════════════════════════════╣${NC}"
  echo -e "${G}║  NGINX Ingress    http://localhost:30800                     ║${NC}"
  echo -e "${G}║  Dashboard        https://localhost:8443 (port-forward)      ║${NC}"
  echo -e "${G}║  Prometheus       http://localhost:9090  (port-forward)      ║${NC}"
  echo -e "${G}║  Grafana          http://localhost:3000  (port-forward)      ║${NC}"
  echo -e "${G}║  Loki             medinovai-monitoring:3100 (cluster-only)   ║${NC}"
  echo -e "${G}║  ArgoCD           http://localhost:8080 (port-forward)       ║${NC}"
  echo -e "${G}║  Ollama           http://localhost:31434  (NodePort)         ║${NC}"
  echo -e "${G}║  Open WebUI       http://localhost:30090  (NodePort)         ║${NC}"
  echo -e "${G}║  Atlas Gateway    http://localhost:31789  (NodePort)         ║${NC}"
  echo -e "${G}╠══════════════════════════════════════════════════════════════╣${NC}"
  echo -e "${G}║  Port-forward shortcuts:                                     ║${NC}"
  echo -e "${G}║  make dashboard-forward    # open dashboard in bg            ║${NC}"
  echo -e "${G}║  make argocd-forward       # open argocd in bg              ║${NC}"
  echo -e "${G}║  make monitoring-forward   # open grafana + prometheus       ║${NC}"
  echo -e "${G}║  make webui-forward        # open webui in bg               ║${NC}"
  echo -e "${G}║  make atlas-forward        # open atlas gateway in bg       ║${NC}"
  echo -e "${G}╠══════════════════════════════════════════════════════════════╣${NC}"
  echo -e "${G}║  Default models: qwen2.5:1.5b · nomic-embed-text · gemma3   ║${NC}"
  echo -e "${G}║  Watch: kubectl logs -n medinovai-ai-local                   ║${NC}"
  echo -e "${G}║         -l job-name=ollama-pull-default -f                  ║${NC}"
  echo -e "${G}╚══════════════════════════════════════════════════════════════╝${NC}"
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  check_prereqs

  if $UNINSTALL; then uninstall_all; exit 0; fi

  setup_helm_repos

  $INSTALL_INGRESS    && install_ingress
  $INSTALL_DASHBOARD  && install_dashboard
  $INSTALL_MONITORING && install_monitoring
  $INSTALL_ARGOCD     && install_argocd
  $INSTALL_OLLAMA     && install_ollama
  $INSTALL_ATLAS      && install_atlas

  print_summary
}

main "$@"
