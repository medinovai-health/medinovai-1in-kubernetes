/**
 * /api/sync — Brain & Platform Knowledge Sync
 * MedinovAI Command Center v3.0
 * (c) 2026 Copyright MedinovAI. All Rights Reserved.
 *
 * Keeps the Command Center in sync with:
 * - medinovai-platform-brain (knowledge graph)
 * - medinovai-Deploy (port registry, deployment state)
 * - medinovai-2pl-atlas-os (features.json, agent fleet)
 */

import { NextRequest, NextResponse } from 'next/server';

const E_BRAIN_REPO = 'medinovai-health/medinovai-platform-brain';
const E_DEPLOY_REPO = 'medinovai-health/medinovai-Deploy';
const E_ATLAS_REPO = 'medinovai-health/medinovai-2pl-atlas-os';

async function fetchGitHubFile(repo: string, path: string): Promise<string | null> {
  try {
    const mos_res = await fetch(
      `https://api.github.com/repos/${repo}/contents/${path}`,
      {
        headers: {
          Authorization: `token ${process.env.GITHUB_TOKEN}`,
          Accept: 'application/vnd.github.v3+json',
        },
        next: { revalidate: 300 }, // cache for 5 minutes
      }
    );
    if (!mos_res.ok) return null;
    const mos_data = await mos_res.json();
    return Buffer.from(mos_data.content, 'base64').toString('utf-8');
  } catch {
    return null;
  }
}

export async function GET(req: NextRequest) {
  const mos_source = req.nextUrl.searchParams.get('source') || 'all';
  const mos_results: Record<string, unknown> = {};

  if (mos_source === 'brain' || mos_source === 'all') {
    const mos_boot = await fetchGitHubFile(E_BRAIN_REPO, 'agent-knowledge/AGENT_BOOT.md');
    const mos_modules = await fetchGitHubFile(E_BRAIN_REPO, 'agent-knowledge/MODULE_INDEX.json');
    const mos_competitive = await fetchGitHubFile(E_BRAIN_REPO, 'agent-knowledge/COMPETITIVE_INTEL.json');
    const mos_deployment = await fetchGitHubFile(E_BRAIN_REPO, 'agent-knowledge/DEPLOYMENT_ARCHITECTURE.md');

    mos_results.brain = {
      status: mos_boot ? 'synced' : 'error',
      files: {
        agent_boot: mos_boot ? 'loaded' : 'missing',
        module_index: mos_modules ? 'loaded' : 'missing',
        competitive_intel: mos_competitive ? 'loaded' : 'missing',
        deployment_architecture: mos_deployment ? 'loaded' : 'missing',
      },
      moduleCount: mos_modules ? JSON.parse(mos_modules).length : 0,
      syncedAt: new Date().toISOString(),
    };
  }

  if (mos_source === 'deploy' || mos_source === 'all') {
    const mos_portRegistry = await fetchGitHubFile(E_DEPLOY_REPO, 'config/port-registry.json');
    mos_results.deploy = {
      status: mos_portRegistry ? 'synced' : 'error',
      portRegistry: mos_portRegistry ? 'loaded' : 'missing',
      syncedAt: new Date().toISOString(),
    };
  }

  if (mos_source === 'atlas' || mos_source === 'all') {
    const mos_features = await fetchGitHubFile(E_ATLAS_REPO, 'features.json');
    const mos_portConfig = await fetchGitHubFile(E_ATLAS_REPO, '.port-config.json');
    mos_results.atlas = {
      status: mos_features ? 'synced' : 'degraded',
      features: mos_features ? 'loaded' : 'missing',
      portConfig: mos_portConfig ? 'loaded' : 'missing',
      syncedAt: new Date().toISOString(),
    };
  }

  return NextResponse.json({
    syncResults: mos_results,
    timestamp: new Date().toISOString(),
    version: '3.0.0',
  });
}

export async function POST(req: NextRequest) {
  // Webhook handler for GitHub push events
  const mos_signature = req.headers.get('x-hub-signature-256');
  const mos_event = req.headers.get('x-github-event');

  if (!mos_signature || !mos_event) {
    return NextResponse.json({ error: 'Invalid webhook' }, { status: 400 });
  }

  // Verify webhook signature
  const mos_secret = process.env.GITHUB_WEBHOOK_SECRET;
  if (!mos_secret) {
    return NextResponse.json({ error: 'Webhook secret not configured' }, { status: 500 });
  }

  const mos_body = await req.text();

  // Verify HMAC signature
  const { createHmac } = await import('crypto');
  const mos_expected = `sha256=${createHmac('sha256', mos_secret).update(mos_body).digest('hex')}`;
  if (mos_signature !== mos_expected) {
    return NextResponse.json({ error: 'Invalid signature' }, { status: 401 });
  }

  const mos_payload = JSON.parse(mos_body);

  // Trigger Nexus knowledge sync on Brain push
  if (mos_event === 'push' && mos_payload.repository?.full_name === E_BRAIN_REPO) {
    try {
      const { nexusAgent } = await import('@/lib/agent/nexus-singleton');
      // Trigger immediate knowledge sync
      nexusAgent.emit('force_sync', { reason: 'github_webhook', timestamp: new Date() });
    } catch {
      // Agent may not be initialized yet
    }
  }

  return NextResponse.json({ received: true, event: mos_event });
}
