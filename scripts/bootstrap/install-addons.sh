#!/usr/bin/env bash
# ============================================================
# install-addons.sh — Deploy cluster addons to docker-desktop K8s
#
# Addons (all fully local, no cloud accounts required):
#   1. NGINX Ingress Controller  → localhost:30800 (HTTP) / :30843 (HTTPS)
#   2. Kubernetes Dashboard      → localhost:8443 via port-forward
#   3. kube-state-metrics        → K8s object metrics for local Prometheus
#   4. ArgoCD                    → localhost:8080 via port-forward (GitOps)
#
# Usage:
#   bash scripts/bootstrap/install-addons.sh              # install all
#   bash scripts/bootstrap/install-addons.sh --ingress    # ingress only
#   bash scripts/bootstrap/install-addons.sh --dashboard  # dashboard only
#   bash scripts/bootstrap/install-addons.sh --monitoring # kube-state-metrics only
#   bash scripts/bootstrap/install-addons.sh --argocd     # argocd only
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
UNINSTALL=false
ALL=true

for arg in "$@"; do
  case "$arg" in
    --ingress)    INSTALL_INGRESS=true;    ALL=false ;;
    --dashboard)  INSTALL_DASHBOARD=true;  ALL=false ;;
    --monitoring) INSTALL_MONITORING=true; ALL=false ;;
    --argocd)     INSTALL_ARGOCD=true;     ALL=false ;;
    --uninstall)  UNINSTALL=true;          ALL=false ;;
    *) err "Unknown flag: $arg"; exit 1 ;;
  esac
done

if $ALL; then
  INSTALL_INGRESS=true
  INSTALL_DASHBOARD=true
  INSTALL_MONITORING=true
  INSTALL_ARGOCD=true
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
  warn "Removing all cluster addons..."
  helm uninstall argocd -n argocd 2>/dev/null || true
  helm uninstall kube-state-metrics -n medinovai-monitoring 2>/dev/null || true
  kubectl delete -f "$ADDON_DIR/dashboard/dashboard-admin.yaml" 2>/dev/null || true
  kubectl delete -f "$ADDON_DIR/dashboard/install.yaml" 2>/dev/null || true
  kubectl delete -f "$ADDON_DIR/ingress-nginx/ingress-medinovai.yaml" 2>/dev/null || true
  helm uninstall ingress-nginx -n ingress-nginx 2>/dev/null || true
  kubectl delete namespace argocd ingress-nginx kubernetes-dashboard 2>/dev/null || true
  rm -f "$REPO_ROOT/.dashboard-token"
  log "All addons removed."
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

# ── 3. kube-state-metrics ─────────────────────────────────────────────────────
install_monitoring() {
  step "3/4 kube-state-metrics..."
  helm upgrade --install kube-state-metrics prometheus-community/kube-state-metrics \
    --namespace medinovai-monitoring \
    --values "$ADDON_DIR/kube-state-metrics/values.yaml" \
    --wait --timeout 2m
  log "✓ kube-state-metrics → medinovai-monitoring:8080/metrics (local Prometheus can scrape)"
}

# ── 4. ArgoCD ────────────────────────────────────────────────────────────────
install_argocd() {
  step "4/4 ArgoCD..."
  kubectl create namespace argocd 2>/dev/null || true
  helm upgrade --install argocd argo/argo-cd \
    --namespace argocd \
    --values "$ADDON_DIR/argocd/values.yaml" \
    --wait --timeout 5m

  kubectl wait --for=condition=established crd/applications.argoproj.io --timeout=60s 2>/dev/null || true
  kubectl apply -f "$ADDON_DIR/argocd/medinovai-app.yaml"

  local pw
  pw=$(kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" 2>/dev/null | base64 --decode || echo "see: kubectl -n argocd get secret argocd-initial-admin-secret")

  log "✓ ArgoCD → kubectl port-forward svc/argocd-server -n argocd 8080:80"
  log "         → http://localhost:8080  |  admin / $pw"
  log "  medinovai-platform app syncing from: main branch"
}

# ── Summary ───────────────────────────────────────────────────────────────────
print_summary() {
  echo ""
  echo -e "${G}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${G}║  Cluster addons ready — all fully local, no cloud accounts  ║${NC}"
  echo -e "${G}╠══════════════════════════════════════════════════════════════╣${NC}"
  echo -e "${G}║  NGINX Ingress    http://localhost:30800                     ║${NC}"
  echo -e "${G}║  Dashboard        https://localhost:8443 (port-forward)      ║${NC}"
  echo -e "${G}║  kube-state-metrics  medinovai-monitoring:8080/metrics       ║${NC}"
  echo -e "${G}║  ArgoCD           http://localhost:8080 (port-forward)       ║${NC}"
  echo -e "${G}╠══════════════════════════════════════════════════════════════╣${NC}"
  echo -e "${G}║  Port-forward shortcuts:                                     ║${NC}"
  echo -e "${G}║  make dashboard-forward   # open dashboard in bg             ║${NC}"
  echo -e "${G}║  make argocd-forward      # open argocd in bg               ║${NC}"
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

  print_summary
}

main "$@"
