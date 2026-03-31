// server/index.ts
import express from "express";
import path from "path";
import { fileURLToPath } from "url";

// server/health-aggregator.ts
function buildEndpoints() {
  const defaults = [
    { id: "postgres", internalUrl: "http://medinovai-postgres:5432", healthPath: "/" },
    { id: "redis", internalUrl: "http://medinovai-redis:6379", healthPath: "/" },
    { id: "prometheus", internalUrl: "http://medinovai-prometheus:9090", healthPath: "/-/healthy" },
    { id: "grafana", internalUrl: "http://medinovai-grafana:3000", healthPath: "/api/health" },
    { id: "mailhog", internalUrl: "http://medinovai-mailhog:8025", healthPath: "/" },
    { id: "localstack", internalUrl: "http://medinovai-localstack:4566", healthPath: "/_localstack/health" },
    { id: "ollama", internalUrl: "http://medinovai-ollama:11434", healthPath: "/api/tags" },
    { id: "openwebui", internalUrl: "http://medinovai-open-webui:8080", healthPath: "/health" },
    { id: "lis", internalUrl: process.env.LIS_INTERNAL_URL ?? "http://medinovai-lis:3000", healthPath: "/health" },
    { id: "cortex", internalUrl: process.env.CORTEX_INTERNAL_URL ?? "http://medinovai-cortex:3100", healthPath: "/health" },
    { id: "etmf", internalUrl: process.env.ETMF_INTERNAL_URL ?? "http://medinovai-etmf:3000", healthPath: "/health" },
    { id: "sales", internalUrl: process.env.SALES_INTERNAL_URL ?? "http://medinovai-sales:3000", healthPath: "/health" },
    { id: "atlas", internalUrl: process.env.ATLAS_INTERNAL_URL ?? "http://atlas-agent:18789", healthPath: "/health" },
    { id: "healthllm", internalUrl: process.env.HEALTHLLM_INTERNAL_URL ?? "http://medinovai-healthllm:8000", healthPath: "/health" },
    { id: "aifactory", internalUrl: process.env.AIFACTORY_INTERNAL_URL ?? "http://medinovai-aifactory:8080", healthPath: "/health" },
    { id: "api-gateway", internalUrl: process.env.API_GW_INTERNAL_URL ?? "http://api-gateway.medinovai-services:3000", healthPath: "/ready" },
    { id: "auth-service", internalUrl: process.env.AUTH_INTERNAL_URL ?? "http://auth-service.medinovai-services:3000", healthPath: "/ready" },
    { id: "consent", internalUrl: process.env.CONSENT_INTERNAL_URL ?? "http://medinovai-consent-preference:3000", healthPath: "/health" },
    { id: "audit-trail", internalUrl: process.env.AUDIT_INTERNAL_URL ?? "http://medinovai-audit-trail-explorer:3000", healthPath: "/health" }
  ];
  return defaults;
}
var CACHE_TTL_MS = 25e3;
var PROBE_TIMEOUT_MS = 4e3;
var cache = [];
var cacheTime = 0;
var probing = false;
var pushedHealth = /* @__PURE__ */ new Map();
async function probeOne(endpoint) {
  const url = endpoint.internalUrl.replace(/\/$/, "") + endpoint.healthPath;
  const start = Date.now();
  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), PROBE_TIMEOUT_MS);
    const res = await fetch(url, {
      signal: controller.signal,
      headers: { "User-Agent": "medinovaios-health/1.0" }
    });
    clearTimeout(timer);
    const latencyMs = Date.now() - start;
    const status = res.ok ? "healthy" : "degraded";
    return { id: endpoint.id, status, latencyMs, checkedAt: (/* @__PURE__ */ new Date()).toISOString() };
  } catch (err) {
    const latencyMs = Date.now() - start;
    const error = err instanceof Error ? err.message : String(err);
    return { id: endpoint.id, status: "offline", latencyMs, checkedAt: (/* @__PURE__ */ new Date()).toISOString(), error };
  }
}
async function getServiceHealth() {
  const now = Date.now();
  if (now - cacheTime < CACHE_TTL_MS && cache.length > 0) {
    return cache;
  }
  if (probing) {
    return cache.length > 0 ? cache : buildEndpoints().map((e) => ({
      id: e.id,
      status: "unknown",
      checkedAt: (/* @__PURE__ */ new Date()).toISOString()
    }));
  }
  probing = true;
  try {
    const endpoints = buildEndpoints();
    const results = await Promise.allSettled(endpoints.map(probeOne));
    cache = results.map(
      (r, i) => r.status === "fulfilled" ? r.value : { id: endpoints[i].id, status: "offline", checkedAt: (/* @__PURE__ */ new Date()).toISOString() }
    );
    for (const [id, pushed] of pushedHealth.entries()) {
      const idx = cache.findIndex((c) => c.id === id);
      if (idx >= 0) cache[idx] = { ...cache[idx], ...pushed };
    }
    cacheTime = Date.now();
    return cache;
  } finally {
    probing = false;
  }
}
function pushHealthData(data) {
  const lines = data.output.split(" ");
  for (const line of lines) {
    if (line.includes("\u2713")) {
      const match = line.match(/✓\s+(\S+)/);
      if (match) {
        pushedHealth.set(match[1], {
          id: match[1],
          status: "healthy",
          checkedAt: data.timestamp
        });
      }
    }
  }
}
setTimeout(() => {
  getServiceHealth().catch(() => {
  });
}, 2e3);

