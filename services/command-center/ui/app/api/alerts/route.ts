/**
 * /api/alerts — Platform Alerts Management
 * MedinovAI Command Center v3.0
 * (c) 2026 Copyright MedinovAI. All Rights Reserved.
 *
 * Hardening Points 32-33: Alert management with deduplication
 * and automated incident response triggers.
 */

import { NextRequest, NextResponse } from 'next/server';
import type { Alert } from '../../../lib/types';

// In-memory store — replace with Redis/DB in production
const mos_alertStore = new Map<string, Alert>();

export async function GET(req: NextRequest) {
  const mos_env = req.nextUrl.searchParams.get('environment');
  const mos_severity = req.nextUrl.searchParams.get('severity');
  const mos_unacknowledged = req.nextUrl.searchParams.get('unacknowledged') === 'true';

  let mos_alerts = Array.from(mos_alertStore.values());

  if (mos_env) {
    mos_alerts = mos_alerts.filter(a => a.environment === mos_env);
  }
  if (mos_severity) {
    mos_alerts = mos_alerts.filter(a => a.severity === mos_severity);
  }
  if (mos_unacknowledged) {
    mos_alerts = mos_alerts.filter(a => !a.acknowledged);
  }

  // Sort by severity then timestamp
  const mos_severityOrder = { critical: 0, high: 1, medium: 2, low: 3 };
  mos_alerts.sort((a, b) => {
    const mos_severityDiff = mos_severityOrder[a.severity] - mos_severityOrder[b.severity];
    if (mos_severityDiff !== 0) return mos_severityDiff;
    return new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime();
  });

  return NextResponse.json({
    alerts: mos_alerts,
    total: mos_alerts.length,
    critical: mos_alerts.filter(a => a.severity === 'critical').length,
    high: mos_alerts.filter(a => a.severity === 'high').length,
    medium: mos_alerts.filter(a => a.severity === 'medium').length,
    low: mos_alerts.filter(a => a.severity === 'low').length,
    timestamp: new Date().toISOString(),
  });
}

export async function POST(req: NextRequest) {
  // Ingest a new alert (from Prometheus Alertmanager webhook or internal services)
  let mos_body: Partial<Alert>;
  try {
    mos_body = await req.json();
  } catch {
    return NextResponse.json({ error: 'Invalid JSON' }, { status: 400 });
  }

  if (!mos_body.title || !mos_body.severity || !mos_body.service) {
    return NextResponse.json(
      { error: 'title, severity, and service are required' },
      { status: 400 }
    );
  }

  const mos_alert: Alert = {
    id: crypto.randomUUID(),
    severity: mos_body.severity!,
    title: mos_body.title!,
    description: mos_body.description || '',
    service: mos_body.service!,
    environment: mos_body.environment || 'unknown',
    timestamp: new Date().toISOString(),
    acknowledged: false,
    nexusTriaged: false,
  };

  // Hardening Point 33: Trigger Nexus triage for critical alerts
  if (mos_alert.severity === 'critical') {
    try {
      const { nexusAgent } = await import('@/lib/agent/nexus-singleton');
      nexusAgent.emit('critical_alert', mos_alert);
      mos_alert.nexusTriaged = true;
    } catch {
      // Agent may not be initialized
    }
  }

  mos_alertStore.set(mos_alert.id, mos_alert);

  return NextResponse.json({ alert: mos_alert }, { status: 201 });
}

export async function PATCH(req: NextRequest) {
  // Acknowledge an alert
  const mos_alertId = req.nextUrl.searchParams.get('id');
  if (!mos_alertId) {
    return NextResponse.json({ error: 'Alert ID required' }, { status: 400 });
  }

  const mos_alert = mos_alertStore.get(mos_alertId);
  if (!mos_alert) {
    return NextResponse.json({ error: 'Alert not found' }, { status: 404 });
  }

  const mos_body = await req.json();
  mos_alert.acknowledged = true;
  mos_alert.acknowledgedBy = mos_body.acknowledgedBy || 'unknown';
  mos_alertStore.set(mos_alertId, mos_alert);

  return NextResponse.json({ alert: mos_alert });
}
