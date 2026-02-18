#!/usr/bin/env bash
# ─── embed_atlasos.sh ────────────────────────────────────────────────────────
# Embed AtlasOS agent workspaces, Cursor rules, and autonomous brain
# into every MedinovAI repo. Single source of truth for agent distribution.
#
# Replaces AtlasOS's deploy_brain.sh + deploy_agents.sh.
#
# Usage:
#   bash scripts/agents/embed_atlasos.sh --all                    # All repos
#   bash scripts/agents/embed_atlasos.sh --repo medinovai-CTMS    # Single repo
#   bash scripts/agents/embed_atlasos.sh --category clinical      # By category
#   bash scripts/agents/embed_atlasos.sh --all --dry-run          # Preview
#   bash scripts/agents/embed_atlasos.sh --all --commit           # Commit changes
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
GITHUB_DIR="${GITHUB_DIR:-$HOME/Github}"
TEMPLATES_DIR="$REPO_ROOT/templates/repo-agents"

TARGET_ALL=false
TARGET_REPO=""
TARGET_CATEGORY=""
DRY_RUN=false
COMMIT=false
STATS_DEPLOYED=0
STATS_SKIPPED=0
STATS_ERRORS=0

while [[ $# -gt 0 ]]; do
    case $1 in
        --all)       TARGET_ALL=true; shift ;;
        --repo)      TARGET_REPO="$2"; shift 2 ;;
        --category)  TARGET_CATEGORY="$2"; shift 2 ;;
        --dry-run)   DRY_RUN=true; shift ;;
        --commit)    COMMIT=true; shift ;;
        *)           echo "Unknown option: $1"; exit 1 ;;
    esac
done

if ! $TARGET_ALL && [ -z "$TARGET_REPO" ] && [ -z "$TARGET_CATEGORY" ]; then
    echo "Usage: embed_atlasos.sh --all | --repo <name> | --category <cat>"
    echo ""
    echo "Categories: clinical, backend-service, frontend-app, platform,"
    echo "            ai-ml, data, security, sales-crm, docs-standards, library"
    exit 1
fi

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $1"; }

# ─── Repo → Category mapping ───────────────────────────────────────────────
get_category() {
    local repo="$1"
    case "$repo" in
        medinovai-CTMS|medinovai-EDC|medinovai-eConsent|medinovai-eISF|medinovai-ePRO|\
        medinovai-eSource|medinovai-etmf|medinovai-iwrs|medinovai-RBM|medinovai-Pharmacovigilance|\
        medinovai-regulatory-submissions|medinovai-lis|medinovai-lis-platform|\
        medinovai-consent-preference-api|medinovai-care-team-chat|medinovai-telehealth-hub|\
        medinovai-patient-onboarding|medinovai-patientmatching|medinovai-drug-interaction-checker|\
        medinovai-guideline-updater|medinovai-cds|medinovai-inventorymanagement|\
        medinovai-ResearchSuite|medinovAIUSB|medinovai-visit-schedule-tracker|\
        medinovai-projects)
            echo "clinical" ;;

        medinovai-aifactory|medinovai-healthLLM|medinovai-ai-scribe|medinovai-anomaly-detector|\
        MedinovAI-Chatbot|medinovAIgent|medinovai-pathology-ai|medinovai-genomics-interpreter|\
        MedinovAI-Model-Service-Orchestrator|medinovai-natural-language-query|\
        medinovai-prompt-vault|medinovai-accessibility-checker|medinovai-SME|\
        PersonalAssistant|CEOassistant|PhotoAI)
            echo "ai-ml" ;;

        medinovai-api|medinovai-core|medinovai-notification-center|medinovai-real-time-stream-bus|\
        medinovai-registry|medinovai-validation|medinovai-api-gateway|medinovai-medical-fax-processing|\
        subscription|MedinovAI-Email-Service)
            echo "backend-service" ;;

        medinovai-lis-ui|medinovaios|medinovai-multimodal-ui-shell|Uiux|\
        medinovai-audit-trail-explorer|Employee-Portal|medinovai-developer-portal|\
        medinovai-feature-flag-console)
            echo "frontend-app" ;;

        ++Docker-Maintenance|medinovai-Deploy|medinovai-infrastructure|medinovai-devops-telemetry|\
        medinovai-test-infrastructure|medinovai-canary-rollout-orchestrator|\
        myOnsiteOperationsMonitoringV1|vercel-clone|ProcessAutomations|architecture-catalog|\
        AtlasOS|medinovai-Atlas|medinovai-atlas-engine)
            echo "platform" ;;

        MedinovAI-security|MedinovAI-security-service|medinovai-universal-sign-on|\
        medinovai-role-based-permissions|medinovai-secrets-manager-bridge|\
        medinovai-encryption-vault|medinovai-hipaa-gdpr-guard)
            echo "security" ;;

        database|medinovai-data-services|medinovai-data-lake-loader|medinovai-knowledge-graph|\
        medinovai-DataOfficer)
            echo "data" ;;

        medinovai-sales|AutoSalesPro|AutoBidPro|Credentialing|ATS|DocuGenie|\
        medinovai-saes)
            echo "sales-crm" ;;

        medinovai-constitution|MedinovAI-AI-Standards|medinovai-dev-standards|\
        medinovai-standards|medinovai-governance-templates|medinovai-quality-certification|\
        medinovai-Developer)
            echo "docs-standards" ;;

        medinovai-web-core|medinovai-ui-components|medinovai-agent-sdk)
            echo "library" ;;

        *)
            echo "backend-service" ;;
    esac
}

