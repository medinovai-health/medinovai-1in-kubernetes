#!/usr/bin/env bash
# ============================================================
# clone-repos.sh — Clone all MedinovAI repositories locally
#
# Clones every known MedinovAI repo into ~/Documents/GitHub/
# Idempotent: skips repos that are already cloned.
# Uses SSH (git@github.com) — requires SSH key configured.
#
# Usage:
#   bash scripts/clone-repos.sh              # clone all repos
#   bash scripts/clone-repos.sh --pull       # pull latest on already-cloned repos
#   bash scripts/clone-repos.sh --list       # list all repos without cloning
#   bash scripts/clone-repos.sh --missing    # show only repos not yet cloned
#
# Prerequisites:
#   - SSH key configured: ssh -T git@github.com
#   - Target dir: ~/Documents/GitHub/
# ============================================================
set -euo pipefail

TARGET_DIR="${HOME}/Documents/GitHub"
ORG="myonsite-healthcare"
PULL_MODE=false
LIST_ONLY=false
MISSING_ONLY=false

G="\033[0;32m"; Y="\033[1;33m"; R="\033[0;31m"; B="\033[0;34m"; NC="\033[0m"; BOLD="\033[1m"
log()  { echo -e "${G}[clone]${NC} $*"; }
skip() { echo -e "${Y}[clone]${NC} $* (already exists)"; }
err()  { echo -e "${R}[clone]${NC} $*" >&2; }
info() { echo -e "${B}[clone]${NC} $*"; }

for arg in "$@"; do
  case "$arg" in
    --pull)    PULL_MODE=true ;;
    --list)    LIST_ONLY=true ;;
    --missing) MISSING_ONLY=true ;;
    --help|-h)
      sed -n '3,15p' "$0" | sed 's/# //'
      exit 0 ;;
    *) err "Unknown flag: $arg"; exit 1 ;;
  esac
done

# ── All MedinovAI repositories ────────────────────────────────────────────────
# Format: "repo-name|description|tier"
# Tier: ai-infra | platform | product | standards | tools
declare -a REPOS=(
  # ── AI Infrastructure (deploy first) ────────────────────────────────────────
  "medinovai-aifactory|MCP Gateway, 184+ LLM models, 3-node cluster (Mac Studio + DGX1 + DGX2)|ai-infra"
  "medinovai-aifactory-1|AIFactory enterprise variant (circuit breaker, warm pool)|ai-infra"
  "medinovai-aifactory-2|AIFactory slim variant with runbooks|ai-infra"
  "medinovai-healthLLM|6 clinical AI experts + Digital Twins (MCP server :8000)|ai-infra"
  "medinovai-healthLLM-1|healthLLM clone / alternate branch|ai-infra"

  # ── Core Platform ────────────────────────────────────────────────────────────
  "medinovai-Deploy|Infrastructure as code: K8s, Helm, ArgoCD, bootstrap scripts|platform"
  "medinovai-core|Shared Python library: MCP client, validation, quality gates|platform"
  "medinovai-data-services|FHIR R5 platform, patient management, analytics (:5000)|platform"
  "medinovai-Atlas|AI orchestration platform, federated network (ports 8080/8001-8003)|platform"
  "medinovai-Atlas-1|Atlas Company Ops: 8-agent runtime, gateway :18789|platform"
  "medinovai-Uiux|112+ healthcare UI components, training platform|platform"

  # ── Product Applications ─────────────────────────────────────────────────────
  "medinovai-lis|Lab Information System: .NET 8 API (:5050), React UI (:3000)|product"
  "medinovai-lis-1|LIS + medinovai-core overlay, 572 QA tests|product"
  "medinovai-lis-2|LIS variant: fresh deploy and standalone compose|product"
  "medinovai-lis-3|LIS variant: AI training data|product"
  "medinovai-Cortex|Healthcare logistics hub: Cortex API (:3050), Admin UI (:3100)|product"
  "medinovai-Cortex-1|Cortex full stack: + Intelligence, n8n, Neo4j, MinIO|product"
  "medinovai-sales|AI sales platform: React 19, tRPC, Intelligence service (:3000/:8000)|product"
  "medinovai-etmf|Electronic Trial Master File for clinical trials (:3000)|product"
  "medinovai-etmf-dev|eTMF development branch|product"

  # ── Operations & Automation ──────────────────────────────────────────────────
  "medinovai-constitution|AI ethics, standards, compliance for all 123+ repos|standards"
  "MedinovAI-AI-Standards|Dev standards, repo policies, AI governance templates|standards"
  "medinovai-dev-standards|MedinovAI Productivity Normalization Method|standards"
  "QMS|QMS AI Agent: compliance platform (healthcare, manufacturing)|tools"
  "QualityManagementSystem|QMS enterprise variant|tools"
  "medinovAIgent|Desktop multi-agent app: CAMEL-AI, Browser/Document agents (:5173)|tools"
  "medinovAIWorkFlow|Workflow definitions and automation|tools"

  # ── Device / Edge ────────────────────────────────────────────────────────────
  "medinovAIUSB-1|UCIIG: Lab analyzer ↔ LIS protocol bridge (HL7/MLLP :2575)|tools"

  # ── Missing core services (referenced by Deploy repo) ───────────────────────
  "medinovai-api-gateway|API Gateway service (K8s: medinovai-services namespace)|platform"
  "medinovai-auth-service|Auth service with JWT/Keycloak (K8s: medinovai-services)|platform"
  "medinovai-clinical-engine|Clinical logic engine (K8s: medinovai-services)|platform"
  "medinovai-data-pipeline|Data pipeline service (K8s: medinovai-services)|platform"
  "medinovai-notification-service|Notification service: email/SMS/push (K8s: medinovai-services)|platform"
  "medinovai-ai-inference|AI inference service with GPU support (K8s: medinovai-ai)|ai-infra"
  "medinovai-intelligence|RAG, proposals, embeddings service (:8000) — used by Cortex-1|ai-infra"
)

