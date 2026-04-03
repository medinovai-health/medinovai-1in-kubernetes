// ─── MedinovAI OS — Dashboards Catalog ───────────────────────────────────────
// All 50+ Grafana, Kibana, and custom dashboards accessible via SSO
// Each dashboard includes SSO relay URL for seamless authentication
// ─────────────────────────────────────────────────────────────────────────────

import { host, proto } from './utils';

export type DashboardProvider = 'grafana' | 'kibana' | 'custom';

export interface DashboardDef {
  id: string;
  name: string;
  description: string;
  provider: DashboardProvider;
  category: string;
  icon: string;
  // Direct URL to dashboard
  url: string;
  // SSO relay URL (proxied through security-service)
  ssoUrl: string;
  // Health check path
  healthPath: string;
  // Whether this dashboard requires authentication
  requiresAuth: boolean;
  // Tags for filtering
  tags: string[];
  // Refresh interval in seconds
  refreshInterval?: number;
}

// Generate URLs with current host
function url(port: number, path: string = ''): string {
  return `${proto()}//${host()}:${port}${path}`;
}

// Generate SSO relay URL through security-service
function ssoUrl(targetUrl: string): string {
  const encoded = encodeURIComponent(targetUrl);
  return url(8300, `/sso/relay?redirect=${encoded}`);
}

// ─── Grafana Dashboards ──────────────────────────────────────────────────────
export const GRAFANA_DASHBOARDS: DashboardDef[] = [
  {
    id: 'grafana-infra-overview',
    name: 'Infrastructure Overview',
    description: 'Core infrastructure health: services, CPU, memory, pods, request rates',
    provider: 'grafana',
    category: 'Infrastructure',
    icon: '📊',
    url: url(4250, '/d/infrastructure-overview'),
    ssoUrl: ssoUrl(url(4250, '/d/infrastructure-overview')),
    healthPath: '/api/health',
    requiresAuth: true,
    tags: ['infrastructure', 'health', 'kubernetes', 'metrics'],
    refreshInterval: 30,
  },
  {
    id: 'grafana-healthcare-clinical',
    name: 'Healthcare Clinical Metrics',
    description: 'Clinical trial operations: enrollment, lab TAT, SAEs, site performance',
    provider: 'grafana',
    category: 'Healthcare',
    icon: '🏥',
    url: url(4250, '/d/healthcare-clinical-metrics'),
    ssoUrl: ssoUrl(url(4250, '/d/healthcare-clinical-metrics')),
    healthPath: '/api/health',
    requiresAuth: true,
    tags: ['healthcare', 'clinical', 'trials', 'patients', 'SAE'],
    refreshInterval: 60,
  },
  {
    id: 'grafana-security-audit',
    name: 'Security & Audit Analytics',
    description: 'Authentication events, PHI access, authorization failures, compliance',
    provider: 'grafana',
    category: 'Security',
    icon: '🔐',
    url: url(4250, '/d/security-audit-dashboard'),
    ssoUrl: ssoUrl(url(4250, '/d/security-audit-dashboard')),
    healthPath: '/api/health',
    requiresAuth: true,
    tags: ['security', 'audit', 'PHI', 'compliance', 'auth'],
    refreshInterval: 30,
  },
  {
    id: 'grafana-ai-factory',
    name: 'AI Factory - Model Performance',
    description: 'Ollama inference metrics: token generation, GPU utilization, queue depth',
    provider: 'grafana',
    category: 'AI Platform',
    icon: '🤖',
    url: url(4250, '/d/ai-factory-metrics'),
    ssoUrl: ssoUrl(url(4250, '/d/ai-factory-metrics')),
    healthPath: '/api/health',
    requiresAuth: true,
    tags: ['AI', 'ML', 'Ollama', 'inference', 'GPU'],
    refreshInterval: 30,
  },
  {
    id: 'grafana-kubernetes',
    name: 'Kubernetes Cluster Health',
    description: 'K8s cluster monitoring: nodes, pods, containers, network, disk I/O',
    provider: 'grafana',
    category: 'Infrastructure',
    icon: '☸️',
    url: url(4250, '/d/kubernetes-cluster-health'),
    ssoUrl: ssoUrl(url(4250, '/d/kubernetes-cluster-health')),
    healthPath: '/api/health',
    requiresAuth: true,
    tags: ['kubernetes', 'k8s', 'cluster', 'docker-desktop'],
    refreshInterval: 15,
  },
  {
    id: 'grafana-registry',
    name: 'Service Registry Catalog',
    description: 'Service discovery metrics: registrations, health, dependencies, topology',
    provider: 'grafana',
    category: 'Infrastructure',
    icon: '📋',
    url: url(4250, '/d/registry-service-catalog'),
    ssoUrl: ssoUrl(url(4250, '/d/registry-service-catalog')),
    healthPath: '/api/health',
    requiresAuth: true,
    tags: ['registry', 'services', 'discovery', 'dependencies'],
    refreshInterval: 30,
  },
  {
    id: 'grafana-lis',
    name: 'LIS - Laboratory Analytics',
    description: 'Lab operations: sample tracking, instruments, QC, turnaround times',
    provider: 'grafana',
    category: 'Healthcare',
    icon: '🔬',
    url: url(4250, '/d/lis-lab-analytics'),
    ssoUrl: ssoUrl(url(4250, '/d/lis-lab-analytics')),
    healthPath: '/api/health',
    requiresAuth: true,
    tags: ['LIS', 'lab', 'samples', 'instruments', 'QC'],
    refreshInterval: 60,
  },
  {
    id: 'grafana-ctms',
    name: 'CTMS - Trial Operations',
    description: 'Clinical trial management: studies, sites, subjects, enrollment trends',
    provider: 'grafana',
    category: 'Healthcare',
    icon: '🧪',
    url: url(4250, '/d/ctms-trial-operations'),
    ssoUrl: ssoUrl(url(4250, '/d/ctms-trial-operations')),
    healthPath: '/api/health',
    requiresAuth: true,
    tags: ['CTMS', 'trials', 'studies', 'enrollment', 'sites'],
    refreshInterval: 300,
  },
  {
    id: 'grafana-stream-bus',
    name: 'Stream Bus Analytics',
    description: 'Kafka event streaming: messages/sec, consumer lag, partition health',
    provider: 'grafana',
    category: 'Infrastructure',
    icon: '🚌',
    url: url(4250, '/d/stream-bus-analytics'),
    ssoUrl: ssoUrl(url(4250, '/d/stream-bus-analytics')),
    healthPath: '/api/health',
    requiresAuth: true,
    tags: ['kafka', 'streaming', 'events', 'messaging'],
    refreshInterval: 30,
  },
];

