#!/usr/bin/env bash
set -euo pipefail

# Apply MedinovAI organization-wide standards to a single repository.
# Usage: ./rollout-to-repo.sh <repo_dir> <repo_id> <old_name> <tier> <category> <lang>

REPO_DIR="$1"
REPO_ID="${2:-unknown}"
OLD_NAME="${3:-unknown}"
TIER="${4:-99}"
CATEGORY="${5:-unknown}"
LANG="${6:-unknown}"

BRAIN_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
PACKAGE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if [ ! -d "$REPO_DIR/.git" ]; then
  echo "SKIP $OLD_NAME — not a git repo at $REPO_DIR"
  exit 0
fi

echo "=== Rolling out standards to: $OLD_NAME (tier=$TIER, category=$CATEGORY, lang=$LANG) ==="

cd "$REPO_DIR"

BRANCH_NAME="standards/org-rollout-2026-03"
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")

git fetch origin --quiet 2>/dev/null || true
git checkout "$DEFAULT_BRANCH" --quiet 2>/dev/null || git checkout main --quiet 2>/dev/null || true
git pull origin "$DEFAULT_BRANCH" --quiet 2>/dev/null || true

if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME" 2>/dev/null; then
  git checkout "$BRANCH_NAME" --quiet
else
  git checkout -b "$BRANCH_NAME" --quiet
fi

CHANGES=0

# --- 1. .cursor/rules/ directory ---
mkdir -p .cursor/rules

RULES_TO_COPY=(
  "security-patterns.mdc"
  "port-authority-enforcement.mdc"
  "structured-logging.mdc"
  "agent-session-protocol.mdc"
  "medinovai-platform-context.mdc"
)

for rule_file in "${RULES_TO_COPY[@]}"; do
  src="$BRAIN_DIR/.cursor/rules/$rule_file"
  if [ -f "$src" ]; then
    cp "$src" ".cursor/rules/$rule_file"
    CHANGES=$((CHANGES + 1))
  fi
done

# --- 2. .cursorrules (slimmed for non-brain repos) ---
cat > .cursorrules << 'CURSORRULES_EOF'
# MedinovAI Platform Standards — Cursor IDE Rules

## MANDATORY: Spec-Driven Development (SDD)
1. SPECIFY → 2. VALIDATE → 3. BMAD → 4. TESTS (TDD) → 5. IMPLEMENT → 6. VALIDATE → 7. DEPLOY

## Non-Negotiables
- No PHI in logs, prompts, embeddings, fixtures, or comments
- No cross-tenant access — every request path stays tenant-scoped
- Every state-changing workflow requires an audit trail
- All logging uses structured JSON (ZTA structlog format)
- All variables: `mos_` prefix. All constants: `E_` prefix
- Code blocks: max 40 lines. UTF-8 encoding. Type hints everywhere

## Security
- Use MSS (medinovai-security-service) via SecurityClient SDK — NEVER local auth
- JWT validation on ALL protected routes
- Dynamic authorization via SpiceDB (ReBAC) — NEVER hardcode roles
- Encrypt PHI at rest (encryption-vault) and in transit (TLS 1.3)
- All secrets via secrets-manager-bridge — NEVER in .env or code

## Port Authority
- ALL ports assigned by medinovai-health/Deploy/config/port-registry.json
- NO hardcoded ports allowed — load from registry
- Internal container port: 8000 (Python) or 3000 (Node.js)

## Testing
- TDD: write tests FIRST (RED), then implement (GREEN), then refactor
- E2E via Playwright, unit via pytest/vitest, integration via API tests
- Feature = "done" only after browser/E2E visual verification

## Agent Session Protocol
- ONE feature per session — never one-shot a full app
- Feature branches only — never commit to main directly
- Checkpoint after every feature: features.json + progress.md + git commit + STOP
CURSORRULES_EOF
CHANGES=$((CHANGES + 1))

# --- 3. CLAUDE.md (repo-specific) ---
LANG_LOWER=$(echo "$LANG" | tr '[:upper:]' '[:lower:]')
case "$LANG_LOWER" in
  python) LANG_STD="Python 3.10+ with type hints, PEP 8, 120 char lines, Google docstrings, structlog" ;;
  typescript|javascript) LANG_STD="TypeScript/Node.js, strict mode, ESLint, pino structured logging" ;;
  csharp|c#) LANG_STD="C# .NET 8+, Serilog structured logging, nullable reference types" ;;
  go) LANG_STD="Go 1.21+, standard library preferred, structured logging" ;;
  *) LANG_STD="Platform standard coding conventions, structlog/structured logging" ;;
esac

RISK_CLASS="low"
if [ "$TIER" -le 1 ]; then RISK_CLASS="high"; fi
if [ "$TIER" -eq 2 ]; then RISK_CLASS="medium"; fi
if [ "$CATEGORY" = "clinical" ] || [ "$CATEGORY" = "research" ]; then RISK_CLASS="high"; fi

