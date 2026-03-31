# MedinovAI Agent

> **One-command install. Every machine in the network. Always stable.**

The MedinovAI Agent is a lightweight daemon that enrolls any machine (dev laptop, DGX inference node, India cloud server) into the MedinovAI infrastructure mesh — similar to how Tailscale works, but purpose-built for the MyOnsite Healthcare AI platform.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    COORDINATOR MESH (always-on)                 │
│                                                                 │
│  agent.medinovai.com ──► AWS ECS (us-east-1, primary)          │
│  agent-eu.medinovai.com ► Railway (EU, secondary)              │
│  aifactory.local:8435 ──► Mac Studio (LAN/Tailscale, local)    │
│  agent-ts.medinovai.com ► Fly.io (Tailscale egress, fallback)  │
│                                                                 │
│  All exposed via Cloudflare DNS. Client picks first healthy.   │
└───────────────────────┬─────────────────────────────────────────┘
                        │  HTTPS + HMAC token auth
          ┌─────────────┼──────────────────────────┐
          ▼             ▼                          ▼
  ┌───────────┐  ┌────────────┐           ┌──────────────┐
  │ MacBook   │  │ DGX Spark  │    ...    │ India Dev    │
  │ Dev (128GB│  │ Node (GPU) │           │ Server       │
  │ M4 Max)   │  │ Ollama+GPU │           │ Ollama tier1 │
  └───────────┘  └────────────┘           └──────────────┘
  role: power-user  role: aifactory-node   role: intern
```

Every agent:
- Sends a **heartbeat every 60s** (CPU, mem, disk, Ollama status, model list)
- **Syncs model fleet** every 5 min (pulls missing, removes retired)
- **Polls for tasks** every 30s (pull model, run script, self-update)
- Checks **security posture** (disk encryption, SSH key perms)
- Alerts via **Mattermost** on critical events
- **Self-updates** from coordinator when new version available

---

## Quick Install (Tailscale-style)

```bash
# Basic install (enroll interactively)
curl -fsSL https://agent.medinovai.com/install.sh | bash

# Automated install with token + role (CI/provisioning)
curl -fsSL https://agent.medinovai.com/install.sh | \
  MEDINOVAI_JOIN_TOKEN=<token> \
  MEDINOVAI_ROLE=intern \
  MEDINOVAI_TAGS=india,bengaluru \
  bash
```

After install, the agent runs as a background service and survives reboots automatically.

---

## Node Roles

| Role | Models | Who |
|------|--------|-----|
| `intern` | Tier 1 (qwen3:8b, phi4:14b, qwen3-coder) | 50 AI interns |
| `power-user` | Tier 1 + 2 (deepseek-r1:32b, codestral:22b) | 5 senior devs |
| `dev-machine` | Tier 1 | General dev workstations |
| `aifactory-node` | All tiers (tier 1+2+3) | DGX Spark GPU nodes |

---

## CLI Reference

```bash
# Enroll this machine (run once after install)
medinovai-agent enroll --join-token <TOKEN> --role intern

# Start daemon (normally called by launchd/systemd)
medinovai-agent run

# Check status
medinovai-agent status

# Show version
medinovai-agent version
```

---

## Directory Layout

```
infra/medinovai-agent/
├── README.md                         ← This file
├── agent/
│   └── medinovai_agent.py            ← Node agent daemon (Python, zero deps)
├── coordinator/
│   ├── main.py                       ← FastAPI coordinator server
│   ├── requirements.txt
│   ├── Dockerfile
│   ├── docker-compose.yml            ← Full stack: API + Postgres + Cloudflare Tunnel
│   └── .env.example                  ← Required secrets template
├── install/
│   └── install.sh                    ← One-liner installer (curl | bash)
└── service/
    ├── com.medinovai.agent.plist     ← macOS LaunchAgent
    └── medinovai-agent.service       ← Linux systemd unit
```

---

## Coordinator Deployment

### Option A — Self-hosted on aifactory.local (start here)

```bash
cd infra/medinovai-agent/coordinator
cp .env.example .env        # fill in secrets
docker compose up -d
docker compose logs -f coordinator
# Health check:
curl http://aifactory.local:8435/v1/health
```

Add Cloudflare Tunnel for public access:
```bash
docker compose --profile cloudflare up -d
```

### Option B — AWS ECS (production primary)

```bash
# Build and push image
docker build -t medinovai/coordinator:latest .
aws ecr get-login-password | docker login --username AWS --password-stdin <ECR_URL>
docker tag medinovai/coordinator:latest <ECR_URL>/medinovai/coordinator:latest
docker push <ECR_URL>/medinovai/coordinator:latest

# Deploy via existing ECS infrastructure in medinovai-deploy/infra/aws/
# See: infra/aws/ecs/coordinator-task-def.json (TODO: add this file)
```

### Option C — Fly.io (lightweight fallback)

```bash
cd infra/medinovai-agent/coordinator
fly launch --name medinovai-coordinator --region sin  # Singapore for India coverage
fly secrets set MEDINOVAI_JOIN_TOKEN=<token> MEDINOVAI_ADMIN_TOKEN=<token> ...
fly deploy
```

---

## Admin Operations

```bash
# List all enrolled nodes (requires MEDINOVAI_ADMIN_TOKEN)
curl -H "Authorization: Bearer <ADMIN_TOKEN>" \
  https://agent.medinovai.com/v1/nodes | jq .

# Dispatch a task to a specific node
curl -X POST \
  -H "Authorization: Bearer <ADMIN_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"target_node": "<node_id>", "type": "ollama_pull", "payload": {"model": "phi4:14b"}}' \
  https://agent.medinovai.com/v1/tasks

# Dispatch to ALL nodes (wildcard)
curl -X POST \
  -H "Authorization: Bearer <ADMIN_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"target_node": "*", "type": "shell", "payload": {"command": "ollama list"}}' \
  https://agent.medinovai.com/v1/tasks
```

---

## Pending Immediate Tasks

| Priority | Task | Blocker |
|----------|------|---------|
| 🔴 P0 | Fix Tailscale ACL — allow SSH to spark-08dd, spark-d0a6 | Manual: login.tailscale.com/admin/acls |
| 🔴 P0 | Upgrade spark-d0a6 Ollama (v0.12.7 → latest) | After ACL fix |
| 🟡 P1 | Deploy coordinator on aifactory.local | `docker compose up -d` |
| 🟡 P1 | Generate join token, distribute to team | After coordinator up |
| 🟡 P1 | MacBook disk cleanup (87% → ~65%) | `ollama rm <retired models>` |
| 🟢 P2 | Install agent on all 4 AIFactory nodes | After coordinator up |
| 🟢 P2 | Deploy coordinator to AWS ECS (primary) | DevOps ticket |
| 🟢 P2 | Configure Cloudflare Tunnel | Cloudflare dashboard |

---

## Security Notes

- **No PHI is ever sent to the coordinator.** Only machine telemetry (CPU, disk, model list).
- Node tokens are HMAC-SHA256 signed and bound to machine UUID — cannot be transferred.
- Join token is single-use per deployment (rotate after bulk enrollment).
- All coordinator traffic must be HTTPS in production (Cloudflare enforces this).
- Audit log at `~/.medinovai/audit.jsonl` satisfies 21 CFR Part 11 local record requirement.
- HIPAA: On-prem inference via Ollama means zero PHI leaves the network perimeter.

---

*MedinovAI Agent v1.0.0 · MyOnsite Healthcare · 2026-03-15*