// ─── Kibana Dashboards ─────────────────────────────────────────────────────
export const KIBANA_DASHBOARDS: DashboardDef[] = [
  {
    id: 'kibana-security-audit',
    name: 'Security Audit Analytics',
    description: 'Security events: authentication patterns, PHI access, break-glass logs',
    provider: 'kibana',
    category: 'Security',
    icon: '🔐',
    url: url(4251, '/app/dashboards/security-audit-dashboard'),
    ssoUrl: ssoUrl(url(4251, '/app/dashboards/security-audit-dashboard')),
    healthPath: '/api/status',
    requiresAuth: true,
    tags: ['security', 'audit', 'logs', 'PHI', 'compliance'],
  },
  {
    id: 'kibana-infrastructure',
    name: 'Infrastructure Services Logs',
    description: 'Centralized logging: all infrastructure services, errors, log levels',
    provider: 'kibana',
    category: 'Infrastructure',
    icon: '📄',
    url: url(4251, '/app/dashboards/infrastructure-logs-dashboard'),
    ssoUrl: ssoUrl(url(4251, '/app/dashboards/infrastructure-logs-dashboard')),
    healthPath: '/api/status',
    requiresAuth: true,
    tags: ['infrastructure', 'logs', 'services', 'ELK'],
  },
  {
    id: 'kibana-clinical',
    name: 'Clinical Data Analytics',
    description: 'Clinical data: patient metrics, study analytics, SAE tracking',
    provider: 'kibana',
    category: 'Healthcare',
    icon: '🏥',
    url: url(4251, '/app/dashboards/clinical-data-analytics'),
    ssoUrl: ssoUrl(url(4251, '/app/dashboards/clinical-data-analytics')),
    healthPath: '/api/status',
    requiresAuth: true,
    tags: ['healthcare', 'clinical', 'patients', 'trials'],
  },
  {
    id: 'kibana-ai-factory',
    name: 'AI Factory - Model Inference Logs',
    description: 'AI inference logs: token generation, model usage, Ollama node status',
    provider: 'kibana',
    category: 'AI Platform',
    icon: '🤖',
    url: url(4251, '/app/dashboards/ai-factory-logs'),
    ssoUrl: ssoUrl(url(4251, '/app/dashboards/ai-factory-logs')),
    healthPath: '/api/status',
    requiresAuth: true,
    tags: ['AI', 'ML', 'Ollama', 'inference', 'logs'],
  },
  {
    id: 'kibana-stream-bus',
    name: 'Stream Bus - Event Streaming',
    description: 'Kafka analytics: message flow, consumer groups, topic metrics',
    provider: 'kibana',
    category: 'Infrastructure',
    icon: '🚌',
    url: url(4251, '/app/dashboards/stream-bus-events'),
    ssoUrl: ssoUrl(url(4251, '/app/dashboards/stream-bus-events')),
    healthPath: '/api/status',
    requiresAuth: true,
    tags: ['kafka', 'streaming', 'events', 'analytics'],
  },
  {
    id: 'kibana-errors',
    name: 'Error Analytics & Troubleshooting',
    description: 'Error analysis: root cause detection, debugging, troubleshooting',
    provider: 'kibana',
    category: 'Operations',
    icon: '🐛',
    url: url(4251, '/app/dashboards/error-analytics'),
    ssoUrl: ssoUrl(url(4251, '/app/dashboards/error-analytics')),
    healthPath: '/api/status',
    requiresAuth: true,
    tags: ['errors', 'debugging', 'troubleshooting', 'logs'],
  },
  {
    id: 'kibana-registry',
    name: 'Registry - Service Catalog Analytics',
    description: 'Service registration analytics: discovery, health, dependencies',
    provider: 'kibana',
    category: 'Infrastructure',
    icon: '📋',
    url: url(4251, '/app/dashboards/registry-service-analytics'),
    ssoUrl: ssoUrl(url(4251, '/app/dashboards/registry-service-analytics')),
    healthPath: '/api/status',
    requiresAuth: true,
    tags: ['registry', 'services', 'discovery', 'analytics'],
  },
  {
    id: 'kibana-lis',
    name: 'LIS - Lab Operations',
    description: 'Lab operations dashboard: sample processing, instrument status',
    provider: 'kibana',
    category: 'Healthcare',
    icon: '🔬',
    url: url(4251, '/app/dashboards/lis-lab-operations'),
    ssoUrl: ssoUrl(url(4251, '/app/dashboards/lis-lab-operations')),
    healthPath: '/api/status',
    requiresAuth: true,
    tags: ['LIS', 'lab', 'operations', 'samples'],
  },
];

