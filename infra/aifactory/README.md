# AIFactory — Federated LLM Inference Infrastructure

**Owner:** Mayank Trivedi (CTO)
**Last Updated:** 2026-03-15
**Status:** Active — Partial deployment (US nodes confirmed, India TBD)
**Classification:** Internal Infrastructure — Source of Truth

---

## What is AIFactory?

AIFactory is MedinovAI's **federated LLM inference layer** — a geo-distributed network of local Ollama nodes exposed as MCP (Model Context Protocol) servers. It is **not** AtlasOS.

| System | Purpose |
|--------|---------|
| **AIFactory** | Federated LLM router — local inference nodes as MCP servers, zero cloud API cost |
| **AtlasOS** | AI orchestration platform — agent workflows, task routing, Atlas agents |
| **medinovai-deploy** | This repo — source of truth for all infrastructure |

### Core Design Principle

> Developers in India should hit a local AIFactory node in India, not cross the ocean to reach a US inference server. Each AIFactory node is a standalone MCP server that exposes local Ollama models. Any team worldwide can point their tools (Cursor, Claude Code, AtlasOS, Hermes) at their nearest node.

```
Developer (India) ──► AIFactory-IN (MCP server, Ollama) ──► Local models
Developer (USA)   ──► AIFactory-US (MCP server, Ollama) ──► Local models
Developer (remote)──► AIFactory via Tailscale mesh       ──► Nearest node
```

---

## Current Node Status

| Node | Location | Hardware | RAM | Ollama | Models | Status |
|------|----------|----------|-----|--------|--------|--------|
| [aifactory-us-mac-studio](nodes/aifactory-us-mac-studio.md) | US (LAN) | Apple M3 Ultra | 512 GB | v0.15.5 | 13 | ✅ Active |
| [macbook-dev](nodes/macbook-dev.md) | US (dev) | Apple M4 Max | 128 GB | latest | 75 | ✅ Active |
| [spark-08dd](nodes/spark-08dd.md) | US (DGX) | Linux/GPU | TBD | v0.16.1 | 10 | ✅ Active |
| [spark-d0a6](nodes/spark-d0a6.md) | US (DGX) | Linux/GPU | TBD | v0.12.7 | 3 | ✅ Active |
| [spark-b587](nodes/spark-b587.md) | US (DGX) | Linux/GPU | TBD | Unknown | TBD | ⚠️ Key needed |
| spark-de04 | US (DGX) | Linux/GPU | TBD | Unknown | TBD | ❌ Offline |
| AIFactory-IN | India | TBD | TBD | — | — | 🔲 Planned |

---

## Quick Links

- [Network Topology](network/topology.md)
- [Model Fleet Standard](models/fleet-standard.md)
- [MCP Federation Design](mcp-federation/design.md)
- [Security & Access](security/access-control.md)
- [Tailscale ACL Fix](network/tailscale-acl-fix.md)
- [Intern Dev Setup](../../docs/aifactory/intern-dev-setup.md)
- [Cost Analysis](../../docs/aifactory/cost-analysis.md)

---

## Access

All nodes reachable via Tailscale mesh (`tail3b5737.ts.net`).
SSH key: `~/.ssh/id_ed25519` (mayanktrivedi@)
Ollama API: `http://<tailscale-ip>:11434`

See [security/access-control.md](security/access-control.md) for full credentials reference.
