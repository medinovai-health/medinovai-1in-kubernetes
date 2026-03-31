# AIFactory — Federated MCP Server Design

**Version:** 1.0
**Last Updated:** 2026-03-15
**Status:** Architecture approved — implementation pending

---

## Problem Statement

A developer in India using Claude Code, Cursor, or AtlasOS should not have to send every LLM request across the Pacific to reach a US-based inference server. That is:
- ~200-400ms added latency per request
- Data sovereignty risk (PHI/code transiting international networks)
- Single point of failure
- Unnecessary bandwidth cost

**Solution:** Each AIFactory node runs as an independent MCP server exposing its local Ollama fleet. Developers connect to their nearest node. All nodes are in sync on model standards. No central dependency.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    DEVELOPER TOOLS                               │
│   Claude Code  │  Cursor  │  AtlasOS  │  Hermes  │  Custom     │
└────────┬───────────────┬──────────────┬──────────────┬──────────┘
         │               │              │              │
         ▼               ▼              ▼              ▼
┌────────────────────────────────────────────────────────────────┐
│              MCP CLIENT ROUTING LAYER                           │
│   Reads: ~/.config/aifactory/endpoints.json                     │
│   Picks nearest healthy endpoint via latency probe              │
│   Falls back to secondary if primary fails                       │
└────────────────────────┬───────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         ▼               ▼               ▼
┌────────────────┐ ┌─────────────────┐ ┌──────────────────────┐
│ AIFactory-US   │ │ AIFactory-IN    │ │ AIFactory-DGX        │
│ aifactory.local│ │ (planned)       │ │ spark-08dd           │
│ 10.0.0.135     │ │ India DC/cloud  │ │ 100.125.48.57        │
│ MCP :8434      │ │ MCP :8434       │ │ MCP :8434            │
│ Ollama :11434  │ │ Ollama :11434   │ │ Ollama :11434        │
│ 512GB M3 Ultra │ │ TBD hardware    │ │ DGX GPU node         │
└────────┬───────┘ └────────┬────────┘ └──────────┬───────────┘
         │                  │                      │
         ▼                  ▼                      ▼
   [Ollama models]    [Ollama models]        [Ollama models]
   Tier 1+2+3         Tier 1+2               Tier 1+2+3
   qwen3-coder        qwen3-coder            qwen3-coder
   deepseek-r1:70b    qwen2.5-coder:32b      deepseek-r1:70b
   ...full fleet      ...India fleet         ...DGX fleet
```

---

## MCP Server Implementation

Each AIFactory node runs `ollama-mcp-server` — a thin MCP adapter in front of the local Ollama API.

### Install on a node

```bash
# Install via npm (Node.js required)
npm install -g @medinovai/aifactory-mcp-server

