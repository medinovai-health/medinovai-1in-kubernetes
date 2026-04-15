/**
 * /api/metrics — Prometheus Metrics Endpoint
 * MedinovAI Command Center v3.0
 * (c) 2026 Copyright MedinovAI. All Rights Reserved.
 */

import { NextRequest, NextResponse } from 'next/server';
import { mos_metrics } from '../../../lib/metrics-store';

const E_VERSION = '3.0.0';
const E_START_TIME = Date.now();

export async function GET(req: NextRequest) {
  const mos_forwarded = req.headers.get('x-forwarded-for');
  const mos_realIp = req.headers.get('x-real-ip');
  const mos_ip = mos_forwarded?.split(',')[0] || mos_realIp || '';

  const mos_isInternal = /^(10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.|127\.|::1$|localhost)/.test(mos_ip);
  const mos_prometheusHeader = req.headers.get('x-prometheus-scrape') === 'true';

  if (!mos_isInternal && !mos_prometheusHeader) {
    return new NextResponse('Forbidden', { status: 403 });
  }

  mos_metrics.memory_usage_bytes = process.memoryUsage().heapUsed;
  const mos_uptime = Math.floor((Date.now() - E_START_TIME) / 1000);

  const mos_output = [
    `# HELP command_center_info Command Center version info`,
    `# TYPE command_center_info gauge`,
    `command_center_info{version="${E_VERSION}",service="command-center"} 1`,
    ``,
    `# HELP command_center_uptime_seconds Uptime in seconds`,
    `# TYPE command_center_uptime_seconds counter`,
    `command_center_uptime_seconds ${mos_uptime}`,
    ``,
    `# HELP command_center_http_requests_total Total HTTP requests`,
    `# TYPE command_center_http_requests_total counter`,
    `command_center_http_requests_total ${mos_metrics.http_requests_total}`,
    ``,
    `# HELP command_center_http_errors_total Total HTTP errors`,
    `# TYPE command_center_http_errors_total counter`,
    `command_center_http_errors_total ${mos_metrics.http_errors_total}`,
    ``,
    `# HELP nexus_queries_total Total Nexus agent queries`,
    `# TYPE nexus_queries_total counter`,
    `nexus_queries_total ${mos_metrics.nexus_queries_total}`,
    ``,
    `# HELP nexus_actions_approved_total Total Nexus actions approved`,
    `# TYPE nexus_actions_approved_total counter`,
    `nexus_actions_approved_total ${mos_metrics.nexus_actions_approved}`,
    ``,
    `# HELP nexus_actions_rejected_total Total Nexus actions rejected`,
    `# TYPE nexus_actions_rejected_total counter`,
    `nexus_actions_rejected_total ${mos_metrics.nexus_actions_rejected}`,
    ``,
    `# HELP brain_syncs_total Total Brain knowledge syncs`,
    `# TYPE brain_syncs_total counter`,
    `brain_syncs_total ${mos_metrics.brain_syncs_total}`,
    ``,
    `# HELP brain_sync_failures_total Total Brain sync failures`,
    `# TYPE brain_sync_failures_total counter`,
    `brain_sync_failures_total ${mos_metrics.brain_sync_failures}`,
    ``,
    `# HELP command_center_memory_bytes Memory usage in bytes`,
    `# TYPE command_center_memory_bytes gauge`,
    `command_center_memory_bytes ${mos_metrics.memory_usage_bytes}`,
    ``,
    `# HELP command_center_active_sessions Active user sessions`,
    `# TYPE command_center_active_sessions gauge`,
    `command_center_active_sessions ${mos_metrics.active_sessions}`,
    ``,
  ].join('\n');

  return new NextResponse(mos_output, {
    headers: {
      'Content-Type': 'text/plain; version=0.0.4; charset=utf-8',
      'Cache-Control': 'no-cache, no-store',
    },
  });
}
