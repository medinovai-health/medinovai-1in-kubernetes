# AIFactory Model Fleet Standard

**Version:** 1.0
**Last Updated:** 2026-03-15
**Owner:** CTO (Mayank Trivedi)

---

## Design Rule: 3 Tiers, Not 75 Models

Having 70+ models available sounds like abundance. In practice it creates:
- Unpredictable routing (interns pick random models)
- Poor VRAM cache hit rates (models constantly cold-loaded)
- No quality baseline for code review
- Wasted disk space on superseded models

**Rule:** Every AIFactory node routes from exactly 3 tiers + specialists.

---

## Tier 1 — Intern Default (fast, good enough for 70% of tasks)

| Model | Size | Use |
|-------|------|-----|
| `qwen3-coder:latest` | 18 GB | **Default for all intern code tasks** — edits, scaffolding, test gen, docs |
| `phi4:14b` | 9 GB | Fast general helper — summaries, formatting, quick Q&A |
| `qwen3:8b` | 5 GB | Ultra-fast lightweight — trivial tasks, health checks |

**Who uses:** All 50 interns. Agents default to this tier unless escalated.

---

## Tier 2 — Power User (stronger reasoning, complex tasks)

| Model | Size | Use |
|-------|------|-----|
| `qwen2.5-coder:32b` | 20 GB | Complex code generation, architecture decisions |
| `deepseek-r1:32b` | 20 GB | Debugging, root cause analysis, reasoning chains |
| `gpt-oss:20b` | 14 GB | Agent/tool-use tasks, multi-step planning |
| `qwen3:32b` | 20 GB | Long-form analysis, design docs, structured output |
| `codestral:22b` | 13 GB | Secondary coder, Mistral-family cross-check |

**Who uses:** 5 power users. Interns can request escalation.

---

## Tier 3 — Heavy Review (strongest, used sparingly)

| Model | Size | Use |
|-------|------|-----|
| `deepseek-r1:70b` | 43 GB | Hardest bugs, security audit, architecture review |
| `llama3.3:70b` | 43 GB | Frontier alternative for cross-validation |
| `qwen2.5:72b` | 47 GB | Long-context repo-wide analysis |

**Who uses:** Power users only. Only on nodes with sufficient VRAM/RAM (512 GB Mac Studio, DGX nodes).

---

## Specialists (all nodes)

| Model | Size | Use |
|-------|------|-----|
| `qwen3-vl:latest` | — | Vision: UI screenshots, diagram reading, doc images |
| `deepseek-ocr:latest` | 7 GB | OCR pipeline for scanned medical/lab documents |
| `meditron:7b` | 4 GB | Healthcare domain NLP, clinical terminology |
| `nomic-embed-text:latest` | 0.3 GB | **Primary embeddings** — RAG, code search, semantic retrieval |
| `mxbai-embed-large:latest` | 0.7 GB | Secondary embeddings, higher dimension |

---

## Node Placement Matrix

| Model | aifactory (512GB) | MacBook (128GB) | spark-08dd (DGX) | spark-d0a6 (DGX) | India (planned) |
|-------|:-----------------:|:---------------:|:----------------:|:----------------:|:---------------:|
| qwen3-coder:latest | ✅ | ✅ | ✅ | pull | ✅ |
| phi4:14b | pull | ✅ | pull | pull | ✅ |
| qwen3:8b | ✅ | ✅ | ✅ | pull | ✅ |
| qwen2.5-coder:32b | ✅ | ✅ | ✅ | pull | ✅ |
| deepseek-r1:32b | pull | ✅ | — | pull | optional |
| gpt-oss:20b | ✅ | ✅ | — | — | optional |
| qwen3:32b | pull | ✅ | — | ✅ | optional |
| codestral:22b | pull | ✅ | ✅ | pull | optional |
| deepseek-r1:70b | pull | ✅ | ✅ | — | ❌ too large |
| llama3.3:70b | pull | ✅ | — | ✅ | ❌ too large |
| qwen2.5:72b | ✅ | ✅ | ✅ | — | ❌ too large |
| qwen3-vl:latest | ✅ | ✅ | — | — | optional |
| deepseek-ocr:latest | pull | ✅ | — | — | optional |
| meditron:7b | pull | ✅ | — | — | ✅ |
| nomic-embed-text | ✅ | ✅ | pull | pull | ✅ |
| mxbai-embed-large | pull | ✅ | pull | pull | optional |

Legend: ✅ = present, `pull` = missing/needs pull, `—` = not needed on this node

---

## Models to Retire from Routing (do not delete immediately — archive first)

These are superseded. Remove from routing configuration; delete after 30-day freeze:

```
llama2:7b, llama2:13b, llama2:70b, llama2:latest
vicuna:latest
wizardcoder:latest
starcoder:latest
falcon:40b
zephyr:7b
tinyllama:1.1b
neural-chat:latest
solar:10.7b
bakllava:7b
deepseek-coder:latest  (776MB stub version)
codellama:latest       (3.8GB stub version)
phi3:mini, phi3:latest
nous-hermes:13b
```

Estimated disk reclaim on MacBook: **~220 GB**

---

## One-Liner: Pull Standard Fleet on Any Node

```bash
# Tier 1 + embeddings (safe on all nodes)
for m in qwen3-coder:latest phi4:14b qwen3:8b nomic-embed-text:latest mxbai-embed-large:latest; do
  ollama pull $m
done

# Tier 2 (nodes with >64GB RAM)
for m in qwen2.5-coder:32b deepseek-r1:32b gpt-oss:20b qwen3:32b codestral:22b; do
  ollama pull $m
done

# Tier 3 (nodes with >256GB RAM or GPU with >80GB VRAM)
for m in deepseek-r1:70b llama3.3:70b qwen2.5:72b; do
  ollama pull $m
done
```
