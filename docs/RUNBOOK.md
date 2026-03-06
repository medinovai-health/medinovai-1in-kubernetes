# Operations Runbook

Day-to-day reference for managing your MedinovAI Atlas automation runtime.

---

## Starting & Stopping

### Start the gateway
```bash
atlas gateway --port 18789
# or
make start
```

### Stop the gateway
```bash
make stop
# or
pkill -f "atlas gateway"
```

### Check status
```bash
atlas status --all
# or
make status
```

### Follow logs in real time
```bash
atlas logs --follow
# or
make logs
```

---

## Cron Jobs

### List all cron jobs
```bash
atlas cron list
```

### Check cron health
```bash
atlas cron status
```

### View run history for a job
```bash
atlas cron runs --id <job-id> --limit 20
```

### Add a new cron job
```bash
atlas cron add \
  --name "Job name" \
  --cron "0 9 * * 1-5" \
  --tz "America/New_York" \
  --session isolated \
  --message "What the agent should do." \
  --announce \
  --channel slack \
  --to "channel:C_CHANNEL_ID"
```

### Remove a cron job
```bash
atlas cron remove --id <job-id>
```

### Temporarily disable a cron job
```bash
atlas cron disable --id <job-id>
```

---

## Hooks & Webhooks

### Test a hook locally
```bash
curl -X POST "http://localhost:18789/hooks/ticket?token=$HOOKS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "support.ticket_created",
    "occurred_at": "2026-02-14T12:00:00Z",
    "source": "zendesk",
    "entity": {"type": "ticket", "id": "T-9999"},
    "data": {"subject": "Test ticket", "priority": "medium"}
  }'
```

### Available hook paths
| Path | Agent | Purpose |
|------|-------|---------|
| `/hooks/ticket` | support | Support ticket events |
| `/hooks/sales` | sales | Sales/CRM events |
| `/hooks/incident` | ops | Incident alerts |
| `/hooks/gmail` | ops | Email events |
| `/hooks/invoice` | finance | Invoice/receipt events |
| `/hooks/payment` | finance | Payment events |
| `/hooks/pr` | eng | Pull request events |
| `/hooks/ci` | eng | CI pipeline events |

### Normalize a webhook payload
```bash
echo '{"type": "invoice.payment_succeeded", "data": {...}}' \
  | python3 scripts/normalize_event.py --json-in --source stripe
```

---

## Agent Management

### List agents
```bash
atlas agents list
```

### Check agent workspace
```bash
ls ~/.atlas/workspace-<agent>/
```

### Update agent workspace files
1. Edit files in this repo under `workspaces/<agent>/`
2. Redeploy: `bash scripts/deploy_config.sh`
3. The agent will pick up changes on next session

### Send a message between agents
Use `sessions_send` from within an agent session. Example: the ops agent can ask the sales agent for a pipeline summary.

---

## Common Scenarios

### Scenario: Morning briefing didn't fire
1. Check cron status: `atlas cron status`
2. Check job runs: `atlas cron runs --id morning-briefing --limit 5`
3. Check logs for errors: `atlas logs --follow`
4. If the job is missing, re-register: `bash scripts/register_crons.sh`

### Scenario: Slack bot not responding
1. Check gateway is running: `atlas status`
2. Check Slack connection in logs: `atlas logs --follow | grep -i slack`
3. Verify tokens: ensure `SLACK_APP_TOKEN` and `SLACK_BOT_TOKEN` are set in `~/.atlas/.env`
4. Check channel allowlist: bot must be invited to the channel AND the channel must be in `atlas.json` allowlist
5. Check `requireMention` setting — if true, you must @mention the bot

### Scenario: Hook returns 401
1. Verify the `token` query parameter matches `HOOKS_TOKEN` in config
2. Tokens are case-sensitive

### Scenario: Agent returning "needs_human"
This is correct behavior — it means the agent's confidence is below the threshold. Review the agent's output and either:
- Provide additional context and re-trigger
- Handle the request manually
- Update the skill/config with better rules

### Scenario: Adding a brand new automation
1. Identify the trigger: Slack message? Webhook? Schedule? Manual command?
2. Identify the agent: Which department handles this?
3. Create a skill: `workspaces/<agent>/skills/<name>/SKILL.md`
4. (Optional) Create a script: `workspaces/<agent>/scripts/<name>.py`
5. Wire the trigger: add cron job, hook mapping, or Slack command
6. Test locally, then deploy: `bash scripts/deploy_config.sh`
7. See `docs/automation_patterns.md` for detailed patterns

---

## Monitoring & Alerting