# Or use the reference implementation
git clone https://github.com/medinovai-health/aifactory-mcp-server
cd aifactory-mcp-server
npm install && npm start
```

### Configuration (`/etc/aifactory/config.json`)

```json
{
  "node_id": "aifactory-us-mac-studio",
  "region": "us-west",
  "ollama_base_url": "http://localhost:11434",
  "mcp_port": 8434,
  "allowed_origins": ["*"],
  "auth": {
    "method": "tailscale_identity",
    "fallback": "api_key"
  },
  "model_routing": {
    "intern": "qwen3-coder:latest",
    "power_user": "deepseek-r1:32b",
    "heavy": "deepseek-r1:70b",
    "vision": "qwen3-vl:latest",
    "embeddings": "nomic-embed-text:latest"
  },
  "rate_limits": {
    "intern_requests_per_minute": 30,
    "power_user_requests_per_minute": 120
  }
}
```

### MCP Tools Exposed by Each Node

| Tool | Description |
|------|-------------|
| `generate` | Text/code generation with model routing |
| `embed` | Generate embeddings for RAG |
| `list_models` | Available models on this node |
| `node_health` | RAM, GPU, load, latency |
| `pull_model` | Pull a model (power user only) |

---

## Client Configuration

Each developer configures their tools once. The MCP client auto-selects nearest healthy node.

### `~/.config/aifactory/endpoints.json`

```json
{
  "default_region": "auto",
  "endpoints": [
    {
      "id": "aifactory-us",
      "region": "us-west",
      "url": "http://100.106.54.9:8434",
      "priority": 1,
      "tailscale_only": true
    },
    {
      "id": "aifactory-dgx-08dd",
      "region": "us-west",
      "url": "http://100.125.48.57:8434",
      "priority": 2,
      "tailscale_only": true
    },
    {
      "id": "aifactory-dgx-d0a6",
      "region": "us-west",
      "url": "http://100.94.48.43:8434",
      "priority": 3,
      "tailscale_only": true
    },
    {
      "id": "aifactory-india",
      "region": "ap-south",
      "url": "http://aifactory-in.tail3b5737.ts.net:8434",
      "priority": 1,
      "tailscale_only": true,
      "status": "planned"
    }
  ],
  "fallback_behavior": "next_priority",
  "health_check_interval_sec": 30,
  "timeout_ms": 5000
}
```

### Claude Code / MCP config (`~/.claude/mcp.json`)

```json
{
  "mcpServers": {
    "aifactory": {
      "command": "npx",
      "args": ["@medinovai/aifactory-mcp-client", "--config", "~/.config/aifactory/endpoints.json"]
    }
  }
}
```

### Cursor / VSCode (`settings.json`)

```json
{
  "cursor.mcp.servers": {
    "aifactory": {
      "url": "http://100.106.54.9:8434",
      "transport": "http"
    }
  }
}
```

---

## India Node — Setup Guide (Planned)

When the India hardware is provisioned:

```bash
# 1. Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh
systemctl enable ollama && systemctl start ollama

# 2. Join Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up --authkey <TAILSCALE_AUTH_KEY> --hostname aifactory-india-01

# 3. Pull India fleet (Tier 1 + Tier 2 only — no 70B models unless hardware supports)
for m in qwen3-coder:latest phi4:14b qwen3:8b qwen2.5-coder:32b \
          qwen3:32b gpt-oss:20b codestral:22b meditron:7b \
          nomic-embed-text:latest mxbai-embed-large:latest; do
  ollama pull $m
done

# 4. Install MCP server
npm install -g @medinovai/aifactory-mcp-server
aifactory-mcp-server --config /etc/aifactory/config.india.json

# 5. Open firewall for Tailscale peers on port 8434 and 11434
ufw allow from 100.64.0.0/10 to any port 8434
ufw allow from 100.64.0.0/10 to any port 11434
```

---

## Security Model

- All AIFactory MCP endpoints are **Tailscale-only** — not exposed to public internet
- Authentication via Tailscale identity (no passwords for node-to-node)
- Developer API keys for client identification and rate limiting
- No PHI ever sent to AIFactory — it processes code and queries only
- Audit log: every request logged with: user, model, token count, latency, node

---

## Monitoring

Each node exposes Prometheus metrics at `:9090/metrics`:

```
aifactory_requests_total{model, user_tier, region}
aifactory_request_duration_ms{model, p50, p95, p99}
aifactory_model_load_time_ms{model}
aifactory_active_runners{model}
aifactory_vram_used_gb
aifactory_queue_depth
```

Centralised Grafana dashboard: `http://10.0.0.135:3000/d/aifactory`

---

## Rollout Phases

| Phase | What | Target Date |
|-------|------|-------------|
| 1 | US nodes only: aifactory + spark-08dd as MCP servers | 2026-04-01 |
| 2 | Hermes + intern sandboxes wired to AIFactory MCP | 2026-04-15 |
| 3 | India node provisioned and joined to mesh | 2026-05-01 |
| 4 | Auto-routing client deployed to all 55 developers | 2026-05-15 |
| 5 | Monitoring dashboards + cost tracking live | 2026-06-01 |
