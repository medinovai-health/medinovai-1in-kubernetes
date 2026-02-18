#!/usr/bin/env bash
# ============================================================
# list-repos.sh — List all MedinovAI repositories and their status
#
# Shows every known repo, whether it's cloned locally, and
# whether it has uncommitted changes or is behind origin.
#
# Usage:
#   bash scripts/list-repos.sh          # full status table
#   bash scripts/list-repos.sh --short  # names only
#   bash scripts/list-repos.sh --dirty  # show only repos with changes
# ============================================================
set -euo pipefail

TARGET_DIR="${HOME}/Documents/GitHub"
SHORT=false
DIRTY_ONLY=false

for arg in "$@"; do
  case "$arg" in
    --short) SHORT=true ;;
    --dirty) DIRTY_ONLY=true ;;
  esac
done

G="\033[0;32m"; Y="\033[1;33m"; R="\033[0;31m"; B="\033[0;34m"; NC="\033[0m"; BOLD="\033[1m"
DIM="\033[2m"

# ── All repos grouped by tier ─────────────────────────────────────────────────
declare -a AI_INFRA=(
  "medinovai-aifactory"
  "medinovai-aifactory-1"
  "medinovai-aifactory-2"
  "medinovai-healthLLM"
  "medinovai-healthLLM-1"
  "medinovai-ai-inference"
  "medinovai-intelligence"
)

declare -a PLATFORM=(
  "medinovai-Deploy"
  "medinovai-core"
  "medinovai-data-services"
  "medinovai-Atlas"
  "medinovai-Atlas-1"
  "medinovai-Uiux"
  "medinovai-api-gateway"
  "medinovai-auth-service"
  "medinovai-clinical-engine"
  "medinovai-data-pipeline"
  "medinovai-notification-service"
)

declare -a PRODUCT=(
  "medinovai-lis"
  "medinovai-lis-1"
  "medinovai-lis-2"
  "medinovai-lis-3"
  "medinovAI-lis-4(Codex)"
  "medinovai-Cortex"
  "medinovai-Cortex-1"
  "medinovai-sales"
  "medinovai-etmf"
  "medinovai-etmf-dev"
)

declare -a STANDARDS=(
  "medinovai-constitution"
  "MedinovAI-AI-Standards"
  "medinovai-dev-standards"
  "QMS"
  "QualityManagementSystem"
  "medinovAIgent"
  "medinovAIWorkFlow"
  "medinovAIUSB-1"
)

repo_status() {
  local repo="$1"
  local path="$TARGET_DIR/$repo"

  if [[ ! -d "$path/.git" ]]; then
    echo "missing"
    return
  fi

  local dirty="" behind="" ahead=""

  # Check dirty
  if ! git -C "$path" diff --quiet 2>/dev/null || ! git -C "$path" diff --cached --quiet 2>/dev/null; then
    dirty="dirty"
  fi

  # Check behind/ahead
  git -C "$path" fetch --quiet 2>/dev/null || true
  local behind_count ahead_count
  behind_count=$(git -C "$path" rev-list --count HEAD..@{u} 2>/dev/null || echo "0")
  ahead_count=$(git -C "$path" rev-list --count @{u}..HEAD 2>/dev/null || echo "0")

  [[ "$behind_count" -gt 0 ]] && behind="behind:${behind_count}"
  [[ "$ahead_count" -gt 0 ]] && ahead="ahead:${ahead_count}"

  local status="ok"
  [[ -n "$dirty" ]] && status="$dirty"
  [[ -n "$behind" ]] && status="${status}|${behind}"
  [[ -n "$ahead"  ]] && status="${status}|${ahead}"
  echo "$status"
}

print_repo() {
  local repo="$1"
  local path="$TARGET_DIR/$repo"

  if $SHORT; then
    echo "$repo"
    return
  fi

  if [[ ! -d "$path/.git" ]]; then
    $DIRTY_ONLY && return
    printf "  ${R}✗${NC} %-42s ${DIM}not cloned${NC}\n" "$repo"
    return
  fi

  local status
  status=$(repo_status "$repo")

  if $DIRTY_ONLY && [[ "$status" == "ok" ]]; then
    return
  fi

  local branch
  branch=$(git -C "$path" branch --show-current 2>/dev/null || echo "?")

  local color="$G"
  local icon="✓"
  if [[ "$status" != "ok" ]]; then
    color="$Y"
    icon="!"
  fi

  printf "  ${color}${icon}${NC} %-42s %-10s %b\n" "$repo" "[$branch]" "${color}${status}${NC}"
}

print_group() {
  local title="$1"
  shift
  local repos=("$@")

  $SHORT || echo -e "\n${BOLD}${B}── $title ──────────────────────────────────────────────${NC}"
  for repo in "${repos[@]}"; do
    print_repo "$repo"
  done
}

# ── Header ────────────────────────────────────────────────────────────────────
if ! $SHORT; then
  echo ""
  echo -e "${BOLD}MedinovAI Repository Status${NC}  —  $(date '+%Y-%m-%d %H:%M')"
  echo -e "${DIM}Checking ${TARGET_DIR}/...${NC}"
fi

print_group "AI Infrastructure" "${AI_INFRA[@]}"
print_group "Platform"          "${PLATFORM[@]}"
print_group "Products"          "${PRODUCT[@]}"
print_group "Standards & Tools" "${STANDARDS[@]}"

if ! $SHORT; then
  # Summary
  TOTAL=$((${#AI_INFRA[@]} + ${#PLATFORM[@]} + ${#PRODUCT[@]} + ${#STANDARDS[@]}))
  CLONED=0
  for repo in "${AI_INFRA[@]}" "${PLATFORM[@]}" "${PRODUCT[@]}" "${STANDARDS[@]}"; do
    [[ -d "$TARGET_DIR/$repo/.git" ]] && CLONED=$((CLONED + 1))
  done
  MISSING=$((TOTAL - CLONED))

  echo ""
  echo -e "  ${BOLD}Total:${NC} $TOTAL  |  ${G}Cloned: $CLONED${NC}  |  ${R}Missing: $MISSING${NC}"
  if [[ $MISSING -gt 0 ]]; then
    echo -e "  ${DIM}Run: make clone-repos  — to clone missing repos${NC}"
  fi
  echo ""
fi
