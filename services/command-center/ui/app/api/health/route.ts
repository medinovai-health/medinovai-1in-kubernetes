/**
 * /api/health — Command Center Health Check
 * MedinovAI Command Center v3.0
 * (c) 2026 Copyright MedinovAI. All Rights Reserved.
 */

import { NextRequest, NextResponse } from 'next/server';

const E_VERSION = '3.0.0';
const E_BUILD = process.env.NEXT_PUBLIC_BUILD_ID || 'local';
const E_ENVIRONMENT = process.env.NEXT_PUBLIC_ENVIRONMENT || 'dev';

export async function GET(req: NextRequest) {
  const mos_start = Date.now();

  // Shallow health check for load balancer
  const mos_shallow = req.nextUrl.searchParams.get('depth') !== 'deep';

  if (mos_shallow) {
    return NextResponse.json({
      status: 'healthy',
      service: 'command-center',
      version: E_VERSION,
      build: E_BUILD,
      environment: E_ENVIRONMENT,
      timestamp: new Date().toISOString(),
    });
  }

  // Deep health check — checks all dependencies
  const mos_checks: Record<string, { status: string; latencyMs?: number; error?: string }> = {};

  // Check Nexus Agent
  try {
    const { nexusAgent } = await import('@/lib/agent/nexus-singleton');
    const mos_agentStatus = nexusAgent.getStatus();
    mos_checks.nexus_agent = {
      status: mos_agentStatus.isRunning ? 'healthy' : 'degraded',
    };
  } catch {
    mos_checks.nexus_agent = { status: 'unhealthy', error: 'Agent not initialized' };
  }

  // Check Brain sync
  try {
    const mos_brainStart = Date.now();
    const mos_res = await fetch(
      `https://api.github.com/repos/medinovai-health/medinovai-platform-brain/contents/agent-knowledge/JCODEMUNCH_INDEX.json`,
      {
        headers: { Authorization: `token ${process.env.GITHUB_TOKEN}` },
        signal: AbortSignal.timeout(5000),
      }
    );
    mos_checks.brain_sync = {
      status: mos_res.ok ? 'healthy' : 'degraded',
      latencyMs: Date.now() - mos_brainStart,
    };
  } catch {
    mos_checks.brain_sync = { status: 'degraded', error: 'Brain unreachable' };
  }

  // Check AtlasOS gateway
  const mos_gatewayUrl = process.env.ATLASOS_GATEWAY_URL;
  if (mos_gatewayUrl) {
    try {
      const mos_gwStart = Date.now();
      const mos_res = await fetch(`${mos_gatewayUrl}/health`, {
        signal: AbortSignal.timeout(3000),
      });
      mos_checks.atlasos_gateway = {
        status: mos_res.ok ? 'healthy' : 'degraded',
        latencyMs: Date.now() - mos_gwStart,
      };
    } catch {
      mos_checks.atlasos_gateway = { status: 'unreachable' };
    }
  }

  const mos_allHealthy = Object.values(mos_checks).every(c => c.status === 'healthy');
  const mos_anyUnhealthy = Object.values(mos_checks).some(c => c.status === 'unhealthy');

  return NextResponse.json({
    status: mos_anyUnhealthy ? 'unhealthy' : mos_allHealthy ? 'healthy' : 'degraded',
    service: 'command-center',
    version: E_VERSION,
    build: E_BUILD,
    environment: E_ENVIRONMENT,
    checks: mos_checks,
    totalLatencyMs: Date.now() - mos_start,
    timestamp: new Date().toISOString(),
    copyright: '(c) 2026 MedinovAI. All Rights Reserved.',
  }, {
    status: mos_anyUnhealthy ? 503 : 200,
  });
}
