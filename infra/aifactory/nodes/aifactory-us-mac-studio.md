# Node: aifactory-us-mac-studio

**Role:** Primary US inference server — AIFactory main node
**Last Scanned:** 2026-03-15 22:00 PST

## Hardware

| Field | Value |
|-------|-------|
| Hostname | aifactory.local |
| Chip | Apple M3 Ultra |
| RAM | 512 GB unified memory |
| Storage | 15 TB (6.7 TB used / 46%) |
| OS | macOS 26.3 (Build 25D125) |
| Serial | JWNCG4LPWL |

## Network

| Interface | Address |
|-----------|---------|
| en0 (primary) | 192.168.0.10 |
| en1 (LAN) | 10.0.0.135 |
| Tailscale (utun4) | 100.106.54.9 |
| Tailscale name | mayanks-mac-studio-1 / macstudio@ |
| Tailscale role | **Exit node** (offers exit to full internet) |

## Ollama

| Field | Value |
|-------|-------|
| Version | 0.15.5 (via Homebrew) — needs upgrade |
| API | http://10.0.0.135:11434 (LAN) |
| API | http://100.106.54.9:11434 (Tailscale) |
| Install path | /opt/homebrew/opt/ollama |
| Model storage | /Users/mayanktrivedi/.ollama/models/ (97 GB) |

## Models (13 installed)

| Model | Size | Tier | Purpose |
|-------|------|------|---------|
| qwen3-coder:latest | 18 GB | 1 — Intern | Primary coding default |
| qwen2.5-coder:32b | 19 GB | 2 — Power | Complex code generation |
| qwen2.5:32b | 19 GB | 2 — Power | General reasoning |
| qwen2.5:14b | 9 GB | 1 — Intern | Mid-size general |
| qwen2.5:7b | 4.7 GB | 1 — Intern | Fast general |
| qwen3-vl:latest | — | Specialist | Vision / screenshots |
| qwen3:8b | 5.2 GB | 1 — Intern | Fast general |
| gpt-oss:20b | 13 GB | 2 — Power | Agent/tool use |
| llama3.1:8b | 4.9 GB | 1 — Intern | Fallback |
| qwen2.5:1.5b | 1 GB | 1 — Intern | Ultra-fast |
| qwen2.5:0.5b | 0.5 GB | 1 — Intern | Tiny/edge |
| smollm2:360m | 0.2 GB | 1 — Intern | Tiny/test |
| nomic-embed-text:latest | 0.3 GB | Specialist | Embeddings / RAG |

## Models to Pull (Missing from standard fleet)

```bash
# Run after Docker redeploy settles
ollama pull phi4:14b
ollama pull deepseek-r1:32b
ollama pull deepseek-r1:70b
ollama pull qwen3:32b
ollama pull codestral:22b
ollama pull llama3.3:70b
ollama pull meditron:7b
ollama pull mxbai-embed-large:latest
ollama pull deepseek-ocr:latest
```

## Running Services

| Service | Status | Notes |
|---------|--------|-------|
| Ollama | ✅ Running (PID 84073) | 3 model runners active |
| Docker Desktop | ⚠️ Daemon redeploying | App installed, daemon restarting |
| Atlas OS | ✅ Workspaces active | .atlas/, .atlas-backups/ |
| Daily backup cron | ✅ Running | 3am, writes to .atlas-backups/ |

## Atlas OS Workspaces

- `/Users/mayanktrivedi/.atlas/workspace-main/` — Main Atlas workspace
- `/Users/mayanktrivedi/.atlas/workspace-ceo/` — CEO assistant workspace
- `/Users/mayanktrivedi/.atlas-backups/` — Daily automated backups (since 2026-02-25)

## SSH Access

```bash
# Via LAN (fastest)
ssh mayanktrivedi@10.0.0.135

# Via Tailscale (remote)
ssh mayanktrivedi@100.106.54.9

# Via hostname
ssh aifactory
```

## Ollama Commands

```bash
# Check running models
curl -s http://10.0.0.135:11434/api/ps | jq '.models[].name'

# List all models
curl -s http://10.0.0.135:11434/api/tags | jq -r '.models[].name'

# Pull missing standard models
ssh mayanktrivedi@10.0.0.135 \
  "for m in phi4:14b deepseek-r1:32b qwen3:32b codestral:22b deepseek-r1:70b llama3.3:70b meditron:7b mxbai-embed-large:latest deepseek-ocr:latest; do ollama pull \$m; done"
```

## Pending Actions

- [ ] Upgrade Ollama: `brew upgrade ollama` (0.15.5 → latest)
- [ ] Pull 9 missing standard-fleet models (see above)
- [ ] Verify Docker redeploy completes successfully
- [ ] Install Hermes Agent (see [../../docs/aifactory/hermes-setup.md])
- [ ] Expose Ollama as MCP server (see [../mcp-federation/design.md])
