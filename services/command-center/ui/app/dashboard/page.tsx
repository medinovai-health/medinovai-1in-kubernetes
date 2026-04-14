/**
 * /dashboard — MedinovAI Command Center Dashboard
 * (c) 2026 Copyright MedinovAI. All Rights Reserved.
 *
 * The primary control plane view — shows platform health, active alerts,
 * environment status, and Nexus agent activity in real-time.
 */

'use client';

import { useState, useEffect, useCallback } from 'react';

// ── Types ──────────────────────────────────────────────────────────────────
type EnvironmentStatus = {
  name: string;
  status: 'healthy' | 'degraded' | 'unhealthy' | 'unknown';
  services: number;
  healthyServices: number;
  lastDeployedAt: string;
  version: string;
};

type PlatformAlert = {
  id: string;
  severity: 'critical' | 'high' | 'medium' | 'low';
  title: string;
  service: string;
  environment: string;
  timestamp: string;
  acknowledged: boolean;
};

type NexusStatus = {
  isRunning: boolean;
  memoryEntries: number;
  knowledgeSyncedAt: string;
  pendingActions: number;
  selfImprovementCount: number;
};

// ── Constants ──────────────────────────────────────────────────────────────
const E_ENVIRONMENTS: EnvironmentStatus[] = [
  { name: 'Production', status: 'healthy', services: 190, healthyServices: 188, lastDeployedAt: '2026-04-14T12:00:00Z', version: '3.0.0' },
  { name: 'Staging', status: 'healthy', services: 185, healthyServices: 185, lastDeployedAt: '2026-04-14T10:00:00Z', version: '3.0.1-rc.1' },
  { name: 'QA', status: 'degraded', services: 180, healthyServices: 172, lastDeployedAt: '2026-04-14T08:00:00Z', version: '3.1.0-beta.3' },
  { name: 'Dev', status: 'healthy', services: 175, healthyServices: 175, lastDeployedAt: '2026-04-14T14:00:00Z', version: '3.1.0-dev' },
];

const E_STATUS_COLORS = {
  healthy: 'text-emerald-400',
  degraded: 'text-amber-400',
  unhealthy: 'text-red-400',
  unknown: 'text-slate-400',
};

const E_SEVERITY_COLORS = {
  critical: 'bg-red-500/20 text-red-300 border-red-500/30',
  high: 'bg-orange-500/20 text-orange-300 border-orange-500/30',
  medium: 'bg-amber-500/20 text-amber-300 border-amber-500/30',
  low: 'bg-blue-500/20 text-blue-300 border-blue-500/30',
};

