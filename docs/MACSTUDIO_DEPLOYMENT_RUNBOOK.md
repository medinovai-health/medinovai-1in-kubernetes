# AIFactory MacStudio Deployment Runbook
## MedinovAI — Astra v2.0.0 + Deploy v2.0.0

**Date:** April 14, 2026  
**Author:** Manus AI Agent  
**Status:** Production-Ready  

---

## Critical Context

The containers on MacStudio run under the `aifactory-medinovai` user, **not** `mayanktrivedi`. All deployment commands must be run as that user. The deploy directories are:

| Service | Port | Directory |
|---------|------|-----------|
| Astra | 36800 | `/Users/aifactory-medinovai/medinovai/medinovai-2ag-astra/` |
| Deploy | 36900 | `/Users/aifactory-medinovai/medinovai/medinovai-2ag-deploy/` |

---

## Step 1 — Switch to the aifactory-medinovai User

SSH into MacStudio as your normal user, then:

```bash
sudo su - aifactory-medinovai
# Verify you are the right user:
whoami
# Should print: aifactory-medinovai
```

---

## Step 2 — Deploy Astra (Port 36800)

```bash
# ── Navigate to deploy directory ──────────────────────────────────────────
cd ~/medinovai

# ── Clone if first time ───────────────────────────────────────────────────
if [ ! -d "medinovai-2ag-astra/.git" ]; then
  git clone https://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@github.com/medinovai-health/medinovai-2ag-astra.git
fi

# ── Pull latest code ──────────────────────────────────────────────────────
cd ~/medinovai/medinovai-2ag-astra
git fetch origin
git reset --hard origin/main
git clean -fd
echo "✓ Code is at: $(git log --oneline -1)"

# ── Stop old container ────────────────────────────────────────────────────
docker compose down --remove-orphans 2>/dev/null || true

# ── Rebuild from scratch (picks up ALL code changes) ─────────────────────
docker compose build --no-cache

# ── Start container ───────────────────────────────────────────────────────
docker compose up -d

# ── Wait and verify ───────────────────────────────────────────────────────
sleep 20
docker compose ps
curl -sf http://localhost:36800/api/health && echo "✅ Astra is HEALTHY" || echo "❌ Health check failed"
```

---

## Step 3 — Deploy Deploy App (Port 36900)

```bash
# ── Navigate to deploy directory ──────────────────────────────────────────
cd ~/medinovai

# ── Clone if first time ───────────────────────────────────────────────────
if [ ! -d "medinovai-2ag-deploy/.git" ]; then
  git clone https://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@github.com/medinovai-health/medinovai-2ag-deploy.git
fi

# ── Pull latest code ──────────────────────────────────────────────────────
cd ~/medinovai/medinovai-2ag-deploy
git fetch origin
git reset --hard origin/main
git clean -fd
echo "✓ Code is at: $(git log --oneline -1)"

# ── Inject GITHUB_PAT for live GitHub data feed ───────────────────────────
cat > .env << 'ENVEOF'
GITHUB_PAT=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
NODE_ENV=production
NEXT_TELEMETRY_DISABLED=1
ENVEOF
echo "✓ .env written"

# ── Stop old container ────────────────────────────────────────────────────
docker compose down --remove-orphans 2>/dev/null || true

# ── Rebuild from scratch ──────────────────────────────────────────────────
docker compose build --no-cache

# ── Start container ───────────────────────────────────────────────────────
docker compose up -d

# ── Wait and verify ───────────────────────────────────────────────────────
sleep 20
docker compose ps
curl -sf http://localhost:36900/api/health && echo "✅ Deploy App is HEALTHY" || echo "❌ Health check failed"
```

---

## Step 4 — Verify Both Services

```bash
# Check running containers
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Astra health
curl -sf http://localhost:36800/api/health | python3 -m json.tool

# Deploy health
curl -sf http://localhost:36900/api/health | python3 -m json.tool

# Check versions (should show 2.0.0)
curl -sf http://localhost:36800/api/health | grep version
curl -sf http://localhost:36900/api/health | grep version
```

---

## Step 5 — View Logs (if something fails)

```bash
# Astra logs
cd ~/medinovai/medinovai-2ag-astra && docker compose logs --tail=100 -f

# Deploy logs
cd ~/medinovai/medinovai-2ag-deploy && docker compose logs --tail=100 -f
```

---

## Step 6 — Register Probe Agents on All Machines

Run this on every Linux/macOS machine you want to monitor:

```bash
curl -sSL http://100.106.54.9:36800/probe/install.sh | bash
```

This installs the Go probe agent that sends telemetry to Astra's ingest API.

---

## Automated CI/CD (Fixed)

The GitHub Actions workflows have been updated to correctly deploy under the `aifactory-medinovai` user. Future pushes to `main` will:

1. Connect to MacStudio via Tailscale
2. SSH as `$MACSTUDIO_USER`
3. `sudo -u aifactory-medinovai` to switch user
4. Pull latest code to `/Users/aifactory-medinovai/medinovai/<repo>/`
5. `docker compose build --no-cache && docker compose up -d`
6. Health check on correct port

**No manual intervention needed after this initial fix.**

---

## Troubleshooting

### Container shows old version after CI run

The CI was previously deploying to `$HOME/aifactory/deployments/` (wrong user's home). Run the manual commands in Steps 2-3 above once to get the correct directories set up. After that, CI will work automatically.

### Build fails with TypeScript errors

```bash
cd ~/medinovai/medinovai-2ag-deploy/ui
npm install --legacy-peer-deps
npm run build 2>&1 | tail -50
```

### Port already in use

```bash
lsof -ti:36800 | xargs kill -9
lsof -ti:36900 | xargs kill -9
```

### Docker disk full

```bash
docker system prune -af --volumes
df -h
```

### Cannot reach Tailscale

```bash
tailscale status
tailscale ping 100.106.54.9
```

---

## What Was Fixed in v2.0.0

| Fix | Component |
|-----|-----------|
| `external: true` Docker network crash | Both |
| `target: production` Dockerfile stage | Both |
| Wrong COPY paths | Both |
| `npm ci` without package-lock.json | Both |
| `@radix-ui/react-badge` non-existent | Deploy |
| `nexus-agent` import outside build context | Deploy |
| `export type` in route files | Deploy |
| `req.ip` removed in Next.js 15 | Both |
| `@aws-sdk/*` missing packages | Astra |
| FMEA `riskClass` vs `highestRisk` type error | Deploy |
| `chart.js` missing from package.json | Deploy |
| OmniBox TypeScript type errors | Both |
| CI deploys to wrong user's home directory | **Both (this fix)** |

---

## GitHub Releases

- **Astra v2.0.0**: https://github.com/medinovai-health/medinovai-2ag-astra/releases/tag/v2.0.0
- **Deploy v2.0.0**: https://github.com/medinovai-health/medinovai-2ag-deploy/releases/tag/v2.0.0

---

*© 2026 myOnsite Healthcare — Confidential*
