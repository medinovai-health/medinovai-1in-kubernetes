// ─── SSO Relay ────────────────────────────────────────────────────────────────
// Validates JWTs against the auth-service and provides token relay for
// cross-app navigation (medinovaiOS ↔ Atlas ↔ other MedinovAI apps).
// ─────────────────────────────────────────────────────────────────────────────

import type { Request, Response } from 'express';

const AUTH_SERVICE_URL = process.env.AUTH_SERVICE_URL ?? 'http://localhost:30081';

interface TokenPayload {
  sub: string;
  email?: string;
  role?: string;
  exp?: number;
}

async function callAuthService(path: string, method: string, body?: object): Promise<Response | null> {
  try {
    const res = await fetch(`${AUTH_SERVICE_URL}${path}`, {
      method,
      headers: { 'Content-Type': 'application/json' },
      body: body ? JSON.stringify(body) : undefined,
      signal: AbortSignal.timeout(5000),
    });
    return res as unknown as Response;
  } catch {
    return null;
  }
}

export async function handleLogin(req: Request, res: Response) {
  const { email, password } = req.body ?? {};
  if (!email || !password) {
    return res.status(400).json({ message: 'email and password required' });
  }

  const upstream = await callAuthService('/auth/login', 'POST', { email, password });
  if (!upstream) {
    // Auth service unreachable — allow guest login in dev environment
    if (process.env.NODE_ENV !== 'production') {
      const devToken = Buffer.from(JSON.stringify({ sub: 'dev', email, role: 'admin', exp: Date.now() / 1000 + 86400 })).toString('base64');
      return res.json({ token: `dev.${devToken}.sig`, user: { email, role: 'admin' } });
    }
    return res.status(503).json({ message: 'Auth service unavailable' });
  }

  const data = await (upstream as unknown as globalThis.Response).json().catch(() => ({}));
  return res.status((upstream as unknown as globalThis.Response).status).json(data);
}

export async function handleValidate(req: Request, res: Response) {
  const authHeader = req.headers.authorization ?? '';
  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : authHeader;

  if (!token) return res.status(401).json({ valid: false });

  // Guest token always valid
  if (token === 'guest') return res.json({ valid: true, role: 'guest' });

  // Dev token (base64 payload, no real sig check in non-production)
  if (token.startsWith('dev.') && process.env.NODE_ENV !== 'production') {
    try {
      const payload: TokenPayload = JSON.parse(Buffer.from(token.split('.')[1], 'base64').toString());
      if (payload.exp && payload.exp * 1000 < Date.now()) {
        return res.status(401).json({ valid: false, reason: 'expired' });
      }
      return res.json({ valid: true, user: payload });
    } catch {
      return res.status(401).json({ valid: false });
    }
  }

  // Forward to auth-service for real JWT validation
  const upstream = await callAuthService('/auth/validate', 'POST', { token });
  if (!upstream) {
    // Fail open in dev (network error to auth service)
    if (process.env.NODE_ENV !== 'production') return res.json({ valid: true, role: 'unknown' });
    return res.status(503).json({ valid: false, reason: 'auth service unreachable' });
  }

  const data = await (upstream as unknown as globalThis.Response).json().catch(() => ({}));
  return res.status((upstream as unknown as globalThis.Response).status).json(data);
}
