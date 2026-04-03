// ─── Health Aggregator ────────────────────────────────────────────────────────
// Server-side health checker. Polls all service health endpoints using internal
// DNS (container names / k8s service names) and caches results.
// The browser polls /api/services/health which returns the cached snapshot.
// ─────────────────────────────────────────────────────────────────────────────

interface ServiceHealthSnapshot {
  id: string;
  status: 'healthy' | 'degraded' | 'offline' | 'unknown';
  latencyMs?: number;
  checkedAt: string;
  error?: string;
}

interface ServiceEndpoint {
  id: string;
  internalUrl: string;
  healthPath: string;
}

// Service endpoints resolved from environment (Docker/K8s internal DNS)
// Overridable per service via env vars: HEALTH_<SERVICE_ID_UPPER>=http://host/path
function buildEndpoints(): ServiceEndpoint[] {
  const defaults: ServiceEndpoint[] = [
    // Infrastructure Services
    { id: 'security-service', internalUrl: 'http://medinovai-security-service.medinovai-services:8000', healthPath: '/health' },
    { id: 'registry',         internalUrl: 'http://medinovai-registry.medinovai-services:8000',         healthPath: '/health' },
    { id: 'stream-bus',       internalUrl: 'http://medinovai-real-time-stream-bus.medinovai:8000',      healthPath: '/health' },
    { id: 'ctms',             internalUrl: 'http://medinovai-ctms.medinovai-services:8000',             healthPath: '/health' },
    { id: 'lis',              internalUrl: 'http://medinovai-lis.medinovai-services:8000',              healthPath: '/health' },
    { id: 'econsent',         internalUrl: 'http://medinovai-econsent.medinovai-services:3000',         healthPath: '/health' },
    { id: 'epro',             internalUrl: 'http://medinovai-epro.medinovai-services:8000',            healthPath: '/health' },
    { id: 'hipaa-guard',      internalUrl: 'http://medinovai-hipaa-gdpr-guard.medinovai-services:8000', healthPath: '/health' },
    { id: 'saes',             internalUrl: 'http://medinovai-saes.medinovai-services:8000',             healthPath: '/' },
    { id: 'data-services',    internalUrl: 'http://medinovai-data-services.medinovai-data:8000',       healthPath: '/health' },

    // Monitoring Services
    { id: 'prometheus',       internalUrl: 'http://prometheus.medinovai-monitoring:9090',                healthPath: '/-/healthy' },
    { id: 'grafana',          internalUrl: 'http://grafana.medinovai-monitoring:3000',                   healthPath: '/api/health' },
    { id: 'kibana',           internalUrl: 'http://kibana.medinovai-monitoring:5601',                    healthPath: '/api/status' },
    { id: 'elasticsearch',    internalUrl: 'http://elasticsearch.medinovai-monitoring:9200',             healthPath: '/_cluster/health' },

    // Data Stores
    { id: 'postgres',         internalUrl: 'http://registry-postgres.medinovai:5432',                    healthPath: '/' },
    { id: 'redis',            internalUrl: 'http://registry-redis.medinovai:6379',                        healthPath: '/' },

    // Dev Tools & Other
    { id: 'mailhog',          internalUrl: 'http://medinovai-mailhog:8025',                               healthPath: '/' },
    { id: 'localstack',       internalUrl: 'http://medinovai-localstack:4566',                           healthPath: '/_localstack/health' },
    { id: 'ollama',           internalUrl: 'http://medinovai-ollama:11434',                                healthPath: '/api/tags' },
    { id: 'openwebui',        internalUrl: 'http://medinovai-open-webui:8080',                           healthPath: '/health' },

    // Products (via env overrides)
    { id: 'cortex',           internalUrl: process.env.CORTEX_INTERNAL_URL   ?? 'http://medinovai-cortex:3100',      healthPath: '/health' },
    { id: 'etmf',             internalUrl: process.env.ETMF_INTERNAL_URL     ?? 'http://medinovai-etmf:3000',        healthPath: '/health' },
    { id: 'sales',            internalUrl: process.env.SALES_INTERNAL_URL    ?? 'http://medinovai-sales:3000',       healthPath: '/health' },
    { id: 'atlas',            internalUrl: process.env.ATLAS_INTERNAL_URL    ?? 'http://atlas-agent:18789',          healthPath: '/health' },
    { id: 'healthllm',        internalUrl: process.env.HEALTHLLM_INTERNAL_URL ?? 'http://medinovai-healthllm:8000', healthPath: '/health' },
    { id: 'aifactory',        internalUrl: process.env.AIFACTORY_INTERNAL_URL ?? 'http://medinovai-aifactory:8080', healthPath: '/health' },

    // Platform Services (via env overrides)
    { id: 'api-gateway',      internalUrl: process.env.API_GW_INTERNAL_URL   ?? 'http://api-gateway.medinovai-services:3000', healthPath: '/ready' },
    { id: 'auth-service',     internalUrl: process.env.AUTH_INTERNAL_URL     ?? 'http://auth-service.medinovai-services:3000', healthPath: '/ready' },
    { id: 'consent',          internalUrl: process.env.CONSENT_INTERNAL_URL  ?? 'http://medinovai-consent-preference:3000',   healthPath: '/health' },
    { id: 'audit-trail',      internalUrl: process.env.AUDIT_INTERNAL_URL    ?? 'http://medinovai-audit-trail-explorer:3000', healthPath: '/health' },
  ];
  return defaults;
}

