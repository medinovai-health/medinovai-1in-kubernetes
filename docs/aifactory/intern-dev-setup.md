# AIFactory — Intern Developer Setup Guide

**Audience:** New interns and developers joining MedinovAI
**Prereq:** Tailscale installed and joined to tail3b5737.ts.net
**Support:** Slack #infra or ping a power user

---

## Step 1: Join Tailscale

Ask your manager for the Tailscale invite link for `tail3b5737.ts.net`.

```bash
# macOS
brew install tailscale
sudo tailscaled &
tailscale up

# Linux
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

Verify:
```bash
tailscale status | grep aifactory
# Should see: 100.106.54.9  mayanks-mac-studio-1 ... active
```

---

## Step 2: Test Ollama Access

You should be able to hit the AIFactory inference server directly:

```bash
# Quick test — list available models
curl -s http://100.106.54.9:11434/api/tags | python3 -c \
  "import json,sys; [print(m['name']) for m in json.load(sys.stdin)['models']]"

# Test a generation
curl -s http://100.106.54.9:11434/api/generate \
  -d '{"model":"qwen3-coder:latest","prompt":"print hello world in Python","stream":false}' \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['response'])"
```

---

## Step 3: Configure Your Tools

### Claude Code

```bash
# ~/.claude/mcp.json
{
  "mcpServers": {
    "aifactory": {
      "type": "http",
      "url": "http://100.106.54.9:8434"
    }
  }
}
```

### Cursor IDE

In Settings → Models → Custom:
```
Base URL: http://100.106.54.9:11434/v1
Model: qwen3-coder:latest
API Key: (leave blank or use any string)
```

### Direct API (Python / scripts)

```python
import requests

AIFACTORY = "http://100.106.54.9:11434"

def generate(prompt: str, model: str = "qwen3-coder:latest") -> str:
    r = requests.post(f"{AIFACTORY}/api/generate", json={
        "model": model,
        "prompt": prompt,
        "stream": False
    })
    return r.json()["response"]
```

---

## Step 4: Model Routing Rules

Use the right model for the right task. **Don't use deepseek-r1:70b for formatting a docstring.**

| Task | Model to Use |
|------|-------------|
| Code edits, scaffolding, tests | `qwen3-coder:latest` ← default |
| Quick questions, summaries, docs | `phi4:14b` |
| Complex debugging, architecture | `deepseek-r1:32b` ← ask power user |
| Vision / screenshot analysis | `qwen3-vl:latest` |
| RAG / semantic search | `nomic-embed-text:latest` |
| Medical / clinical terminology | `meditron:7b` |

---

## Step 5: AGENTS.md

Every repo you work in has an `AGENTS.md` at root. Read it before starting. It defines:
- Which operations agents are allowed to do
- Coding standards (E_CONSTANTS, mos_variables)
- What branches you can write to
- When to escalate to a power user

---

## Dos and Don'ts

### ✅ Do
- Use `qwen3-coder:latest` as your default
- Run tests before requesting a PR review
- Keep prompts focused — no PHI in prompts ever
- Check model latency if something feels slow (`curl http://100.106.54.9:11434/api/ps`)

### ❌ Don't
- Send patient data, real names, or PHI to any model — even local ones
- Use 70B models for routine tasks (wastes shared VRAM)
- SSH directly into AIFactory nodes — you don't have access and don't need it
- Commit `.env` files or API keys to repos