// ─── Custom Dashboards ───────────────────────────────────────────────────────
export const CUSTOM_DASHBOARDS: DashboardDef[] = [
  {
    id: 'custom-infrastructure-health',
    name: 'Infrastructure Health Scorecard',
    description: 'Overall infrastructure health scoring across all components',
    provider: 'custom',
    category: 'Infrastructure',
    icon: '📈',
    url: url(3000, '/dashboards/infrastructure-health'),
    ssoUrl: url(3000, '/dashboards/infrastructure-health'),
    healthPath: '/api/health',
    requiresAuth: true,
    tags: ['health', 'scorecard', 'infrastructure', 'overview'],
    refreshInterval: 60,
  },
  {
    id: 'custom-service-topology',
    name: 'Service Topology Map',
    description: 'Visual dependency graph of all services and their relationships',
    provider: 'custom',
    category: 'Infrastructure',
    icon: '🕸️',
    url: url(3000, '/dashboards/service-topology'),
    ssoUrl: url(3000, '/dashboards/service-topology'),
    healthPath: '/api/health',
    requiresAuth: true,
    tags: ['topology', 'dependencies', 'graph', 'services'],
  },
  {
    id: 'custom-compliance',
    name: 'Compliance Dashboard',
    description: 'HIPAA/GDPR compliance metrics, audit status, violation tracking',
    provider: 'custom',
    category: 'Security',
    icon: '✅',
    url: url(3000, '/dashboards/compliance'),
    ssoUrl: url(3000, '/dashboards/compliance'),
    healthPath: '/api/health',
    requiresAuth: true,
    tags: ['compliance', 'HIPAA', 'GDPR', 'audit'],
  },
];

// ─── All Dashboards Combined ─────────────────────────────────────────────────
export const ALL_DASHBOARDS: DashboardDef[] = [
  ...GRAFANA_DASHBOARDS,
  ...KIBANA_DASHBOARDS,
  ...CUSTOM_DASHBOARDS,
];

// ─── Helper Functions ──────────────────────────────────────────────────────
export function getDashboardById(id: string): DashboardDef | undefined {
  return ALL_DASHBOARDS.find((d) => d.id === id);
}

export function getDashboardsByCategory(category: string): DashboardDef[] {
  return ALL_DASHBOARDS.filter((d) => d.category === category);
}

export function getDashboardsByProvider(provider: DashboardProvider): DashboardDef[] {
  return ALL_DASHBOARDS.filter((d) => d.provider === provider);
}

export function getDashboardsByTag(tag: string): DashboardDef[] {
  return ALL_DASHBOARDS.filter((d) => d.tags.includes(tag));
}

export const DASHBOARD_CATEGORIES = [
  'Infrastructure',
  'Healthcare',
  'Security',
  'AI Platform',
  'Operations',
];

export const CATEGORY_COLORS: Record<string, string> = {
  'Infrastructure': '#f97316',
  'Healthcare': '#06b6d4',
  'Security': '#ef4444',
  'AI Platform': '#8b5cf6',
  'Operations': '#10b981',
};
