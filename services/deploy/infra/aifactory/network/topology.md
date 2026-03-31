# AIFactory Network Topology

**Last Updated:** 2026-03-15
**Tailnet:** tail3b5737.ts.net

---

## Physical Network Map

```
Internet
    │
    ▼
┌──────────────────────────────────────────────────────────────────────┐
│  HOME / OFFICE LAN — 10.0.0.x / 192.168.0.x                        │
│                                                                      │
│  Router (10.0.0.1 / 192.168.0.1)                                    │
│      │                                                               │
│      ├── MacBook Pro M4 Max (10.0.0.103 / 192.168.139.x)           │
│      │   └── Ollama :11434 (local), AtlasOS dev stack               │
│      │                                                               │
│      ├── aifactory.local M3 Ultra (10.0.0.135 / 192.168.0.10)      │
│      │   └── Ollama :11434, AtlasOS prod, 15TB storage              │
│      │                                                               │
│      ├── 10.0.0.180 — Gateway/switch to DGX subnet                 │
│      │   └── Spark/DGX nodes connect via this IP (Tailscale relay) │
│      │                                                               │
│      ├── 10.0.0.30  — Unknown device                               │
│      └── 10.0.0.71  — Dropbear SSH device (router/NAS/embedded)    │
│                                                                      │
│  192.168.0.x subnet (aifactory secondary interface):                │
│      192.168.0.20, .21, .23, .24, .26, .27 — discovered hosts      │
│      (192.168.0.21 has SSH open — possibly DGX management port)     │
└──────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│  TAILSCALE MESH — tail3b5737.ts.net                                  │
│                                                                      │
│  mayank@ account:                                                    │
│    medinovai-devops-mac (MacBook)   100.79.214.33                   │
│    mayanks-mac-studio-1 (aifactory) 100.106.54.9  ← EXIT NODE      │
│    iphone-15-pro-max                100.81.231.109                  │
│    bb12c0d180d7 (Linux container)   100.107.111.123  OFFLINE        │
│    glkvm                            100.121.97.27                   │
│                                                                      │
│  n8n@ account (Spark/DGX nodes):                                    │
│    spark-08dd  ← DGX, Ollama v0.16.1   100.125.48.57  ACTIVE       │
│    spark-b587  ← DGX, key needed       100.83.165.95  IDLE         │
│    spark-d0a6  ← DGX, Ollama v0.12.7   100.94.48.43   ACTIVE       │
│    spark-de04  ← DGX                   100.95.79.93   OFFLINE      │
│    mayanks-mac-studio (old)            100.87.47.68   OFFLINE      │
│                                                                      │
│  n8n@ account (AWS automation):                                     │
│    ip-10-158-15-194    100.96.223.57                                │
│    ip-10-158-15-222    100.107.12.91                                │
│    ip-10-158-15-92     100.86.38.120                                │
│    ip-10-158-17-74     100.76.31.105                                │
│    ip-10-158-17-8      100.123.11.83                                │
│                                                                      │
│  Other:                                                              │
│    itpc (Windows)      100.113.35.53                                │
│    mospc14 (Windows)   100.96.182.100  OFFLINE                     │
│    mohc020 (Windows)   100.64.124.104  OFFLINE                     │
└──────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│  PLANNED — AIFactory India Region                                    │
│                                                                      │
│  aifactory-india-01  ← TBD hardware                                 │
│    Ollama + MCP server                                               │
│    Tailscale connected to tail3b5737.ts.net                         │
│    Models: Tier 1 + Tier 2 (India team use)                         │
└──────────────────────────────────────────────────────────────────────┘
```

## Ollama Endpoints (confirmed reachable)

| Node | LAN | Tailscale | Status |
|------|-----|-----------|--------|
| aifactory.local | http://10.0.0.135:11434 | http://100.106.54.9:11434 | ✅ |
| spark-08dd | — | http://100.125.48.57:11434 | ✅ |
| spark-d0a6 | — | http://100.94.48.43:11434 | ✅ |
| macbook (local) | http://localhost:11434 | http://100.79.214.33:11434 | ✅ local |
| spark-b587 | — | http://100.83.165.95:11434 | ❌ no response |

## Important IPs to Know

| IP | Machine | Notes |
|----|---------|-------|
| 10.0.0.1 | Router | Default gateway, LAN |
| 10.0.0.103 | MacBook | Dev workstation |
| 10.0.0.135 | aifactory.local | Primary inference server |
| 10.0.0.180 | Unknown | DGX nodes relay via this IP over Tailscale WireGuard |
| 192.168.0.10 | aifactory.local | Secondary interface |
| 192.168.0.21 | Unknown | SSH port open — possibly DGX mgmt |
| 100.106.54.9 | aifactory Tailscale | Offers Tailscale exit node |
