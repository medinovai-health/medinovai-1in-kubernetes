// ─── medinovaiOS Server ───────────────────────────────────────────────────────
// Express server that:
//   1. Serves the built Vite SPA from /dist
//   2. Provides /api/services/health — server-side health aggregation
//   3. Provides /api/sso/* — SSO login + token validation
//   4. Accepts /api/health-push from the deploy-agent watchdog
//   5. Exposes /health for container probes
// ─────────────────────────────────────────────────────────────────────────────

import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import { getServiceHealth, pushHealthData } from './health-aggregator.js';
import { handleLogin, handleValidate } from './sso-relay.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const app = express();
const PORT = parseInt(process.env.PORT ?? '3030', 10);

app.use(express.json({ limit: '100kb' }));

// ── CORS for dev (Vite proxy handles it in prod) ──────────────────────────────
if (process.env.NODE_ENV !== 'production') {
  app.use((req, res, next) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    if (req.method === 'OPTIONS') return res.sendStatus(204);
    next();
  });
}

// ── Health probe ──────────────────────────────────────────────────────────────
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: 'medinovaios', ts: new Date().toISOString() });
});

// ── Service health aggregation ────────────────────────────────────────────────
app.get('/api/services/health', async (_req, res) => {
  try {
    const health = await getServiceHealth();
    res.json(health);
  } catch (err) {
    console.error('[health] aggregation error:', err);
    res.status(500).json({ error: 'Health aggregation failed' });
  }
});

// ── Health push from deploy-agent watchdog ────────────────────────────────────
app.post('/api/health-push', (req, res) => {
  const { timestamp, source, output } = req.body ?? {};
  if (!timestamp || !source) {
    return res.status(400).json({ error: 'timestamp and source required' });
  }
  pushHealthData({ timestamp, source, output: output ?? '' });
  console.log(`[watchdog] Health push received from ${source} at ${timestamp}`);
  return res.json({ status: 'ok' });
});

// ── SSO endpoints ─────────────────────────────────────────────────────────────
app.post('/api/sso/login', handleLogin);
app.post('/api/sso/validate', handleValidate);
app.get('/api/sso/validate', handleValidate);

// ── Serve static SPA (production) ─────────────────────────────────────────────
const distPath = path.resolve(__dirname, '..', 'dist');
app.use(express.static(distPath, { maxAge: '1h', immutable: true }));

// SPA fallback — all non-API routes return index.html
app.get('*', (req, res) => {
  if (req.path.startsWith('/api/')) {
    return res.status(404).json({ error: 'API route not found' });
  }
  return res.sendFile(path.join(distPath, 'index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`[medinovaios] Server running on http://0.0.0.0:${PORT}`);
  console.log(`[medinovaios] Serving SPA from ${distPath}`);
  console.log(`[medinovaios] Auth service: ${process.env.AUTH_SERVICE_URL ?? 'http://localhost:30081'}`);
});

export default app;
