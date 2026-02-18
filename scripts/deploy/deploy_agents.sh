#!/usr/bin/env bash
# deploy_agents.sh -- Deploy domain-specific AGENTS.md + HEARTBEAT.md to all repos
set -euo pipefail

GITHUB_DIR="/Users/mayanktrivedi/Github"
TEMPLATES_DIR="$GITHUB_DIR/MedinovAI Atlas/templates"
COMMIT_MSG="Add domain-specific AI agent specification"

SUCCESS=0
SKIPPED=0
FAILED=0
FAILED_LIST=""

# ── Repo-to-Category Mapping ─────────────────────────────────────────────────
get_category() {
    local repo="$1"
    case "$repo" in
        # ── Clinical (40+) ────────────────────────────────────────────────
        medinovai-CTMS|medinovai-EDC|medinovai-ePRO|medinovai-eConsent) echo "clinical" ;;
        medinovai-eISF|medinovai-eSource|medinovai-etmf) echo "clinical" ;;
        medinovai-iwrs|medinovai-RBM|medinovai-Pharmacovigilance) echo "clinical" ;;
        medinovai-lis|medinovai-lis-platform|medinovai-lab-order-router) echo "clinical" ;;
        medinovai-drug-interaction-checker|medinovai-e-prescribe-gateway) echo "clinical" ;;
        medinovai-imaging-viewer|medinovai-medical-fax-processing) echo "clinical" ;;
        medinovai-medication-tracker|medinovai-patient-onboarding) echo "clinical" ;;
        medinovai-patientmatching|medinovai-remote-vitals-ingest) echo "clinical" ;;
        medinovai-care-team-chat|medinovai-clinical-decision-support|medinovai-cds) echo "clinical" ;;
        medinovai-guideline-updater|medinovai-health-timeline) echo "clinical" ;;
        medinovai-inventorymanagement|medinovai-smart-scheduler) echo "clinical" ;;
        medinovai-telehealth-hub|medinovai-virtual-triage) echo "clinical" ;;
        medinovai-wait-list-balancer|medinovai-provider-credentialing) echo "clinical" ;;
        medinovai-regulatory-submissions|medinovai-risk-management) echo "clinical" ;;
        medinovai-ResearchSuite|medinovai-projects) echo "clinical" ;;
        medinovAI-SiteFeasibility|medinovAI-eSign|medinovAIUSB) echo "clinical" ;;
        medinovai-Livekit|medinovai-consent-preference-api) echo "clinical" ;;
        medinovaios|medinovaios-1|medinovaios-2|medinovaios-3|medinovaios-4|medinovaios-5) echo "clinical" ;;

        # ── Backend Service (15+) ─────────────────────────────────────────
        medinovai-core|medinovai-api|medinovai-notification-center) echo "backend-service" ;;
        medinovai-mail|medinovai-registry|medinovai-validation) echo "backend-service" ;;
        medinovai-real-time-stream-bus|subscription) echo "backend-service" ;;
        MedinovAI-Email-Service|medinovAI-media|medinovAIWorkFlow) echo "backend-service" ;;

        # ── Frontend App (12+) ────────────────────────────────────────────
        medinovai-Uiux|medinovai-lis-ui|Employee-Portal) echo "frontend-app" ;;
        medinovai-task-kanban|medinovai-developer-portal) echo "frontend-app" ;;
        medinovai-audit-trail-explorer|medinovai-multimodal-ui-shell) echo "frontend-app" ;;
        medinovai-feature-flag-console|medinovai-help) echo "frontend-app" ;;
        medinovai-white-label-skinner|Uiux|vibe-kanban) echo "frontend-app" ;;

        # ── Platform / Infrastructure (15+) ───────────────────────────────
        medinovai-infrastructure|medinovai-canary-rollout-orchestrator) echo "platform" ;;
        medinovai-Atlas|medinovai-devops-telemetry) echo "platform" ;;
        medinovai-edge-cache-cdn|medinovai-test-infrastructure) echo "platform" ;;
        medinovai-policy-diff-watcher|ProcessAutomations) echo "platform" ;;
        architecture-catalog|architecture-catalog-1|architecture-catalog-2) echo "platform" ;;
        architecture-catalog-3|architecture-catalog-4) echo "platform" ;;
        ++Docker-Maintenance\ |__Docker-Maintenance-1|__Docker-Maintenance-clean) echo "platform" ;;
        vercel-clone|"MedinovAI Atlas") echo "platform" ;;
        myOnsiteOperationsMonitoringV1|myOnsiteOperationsMonitoringV1-1) echo "platform" ;;
        myonsite-all-code-base|myonsite-all-code-base-1) echo "platform" ;;

        # ── AI/ML (20+) ──────────────────────────────────────────────────
        medinovai-aifactory|medinovai-aifactory-1|aifactory-teams) echo "ai-ml" ;;
        medinovai-healthLLM|medinovai-healthLLM-1|medinovai-healthLLM-2) echo "ai-ml" ;;
        medinovai-pathology-ai|medinovai-genomics-interpreter) echo "ai-ml" ;;
        medinovai-sentiment-monitor|medinovai-anomaly-detector) echo "ai-ml" ;;
        medinovai-content-translator|medinovai-doc-summarizer) echo "ai-ml" ;;
        medinovai-image-to-text-ocr|medinovai-natural-language-query) echo "ai-ml" ;;
        medinovai-text-to-speech-narrator|medinovai-voice-command-layer) echo "ai-ml" ;;
        medinovai-accessibility-checker|medinovai-ai-scribe) echo "ai-ml" ;;
        medinovai-prompt-vault|medinovai-qa-agent-builder) echo "ai-ml" ;;
        medinovai-SME|MedinovAI-Chatbot) echo "ai-ml" ;;
        MedinovAI-Model-Service-Orchestrator|MAADS) echo "ai-ml" ;;
        PersonalAssistant|PersonalAssistant-1|PersonalAssistant-2) echo "ai-ml" ;;
        PhotoAI|medinovAIgent) echo "ai-ml" ;;

        # ── Data (8+) ────────────────────────────────────────────────────
        medinovai-data-services|medinovai-data-services-1) echo "data" ;;
        medinovai-data-services-2|medinovai-data-services-3) echo "data" ;;
        medinovai-etl-designer|medinovai-data-lake-loader) echo "data" ;;
        medinovai-knowledge-graph|medinovai-DataOfficer) echo "data" ;;
        medinovai-reseach-fabric|database) echo "data" ;;

        # ── Security (7+) ────────────────────────────────────────────────
        MedinovAI-security|MedinovAI-security-service) echo "security" ;;
        medinovai-hipaa-gdpr-guard|medinovai-encryption-vault) echo "security" ;;
        medinovai-role-based-permissions|medinovai-secrets-manager-bridge) echo "security" ;;
        medinovai-universal-sign-on) echo "security" ;;

        # ── Sales / CRM (12+) ────────────────────────────────────────────
        AutoSalesPro|AutoSalesPro-1|AutoSalesPro-2|AutoSalesPro-3) echo "sales-crm" ;;
        AutoBidPro|AutoGrantPro-Cursor) echo "sales-crm" ;;
        medinovai-sales|medinovai-saes|ATS) echo "sales-crm" ;;
        Credentialing|Credentialing-1) echo "sales-crm" ;;
        DocumentGenie|DocumentGenie-1|DocuGenie) echo "sales-crm" ;;

        # ── Docs / Standards (10+) ───────────────────────────────────────
        medinovai-standards|medinovai-dev-standards) echo "docs-standards" ;;
        medinovai-constitution|medinovai-governance-templates) echo "docs-standards" ;;
        medinovai-quality-certification) echo "docs-standards" ;;
        MedinovAI-AI-Standards|MedinovAI-AI-Standards-1|MedinovAI-AI-Standards-3) echo "docs-standards" ;;
        medinovai-Developer|medinovai-Developer-1) echo "docs-standards" ;;
        system-prompts-and-models-of-ai-tools|BMAD-METHOD) echo "docs-standards" ;;

        # ── Library (3+) ─────────────────────────────────────────────────
        medinovai-ui-components|medinovai-web-core|medinovai-agent-sdk) echo "library" ;;

        # ── Default: backend-service (safe catch-all) ────────────────────
        *) echo "backend-service" ;;
    esac
}

