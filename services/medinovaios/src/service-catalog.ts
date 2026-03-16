// ─── MedinovAI OS — Service Catalog ──────────────────────────────────────────
// Single source of truth for every product, service, and tool in the platform.
// Add new services here — the UI, health aggregator, and SSO relay all read
// from this catalog automatically.
// ─────────────────────────────────────────────────────────────────────────────

// Resolve the current hostname at runtime (browser-safe — never called during build)
function host(): string {
  return typeof window !== 'undefined' ? window.location.hostname : 'localhost';
}
function proto(): string {
  return typeof window !== 'undefined' ? window.location.protocol : 'http:';
}
function url(port: number): string {
  return `${proto()}//${host()}:${port}`;
}

export type ServiceCategory =
  | 'Products'
  | 'AI Platform'
  | 'Monitoring'
  | 'GitOps'
  | 'Dev Tools'
  | 'Platform Services';

export type HealthStatus = 'healthy' | 'degraded' | 'offline' | 'unknown';

export interface ServiceDef {
  id: string;
  name: string;
  description: string;
  category: ServiceCategory;
  icon: string;
  // URL the browser opens (external / NodePort / ingress path)
  externalUrl: string;
  // Path on externalUrl to perform health check from the browser
  healthPath: string;
  // Internal URL for server-side health aggregation (container/service DNS)
  // Falls back to externalUrl if not set
  internalHealthUrl?: string;
  // Whether this service can be embedded in an iframe panel
  embed: boolean;
  // Port label shown in the UI
  port?: string;
  // Atlas UI cross-link (bidirectional SSO navigation)
  crossLink?: boolean;
  // Tags for search/filter
  tags?: string[];
  // Whether this service requires a token to be launched
  requiresAuth?: boolean;
}

