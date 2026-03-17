# Node: spark-08dd (DGX)

**Role:** US DGX GPU inference node — Tier 2/3 models
**Last Scanned:** 2026-03-15 22:05 PST

## Network

| Interface | Address |
|-----------|---------|
| Tailscale IP | 100.125.48.57 |
| Tailscale name | spark-08dd / n8n@ |
| Tailscale status | Active — direct to 10.0.0.180 |
| LAN IP | Unknown (behind NAT — 10.0.0.180 gateway) |

## Ollama

| Field | Value |
|-------|-------|
| Version | 0.16.1 |
| API (Tailscale) | http://100.125.48.57:11434 ✅ reachable |
| API (LAN) | Unknown |

## Models (10 installed — 169.4 GB)

| Model | Size | Quant | Added | Tier |
|-------|------|-------|-------|------|
| qwen3-coder:30b | 18.6 GB | Q4_K_M | 2026-02-18 | 1 — Intern |
| codestral:22b | 12.6 GB | — | 2026-02-17 | 2 — Power |
| deepseek-r1:70b | 42.5 GB | — | 2026-02-15 | 3 — Heavy |
| qwen2.5-coder:32b | 19.9 GB | — | 2026-02-16 | 2 — Power |
| qwen2.5-coder:14b | 9.0 GB | — | 2026-02-16 | 1 — Intern |
| qwen2.5:72b | 47.4 GB | — | 2026-02-15 | 3 — Heavy |
| qwen2.5:14b | 9.0 GB | — | 2026-02-16 | 1 — Intern |
| qwen2.5:7b | 4.7 GB | — | 2026-02-16 | 1 — Intern |
| qwen3:8b | 5.2 GB | — | 2026-02-17 | 1 — Intern |
| tinyllama:1.1b | 0.6 GB | — | 2026-02-16 | Legacy |

## Hardware

| Field | Value |
|-------|-------|
| OS | Linux |
| GPU | Unknown (DGX — likely A100 or H100) |
| RAM | Unknown — pending SSH access |

## SSH Access

```bash
# SSH currently blocked by Tailscale ACL policy
# Fix: update ACL at https://login.tailscale.com/admin/acls
# See: ../network/tailscale-acl-fix.md

# After ACL fix:
ssh n8n@100.125.48.57
```

## Pending Actions

- [ ] Fix Tailscale ACL to allow SSH (see [../network/tailscale-acl-fix.md])
- [ ] Collect: GPU model, VRAM, CPU, RAM via `nvidia-smi` + `free -h`
- [ ] Upgrade Ollama: v0.16.1 → latest
- [ ] Add missing standard models: `nomic-embed-text`, `gpt-oss:20b`, `phi4:14b`
- [ ] Remove: `tinyllama:1.1b` (legacy)
- [ ] Expose as MCP server (see [../mcp-federation/design.md])
