// ─── medinovaiOS Server ───────────────────────────────────────────────────────
// Express server that:
//   1. Serves the built Vite SPA from /dist
//   2. Provides /api/services/health — server-side health aggregation
//   3. Provides /api/sso/* — OIDC relay via Keycloak (httpOnly cookie auth)
//   4. Accepts /api/health-push from the deploy-agent watchdog
//   5. Exposes /health for container probes
// ─────────────────────────────────────────────────────────────────────────────

import express from 'express';
import cookieParser from 'cookie-parser';
import path from 'path';
import { fileURLToPath } from 'url';
import { getServiceHealth, pushHealthData } from './health-aggregator.js';
import {
  handleLogin,
  handleCallback,
  handleValidate,
  handleMe,
  handleLogout,
  handleRefresh,
} from './sso-relay.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const app = express();
const PORT = parseInt(process.env.PORT ?? '3030', 10);

app.use(express.json({ limit: '100kb' }));
app.use(cookieParser());

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

// ── SSO endpoints (OIDC relay via Keycloak) ───────────────────────────────────
// GET  /api/sso/login     — generate PKCE + redirect to Keycloak
app.get('/api/sso/login', handleLogin);

// GET  /api/sso/callback  — exchange code for tokens, set httpOnly cookies
app.get('/api/sso/callback', handleCallback);

// GET  /api/sso/validate  — validate kc_access cookie (used by nginx auth_request)
// Returns 200 + X-User-* headers on success, 401 on failure
app.get('/api/sso/validate', handleValidate);

// GET  /api/sso/me        — return decoded user from valid cookie (used by SPA on mount)
app.get('/api/sso/me', handleMe);

// POST /api/sso/logout    — clear cookies + call Keycloak backchannel logout
app.post('/api/sso/logout', handleLogout);

// GET  /api/sso/refresh   — rotate access token using refresh token
app.get('/api/sso/refresh', handleRefresh);

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
  console.log(`[medinovaios] Keycloak: ${process.env.KEYCLOAK_URL ?? 'http://localhost:8081'}/realms/${process.env.KEYCLOAK_REALM ?? 'medinov-ai'}`);
  console.log(`[medinovaios] Auth flow: GET /api/sso/login → Keycloak → GET /api/sso/callback`);
});

export default app;
