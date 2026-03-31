# Automation Patterns Guide

How to add new hooks, cron jobs, skills, and agents to your MedinovAI Atlas setup.

---

## Pattern 1: Adding a New Webhook Hook

Hooks let external systems trigger MedinovAI Atlas workflows via HTTP POST.

### Steps

1. **Define the hook mapping** in `config/atlas.json5` under `hooks.mappings`:

```json5
{
  match: { path: "my-new-hook" },
  action: "agent",
  agentId: "ops",       // Which agent handles this
  deliver: true,        // Post result to Slack
}
```

2. **Create the normalized event schema** your system will POST:

```json
{
  "event_type": "my_system.event_name",
  "occurred_at": "2026-02-14T12:00:00Z",
  "source": "my_system",
  "entity": { "type": "item", "id": "123" },
  "data": { "key": "value" }
}
```

3. **Test the hook**:

```bash
curl -X POST "http://localhost:18789/hooks/my-new-hook?token=$HOOKS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"event_type": "test", "data": {}}'
```

4. **(Optional) Add a skill** to handle the event with structured logic — see Pattern 3.

### Best Practices
- Always include `event_type` and `occurred_at` in payloads.
- Use `allowedSessionKeyPrefixes` to scope sessions.
- Log every event to `outputs/events/` for audit.

---

## Pattern 2: Adding a New Cron Job

Cron jobs run on a precise schedule (UTC or timezone-aware).

### Steps

1. **Register via CLI** (gateway must be running):

```bash
atlas cron add \
  --name "My scheduled task" \
  --cron "0 9 * * 1-5" \
  --tz "America/New_York" \
  --session isolated \
  --message "Describe what the agent should do in plain English." \
  --announce \
  --channel slack \
  --to "channel:C_YOUR_CHANNEL_ID"
```

2. **Verify it's registered**:

```bash
atlas cron list
atlas cron status
```

3. **Check runs**:

```bash
atlas cron runs --id <job-id> --limit 10
```

### Cron vs Heartbeat

| Feature | Cron | Heartbeat |
|---------|------|-----------|
| Timing | Exact schedule | Periodic (e.g., every 30m) |
| Session | Isolated (new each run) | Continues existing session |
| Use case | Reports, batch jobs | Monitoring, checks |
| Config | CLI `atlas cron add` | `HEARTBEAT.md` in workspace |

### Best Practices
- Use `--session isolated` so each run starts fresh.
- Set `maxConcurrentRuns` to prevent overlap.
- Use timezone-aware schedules for business-hour jobs.
- Add `--announce` to post to Slack when the job runs.

---

## Pattern 3: Adding a New Skill

Skills are reusable automation modules that live in agent workspaces.

### Steps

1. **Create the skill directory**:

```bash
mkdir -p workspaces/<agent>/skills/<skill-name>/
```

2. **Write the SKILL.md** file:

```markdown
---
name: my-skill
description: One-line description of what this skill does.
inputs:
  - input_name (description)
outputs:
  - output description
failure_modes:
  - What happens on error
requires_approval: false
---

You are the **my-skill** skill.

## Steps
1. First step...
2. Second step...
3. Output result.

## Rules
- Rule 1...
- Rule 2...
```

3. **(Optional) Add a supporting script**:

```bash
# workspaces/<agent>/scripts/my_script.py
#!/usr/bin/env python3
# Accepts --json-in, outputs JSON to stdout
```

4. **Deploy** the skill to the agent workspace:

```bash
cp -r workspaces/<agent>/skills/<skill-name>/ ~/.atlas/workspace-<agent>/skills/
```

### Skill Checklist
Before deploying any skill, verify:

- [ ] **Permissions**: What tools/APIs does it need?
- [ ] **Data access**: What data does it read/write?
- [ ] **Approval needs**: Which actions require human approval?
- [ ] **Logging**: Does it log its outputs for audit?
- [ ] **Failure modes**: Are error cases handled gracefully?
- [ ] **Output schema**: Is the JSON output documented?

### Skill Precedence
1. `<workspace>/skills/` (highest — per-agent overrides)
2. `~/.atlas/skills/` (shared across agents)
3. Bundled skills (lowest — MedinovAI Atlas defaults)

---

## Pattern 4: Adding a New Agent

Agents are specialized bots with their own workspace, tools, and routing rules.

### Steps

1. **Create the workspace**:

```bash
mkdir -p ~/.atlas/workspace-newagent/{skills,scripts,logs,outputs,state,config}
```

2. **Add workspace files**:
   - `AGENTS.md` — Operating rules for this agent
   - `TOOLS.md` — Tool access and safety rules
   - (Optional) `SOUL.md` — Voice and tone
   - (Optional) `HEARTBEAT.md` — Periodic checks

3. **Register the agent** in `config/atlas.json5`:

```json5
// Under agents.list:
{ id: "newagent", workspace: "~/.atlas/workspace-newagent" },
```

4. **Or register via CLI**:

```bash
atlas agents add newagent \
  --workspace ~/.atlas/workspace-newagent \
  --model anthropic/claude-opus-4-6 \
  --non-interactive --json
```

