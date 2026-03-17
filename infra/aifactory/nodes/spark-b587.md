# Node: spark-b587 (DGX)

**Role:** US DGX GPU inference node
**Last Scanned:** 2026-03-15 22:05 PST

## Network

| Interface | Address |
|-----------|---------|
| Tailscale IP | 100.83.165.95 |
| Tailscale name | spark-b587 / n8n@ |
| Tailscale status | Idle |

## Ollama

| Field | Value |
|-------|-------|
| API port 11434 | ❌ Not responding on Tailscale IP |
| Version | Unknown |

## SSH Access Issue

SSH responds but rejects all credentials — node requires public key auth and no key has been distributed yet.

```bash
# To fix: push SSH key from a node that already has access
# Option A: from spark-08dd or spark-d0a6 after those are accessible:
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGoW6QduestVae+2HtaODHLUfttDRH6rXzNHNXi1J81d claude-cowork-20260315" \
  | ssh n8n@100.125.48.57 "ssh n8n@100.83.165.95 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys'"

# Option B: console/physical access to add authorized_keys directly
```

## Pending Actions

- [ ] Distribute SSH key via sibling Spark node or console access
- [ ] Inventory: hardware, GPU, RAM, OS, Ollama version
- [ ] Check if Ollama is installed/running (`curl http://localhost:11434/api/version`)
- [ ] Pull standard fleet models
- [ ] Expose as MCP server