# ── AI Governance Deployment Helper ───────────────────────────────────────────
# Deploys governance-specific files (schemas, skills, standards) to repos
# based on their category. See docs/AI_GOVERNANCE_FRAMEWORK.md (GOV-01 through GOV-10).
GOVERNANCE_DIR="$GITHUB_DIR/MedinovAI Atlas"
GOVERNANCE_COMMIT_MSG="Add AI governance controls (GOV-01 through GOV-10)"

deploy_governance() {
    local dir="$1"
    local category="$2"
    local repo_name="$3"
    local gov_files_added=0

    # -- AI/ML repos: deploy model registry, bias testing, incident response, explainability --
    if [ "$category" = "ai-ml" ]; then
        mkdir -p "$dir/config" "$dir/skills/model-registry" "$dir/skills/bias-testing" "$dir/skills/ai-incident-response"
        cp "$TEMPLATES_DIR/ai-ml/config/model_risk_register_schema.json" "$dir/config/" 2>/dev/null && gov_files_added=$((gov_files_added + 1))
        cp "$TEMPLATES_DIR/ai-ml/config/explainability_standards.md" "$dir/config/" 2>/dev/null && gov_files_added=$((gov_files_added + 1))
        cp "$TEMPLATES_DIR/ai-ml/skills/model-registry/SKILL.md" "$dir/skills/model-registry/" 2>/dev/null && gov_files_added=$((gov_files_added + 1))
        cp "$TEMPLATES_DIR/ai-ml/skills/bias-testing/SKILL.md" "$dir/skills/bias-testing/" 2>/dev/null && gov_files_added=$((gov_files_added + 1))
        cp "$TEMPLATES_DIR/ai-ml/skills/ai-incident-response/SKILL.md" "$dir/skills/ai-incident-response/" 2>/dev/null && gov_files_added=$((gov_files_added + 1))
    fi

    # -- Clinical repos: deploy AI incident response and explainability standards --
    if [ "$category" = "clinical" ]; then
        mkdir -p "$dir/config" "$dir/skills/ai-incident-response"
        cp "$TEMPLATES_DIR/ai-ml/config/explainability_standards.md" "$dir/config/" 2>/dev/null && gov_files_added=$((gov_files_added + 1))
        cp "$TEMPLATES_DIR/ai-ml/skills/ai-incident-response/SKILL.md" "$dir/skills/ai-incident-response/" 2>/dev/null && gov_files_added=$((gov_files_added + 1))
    fi

    # -- Data repos: deploy data lineage schema --
    if [ "$category" = "data" ]; then
        mkdir -p "$dir/config"
        cp "$TEMPLATES_DIR/data/config/data_lineage_schema.json" "$dir/config/" 2>/dev/null && gov_files_added=$((gov_files_added + 1))
    fi

    # -- Docs/Standards repos: deploy vendor accountability terms --
    if [ "$category" = "docs-standards" ]; then
        cp "$TEMPLATES_DIR/docs-standards/vendor-ai-accountability-terms.md" "$dir/" 2>/dev/null && gov_files_added=$((gov_files_added + 1))
    fi

    # -- All repos: deploy governance framework reference doc --
    cp "$GOVERNANCE_DIR/docs/AI_GOVERNANCE_FRAMEWORK.md" "$dir/AI_GOVERNANCE_FRAMEWORK.md" 2>/dev/null && gov_files_added=$((gov_files_added + 1))

    echo "  Governance files deployed: $gov_files_added"
}

