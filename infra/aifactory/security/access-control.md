# AIFactory Security & Access Control

**Classification:** Internal — Infrastructure Team Only
**Last Updated:** 2026-03-15

> ⚠️ Do NOT commit actual passwords or private keys to this file.
> Store secrets in the team password manager. This file documents the access pattern, not the values.

---

## Access Architecture

All AIFactory nodes are accessible exclusively via **Tailscale mesh** (`tail3b5737.ts.net`).
No AIFactory node exposes ports directly to the public internet.

```
Developer device  ──► Tailscale VPN ──► AIFactory node
                                         :11434 (Ollama API)
                                         :8434  (MCP server)
                                         :22    (SSH — admins only)
```

---

## Node Access Reference

| Node | Tailscale IP | SSH User | Auth Method | Port 11434 | Port 8434 |
|------|-------------|----------|-------------|-----------|----------|
| aifactory-us-mac-studio | 100.106.54.9 | mayanktrivedi | id_ed25519 key | ✅ open | planned |
| macbook-dev | 100.79.214.33 | mayanktrivedi | local | local only | local only |
| spark-08dd | 100.125.48.57 | n8n | key (ACL blocked) | ✅ open | planned |
| spark-b587 | 100.83.165.95 | n8n | key (not distributed) | ❌ | planned |
| spark-d0a6 | 100.94.48.43 | n8n | key (ACL blocked) | ✅ open | planned |

## SSH Keys

| Key Name | Path | Deployed To | Purpose |
|----------|------|-------------|---------|
| id_ed25519 | ~/.ssh/id_ed25519 | aifactory.local | Primary admin key |
| id_ed25519_github | ~/.ssh/id_ed25519_github | GitHub | Repo access |
| cowork_session | ~/.ssh/cowork_session | aifactory.local | Session key (2026-03-15) |

**Session key public value** (safe to commit — public key only):
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGoW6QduestVae+2HtaODHLUfttDRH6rXzNHNXi1J81d claude-cowork-20260315
```

---

## Credentials Location

All passwords and private keys are stored in **1Password / team vault**.
Reference only — do not write values here:

| Secret | Vault Entry |
|--------|------------|
| aifactory.local SSH password | `infra/aifactory-macstudio-password` |
| Spark nodes SSH password | `infra/spark-nodes-n8n-password` |
| Tailscale admin credentials | `infra/tailscale-admin` |
| Tailscale auth keys | `infra/tailscale-auth-keys` |

---

## Intern Developer Access Model

Interns **never SSH into** AIFactory nodes directly. They consume via:
1. MCP endpoint (read-only model access via tool calls)
2. Hermes Agent sandboxed workspace (Docker container, scoped to their repo branch)
3. AtlasOS task submission

```
Intern device ──► Tailscale ──► AIFactory MCP :8434 ──► Ollama (model only)
                           └──► Hermes sandbox ──► repo (branch-scoped)
```

Power users have SSH access to aifactory.local for administration.

---

## Network Security Rules

### Tailscale ACL (required state)

```json
"ssh": [
  {
    "action": "accept",
    "src":    ["autogroup:member"],
    "dst":    ["autogroup:self"],
    "users":  ["autogroup:nonroot", "root"]
  }
]
```

### Ollama Port Exposure

Ollama should only listen on `localhost` by default. For Tailscale access, bind to the Tailscale interface:

```bash
# /etc/systemd/system/ollama.service (Linux nodes)
Environment="OLLAMA_HOST=0.0.0.0:11434"
# Then firewall to Tailscale CGNAT range only:
ufw allow from 100.64.0.0/10 to any port 11434
ufw allow from 100.64.0.0/10 to any port 8434
ufw deny 11434
ufw deny 8434
```

```bash
# macOS (aifactory) — launchd plist
# /Library/LaunchDaemons/com.medinovai.ollama.plist already handles this
# Ensure OLLAMA_HOST is set in the plist environment
```

---

## Audit Requirements (HIPAA / 21 CFR Part 11)

Every request through the AIFactory MCP layer MUST log:

```json
{
  "timestamp": "ISO8601",
  "node_id": "aifactory-us-mac-studio",
  "user_id": "intern-001@myonsitehealthcare.com",
  "model": "qwen3-coder:latest",
  "prompt_tokens": 512,
  "completion_tokens": 256,
  "latency_ms": 1240,
  "repo": "medinovai-core",
  "branch": "intern/feature-xyz"
}
```

Log destination: ELK stack on aifactory (`http://10.0.0.135:9200`)
Retention: 90 days minimum (HIPAA requirement for audit trails)