# ── List mode ─────────────────────────────────────────────────────────────────
if $LIST_ONLY; then
  echo ""
  echo -e "${BOLD}All MedinovAI repositories (${#REPOS[@]} total):${NC}"
  echo ""
  for entry in "${REPOS[@]}"; do
    IFS='|' read -r repo desc tier <<< "$entry"
    local_path="$TARGET_DIR/$repo"
    if [[ -d "$local_path/.git" ]]; then
      status="${G}✓ cloned${NC}"
    else
      status="${Y}✗ missing${NC}"
    fi
    printf "  %-40s %-12s %b\n" "$repo" "[$tier]" "$status"
  done
  echo ""
  exit 0
fi

# ── Missing mode ──────────────────────────────────────────────────────────────
if $MISSING_ONLY; then
  echo ""
  echo -e "${BOLD}Repos NOT yet cloned:${NC}"
  for entry in "${REPOS[@]}"; do
    IFS='|' read -r repo desc tier <<< "$entry"
    local_path="$TARGET_DIR/$repo"
    if [[ ! -d "$local_path/.git" ]]; then
      echo "  $repo  [$tier]  — $desc"
    fi
  done
  echo ""
  exit 0
fi

# ── Prerequisites ─────────────────────────────────────────────────────────────
mkdir -p "$TARGET_DIR"

if ! ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
  err "SSH to GitHub failed. Run: ssh-keygen -t ed25519 && cat ~/.ssh/id_ed25519.pub"
  err "Then add the key to GitHub: https://github.com/settings/ssh/new"
  exit 2
fi

# ── Clone / pull ──────────────────────────────────────────────────────────────
CLONED=0
PULLED=0
SKIPPED=0
FAILED=0

for entry in "${REPOS[@]}"; do
  IFS='|' read -r repo desc tier <<< "$entry"
  local_path="$TARGET_DIR/$repo"
  ssh_url="git@github.com:${ORG}/${repo}.git"

  if [[ -d "$local_path/.git" ]]; then
    if $PULL_MODE; then
      info "Pulling latest: $repo..."
      if git -C "$local_path" pull --ff-only 2>/dev/null; then
        log "↑ Pulled: $repo"
        PULLED=$((PULLED + 1))
      else
        skip "$repo (merge conflict or non-ff — manual pull needed)"
        SKIPPED=$((SKIPPED + 1))
      fi
    else
      skip "$repo"
      SKIPPED=$((SKIPPED + 1))
    fi
  else
    info "Cloning: $repo [$tier]"
    if git clone "$ssh_url" "$local_path" 2>/dev/null; then
      log "✓ Cloned: $repo"
      CLONED=$((CLONED + 1))
    else
      err "✗ Failed to clone: $repo (repo may not exist or no access)"
      FAILED=$((FAILED + 1))
    fi
  fi
done

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${G}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${G}║  Clone complete                                  ║${NC}"
echo -e "${BOLD}${G}╠══════════════════════════════════════════════════╣${NC}"
echo -e "${G}║  Cloned:  ${CLONED}                                       ║${NC}"
echo -e "${G}║  Pulled:  ${PULLED}                                       ║${NC}"
echo -e "${G}║  Skipped: ${SKIPPED} (already existed)                   ║${NC}"
[[ $FAILED -gt 0 ]] && \
echo -e "${R}║  Failed:  ${FAILED} (check access / repo name)           ║${NC}"
echo -e "${G}╠══════════════════════════════════════════════════╣${NC}"
echo -e "${G}║  All repos: ~/Documents/GitHub/                  ║${NC}"
echo -e "${G}║  Check missing: bash scripts/clone-repos.sh --missing ║${NC}"
echo -e "${G}╚══════════════════════════════════════════════════╝${NC}"
echo ""