# ── Main Deployment Loop ──────────────────────────────────────────────────────
for dir in "$GITHUB_DIR"/*/; do
    repo_name=$(basename "$dir")

    # Skip MedinovAI Atlas (it's the source)
    if [ "$repo_name" = "MedinovAI Atlas" ]; then
        continue
    fi

    # Skip non-git repos
    if [ ! -d "$dir/.git" ]; then
        echo "SKIP (no .git): $repo_name"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    # Skip hidden/special directories
    if [[ "$repo_name" == .* ]]; then
        echo "SKIP (hidden): $repo_name"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    # Skip vibe-kanban (already has AGENTS.md)
    if [ "$repo_name" = "vibe-kanban" ] && [ -f "$dir/AGENTS.md" ]; then
        # Still deploy HEARTBEAT.md and governance files
        category=$(get_category "$repo_name")
        if [ -f "$TEMPLATES_DIR/$category/HEARTBEAT.md" ]; then
            cp "$TEMPLATES_DIR/$category/HEARTBEAT.md" "$dir/HEARTBEAT.md"
            deploy_governance "$dir" "$category" "$repo_name"
            cd "$dir"
            git add -A 2>/dev/null || true
            if ! git diff --cached --quiet 2>/dev/null; then
                git commit -m "Add domain-specific heartbeat checks and AI governance controls" --no-verify 2>/dev/null && echo "  OK (HEARTBEAT + governance): $repo_name" && SUCCESS=$((SUCCESS + 1)) || true
            fi
            cd "$GITHUB_DIR"
        fi
        continue
    fi

    # Get category for this repo
    category=$(get_category "$repo_name")

    # Verify template exists
    if [ ! -f "$TEMPLATES_DIR/$category/AGENTS.md" ]; then
        echo "FAIL (no template for $category): $repo_name"
        FAILED=$((FAILED + 1))
        FAILED_LIST="$FAILED_LIST $repo_name"
        continue
    fi

    echo "--- $repo_name [$category] ---"

    # Copy core templates
    cp "$TEMPLATES_DIR/$category/AGENTS.md" "$dir/AGENTS.md"
    cp "$TEMPLATES_DIR/$category/HEARTBEAT.md" "$dir/HEARTBEAT.md"

    # Deploy governance files based on category
    deploy_governance "$dir" "$category" "$repo_name"

    # Git add and commit
    cd "$dir"
    git add -A 2>/dev/null || true

    if git diff --cached --quiet 2>/dev/null; then
        echo "  SKIP (no changes): $repo_name"
        SKIPPED=$((SKIPPED + 1))
    else
        if git commit -m "$COMMIT_MSG" --no-verify 2>/dev/null; then
            echo "  OK: $repo_name [$category]"
            SUCCESS=$((SUCCESS + 1))
        else
            echo "  FAIL: $repo_name"
            FAILED=$((FAILED + 1))
            FAILED_LIST="$FAILED_LIST $repo_name"
        fi
    fi

    cd "$GITHUB_DIR"
done

echo ""
echo "=== DEPLOYMENT SUMMARY ==="
echo "Success: $SUCCESS"
echo "Skipped: $SKIPPED"
echo "Failed:  $FAILED"
if [ -n "$FAILED_LIST" ]; then
    echo "Failed repos:$FAILED_LIST"
fi
