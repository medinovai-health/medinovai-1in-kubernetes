# Node: spark-d0a6 (DGX)

**Role:** US DGX GPU inference node — Tier 2/3 heavy models
**Last Scanned:** 2026-03-15 22:05 PST

## Network

| Interface | Address |
|-----------|---------|
| Tailscale IP | 100.94.48.43 |
| Tailscale name | spark-d0a6 / n8n@ |
| Tailscale status | Active — direct to 10.0.0.180 |
| LAN IP | Unknown (behind NAT) |

## Ollama

| Field | Value |
|-------|-------|
| Version | 0.12.7 ⚠️ Very outdated — upgrade immediately |
| API (Tailscale) | http://100.94.48.43:11434 ✅ reachable |

## Models (3 installed — 67.6 GB)

| Model | Size | Added | Tier |
|-------|------|-------|------|
| qwen3:32b | 20.2 GB | 2026-02-20 | 2 — Power |
| llama3.3:70b | 42.5 GB | 2026-02-15 | 3 — Heavy |
| llama3.1:8b | 4.9 GB | 2026-02-14 | 1 — Intern |

## Hardware

| Field | Value |
|-------|-------|
| OS | Linux |
| GPU | Unknown (DGX) |
| RAM | Unknown — pending SSH access |

## SSH Access

```bash
# SSH currently blocked by Tailscale ACL policy
# Fix: update ACL at https://login.tailscale.com/admin/acls

# After ACL fix:
ssh n8n@100.94.48.43
```

## Pending Actions

- [ ] Fix Tailscale ACL to allow SSH (critical — see [../network/tailscale-acl-fix.md])
- [ ] **Upgrade Ollama immediately**: v0.12.7 is 4+ major versions behind
- [ ] Collect hardware details: `nvidia-smi`, `free -h`, `lscpu`
- [ ] Pull missing standard models: `qwen3-coder:latest`, `deepseek-r1:32b`, `qwen2.5-coder:32b`, `codestral:22b`, `gpt-oss:20b`, `nomic-embed-text:latest`
- [ ] Expose as MCP server (see [../mcp-federation/design.md])