### What to watch
| Metric | Where to check | Alert threshold |
|--------|---------------|-----------------|
| Gateway uptime | `atlas status` | Any downtime |
| Cron failures | `atlas cron status` | Any failed run |
| Hook response time | Gateway logs | > 30s |
| Agent errors | `atlas logs` | Any error-level log |
| Slack connection | Gateway logs | Disconnect events |

### Log levels
- `info`: Normal operations (job started, message received)
- `warn`: Non-critical issues (retry, timeout, low confidence)
- `error`: Failures requiring attention

---

## Maintenance

### Weekly
- Review cron job runs for failures
- Check workspace disk usage
- Review `state/` files for stale data
- Update `known_issues.json` with resolved issues

### Monthly
- Rotate old outputs (`outputs/` directories)
- Review and update skills based on feedback
- Update dependency policy if needed
- Review access audit logs

### Config changes
1. Edit files in this repo
2. Commit to git
3. Redeploy: `bash scripts/deploy_config.sh`
4. Restart gateway if config structure changed: `make stop && make start`

---

## Health Monitoring

### Health probe endpoints
The gateway exposes health and readiness probes:

```bash
# Liveness check
curl http://localhost:18789/health

# Readiness check (all agents loaded, all connections established)
curl http://localhost:18789/ready
```

### Circuit breaker status
Check circuit breaker state for any agent:
```bash
cat ~/.atlas/workspace-<agent>/state/circuit_breakers.json | python3 -m json.tool
```

Reset a tripped circuit breaker:
```bash
# Edit the circuit_breakers.json for the affected agent
# Set "state": "closed", "failures": 0
```

---

## Dead Letter Management

### Check for unprocessed dead letter items
```bash
ls -la ~/.atlas/workspace-<agent>/state/dead_letter/
```

### Reprocess a dead letter item
```bash
# Read the item to understand what failed
cat ~/.atlas/workspace-<agent>/state/dead_letter/<item>.json

# Delete the item after manual resolution
rm ~/.atlas/workspace-<agent>/state/dead_letter/<item>.json
```

### Dead letter age check (run across all agents)
```bash
find ~/.atlas/workspace-*/state/dead_letter/ -name '*.json' -mtime +1
```

---

## Audit Chain Verification

### Verify all audit chains
```bash
python3 scripts/verify_audit_chain.py --all
```

### Verify a specific agent's audit chain
```bash
python3 scripts/verify_audit_chain.py --workspace ops
```

### View recent audit entries
```bash
tail -20 ~/.atlas/workspace-<agent>/audit/audit.jsonl | python3 -m json.tool
```

---

## Memory Operations

### View agent memories
```bash
# World knowledge
cat ~/.atlas/workspace-<agent>/state/memory/world.json | python3 -m json.tool

# Past experiences
cat ~/.atlas/workspace-<agent>/state/memory/experiences.json | python3 -m json.tool

# Known entities
cat ~/.atlas/workspace-<agent>/state/memory/entities.json | python3 -m json.tool

# Beliefs and hypotheses
cat ~/.atlas/workspace-<agent>/state/memory/beliefs.json | python3 -m json.tool
```

### Trigger manual memory reflection
Run the weekly memory reflection cron manually:
```bash
atlas cron run --id memory-reflection
```

---

## Guardian Operations

### Check Guardian validation decisions
```bash
tail -20 ~/.atlas/workspace-guardian/audit/audit.jsonl | python3 -m json.tool
```

### View blocked actions
```bash
grep '"allowed": false' ~/.atlas/workspace-guardian/audit/audit.jsonl | tail -10
```

### Guardian is blocking legitimate actions
1. Check the policy in `workspaces/guardian/AGENTS.md`
2. Review the denied action's reasoning
3. If policy needs updating, edit the Guardian workspace and redeploy
4. If the action should proceed, use Approval Pipeline approval override

---

## Supervisor Operations

### Check supervisor interventions
```bash
cat ~/.atlas/workspace-supervisor/state/interventions.json | python3 -m json.tool
```

### View recent intervention history
```bash
tail -20 ~/.atlas/workspace-supervisor/audit/audit.jsonl | python3 -m json.tool
```

---

## Emergency Procedures

### Kill all MedinovAI Atlas processes
```bash
pkill -f atlas
```

### Disable all webhooks temporarily
Set `hooks.enabled: false` in `~/.atlas/atlas.json` and restart the gateway.

### Disable a specific agent
Remove it from the `agents.list` in config, or change its workspace to a minimal one with restrictive `AGENTS.md`.

### Rollback config
```bash
# List backups
ls ~/.atlas/atlas.json.backup.*

# Restore a backup
cp ~/.atlas/atlas.json.backup.YYYYMMDD_HHMMSS ~/.atlas/atlas.json

# Restart
make stop && make start
```

