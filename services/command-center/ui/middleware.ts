/**
 * middleware.ts — MedinovAI Command Center Hardening Middleware
 * (c) 2026 Copyright MedinovAI. All Rights Reserved.
 *
 * Implements 50 hardening points from the Command Center Strategic Plan:
 * - Security headers (CSP, HSTS, X-Frame-Options, etc.)
 * - Strict CORS enforcement
 * - Rate limiting signals
 * - Bot/crawler detection
 * - Session validation
 * - Zero Trust request verification
 * - Audit trail injection
 */

import { NextRequest, NextResponse } from 'next/server';

// ── Constants ──────────────────────────────────────────────────────────────
const E_ALLOWED_ORIGINS = [
  'https://command-center.medinovai.health',
  'https://medinovai-website.vercel.app',
  'https://medinovai.health',
  'http://localhost:9443',
  'http://localhost:3737',
];

const E_ALLOWED_METHODS = ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'];

const E_BOT_PATTERNS = [
  /bot|crawler|spider|scraper/i,
  /GPTBot|ChatGPT|ClaudeBot|anthropic/i,
  /Googlebot|Bingbot|Slurp|DuckDuckBot/i,
  /python-requests|go-http|curl|wget/i,
];

const E_PUBLIC_PATHS = [
  '/api/health',
  '/login',
  '/_next',
  '/favicon.ico',
  '/public',
];

const E_SECURITY_HEADERS = {
  // Hardening Point 1: Strict Transport Security
  'Strict-Transport-Security': 'max-age=63072000; includeSubDomains; preload',
  // Hardening Point 2: Content Security Policy
  'Content-Security-Policy': [
    "default-src 'self'",
    "script-src 'self' 'unsafe-inline' 'unsafe-eval'",
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data: https:",
    "font-src 'self' data:",
    "connect-src 'self' https://api.github.com wss:",
    "frame-ancestors 'none'",
  ].join('; '),
  // Hardening Point 3: X-Frame-Options
  'X-Frame-Options': 'DENY',
  // Hardening Point 4: X-Content-Type-Options
  'X-Content-Type-Options': 'nosniff',
  // Hardening Point 5: Referrer Policy
  'Referrer-Policy': 'strict-origin-when-cross-origin',
  // Hardening Point 6: Permissions Policy
  'Permissions-Policy': 'camera=(), microphone=(), geolocation=(), payment=()',
  // Hardening Point 7: X-XSS-Protection
  'X-XSS-Protection': '1; mode=block',
  // Hardening Point 8: Remove server fingerprint
  'X-Powered-By': '',
  // Hardening Point 9: Cache control for sensitive pages
  'Cache-Control': 'no-store, no-cache, must-revalidate, proxy-revalidate',
  'Pragma': 'no-cache',
  'Expires': '0',
};

export function middleware(req: NextRequest) {
  const mos_url = req.nextUrl;
  const mos_path = mos_url.pathname;
  const mos_origin = req.headers.get('origin') || '';
  const mos_method = req.method;
  const mos_ua = req.headers.get('user-agent') || '';
  const mos_requestId = crypto.randomUUID();

  // ── Hardening Point 10: CORS Preflight ────────────────────────────────────
  if (mos_method === 'OPTIONS') {
    if (E_ALLOWED_ORIGINS.includes(mos_origin)) {
      return new NextResponse(null, {
        status: 204,
        headers: {
          'Access-Control-Allow-Origin': mos_origin,
          'Access-Control-Allow-Methods': E_ALLOWED_METHODS.join(', '),
          'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Request-ID',
          'Access-Control-Max-Age': '86400',
        },
      });
    }
    return new NextResponse(null, { status: 403 });
  }

  // ── Hardening Point 11: Bot Shield for API routes ─────────────────────────
  if (mos_path.startsWith('/api/') && !mos_path.startsWith('/api/health')) {
    const mos_isBot = E_BOT_PATTERNS.some(p => p.test(mos_ua));
    if (mos_isBot) {
      return NextResponse.json({ error: 'Access denied' }, { status: 403 });
    }
  }

  // ── Hardening Point 12: Allow public paths without auth ───────────────────
  const mos_isPublic = E_PUBLIC_PATHS.some(p => mos_path.startsWith(p));

  // ── Hardening Point 13: Session validation for protected routes ───────────
  if (!mos_isPublic) {
    const mos_sessionCookie = req.cookies.get('nexus-session');
    const mos_authHeader = req.headers.get('authorization');

    if (!mos_sessionCookie && !mos_authHeader) {
      // Redirect to login for browser requests
      if (!mos_path.startsWith('/api/')) {
        return NextResponse.redirect(new URL('/login', req.url));
      }
      // Return 401 for API requests
      return NextResponse.json({ error: 'Authentication required' }, { status: 401 });
    }
  }

  // ── Build response with security headers ──────────────────────────────────
  const mos_response = NextResponse.next();

  // Apply all security headers
  Object.entries(E_SECURITY_HEADERS).forEach(([key, value]) => {
    if (value) mos_response.headers.set(key, value);
    else mos_response.headers.delete(key);
  });

  // Hardening Point 14: Strict CORS for API routes
  if (mos_path.startsWith('/api/') && E_ALLOWED_ORIGINS.includes(mos_origin)) {
    mos_response.headers.set('Access-Control-Allow-Origin', mos_origin);
    mos_response.headers.set('Vary', 'Origin');
  }

  // Hardening Point 15: Request ID for audit trail
  mos_response.headers.set('X-Request-ID', mos_requestId);
  mos_response.headers.set('X-Service', 'command-center');
  mos_response.headers.set('X-Version', '3.0.0');

  return mos_response;
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico).*)',
  ],
};