# ─── Deploy agent kit to a single repo ──────────────────────────────────────
deploy_to_repo() {
    local repo_name="$1"
    local repo_path="$GITHUB_DIR/$repo_name"

    if [ ! -d "$repo_path/.git" ]; then
        log "  SKIP: $repo_name (not a git repo at $repo_path)"
        STATS_SKIPPED=$((STATS_SKIPPED + 1))
        return 0
    fi

    local category
    category=$(get_category "$repo_name")

    local template_dir="$TEMPLATES_DIR/$category"
    if [ ! -d "$template_dir" ]; then
        log "  SKIP: No template for category '$category' at $template_dir"
        STATS_SKIPPED=$((STATS_SKIPPED + 1))
        return 0
    fi

    if $DRY_RUN; then
        log "  [DRY RUN] $repo_name → category: $category"
        STATS_DEPLOYED=$((STATS_DEPLOYED + 1))
        return 0
    fi

    log "  Deploying to $repo_name (category: $category)..."

    # Deploy Cursor rules
    mkdir -p "$repo_path/.cursor/rules"
    if ls "$template_dir/.cursor/rules/"*.mdc &>/dev/null; then
        for rule_file in "$template_dir/.cursor/rules/"*.mdc; do
            [ -f "$rule_file" ] && cp "$rule_file" "$repo_path/.cursor/rules/"
        done
    fi

    # Deploy autonomous brain (shared across all categories)
    local brain_rule="$REPO_ROOT/agents/platform/AGENTS.md"
    [ -f "$REPO_ROOT/.cursor/rules/atlas-autonomous-brain.mdc" ] && \
        cp "$REPO_ROOT/.cursor/rules/atlas-autonomous-brain.mdc" "$repo_path/.cursor/rules/" 2>/dev/null || true

    # Deploy agent workspace files
    for agent_file in AGENTS.md HEARTBEAT.md SOUL.md TOOLS.md MISTAKES.md; do
        [ -f "$template_dir/$agent_file" ] && cp "$template_dir/$agent_file" "$repo_path/"
    done

    # Deploy governance files (category-specific)
    if [ -d "$template_dir/governance" ]; then
        mkdir -p "$repo_path/governance"
        cp -r "$template_dir/governance/"* "$repo_path/governance/" 2>/dev/null || true
    fi

    # Commit if requested
    if $COMMIT; then
        cd "$repo_path"
        git add -A .cursor/ AGENTS.md HEARTBEAT.md SOUL.md TOOLS.md MISTAKES.md governance/ 2>/dev/null || true
        if git diff --cached --quiet; then
            log "    No changes to commit"
        else
            git commit -m "Embed AtlasOS agent kit (category: $category)" --no-verify 2>/dev/null || true
            log "    ✓ Committed"
        fi
        cd "$REPO_ROOT"
    fi

    STATS_DEPLOYED=$((STATS_DEPLOYED + 1))
}

# ─── Main ────────────────────────────────────────────────────────────────────
log "MedinovAI Deploy — Embed AtlasOS in Repos"
echo ""

if [ -n "$TARGET_REPO" ]; then
    deploy_to_repo "$TARGET_REPO"
elif $TARGET_ALL || [ -n "$TARGET_CATEGORY" ]; then
    for repo_dir in "$GITHUB_DIR"/*/; do
        [ ! -d "$repo_dir" ] && continue
        repo_name=$(basename "$repo_dir")

        # Skip non-MedinovAI and special dirs
        [[ "$repo_name" == "." || "$repo_name" == ".." ]] && continue

        if [ -n "$TARGET_CATEGORY" ]; then
            local_cat=$(get_category "$repo_name")
            [ "$local_cat" != "$TARGET_CATEGORY" ] && continue
        fi

        deploy_to_repo "$repo_name"
    done
fi

echo ""
log "Embedding complete."
log "  Deployed: $STATS_DEPLOYED"
log "  Skipped:  $STATS_SKIPPED"
log "  Errors:   $STATS_ERRORS"