cat > CLAUDE.md << CLAUDE_EOF
# ${OLD_NAME} — AI Development Rules

## Repo Identity
| Field | Value |
|-------|-------|
| Repo | ${OLD_NAME} |
| Repo ID | ${REPO_ID} |
| Tier | ${TIER} |
| Domain | ${CATEGORY} |
| Language | ${LANG} |
| Risk Class | ${RISK_CLASS} |
| Platform Standard | v2.0 |

## Platform Standards (MANDATORY)
- All development follows Spec-Driven Development (SDD): SPECIFY → VALIDATE → BMAD → TESTS → IMPLEMENT → VALIDATE → DEPLOY
- Never write implementation code without a specification
- Never write code before tests (TDD: RED → GREEN → REFACTOR)
- Use platform shared services — never reimplement auth, secrets, audit, or telemetry locally

## Coding Standards
- ${LANG_STD}
- Async/await for all I/O operations
- Pydantic/Zod models for request/response validation

## Naming Conventions
- Constants: \`E_\` prefix in UPPER_CASE (e.g., \`E_MODULE_ID\`)
- Variables: \`mos_\` prefix in lowerCamelCase (e.g., \`mos_patientData\`)
- Code blocks: Maximum 40 lines for readability
- Encoding: UTF-8 everywhere

## Logging Standard (ZTA Format)
ALL logging MUST use structured JSON format (ZTA standard):
\`\`\`json
{"timestamp": "ISO8601", "level": "INFO", "service_id": "${OLD_NAME}",
  "correlation_id": "uuid", "tenant_id": "string", "actor_id": "string",
  "event": "string", "category": "audit|business|debug", "phi_safe": true}
\`\`\`
- NEVER use print() or plain logging.info()
- NEVER log raw PHI/PII values (use IDs only)

## Port Authority
- ALL ports from medinovai-health/Deploy/config/port-registry.json
- NO hardcoded ports — load from registry

## Platform References
- Unified Standard: medinovai-Developer/docs/platform-audit/UNIFIED_ALIGNMENT_STANDARD_v2.0.md
- System Docs: medinovai-Developer/docs/platform-audit/SYSTEM_TECHNICAL_DOCUMENTATION.md
CLAUDE_EOF
CHANGES=$((CHANGES + 1))

# --- 4. AGENTS.md ---
cat > AGENTS.md << AGENTS_EOF
# AtlasOS Agent — ${OLD_NAME}

This repo is managed by AtlasOS autonomous agents.

## Role and Identity
- **Repo**: ${OLD_NAME}
- **Tier**: ${TIER}
- **Category**: ${CATEGORY}
- **Risk Level**: $(echo "$RISK_CLASS" | tr '[:lower:]' '[:upper:]')

## Guardrails and Constraints
- **NEVER** alter governance or compliance policy without approval
- **ALWAYS** preserve accuracy when editing; do not introduce factual errors
- **ALWAYS** maintain cross-references and links

## Session Protocol
- Use \`progress.md\` as the durable session log
- Use \`features.json\` as the feature queue
- Rebuild context from \`pwd\`, git history, \`progress.md\`, and \`features.json\`
- Work on one feature at a time, preserve existing tests
- Stop after a clean handoff state

## Non-Negotiable Rules
1. **One feature per session** — never build the whole app at once
2. **Never delete tests** — treat as an absolute wall
3. **Feature branches only** — never commit directly to \`main\`
4. **Visual verification required** — Playwright/browser E2E before marking done
5. **Checkpoint after every feature** — \`features.json\` + \`progress.md\` + git commit + STOP
AGENTS_EOF
CHANGES=$((CHANGES + 1))

# --- 5. Stage and commit ---
if [ "$CHANGES" -gt 0 ]; then
  git add .cursorrules CLAUDE.md AGENTS.md .cursor/rules/ 2>/dev/null || true

  if git diff --cached --quiet; then
    echo "  No changes to commit for $OLD_NAME"
  else
    git commit -m "feat: Apply MedinovAI org-wide standards rollout (2026-03)

Standards applied:
- .cursorrules (SDD workflow, security, port authority)
- CLAUDE.md (repo-specific AI development rules)
- AGENTS.md (AtlasOS agent configuration)
- .cursor/rules/ (security-patterns, port-authority, structured-logging, session-protocol, platform-context)

Source: medinovai-Developer-1 (Platform Brain)
Rollout date: $(date -u +%Y-%m-%dT%H:%M:%SZ)" --quiet

    echo "  COMMITTED standards for $OLD_NAME"
  fi
else
  echo "  No changes needed for $OLD_NAME"
fi

echo "=== Done: $OLD_NAME ==="