---

## Deployment Operations Runbook

### Scenario: Keycloak ownership conflict

Use a single Keycloak owner per runtime:

- Compose platform mode -> tier0 Keycloak in `medinovai-Deploy`
- Compose standalone mode -> external `medinovai-security-service`
- Kubernetes platform mode -> tier0 Keycloak service

Validate before deploy:

```bash
bash scripts/validation/validate_keycloak_ownership.sh --runtime compose --compose-mode platform --mode warn
bash scripts/validation/validate_keycloak_ownership.sh --runtime k8s --mode warn
```

If rollout is complete and stable, switch to strict mode:

```bash
bash scripts/validation/validate_keycloak_ownership.sh --runtime compose --compose-mode platform --mode enforce
```

### Scenario: Bootstrap failure (fresh host)

1. Run preflight validation: `bash scripts/validation/validate_setup.sh`
2. Check the exact step that failed in the output
3. Common causes:
   - Missing binaries: install via `bash scripts/bootstrap/prerequisites.sh`
   - Missing `.env` file: copy from `infra/docker/.env.example` and fill in values
   - Docker not running: verify `docker ps` works
4. Fix the root cause and re-run: `bash scripts/bootstrap/bootstrap-all.sh`
5. Bootstrap is idempotent -- re-running skips completed steps

### Scenario: Vault is sealed / unreachable

1. Check Vault status: `vault status -address=http://localhost:8200`
2. If sealed:
   - Dev mode: restart the container -- it auto-unseals
   - Production: unseal with configured unseal keys
3. If container is down: `docker compose -f infra/docker/docker-compose.dev.yml up -d vault`
4. Wait for health: `until vault status &>/dev/null; do sleep 1; done`
5. Re-run secret seeding if needed: `bash scripts/bootstrap/init-vault.sh --seed-only`

### Scenario: Canary deployment stuck

1. Check canary pod status: `kubectl get pods -l track=canary -n medinovai-services`
2. Check pod events: `kubectl describe pod <canary-pod> -n medinovai-services`
3. Check logs: `kubectl logs -l track=canary -n medinovai-services --tail=50`
4. If CrashLoopBackOff: fix the image, rebuild, and re-deploy
5. Abort canary: `kubectl delete deployment <service>-canary -n medinovai-services`
6. The stable deployment remains untouched

### Scenario: Full service rollback

1. Single service: `bash scripts/deploy/rollback_service.sh --service <name> --environment <env>`
2. This runs `kubectl rollout undo` and waits for health
3. Verify: `kubectl rollout status deployment/<name> -n medinovai-services`
4. Check audit log: `tail -1 outputs/deploy-audit.jsonl | python3 -m json.tool`

### Scenario: Full-stack rollback (all services)

1. Identify the blast radius: which tier(s) are affected?
2. Rollback by tier in reverse order (highest tier first):
   ```bash
   for svc in $(kubectl get deployments -n medinovai-services -o name); do
     kubectl rollout undo "$svc" -n medinovai-services
   done
   ```
3. Wait for all rollouts: `kubectl rollout status deployment --all -n medinovai-services --timeout=300s`
4. Verify tier0 health: `kubectl get pods -n medinovai-data`

### Scenario: DGX node won't join cluster

1. Verify K3s server is running: `kubectl get nodes` (from the server node)
2. Verify node token exists: `cat $DEPLOY_HOME/node-token`
3. On the DGX node, check K3s agent logs: `journalctl -u k3s-agent -f`
4. Verify Tailscale connectivity: `tailscale ping <server-ip>`
5. If token mismatch: copy the correct token from server and re-run `init-dgx.sh`

### Scenario: Secret rotation emergency

1. Generate new secrets: `bash scripts/bootstrap/init-secrets.sh --cloud vault --environment production`
2. Update affected services: `kubectl rollout restart deployment -n medinovai-services`
3. Verify services come back healthy: `kubectl get pods -n medinovai-services -w`
4. Invalidate old AppRole tokens: rotate via `vault write -f auth/approle/role/<name>/secret-id`
5. Log the rotation event in `outputs/deploy-audit.jsonl`

### Scenario: Monitoring stack not collecting metrics

1. Check Prometheus is running: `kubectl get pods -n medinovai-monitoring`
2. Check Prometheus targets: `kubectl port-forward svc/prometheus -n medinovai-monitoring 9090:9090`, then visit `http://localhost:9090/targets`
3. If targets are down, check ServiceMonitor selectors match service labels
4. Check Grafana datasource: `kubectl port-forward svc/grafana -n medinovai-monitoring 3000:3000`
5. Re-deploy monitoring: `bash scripts/monitoring/setup_monitoring.sh`
