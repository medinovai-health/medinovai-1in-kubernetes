# Tailscale ACL Fix — Enable SSH to Spark/DGX Nodes

**Priority:** HIGH — Spark nodes unreachable via SSH until this is done
**Admin URL:** https://login.tailscale.com/admin/acls

---

## Problem

spark-08dd (100.125.48.57) and spark-d0a6 (100.94.48.43) respond with:

```
tailscale: tailnet policy does not permit you to SSH to this node
```

The `mayank@` account cannot SSH to `n8n@` nodes because no SSH ACL rule permits it.

Note: Ollama port 11434 IS accessible (Tailscale doesn't block it — only SSH action is ACL-gated).

---

## Fix

Go to https://login.tailscale.com/admin/acls and add this to the `"ssh"` array:

```json
{
  "action": "accept",
  "src":    ["autogroup:member"],
  "dst":    ["autogroup:self"],
  "users":  ["autogroup:nonroot", "root"]
}
```

**Minimal version** (if you want to only allow your account):
```json
{
  "action": "accept",
  "src":    ["mayank@myonsitehealthcare.com"],
  "dst":    ["tag:n8n"],
  "users":  ["n8n", "ubuntu", "root"]
}
```

---

## Verify Fix

After saving the policy:

```bash
# Test SSH to both blocked nodes
ssh -o ConnectTimeout=5 n8n@100.125.48.57 "hostname && uname -a && nvidia-smi"
ssh -o ConnectTimeout=5 n8n@100.94.48.43  "hostname && uname -a && nvidia-smi"
```

---

## Also: Tailscale Client Outdated

MacBook client is version 1.86.2 but server daemon is 1.94.2:

```bash
brew upgrade tailscale
```

---

## spark-b587 (100.83.165.95) — Separate Issue

This node is NOT blocked by ACL — it accepts the SSH connection but rejects the key.
The `n8n` user requires a specific SSH key that hasn't been distributed yet.

```bash
# After getting into spark-08dd or spark-d0a6, run from there:
ssh n8n@100.125.48.57 \
  "ssh-copy-id -i ~/.ssh/authorized_keys n8n@100.83.165.95"

# Or add our session key directly if you have console access:
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGoW6QduestVae+2HtaODHLUfttDRH6rXzNHNXi1J81d claude-cowork-20260315" \
  >> /home/n8n/.ssh/authorized_keys
```
