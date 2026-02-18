# Ops Agent — Available Tools

## Exec Tools
- `bash` — run shell commands (sandboxed, allowlist only)
- `python3` — data analysis and scripting

## Atlas Built-ins
- `approval_pipeline` — route actions requiring human approval
- `llm-task` — delegate subtasks to local Ollama models
- `memory_recall` — query long-term memory
- `memory_store` — store facts for future sessions

## Monitoring
- `kubectl get pods --all-namespaces` — cluster health
- `kubectl logs -n <ns> <pod>` — pod logs
- `make cluster-status` — full health check

## Communication
- Slack (via Atlas channel bindings)
- Webhook responses (structured JSON)

## Restrictions
- NO `docker system prune`, `rm -rf`, `sudo`
- NO direct database mutations
- NO external API calls with PHI