export const SERVICES: ServiceDef[] = [
  // ─── Products ───────────────────────────────────────────────────────────────
  {
    id: 'lis',
    name: 'LIS',
    description: 'Laboratory Information System — sample tracking, results, orders',
    category: 'Products',
    icon: '🔬',
    externalUrl: url(3200),
    healthPath: '/health',
    internalHealthUrl: 'http://medinovai-lis:3000/health',
    embed: false,
    port: ':3200',
    tags: ['lab', 'samples', 'orders', 'results'],
    requiresAuth: true,
  },
  {
    id: 'cortex',
    name: 'Cortex',
    description: 'Healthcare logistics hub — trips, phlebotomists, AI dispatch',
    category: 'Products',
    icon: '💉',
    externalUrl: url(3100),
    healthPath: '/health',
    internalHealthUrl: 'http://medinovai-cortex:3100/health',
    embed: false,
    port: ':3100',
    tags: ['logistics', 'trips', 'dispatch', 'phlebotomy'],
    requiresAuth: true,
  },
  {
    id: 'etmf',
    name: 'eTMF',
    description: 'Electronic Trial Master File — clinical trial document management',
    category: 'Products',
    icon: '📋',
    externalUrl: url(3300),
    healthPath: '/health',
    internalHealthUrl: 'http://medinovai-etmf:3000/health',
    embed: false,
    port: ':3300',
    tags: ['trials', 'documents', 'compliance', 'ICH'],
    requiresAuth: true,
  },
  {
    id: 'sales',
    name: 'Sales Platform',
    description: 'AI-powered sales intelligence — 50-capability conversation agent',
    category: 'Products',
    icon: '📈',
    externalUrl: url(3400),
    healthPath: '/health',
    internalHealthUrl: 'http://medinovai-sales:3000/health',
    embed: false,
    port: ':3400',
    tags: ['sales', 'CRM', 'AI', 'conversations'],
    requiresAuth: true,
  },

  {
    id: 'northstar',
    name: 'Northstar',
    description: 'Employee recognition, rewards, culture building & engagement platform',
    category: 'Products',
    icon: '⭐',
    externalUrl: url(18000),
    healthPath: '/health',
    internalHealthUrl: 'http://northstar-identity:8000/health',
    embed: false,
    port: ':18000',
    tags: ['employee', 'recognition', 'rewards', 'culture', 'engagement'],
    requiresAuth: true,
  },

  // ─── AI Platform ────────────────────────────────────────────────────────────
  {
    id: 'atlas',
    name: 'Atlas',
    description: 'AI orchestration platform — agents, workspaces, gateway',
    category: 'AI Platform',
    icon: '🗺️',
    externalUrl: url(3737),
    healthPath: '/health',
    internalHealthUrl: 'http://atlas-agent:18789/health',
    embed: false,
    port: ':3737',
    crossLink: true,
    tags: ['agents', 'orchestration', 'Atlas', 'AI'],
    requiresAuth: true,
  },
  {
    id: 'healthllm',
    name: 'HealthLLM',
    description: '6 AI expert agents + Digital Twins for clinical decision support',
    category: 'AI Platform',
    icon: '🧠',
    externalUrl: url(8000),
    healthPath: '/health',
    internalHealthUrl: 'http://medinovai-healthllm:8000/health',
    embed: false,
    port: ':8000',
    tags: ['clinical', 'AI', 'digital twin', 'experts'],
    requiresAuth: true,
  },
  {
    id: 'aifactory',
    name: 'AIFactory',
    description: 'MCP Gateway + AI inference cluster — model routing and orchestration',
    category: 'AI Platform',
    icon: '⚡',
    externalUrl: url(8080),
    healthPath: '/health',
    internalHealthUrl: 'http://medinovai-aifactory:8080/health',
    embed: false,
    port: ':8080',
    tags: ['MCP', 'inference', 'models', 'routing'],
    requiresAuth: true,
  },
  {
    id: 'openwebui',
    name: 'Open WebUI',
    description: 'Browser-based chat interface for local Ollama models',
    category: 'AI Platform',
    icon: '💬',
    externalUrl: url(8091),
    healthPath: '/health',
    internalHealthUrl: 'http://medinovai-open-webui:8080/health',
    embed: true,
    port: ':8091',
    tags: ['chat', 'Ollama', 'LLM', 'local AI'],
  },
  {
    id: 'ollama',
    name: 'Ollama',
    description: 'Local LLM inference engine — PHI-safe, fully on-device',
    category: 'AI Platform',
    icon: '🦙',
    externalUrl: url(11435),
    healthPath: '/api/tags',
    internalHealthUrl: 'http://medinovai-ollama:11434/api/tags',
    embed: false,
    port: ':11435',
    tags: ['Ollama', 'LLM', 'local', 'PHI-safe'],
  },

  // ─── Monitoring ─────────────────────────────────────────────────────────────
  {
    id: 'grafana',
    name: 'Grafana',
    description: 'Metrics dashboards — system health, AI performance, business KPIs',
    category: 'Monitoring',
    icon: '📊',
    externalUrl: url(3000),
    healthPath: '/api/health',
    internalHealthUrl: 'http://medinovai-grafana:3000/api/health',
    embed: true,
    port: ':3000',
    tags: ['metrics', 'dashboards', 'monitoring'],
  },
  {
    id: 'prometheus',
    name: 'Prometheus',
    description: 'Metrics collection and alerting — all services scraped every 15s',
    category: 'Monitoring',
    icon: '🔥',
    externalUrl: url(9090),
    healthPath: '/-/healthy',
    internalHealthUrl: 'http://medinovai-prometheus:9090/-/healthy',
    embed: true,
    port: ':9090',
    tags: ['metrics', 'alerts', 'time-series'],
  },

  // ─── GitOps ─────────────────────────────────────────────────────────────────
  {
    id: 'argocd',
    name: 'ArgoCD',
    description: 'GitOps continuous deployment — watches GitHub, auto-syncs cluster',
    category: 'GitOps',
    icon: '🔄',
    externalUrl: 'http://localhost:8080',
    healthPath: '/healthz',
    internalHealthUrl: 'http://argocd-server.argocd.svc.cluster.local:80/healthz',
    embed: false,
    port: ':8080 (port-forward)',
    tags: ['GitOps', 'CD', 'ArgoCD', 'k8s'],
  },
  {
    id: 'k8sdash',
    name: 'K8s Dashboard',
    description: 'Kubernetes cluster management — pods, services, ingresses, events',
    category: 'GitOps',
    icon: '☸️',
    externalUrl: 'https://localhost:8443',
    healthPath: '/',
    embed: false,
    port: ':8443 (port-forward)',
    tags: ['kubernetes', 'cluster', 'pods'],
  },

  // ─── Dev Tools ──────────────────────────────────────────────────────────────
  {
    id: 'mailhog',
    name: 'MailHog',
    description: 'Email capture for development — all outgoing mail intercepted here',
    category: 'Dev Tools',
    icon: '📧',
    externalUrl: url(8025),
    healthPath: '/',
    internalHealthUrl: 'http://medinovai-mailhog:8025/',
    embed: true,
    port: ':8025',
    tags: ['email', 'SMTP', 'testing'],
  },
  {
    id: 'localstack',
    name: 'LocalStack',
    description: 'AWS services emulator — S3, SQS, SNS, Secrets Manager locally',
    category: 'Dev Tools',
    icon: '☁️',
    externalUrl: `${window?.location?.protocol ?? 'http:'}//${window?.location?.hostname ?? 'localhost'}:4566`,
    healthPath: '/_localstack/health',
    internalHealthUrl: 'http://medinovai-localstack:4566/_localstack/health',
    embed: false,
    port: ':4566',
    tags: ['AWS', 'S3', 'SQS', 'local'],
  },

  // ─── Platform Services ───────────────────────────────────────────────────────
  {
    id: 'api-gateway',
    name: 'API Gateway',
    description: 'Central request routing and load balancing for all services',
    category: 'Platform Services',
    icon: '🚪',
    externalUrl: 'http://localhost:30080',
    healthPath: '/ready',
    internalHealthUrl: 'http://api-gateway.medinovai-services.svc.cluster.local:3000/ready',
    embed: false,
    port: ':30080',
    tags: ['gateway', 'routing', 'API'],
  },
  {
    id: 'auth-service',
    name: 'Auth Service',
    description: 'JWT authentication and SSO token issuance for all MedinovAI apps',
    category: 'Platform Services',
    icon: '🔐',
    externalUrl: 'http://localhost:30081',
    healthPath: '/ready',
    internalHealthUrl: 'http://auth-service.medinovai-services.svc.cluster.local:3000/ready',
    embed: false,
    port: ':30081',
    tags: ['auth', 'JWT', 'SSO'],
  },
  {
    id: 'consent',
    name: 'Consent Manager',
    description: 'Patient consent tracking and preference management — HIPAA required',
    category: 'Platform Services',
    icon: '✅',
    externalUrl: 'http://localhost:30082',
    healthPath: '/health',
    internalHealthUrl: 'http://medinovai-consent-preference.medinovai-services.svc.cluster.local/health',
    embed: false,
    port: ':30082',
    tags: ['consent', 'HIPAA', 'compliance', 'patients'],
  },
  {
    id: 'audit-trail',
    name: 'Audit Trail',
    description: 'Tamper-evident audit log browser — all AI decisions and user actions',
    category: 'Platform Services',
    icon: '📜',
    externalUrl: 'http://localhost:30083',
    healthPath: '/health',
    internalHealthUrl: 'http://medinovai-audit-trail-explorer.medinovai-services.svc.cluster.local/health',
    embed: true,
    port: ':30083',
    tags: ['audit', 'HIPAA', 'compliance', 'logs'],
  },
];

export const CATEGORIES: ServiceCategory[] = [
  'Products',
  'AI Platform',
  'Monitoring',
  'GitOps',
  'Dev Tools',
  'Platform Services',
];

export const CATEGORY_META: Record<ServiceCategory, { color: string; description: string }> = {
  Products: { color: '#06b6d4', description: 'Clinical and business applications' },
  'AI Platform': { color: '#8b5cf6', description: 'AI models, agents, and inference' },
  Monitoring: { color: '#10b981', description: 'Metrics, dashboards, and alerting' },
  GitOps: { color: '#f59e0b', description: 'Kubernetes and deployment management' },
  'Dev Tools': { color: '#6b7280', description: 'Local development utilities' },
  'Platform Services': { color: '#3b82f6', description: 'Core infrastructure services' },
};

export function getServiceById(id: string): ServiceDef | undefined {
  return SERVICES.find((s) => s.id === id);
}

export function getServicesByCategory(category: ServiceCategory): ServiceDef[] {
  return SERVICES.filter((s) => s.category === category);
}
