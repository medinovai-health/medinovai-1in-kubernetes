# Node: macbook-dev (Primary Dev Workstation)

**Role:** Developer workstation — local inference + AtlasOS dev environment
**Last Scanned:** 2026-03-15 22:00 PST

## Hardware

| Field | Value |
|-------|-------|
| Hostname | Mayank-MBP25-7472.local |
| Chip | Apple M4 Max |
| RAM | 128 GB unified memory |
| Storage | 7.3 TB (6.4 TB used — **87% ⚠️**) |
| OS | macOS 26.4 |

## Network

| Interface | Address |
|-----------|---------|
| en0 (LAN) | 10.0.0.103 |
| Tailscale | 100.79.214.33 |
| Tailscale name | medinovai-devops-mac-mayanktrivedi / mayank@ |

## Ollama

| Field | Value |
|-------|-------|
| Version | Latest (Ollama.app) |
| API | http://localhost:11434 (local only) |
| Models | 75 models / 883 GB |

## Running Docker Containers

| Container | Port | Status |
|-----------|------|--------|
| atlasos-dev-core | 8888→8000, 8889→8001, 8890→8002 | ✅ healthy |
| atlasos-dev-ui | 3737→3737 | ✅ healthy |
| atlasos-dev-mcp-gateway | 8400→8400 | ✅ healthy |
| atlasos-dev-webhook-handler | 18081→8080 | ✅ healthy |
| atlasos-dev-ai-orchestrator | 3003→3000 | ✅ healthy |
| atlasos-dev-smoke | 18000→8000, 18002→8002 | ⚠️ unhealthy |
| medinovai-atlas-dev-core | 8000-8002 | ✅ healthy |
| medinovai-atlas-dev-ui | 3000, 3737 | ✅ healthy |
| medinovai-atlas-dev-mcp-gateway | 8400 | ✅ healthy |
| medinovai-atlas-dev-webhook-handler | 8080 | ✅ healthy |
| medinovai-atlas-dev-ai-orchestrator | 3000 | ✅ healthy |
| medinovai-atlas-dev-stirling-pdf | 8080 | ✅ healthy |
| paperclip-server | 3100→3100 | ✅ healthy |
| paperclip-db (postgres:17) | 5432 | ✅ healthy |

## Model Fleet (75 models / 883 GB)

### Keep — Active Use

| Model | Size | Tier |
|-------|------|------|
| qwen3-coder:latest | 18.6 GB | 1 — Intern default |
| qwen2.5-coder:32b | 19.9 GB | 2 — Power |
| codestral:22b | 12.6 GB | 2 — Power |
| deepseek-r1:32b | 19.9 GB | 2 — Power |
| deepseek-r1:70b | 42.5 GB | 3 — Heavy |
| gpt-oss:20b | 13.8 GB | 2 — Power |
| qwen3:32b | 20.2 GB | 2 — Power |
| phi4:14b | 9.1 GB | 1 — Intern |
| gemma3:27b | 17.4 GB | 2 — Power |
| llama3.3:70b | 42.5 GB | 3 — Heavy |
| qwen2.5:72b | 47.4 GB | 3 — Heavy |
| llava:34b | 20.2 GB | Specialist — Vision |
| deepseek-ocr:latest | 6.7 GB | Specialist — OCR |
| meditron:7b | 3.8 GB | Specialist — Healthcare |
| nomic-embed-text:latest | 0.3 GB | Specialist — Embeddings |
| mxbai-embed-large:latest | 0.7 GB | Specialist — Embeddings |
| bge-m3:latest | 1.2 GB | Specialist — Embeddings |
| command-r:35b | 18.7 GB | 2 — Power |
| mistral-small:24b | 14.3 GB | 2 — Power |

### Remove — Legacy / Superseded (~220 GB freed)

```bash
ollama rm llama2:7b llama2:13b llama2:70b llama2:latest
ollama rm vicuna:latest wizardcoder:latest starcoder:latest
ollama rm falcon:40b zephyr:7b tinyllama:1.1b neural-chat:latest
ollama rm solar:10.7b bakllava:7b deepseek-coder:latest
ollama rm phi3:mini phi3:latest codellama:latest
```

## Pending Actions

- [ ] **URGENT: Free disk space** — at 87%, run legacy model removal above (~220 GB freed)
- [ ] Fix unhealthy `atlasos-dev-smoke` container: `docker logs atlasos-dev-smoke --tail 50`
- [ ] Upgrade Tailscale client: `brew upgrade tailscale` (1.86.2 → 1.94.2)
