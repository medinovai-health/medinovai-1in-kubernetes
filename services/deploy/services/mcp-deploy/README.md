# MCP-Deploy Tool Server

HTTP MCP server that exposes MedinovAI deployment scripts as callable tools. This is the **critical bridge** that lets AtlasOS agents trigger deployments via a consistent API.

## Endpoints

| Method | Path         | Description                          |
|--------|--------------|--------------------------------------|
| GET    | `/health`    | Health check, reports sandbox mode   |
| GET    | `/tools/list`| List available tools                 |
| POST   | `/tools/list`| List tools (same as GET)             |
| POST   | `/tools/call`| Invoke a tool by name with arguments |

## Tools

| Tool                 | Wraps                              | Approval |
|----------------------|------------------------------------|----------|
| `deploy_service`     | `scripts/deploy/deploy_service.sh`  | No       |
| `deploy_agents`      | `scripts/deploy/deploy_agents.sh`  | No       |
| `deploy_brain`       | `scripts/deploy/deploy_brain.sh`   | No       |
| `promote_canary`     | `scripts/deploy/promote_canary.sh` | No       |
| `rollback_service`   | `scripts/deploy/rollback_service.sh`| No       |
| `health_check`       | `scripts/validation/health_check_tier.sh` + kubectl | No |
| `validate_setup`     | `scripts/validation/validate_setup.sh` | No   |
| `validate_dependencies` | `scripts/validation/validate_dependency_order.sh` | No |
| `bootstrap_all`     | `scripts/bootstrap/bootstrap-all.sh` | **Yes** |
| `init_secrets`      | `scripts/bootstrap/init-secrets.sh`   | **Yes** |
| `init_vault`        | `scripts/bootstrap/init-vault.sh`     | **Yes** |
| `embed_atlasos`     | `scripts/agents/embed_atlasos.sh`     | No   |

## Run

```bash
# From repo root
cd services/mcp-deploy
python3 mcp_deploy_server.py
```

Default port: **3120** (override with `MCP_DEPLOY_PORT`).

## Sandbox Mode

Set `SANDBOX_MODE=1` to simulate tool execution without running scripts. Approval tools always return `needs_approval` and never execute.

## Example: Call a Tool

```bash
curl -X POST http://localhost:3120/tools/call \
  -H "Content-Type: application/json" \
  -d '{"name": "validate_setup", "arguments": {}}'
```

## Audit Log

Executions are logged to `outputs/mcp-deploy-audit.jsonl` for audit and debugging.