5. **Add routing** so messages reach the right agent:
   - In `atlas.json5`, add a binding:
     ```json5
     { channel: "slack", match: { channelId: "C_NEW_CHANNEL" }, agentId: "newagent" },
     ```
   - Or add a hook mapping for webhook-driven activation.

---

## Pattern 5: Building a Approval Pipeline Approval Pipeline

Approval Pipeline provides deterministic, resumable, approval-gated workflows.

### Steps

1. **Define the pipeline steps** — each step is a small script or tool call that outputs JSON.

2. **Add approval gates** before any side-effect steps (send, deploy, pay, delete).

3. **Set timeouts and output caps** to keep runs safe.

4. **Example workflow**: Draft email → Preview → Approve → Send → Log

### Best Practices
- Every step should be idempotent where possible.
- Use resume tokens so interrupted pipelines can continue.
- Log the full pipeline trace for audit.

---

## Pattern 6: Event-Driven Company Automation

Combine hooks, skills, and agents for end-to-end event processing.

### Architecture

```
External System → POST /hooks/<name> → MedinovAI Atlas Gateway
  → Route to Agent (by hook mapping)
  → Agent loads Skill (from workspace)
  → Skill runs Script (exec sandbox)
  → Output → Slack notification + workspace log
```

### Example: New Lead Processing

1. CRM fires webhook on lead creation → POST `/hooks/sales`
2. Sales agent receives the event payload
3. `sales-copilot` skill enriches the lead (web research)
4. Drafts a personalized first-touch email
5. Posts draft to #sales for approval
6. On approval, sends email and logs to CRM

### Event Schema Standard

All inbound webhooks should conform to:

```json
{
  "event_type": "namespace.event_name",
  "occurred_at": "ISO-8601",
  "source": "system_name",
  "entity": { "type": "entity_type", "id": "entity_id" },
  "data": {}
}
```

This makes routing, logging, and debugging consistent across all integrations.

---

## Pattern 7: Adding a Quality Gate to a Skill

Quality gates validate skill output completeness before delivery.

### Steps

1. **Add quality_gate to the skill YAML front matter**:

```yaml
quality_gate:
  min_completeness: 0.8
  required_fields: ["field1", "field2", "field3"]
  consecutive_failures_to_rollback: 3
```

2. **Define required fields** — these are checked in the skill's output JSON.

3. **Set failure threshold** — after N consecutive failures, the skill enters rollback mode (uses last known-good output or degrades gracefully).

### Best Practices
- Set `min_completeness` to 0.8 or higher for critical skills.
- Keep `required_fields` specific to the skill's deliverables.
- Use `consecutive_failures_to_rollback: 3` as a safe default.
- Quality gates are checked automatically — no manual intervention needed unless rollback triggers.

---

## Pattern 8: Adding Memory to an Agent

Memory lets agents retain context across sessions for better performance.

### Steps

1. **Create memory files** in the agent's workspace:

```bash
mkdir -p workspaces/<agent>/state/memory/
```

Create four JSON files:
- `world.json` — company knowledge, configurations
- `experiences.json` — past executions and outcomes
- `entities.json` — people, systems, recurring issues
- `beliefs.json` — hypotheses about what works

2. **Add the Memory Protocol** to the agent's `AGENTS.md`:

```markdown
## Memory Protocol (Retain / Recall / Reflect)
- **Retain**: Store key learnings after each task.
- **Recall**: Retrieve relevant memories before executing skills.
- **Reflect**: Weekly, consolidate patterns into beliefs.
```

3. **Configure memory** in `config/atlas.json5`:

```json5
memory: {
  enabled: true,
  retain_after_session: true,
  recall_top_k: 5,
  reflect_schedule: "weekly",
  tenant_scoped: true,
}
```

### Best Practices
- Keep memories factual — no opinions or speculation.
- Prune stale memories during weekly reflection.
- Scope memories to the tenant (never cross-contaminate).
- Beliefs should be testable hypotheses, not assumptions.

---

## Pattern 9: Postmortem Crystallization

Convert incident postmortems into operational improvements automatically.

### Steps

1. **Write a postmortem** following the standard template (`templates/postmortem.md`).

2. **Trigger the crystallizer** skill:

```bash
atlas skill run postmortem-crystallizer --path outputs/postmortems/<incident_id>.md
```

3. **The skill will**:
   - Extract lessons learned
   - Classify each as: mistake-note, skill-update, heartbeat-check, or monitoring-rule
   - Generate draft updates
   - Submit via Approval Pipeline for approval

4. **Review and approve** the draft updates in Slack.

5. **On approval**, changes are applied to the relevant workspace files.

### What Gets Updated
| Classification | Target |
|----------------|--------|
| mistake-note | `MISTAKES.md` for the relevant agent |
| skill-update | The affected skill's `SKILL.md` |
| heartbeat-check | The agent's `HEARTBEAT.md` |
| monitoring-rule | Threshold configs or alerting rules |

### Best Practices
- Run crystallization within 48 hours of incident close (while context is fresh).
- Review all auto-generated updates — they are drafts, not final.
- Track crystallization effectiveness in `state/crystallization_log.json`.
