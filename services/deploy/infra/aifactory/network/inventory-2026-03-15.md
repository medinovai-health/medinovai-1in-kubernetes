# Network Inventory Snapshot — 2026-03-15

**Scanned by:** Claude (Cowork session via Desktop Commander)
**Time:** 22:05 PST
**Method:** Live SSH + Ollama API + Tailscale status

This is a point-in-time snapshot. For current state, re-run:
```bash
./infra/aifactory/scripts/health-check.sh
```

---

## Confirmed Ollama Nodes

| Node | IP | Ollama Ver | Models | Total Size | RAM | Chip |
|------|----|-----------|--------|-----------|-----|------|
| aifactory.local | 10.0.0.135 / 100.106.54.9 | 0.15.5 | 13 | 97 GB | 512 GB | M3 Ultra |
| macbook-dev | 10.0.0.103 / 100.79.214.33 | latest | 75 | 883 GB | 128 GB | M4 Max |
| spark-08dd | 100.125.48.57 | 0.16.1 | 10 | 169 GB | TBD | DGX/GPU |
| spark-d0a6 | 100.94.48.43 | 0.12.7 | 3 | 68 GB | TBD | DGX/GPU |

**Total confirmed model storage across fleet: ~1,217 GB / ~1.2 TB**

---

## spark-08dd Models (Ollama v0.16.1)

| Model | Size | Quant | Date Added |
|-------|------|-------|-----------|
| qwen3-coder:30b | 18.6 GB | Q4_K_M | 2026-02-18 |
| deepseek-r1:70b | 42.5 GB | — | 2026-02-15 |
| qwen2.5:72b | 47.4 GB | — | 2026-02-15 |
| codestral:22b | 12.6 GB | — | 2026-02-17 |
| qwen2.5-coder:32b | 19.9 GB | — | 2026-02-16 |
| qwen2.5-coder:14b | 9.0 GB | — | 2026-02-16 |
| qwen2.5:14b | 9.0 GB | — | 2026-02-16 |
| qwen2.5:7b | 4.7 GB | — | 2026-02-16 |
| qwen3:8b | 5.2 GB | — | 2026-02-17 |
| tinyllama:1.1b | 0.6 GB | — | 2026-02-16 |

---

## spark-d0a6 Models (Ollama v0.12.7 — OUTDATED)

| Model | Size | Date Added |
|-------|------|-----------|
| qwen3:32b | 20.2 GB | 2026-02-20 |
| llama3.3:70b | 42.5 GB | 2026-02-15 |
| llama3.1:8b | 4.9 GB | 2026-02-14 |

---

## aifactory.local Models (Ollama v0.15.5)

| Model | Size |
|-------|------|
| qwen3-coder:latest | 18 GB |
| qwen2.5-coder:32b | 19 GB |
| qwen2.5:32b | 19 GB |
| qwen2.5:14b | 9 GB |
| qwen2.5:7b | 4.7 GB |
| qwen2.5:1.5b | 1 GB |
| qwen2.5:0.5b | 0.5 GB |
| qwen3-vl:latest | — |
| qwen3:8b | 5.2 GB |
| gpt-oss:20b | 13 GB |
| llama3.1:8b | 4.9 GB |
| smollm2:360m | 0.2 GB |
| nomic-embed-text:latest | 0.3 GB |

---

## Unreachable / Pending Nodes

| Node | IP | Issue | Resolution |
|------|----|-------|-----------|
| spark-b587 | 100.83.165.95 | SSH key not distributed, Ollama port closed | Distribute key from sibling node |
| spark-de04 | 100.95.79.93 | Offline | Check physical power/network |
| 192.168.0.21 | — | SSH open, identity unknown | Probe from aifactory |

---

## Tailscale Network Devices (Full)

| Hostname | IP | OS | Account | Status |
|----------|----|----|---------|--------|
| medinovai-devops-mac-mayanktrivedi | 100.79.214.33 | macOS | mayank@ | Active |
| mayanks-mac-studio-1 (aifactory) | 100.106.54.9 | macOS | macstudio@ | Active (exit node) |
| spark-08dd | 100.125.48.57 | Linux | n8n@ | Active |
| spark-b587 | 100.83.165.95 | Linux | n8n@ | Idle |
| spark-d0a6 | 100.94.48.43 | Linux | n8n@ | Active |
| spark-de04 | 100.95.79.93 | Linux | n8n@ | Offline |
| glkvm | 100.121.97.27 | Linux | mayank@ | Idle |
| bb12c0d180d7 | 100.107.111.123 | Linux | mayank@ | Offline |
| iphone-15-pro-max | 100.81.231.109 | iOS | mayank@ | Idle |
| itpc | 100.113.35.53 | Windows | n8n@ | Idle |
| mospc14 | 100.96.182.100 | Windows | n8n@ | Offline |
| mohc020 | 100.64.124.104 | Windows | n8n@ | Offline |
| mayanks-mac-studio (old) | 100.87.47.68 | macOS | n8n@ | Offline |
| ip-10-158-15-194 | 100.96.223.57 | Linux | n8n@ | Idle (AWS n8n) |
| ip-10-158-15-222 | 100.107.12.91 | Linux | n8n@ | Idle (AWS n8n) |
| ip-10-158-15-92 | 100.86.38.120 | Linux | n8n@ | Idle (AWS n8n) |
| ip-10-158-17-74 | 100.76.31.105 | Linux | n8n@ | Idle (AWS n8n) |
| ip-10-158-17-8 | 100.123.11.83 | Linux | n8n@ | Idle (AWS n8n) |
