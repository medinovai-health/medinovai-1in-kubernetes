#!/usr/bin/env bash
# ─── MCP Connector Scaffolder ─────────────────────────────────────────────────
# Usage:
#   ./infra/scripts/scaffold-connector.sh <connector-id>
#
# Example:
#   ./infra/scripts/scaffold-connector.sh stripe
#   ./infra/scripts/scaffold-connector.sh epic_ehr
#
# This script:
#   1. Looks up the connector in CONNECTOR_REGISTRY.yml
#   2. Creates the connector directory + connector.py from template
#   3. Creates the workspace skill SKILL.md for Arjun
#   4. Seeds a placeholder in Vault
#   5. Prints instructions for regenerating the compose file
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

CONNECTOR_ID="${1:-}"
if [[ -z "$CONNECTOR_ID" ]]; then
  echo "Usage: $0 <connector-id>"
  echo "Available IDs:"
  python3 infra/scripts/generate-mcp-compose.py --list 2>/dev/null | awk 'NR>2 && /planned/{print "  "$1}' || true
  exit 1
fi

ATLASOS_PATH="${ATLASOS_PATH:-/Users/mayanktrivedi/Github/medinovai-health/medinovai-Atlas}"
REGISTRY="$ATLASOS_PATH/services/mcp-connectors/CONNECTOR_REGISTRY.yml"
TEMPLATE="$ATLASOS_PATH/services/mcp-connectors/template/connector.py"
CONNECTORS_DIR="$ATLASOS_PATH/services/mcp-connectors"
SKILLS_DIR="${HOME}/.atlas/workspace-ceo/skills"
VAULT_ADDR="${VAULT_ADDR:-http://localhost:41100}"
VAULT_TOKEN="${VAULT_TOKEN:-medinovai-dev-token}"

# ── Parse registry entry ──────────────────────────────────────────────────────
CONNECTOR_DATA=$(python3 - <<PYEOF
import yaml, sys, json

with open("$REGISTRY") as f:
    data = yaml.safe_load(f)

connectors = data.get("connectors", [])
match = next((c for c in connectors if c["id"] == "$CONNECTOR_ID"), None)
if not match:
    available = [c["id"] for c in connectors]
    print(f"ERROR: Connector '$CONNECTOR_ID' not found in registry.", file=sys.stderr)
    print(f"Available: {available}", file=sys.stderr)
    sys.exit(1)

print(json.dumps(match))
PYEOF
)

if [[ -z "$CONNECTOR_DATA" ]]; then
  exit 1
fi

# Extract fields
CONNECTOR_NAME=$(echo "$CONNECTOR_DATA" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['name'])")
CONNECTOR_DIR=$(echo "$CONNECTOR_DATA" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('connector_dir', d['id']))")
VAULT_PATH=$(echo "$CONNECTOR_DATA" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['vault_path'])")
PORT=$(echo "$CONNECTOR_DATA" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['port'])")
DESCRIPTION=$(echo "$CONNECTOR_DATA" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('description',''))")
TOOLS=$(echo "$CONNECTOR_DATA" | python3 -c "import json,sys; d=json.load(sys.stdin); print(', '.join(d.get('tools',[])))")
CREDENTIALS=$(echo "$CONNECTOR_DATA" | python3 -c "import json,sys; d=json.load(sys.stdin); print(', '.join(c['name'] for c in d.get('credentials',[])))")
CLASS_NAME=$(echo "$CONNECTOR_DIR" | python3 -c "import sys; s=sys.stdin.read().strip(); print(''.join(p.capitalize() for p in s.replace('-','_').split('_')))")

echo "Scaffolding connector: $CONNECTOR_NAME ($CONNECTOR_ID)"
echo "  Dir:         $CONNECTORS_DIR/$CONNECTOR_DIR/"
echo "  Port:        $PORT"
echo "  Vault path:  $VAULT_PATH"
echo ""

# ── Step 1: Create connector directory + connector.py ────────────────────────
TARGET_DIR="$CONNECTORS_DIR/$CONNECTOR_DIR"
if [[ -d "$TARGET_DIR" ]]; then
  echo "  [SKIP] Connector directory already exists: $TARGET_DIR"