const CACHE_TTL_MS = 25_000; // Slightly less than browser poll interval of 30s
const PROBE_TIMEOUT_MS = 4_000;

let cache: ServiceHealthSnapshot[] = [];
let cacheTime = 0;
let probing = false;

// Pushed results from the deploy-agent watchdog
const pushedHealth: Map<string, ServiceHealthSnapshot> = new Map();

async function probeOne(endpoint: ServiceEndpoint): Promise<ServiceHealthSnapshot> {
  const url = endpoint.internalUrl.replace(/\/$/, '') + endpoint.healthPath;
  const start = Date.now();
  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), PROBE_TIMEOUT_MS);

    const res = await fetch(url, {
      signal: controller.signal,
      headers: { 'User-Agent': 'medinovaios-health/1.0' },
    });
    clearTimeout(timer);

    const latencyMs = Date.now() - start;
    const status = res.ok ? 'healthy' : 'degraded';
    return { id: endpoint.id, status, latencyMs, checkedAt: new Date().toISOString() };
  } catch (err: unknown) {
    const latencyMs = Date.now() - start;
    const error = err instanceof Error ? err.message : String(err);
    return { id: endpoint.id, status: 'offline', latencyMs, checkedAt: new Date().toISOString(), error };
  }
}

export async function getServiceHealth(): Promise<ServiceHealthSnapshot[]> {
  const now = Date.now();
  if (now - cacheTime < CACHE_TTL_MS && cache.length > 0) {
    return cache;
  }
  if (probing) {
    return cache.length > 0 ? cache : buildEndpoints().map((e) => ({
      id: e.id, status: 'unknown' as const, checkedAt: new Date().toISOString(),
    }));
  }

  probing = true;
  try {
    const endpoints = buildEndpoints();
    const results = await Promise.allSettled(endpoints.map(probeOne));
    cache = results.map((r, i) =>
      r.status === 'fulfilled'
        ? r.value
        : { id: endpoints[i].id, status: 'offline' as const, checkedAt: new Date().toISOString() }
    );

    // Merge pushed health data (from deploy-agent watchdog) where available
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

export function pushHealthData(data: { source: string; timestamp: string; output: string }) {
  // Parse simple pass/fail from watchdog output
  const lines = data.output.split(' ');
  for (const line of lines) {
    if (line.includes('✓')) {
      const match = line.match(/✓\s+(\S+)/);
      if (match) {
        pushedHealth.set(match[1], {
          id: match[1],
          status: 'healthy',
          checkedAt: data.timestamp,
        });
      }
    }
  }
}

// Warm cache on startup (non-blocking)
setTimeout(() => { getServiceHealth().catch(() => {}); }, 2000);
