/**
 * /api/agent — Nexus AI Agent API Route
 * MedinovAI Command Center v3.0
 * (c) 2026 Copyright MedinovAI. All Rights Reserved.
 *
 * Provides the HTTP interface for the Nexus AI Agent.
 * Enforces authentication, rate limiting, and audit logging.
 */

import { NextRequest, NextResponse } from 'next/server';

// ── Constants ──────────────────────────────────────────────────────────────
const E_RATE_LIMIT_WINDOW_MS = 60 * 1000; // 1 minute
const E_RATE_LIMIT_MAX_REQUESTS = 30;
const E_MAX_INPUT_LENGTH = 2000;
const E_ALLOWED_ENVIRONMENTS = ['dev', 'qa', 'staging', 'production'];

// Simple in-memory rate limiter (replace with Redis in production)
const mos_rateLimitStore = new Map<string, { count: number; resetAt: number }>();

function checkRateLimit(clientId: string): boolean {
  const mos_now = Date.now();
  const mos_entry = mos_rateLimitStore.get(clientId);

  if (!mos_entry || mos_now > mos_entry.resetAt) {
    mos_rateLimitStore.set(clientId, { count: 1, resetAt: mos_now + E_RATE_LIMIT_WINDOW_MS });
    return true;
  }

  if (mos_entry.count >= E_RATE_LIMIT_MAX_REQUESTS) return false;
  mos_entry.count++;
  return true;
}

function detectBot(req: NextRequest): boolean {
  const mos_ua = req.headers.get('user-agent') || '';
  const mos_botPatterns = [
    /bot|crawler|spider|scraper|curl|wget|python-requests|go-http/i,
    /GPTBot|ChatGPT|ClaudeBot|anthropic|cohere|ai2bot/i,
    /Googlebot|Bingbot|Slurp|DuckDuckBot/i,
  ];
  return mos_botPatterns.some(p => p.test(mos_ua));
}

export async function POST(req: NextRequest) {
  // ── Bot/Crawler Shield ───────────────────────────────────────────────────
  if (detectBot(req)) {
    return NextResponse.json(
      { error: 'Access denied' },
      { status: 403 }
    );
  }

  // ── Authentication ───────────────────────────────────────────────────────
  const mos_authHeader = req.headers.get('authorization');
  const mos_sessionCookie = req.cookies.get('nexus-session');

  if (!mos_authHeader && !mos_sessionCookie) {
    return NextResponse.json(
      { error: 'Authentication required' },
      { status: 401 }
    );
  }

  // ── Rate Limiting ────────────────────────────────────────────────────────
  const mos_clientId = req.headers.get('x-forwarded-for') || req.ip || 'unknown';
  if (!checkRateLimit(mos_clientId)) {
    return NextResponse.json(
      { error: 'Rate limit exceeded. Please wait before sending more requests.' },
      { status: 429 }
    );
  }

  // ── Input Validation ─────────────────────────────────────────────────────
  let mos_body: { query?: string; environment?: string; sessionId?: string };
  try {
    mos_body = await req.json();
  } catch {
    return NextResponse.json({ error: 'Invalid JSON body' }, { status: 400 });
  }

  const { query, environment = 'dev', sessionId = 'unknown' } = mos_body;

  if (!query || typeof query !== 'string') {
    return NextResponse.json({ error: 'query is required' }, { status: 400 });
  }

  if (query.length > E_MAX_INPUT_LENGTH) {
    return NextResponse.json(
      { error: `Query too long. Max ${E_MAX_INPUT_LENGTH} characters.` },
      { status: 400 }
    );
  }

  if (!E_ALLOWED_ENVIRONMENTS.includes(environment)) {
    return NextResponse.json(
      { error: `Invalid environment. Must be one of: ${E_ALLOWED_ENVIRONMENTS.join(', ')}` },
      { status: 400 }
    );
  }

  // ── Sanitize Input ───────────────────────────────────────────────────────
  const mos_sanitizedQuery = query
    .replace(/<[^>]*>/g, '') // strip HTML
    .replace(/[<>'"]/g, '') // strip special chars
    .trim();

  // ── Call Nexus Agent ─────────────────────────────────────────────────────
  try {
    // Dynamic import to avoid loading the agent on every request
    const { nexusAgent } = await import('@/lib/agent/nexus-singleton');

    const mos_result = await nexusAgent.query(mos_sanitizedQuery, {
      environment,
      userId: mos_authHeader || 'session-user',
      sessionId,
    });

    // ── Audit Log ──────────────────────────────────────────────────────────
    // In production: write to immutable audit chain
    console.log(JSON.stringify({
      event: 'nexus_query',
      environment,
      sessionId,
      queryLength: mos_sanitizedQuery.length,
      actionsCount: mos_result.actions.length,
      confidence: mos_result.confidence,
      timestamp: new Date().toISOString(),
      // Never log the actual query content — may contain sensitive operational data
    }));

    return NextResponse.json({
      response: mos_result.response,
      actions: mos_result.actions.map(a => ({
        id: a.id,
        type: a.type,
        description: a.description,
        requiresApproval: a.requiresApproval,
        confidence: a.confidence,
      })),
      confidence: mos_result.confidence,
      agent: 'Nexus',
      version: '3.0.0',
    });
  } catch (mos_error) {
    console.error('[Nexus API] Error:', mos_error);
    return NextResponse.json(
      { error: 'Nexus agent encountered an error. Please try again.' },
      { status: 500 }
    );
  }
}

export async function GET(req: NextRequest) {
  if (detectBot(req)) {
    return NextResponse.json({ error: 'Access denied' }, { status: 403 });
  }

  try {
    const { nexusAgent } = await import('@/lib/agent/nexus-singleton');
    return NextResponse.json({
      status: nexusAgent.getStatus(),
      version: '3.0.0',
      copyright: '(c) 2026 MedinovAI. All Rights Reserved.',
    });
  } catch {
    return NextResponse.json({ status: 'initializing' });
  }
}