// ── Component ──────────────────────────────────────────────────────────────
export default function DashboardPage() {
  const [mos_nexusStatus, setMosNexusStatus] = useState<NexusStatus | null>(null);
  const [mos_alerts, setMosAlerts] = useState<PlatformAlert[]>([]);
  const [mos_nexusQuery, setMosNexusQuery] = useState('');
  const [mos_nexusResponse, setMosNexusResponse] = useState('');
  const [mos_isQuerying, setMosIsQuerying] = useState(false);
  const [mos_lastSync, setMosLastSync] = useState<string>('');

  const fetchNexusStatus = useCallback(async () => {
    try {
      const mos_res = await fetch('/api/agent');
      if (mos_res.ok) {
        const mos_data = await mos_res.json();
        setMosNexusStatus(mos_data.status);
      }
    } catch {
      // Agent may still be initializing
    }
  }, []);

  const fetchAlerts = useCallback(async () => {
    try {
      const mos_res = await fetch('/api/alerts');
      if (mos_res.ok) {
        const mos_data = await mos_res.json();
        setMosAlerts(mos_data.alerts || []);
      }
    } catch {
      // Alerts endpoint may not be available
    }
  }, []);

  useEffect(() => {
    fetchNexusStatus();
    fetchAlerts();
    setMosLastSync(new Date().toLocaleTimeString());

    // Refresh every 30 seconds
    const mos_interval = setInterval(() => {
      fetchNexusStatus();
      fetchAlerts();
      setMosLastSync(new Date().toLocaleTimeString());
    }, 30000);

    return () => clearInterval(mos_interval);
  }, [fetchNexusStatus, fetchAlerts]);

  const handleNexusQuery = async () => {
    if (!mos_nexusQuery.trim() || mos_isQuerying) return;
    setMosIsQuerying(true);
    setMosNexusResponse('');

    try {
      const mos_res = await fetch('/api/agent', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          query: mos_nexusQuery,
          environment: 'production',
          sessionId: 'dashboard-session',
        }),
      });

      if (mos_res.ok) {
        const mos_data = await mos_res.json();
        setMosNexusResponse(mos_data.response);
      } else if (mos_res.status === 401) {
        setMosNexusResponse('Authentication required. Please log in to use Nexus.');
      } else {
        setMosNexusResponse('Nexus encountered an error. Please try again.');
      }
    } catch {
      setMosNexusResponse('Unable to reach Nexus. Check your connection.');
    } finally {
      setMosIsQuerying(false);
    }
  };

  const mos_totalAlerts = mos_alerts.length;
  const mos_criticalAlerts = mos_alerts.filter(a => a.severity === 'critical').length;
  const mos_overallHealth = E_ENVIRONMENTS.every(e => e.status === 'healthy') ? 'healthy' :
    E_ENVIRONMENTS.some(e => e.status === 'unhealthy') ? 'unhealthy' : 'degraded';

  return (
    <div className="min-h-screen bg-slate-950 p-6">
      {/* Header */}
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold text-white tracking-tight">
            MedinovAI Command Center
          </h1>
          <p className="text-slate-400 text-sm mt-1">
            v3.0.0 — Unified Control Plane — Last sync: {mos_lastSync}
          </p>
        </div>
        <div className="flex items-center gap-3">
          <span className={`text-sm font-medium ${E_STATUS_COLORS[mos_overallHealth]}`}>
            ● Platform {mos_overallHealth}
          </span>
          {mos_criticalAlerts > 0 && (
            <span className="bg-red-500/20 text-red-300 border border-red-500/30 text-xs px-2 py-1 rounded-full">
              {mos_criticalAlerts} critical
            </span>
          )}
        </div>
      </div>

      {/* Environment Status Grid — Bento Layout */}
      <div className="mos-bento mb-6">
        {E_ENVIRONMENTS.map(env => (
          <div key={env.name} className="mos-glass p-5">
            <div className="flex items-start justify-between mb-3">
              <div>
                <h3 className="text-white font-semibold">{env.name}</h3>
                <p className="text-slate-400 text-xs mt-0.5">v{env.version}</p>
              </div>
              <span className={`text-sm font-medium ${E_STATUS_COLORS[env.status]}`}>
                ● {env.status}
              </span>
            </div>
            <div className="space-y-2">
              <div className="flex justify-between text-sm">
                <span className="text-slate-400">Services</span>
                <span className="text-white">{env.healthyServices}/{env.services}</span>
              </div>
              <div className="w-full bg-slate-800 rounded-full h-1.5">
                <div
                  className={`h-1.5 rounded-full transition-all ${
                    env.status === 'healthy' ? 'bg-emerald-400' :
                    env.status === 'degraded' ? 'bg-amber-400' : 'bg-red-400'
                  }`}
                  style={{ width: `${(env.healthyServices / env.services) * 100}%` }}
                />
              </div>
              <p className="text-slate-500 text-xs">
                Last deploy: {new Date(env.lastDeployedAt).toLocaleString()}
              </p>
            </div>
          </div>
        ))}
      </div>

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Nexus Agent Panel */}
        <div className="lg:col-span-2 mos-glass p-6">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 rounded-full bg-blue-400 animate-pulse" />
              <h2 className="text-white font-semibold">Nexus AI Agent</h2>
              <span className="text-xs text-slate-400 bg-slate-800 px-2 py-0.5 rounded-full">
                {mos_nexusStatus?.isRunning ? 'Active' : 'Initializing'}
              </span>
            </div>
            {mos_nexusStatus && (
              <div className="flex gap-4 text-xs text-slate-400">
                <span>{mos_nexusStatus.memoryEntries} memories</span>
                <span>{mos_nexusStatus.pendingActions} pending</span>
                <span>{mos_nexusStatus.selfImprovementCount} improvements</span>
              </div>
            )}
          </div>

          {/* Nexus Response */}
          {mos_nexusResponse && (
            <div className="mos-nexus-bubble mb-4 mos-animate-in">
              <p className="text-slate-200 text-sm leading-relaxed whitespace-pre-wrap">
                {mos_nexusResponse}
              </p>
            </div>
          )}

          {/* Nexus Query Input */}
          <div className="flex gap-3 items-center">
            <input
              type="text"
              value={mos_nexusQuery}
              onChange={e => setMosNexusQuery(e.target.value)}
              onKeyDown={e => e.key === 'Enter' && handleNexusQuery()}
              placeholder="Ask Nexus anything — deployments, incidents, compliance, performance..."
              className="mos-command-input flex-1"
              disabled={mos_isQuerying}
            />
            <button
              onClick={handleNexusQuery}
              disabled={mos_isQuerying || !mos_nexusQuery.trim()}
              className="px-4 py-2 bg-blue-600 hover:bg-blue-500 disabled:opacity-50 disabled:cursor-not-allowed text-white text-sm rounded-lg transition-colors"
            >
              {mos_isQuerying ? '...' : 'Ask'}
            </button>
          </div>
        </div>

        {/* Alerts Panel */}
        <div className="mos-glass p-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-white font-semibold">Active Alerts</h2>
            <span className="text-xs text-slate-400">{mos_totalAlerts} total</span>
          </div>
          <div className="space-y-2 max-h-64 overflow-y-auto">
            {mos_alerts.length === 0 ? (
              <p className="text-slate-400 text-sm text-center py-4">
                No active alerts — all systems nominal
              </p>
            ) : (
              mos_alerts.slice(0, 10).map(alert => (
                <div
                  key={alert.id}
                  className={`p-3 rounded-lg border text-xs ${E_SEVERITY_COLORS[alert.severity]}`}
                >
                  <div className="font-medium">{alert.title}</div>
                  <div className="mt-1 opacity-75">{alert.service} · {alert.environment}</div>
                </div>
              ))
            )}
          </div>
        </div>
      </div>

      {/* Footer */}
      <div className="mt-8 text-center text-slate-600 text-xs">
        (c) 2026 MedinovAI. All Rights Reserved. — Command Center v3.0.0
      </div>
    </div>
  );
}
