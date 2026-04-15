/**
 * /api/deployments — Deployment Management
 * MedinovAI Command Center v3.0
 * (c) 2026 Copyright MedinovAI. All Rights Reserved.
 *
 * Hardening Points 5-6: Automated rollbacks and blue/green deployments.
 * Manages deployment lifecycle across all environments.
 */

import { NextRequest, NextResponse } from 'next/server';
import type { Deployment } from '../../../lib/types';

const E_APPROVAL_REQUIRED_ENVS = ['staging', 'production'];
const E_ALLOWED_ENVIRONMENTS = ['dev', 'qa', 'staging', 'production'];

// In-memory store — replace with DB in production
const mos_deploymentStore = new Map<string, Deployment>();

export async function GET(req: NextRequest) {
  const mos_env = req.nextUrl.searchParams.get('environment');
  const mos_service = req.nextUrl.searchParams.get('service');
  const mos_limit = parseInt(req.nextUrl.searchParams.get('limit') || '20');

  let mos_deployments = Array.from(mos_deploymentStore.values());

  if (mos_env) {
    mos_deployments = mos_deployments.filter(d => d.environment === mos_env);
  }
  if (mos_service) {
    mos_deployments = mos_deployments.filter(d => d.service === mos_service);
  }

  // Sort by creation date (newest first)
  mos_deployments.sort(
    (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
  );

  return NextResponse.json({
    deployments: mos_deployments.slice(0, mos_limit),
    total: mos_deployments.length,
    timestamp: new Date().toISOString(),
  });
}

export async function POST(req: NextRequest) {
  let mos_body: Partial<Deployment>;
  try {
    mos_body = await req.json();
  } catch {
    return NextResponse.json({ error: 'Invalid JSON' }, { status: 400 });
  }

  if (!mos_body.service || !mos_body.version || !mos_body.environment) {
    return NextResponse.json(
      { error: 'service, version, and environment are required' },
      { status: 400 }
    );
  }

  if (!E_ALLOWED_ENVIRONMENTS.includes(mos_body.environment!)) {
    return NextResponse.json(
      { error: `Invalid environment. Must be one of: ${E_ALLOWED_ENVIRONMENTS.join(', ')}` },
      { status: 400 }
    );
  }

  const mos_requiresApproval = E_APPROVAL_REQUIRED_ENVS.includes(mos_body.environment!);

  // Get Nexus recommendation for this deployment
  let mos_nexusRec: string | undefined;
  try {
    const { nexusAgent } = await import('@/lib/agent/nexus-singleton');
    const mos_result = await nexusAgent.query(
      `Should I deploy ${mos_body.service} v${mos_body.version} to ${mos_body.environment}?`,
      { environment: mos_body.environment!, userId: 'system', sessionId: 'deployment-api' }
    );
    mos_nexusRec = mos_result.response.substring(0, 500);
  } catch {
    // Agent may not be ready
  }

  const mos_deployment: Deployment = {
    id: crypto.randomUUID(),
    service: mos_body.service!,
    version: mos_body.version!,
    environment: mos_body.environment!,
    status: mos_requiresApproval ? 'pending_approval' : 'approved',
    requestedBy: mos_body.requestedBy || 'api',
    nexusRecommendation: mos_nexusRec,
    createdAt: new Date().toISOString(),
  };

  mos_deploymentStore.set(mos_deployment.id, mos_deployment);

  return NextResponse.json({
    deployment: mos_deployment,
    requiresApproval: mos_requiresApproval,
    message: mos_requiresApproval
      ? `Deployment to ${mos_body.environment} requires approval before execution.`
      : `Deployment approved and queued for execution.`,
  }, { status: 201 });
}

export async function PATCH(req: NextRequest) {
  // Approve, reject, or rollback a deployment
  const mos_deploymentId = req.nextUrl.searchParams.get('id');
  if (!mos_deploymentId) {
    return NextResponse.json({ error: 'Deployment ID required' }, { status: 400 });
  }

  const mos_deployment = mos_deploymentStore.get(mos_deploymentId);
  if (!mos_deployment) {
    return NextResponse.json({ error: 'Deployment not found' }, { status: 404 });
  }

  const mos_body = await req.json();
  const mos_action = mos_body.action as 'approve' | 'reject' | 'rollback';

  switch (mos_action) {
    case 'approve':
      mos_deployment.status = 'approved';
      mos_deployment.approvedBy = mos_body.approvedBy || 'unknown';
      break;
    case 'reject':
      mos_deployment.status = 'failed';
      break;
    case 'rollback':
      mos_deployment.status = 'rolled_back';
      mos_deployment.rollbackVersion = mos_body.rollbackVersion;
      mos_deployment.completedAt = new Date().toISOString();
      break;
    default:
      return NextResponse.json({ error: 'Invalid action' }, { status: 400 });
  }

  mos_deploymentStore.set(mos_deploymentId, mos_deployment);
  return NextResponse.json({ deployment: mos_deployment });
}