// server/sso-relay.ts
var AUTH_SERVICE_URL = process.env.AUTH_SERVICE_URL ?? "http://localhost:30081";
async function callAuthService(path2, method, body) {
  try {
    const res = await fetch(`${AUTH_SERVICE_URL}${path2}`, {
      method,
      headers: { "Content-Type": "application/json" },
      body: body ? JSON.stringify(body) : void 0,
      signal: AbortSignal.timeout(5e3)
    });
    return res;
  } catch {
    return null;
  }
}
async function handleLogin(req, res) {
  const { email, password } = req.body ?? {};
  if (!email || !password) {
    return res.status(400).json({ message: "email and password required" });
  }
  const upstream = await callAuthService("/auth/login", "POST", { email, password });
  if (!upstream) {
    if (process.env.NODE_ENV !== "production") {
      const devToken = Buffer.from(JSON.stringify({ sub: "dev", email, role: "admin", exp: Date.now() / 1e3 + 86400 })).toString("base64");
      return res.json({ token: `dev.${devToken}.sig`, user: { email, role: "admin" } });
    }
    return res.status(503).json({ message: "Auth service unavailable" });
  }
  const data = await upstream.json().catch(() => ({}));
  return res.status(upstream.status).json(data);
}
async function handleValidate(req, res) {
  const authHeader = req.headers.authorization ?? "";
  const token = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : authHeader;
  if (!token) return res.status(401).json({ valid: false });
  if (token === "guest") return res.json({ valid: true, role: "guest" });
  if (token.startsWith("dev.") && process.env.NODE_ENV !== "production") {
    try {
      const payload = JSON.parse(Buffer.from(token.split(".")[1], "base64").toString());
      if (payload.exp && payload.exp * 1e3 < Date.now()) {
        return res.status(401).json({ valid: false, reason: "expired" });
      }
      return res.json({ valid: true, user: payload });
    } catch {
      return res.status(401).json({ valid: false });
    }
  }
  const upstream = await callAuthService("/auth/validate", "POST", { token });
  if (!upstream) {
    if (process.env.NODE_ENV !== "production") return res.json({ valid: true, role: "unknown" });
    return res.status(503).json({ valid: false, reason: "auth service unreachable" });
  }
  const data = await upstream.json().catch(() => ({}));
  return res.status(upstream.status).json(data);
}

// server/index.ts
var __dirname = path.dirname(fileURLToPath(import.meta.url));
var app = express();
var PORT = parseInt(process.env.PORT ?? "3030", 10);
app.use(express.json({ limit: "100kb" }));
if (process.env.NODE_ENV !== "production") {
  app.use((req, res, next) => {
    res.setHeader("Access-Control-Allow-Origin", "*");
    res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");
    res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    if (req.method === "OPTIONS") return res.sendStatus(204);
    next();
  });
}
app.get("/health", (_req, res) => {
  res.json({ status: "ok", service: "medinovaios", ts: (/* @__PURE__ */ new Date()).toISOString() });
});
app.get("/api/services/health", async (_req, res) => {
  try {
    const health = await getServiceHealth();
    res.json(health);
  } catch (err) {
    console.error("[health] aggregation error:", err);
    res.status(500).json({ error: "Health aggregation failed" });
  }
});
app.post("/api/health-push", (req, res) => {
  const { timestamp, source, output } = req.body ?? {};
  if (!timestamp || !source) {
    return res.status(400).json({ error: "timestamp and source required" });
  }
  pushHealthData({ timestamp, source, output: output ?? "" });
  console.log(`[watchdog] Health push received from ${source} at ${timestamp}`);
  return res.json({ status: "ok" });
});
app.post("/api/sso/login", handleLogin);
app.post("/api/sso/validate", handleValidate);
app.get("/api/sso/validate", handleValidate);
var distPath = path.resolve(__dirname, "..", "dist");
app.use(express.static(distPath, { maxAge: "1h", immutable: true }));
app.get("*", (req, res) => {
  if (req.path.startsWith("/api/")) {
    return res.status(404).json({ error: "API route not found" });
  }
  return res.sendFile(path.join(distPath, "index.html"));
});
app.listen(PORT, "0.0.0.0", () => {
  console.log(`[medinovaios] Server running on http://0.0.0.0:${PORT}`);
  console.log(`[medinovaios] Serving SPA from ${distPath}`);
  console.log(`[medinovaios] Auth service: ${process.env.AUTH_SERVICE_URL ?? "http://localhost:30081"}`);
});
var index_default = app;
export {
  index_default as default
};