else
  mkdir -p "$TARGET_DIR"
  sed \
    -e "s/{{CONNECTOR_ID}}/$CONNECTOR_ID/g" \
    -e "s/{{CONNECTOR_NAME_TITLE}}/$CONNECTOR_NAME/g" \
    -e "s/{{CLASS_NAME}}/$CLASS_NAME/g" \
    -e "s|{{VAULT_PATH}}|$VAULT_PATH|g" \
    -e "s/{{TOOLS_LIST}}/$TOOLS/g" \
    -e "s/{{CREDENTIAL_KEYS}}/$CREDENTIALS/g" \
    "$TEMPLATE" > "$TARGET_DIR/connector.py"
  echo "  [OK]   Created: $TARGET_DIR/connector.py"
fi

# ── Step 2: Create workspace skill SKILL.md ───────────────────────────────────
SKILL_DIR="$SKILLS_DIR/$CONNECTOR_ID"
if [[ -d "$SKILL_DIR" ]]; then
  echo "  [SKIP] Skill already exists: $SKILL_DIR/SKILL.md"
else
  mkdir -p "$SKILL_DIR"
  cat > "$SKILL_DIR/SKILL.md" <<SKILLEOF
# $CONNECTOR_NAME Skill

**Connector:** \`ceo-mcp-$CONNECTOR_ID\` running at \`http://mcp-$CONNECTOR_ID:8080\` (internal Docker network)
**Host port:** \`localhost:$PORT\`
**Auth:** Credentials via Vault at \`$VAULT_PATH\`

## Description

$DESCRIPTION

## When to Use This Skill

TODO: Describe the natural language triggers that should invoke this skill.

## Available Tools

| Tool | Method | Description |
|------|--------|-------------|
$(echo "$TOOLS" | tr ',' '\n' | sed 's/^ *//' | awk '{printf "| `%s` | POST `/tools/%s` | TODO: describe |\n", $0, $0}')

## How to Call (Internal Docker Network)

\`\`\`bash
# TODO: Add curl examples
curl -s -X POST http://mcp-$CONNECTOR_ID:8080/tools/get_summary \\
  -H "Content-Type: application/json" -d '{}'
\`\`\`

## Credential Update

\`\`\`bash
./infra/scripts/seed-vault-credentials.sh $CONNECTOR_ID
docker compose -f infra/docker/docker-compose.ceo.yml up -d --force-recreate mcp-$CONNECTOR_ID
\`\`\`
SKILLEOF
  echo "  [OK]   Created: $SKILL_DIR/SKILL.md"
fi

# ── Step 3: Seed placeholder in Vault ────────────────────────────────────────
echo "$CONNECTOR_DATA" | python3 - <<PYEOF
import json, sys, urllib.request

data = json.load(sys.stdin)
vault_path = data["vault_path"]
credentials = data.get("credentials", [])

payload = {}
for cred in credentials:
    payload[cred["name"]] = cred.get("default", f"REPLACE_WITH_{cred['name'].upper()}")

body = json.dumps({"data": payload}).encode()
req = urllib.request.Request(
    f"${VAULT_ADDR}/v1/{vault_path}",
    data=body, method="POST"
)
req.add_header("X-Vault-Token", "${VAULT_TOKEN}")
req.add_header("Content-Type", "application/json")
try:
    with urllib.request.urlopen(req) as r:
        result = json.loads(r.read())
        print(f"  [OK]   Vault placeholder seeded: {vault_path}")
except Exception as e:
    print(f"  [WARN] Vault seed failed (will retry on stack start): {e}", file=sys.stderr)
PYEOF

# ── Step 4: Print next steps ──────────────────────────────────────────────────
echo ""
echo "Scaffold complete for: $CONNECTOR_NAME ($CONNECTOR_ID)"
echo ""
echo "Next steps:"
echo "  1. Implement the connector:"
echo "       edit $CONNECTORS_DIR/$CONNECTOR_DIR/connector.py"
echo ""
echo "  2. Regenerate compose file:"
echo "       make generate-mcp-compose"
echo "     OR to include planned connectors:"
echo "       make generate-mcp-compose STATUS=stable,beta,scaffold"
echo ""
echo "  3. Seed real credentials:"
echo "       ./infra/scripts/seed-vault-credentials.sh $CONNECTOR_ID"
echo ""
echo "  4. Build and start:"
echo "       ATLASOS_PATH=$ATLASOS_PATH docker compose -f infra/docker/docker-compose.ceo.yml up -d --build mcp-$CONNECTOR_ID"
echo ""
echo "  5. Update the skill doc:"
echo "       edit $SKILL_DIR/SKILL.md"
