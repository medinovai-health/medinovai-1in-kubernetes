// ─── SSO Relay (Keycloak OIDC) ────────────────────────────────────────────────
// Implements the server-side OIDC authorization code flow with PKCE.
// medinovaiOS is a confidential OIDC client — the Express server handles token
// exchange and stores tokens in httpOnly cookies (never exposed to the browser).
//
// Routes wired in server/index.ts:
//   GET  /api/sso/login     → redirect to Keycloak with PKCE challenge
//   GET  /api/sso/callback  → exchange code for tokens, set cookies, redirect home
//   GET  /api/sso/validate  → verify kc_access cookie (used by nginx auth_request)
//   GET  /api/sso/me        → return user info from valid access token
//   POST /api/sso/logout    → clear cookies + call Keycloak logout endpoint
//   GET  /api/sso/refresh   → use refresh token to rotate access token
// ─────────────────────────────────────────────────────────────────────────────

import type { Request, Response } from 'express';
import { createHash, randomBytes } from 'crypto';

// ── Configuration (from environment) ─────────────────────────────────────────
// KC_URL: internal URL for server-to-server calls (token exchange, JWKS, logout)
// KC_PUBLIC_URL: browser-facing URL for auth redirects (falls back to KC_URL)
const KC_URL        = process.env.KEYCLOAK_URL        ?? 'http://localhost:8081';
const KC_PUBLIC_URL = process.env.KEYCLOAK_PUBLIC_URL  ?? KC_URL;
const KC_REALM      = process.env.KEYCLOAK_REALM       ?? 'medinov-ai';
const CLIENT_ID     = process.env.KEYCLOAK_CLIENT_ID   ?? 'medinovaios';
const CLIENT_SECRET = process.env.KEYCLOAK_CLIENT_SECRET ?? '';
const REDIRECT_URI  = process.env.KEYCLOAK_REDIRECT_URI ?? 'http://localhost:3030/api/sso/callback';
const JWKS_URI      = process.env.KEYCLOAK_JWKS_URI     ?? `${KC_URL}/realms/${KC_REALM}/protocol/openid-connect/certs`;
const FORCE_SECURE_COOKIE = process.env.SSO_COOKIE_SECURE;
const IS_LOCAL_HTTP =
  KC_PUBLIC_URL.startsWith('http://localhost') ||
  REDIRECT_URI.startsWith('http://localhost');

const TOKEN_ENDPOINT  = `${KC_URL}/realms/${KC_REALM}/protocol/openid-connect/token`;
const AUTH_ENDPOINT   = `${KC_PUBLIC_URL}/realms/${KC_REALM}/protocol/openid-connect/auth`;
const LOGOUT_ENDPOINT = `${KC_URL}/realms/${KC_REALM}/protocol/openid-connect/logout`;

// Cookie names
const COOKIE_ACCESS   = 'kc_access';
const COOKIE_REFRESH  = 'kc_refresh';
const COOKIE_STATE    = 'kc_state';

// Cookie options — httpOnly prevents XSS token theft
const COOKIE_OPTS = {
  httpOnly: true,
  // Local development uses http://localhost, so secure cookies would be dropped.
  secure: FORCE_SECURE_COOKIE
    ? FORCE_SECURE_COOKIE === 'true'
    : process.env.NODE_ENV === 'production' && !IS_LOCAL_HTTP,
  sameSite: 'lax' as const,
  path: '/',
};

// ── JWKS Cache ────────────────────────────────────────────────────────────────
interface JwksKey {
  kid: string;
  n: string;
  e: string;
  alg: string;
  use: string;
}

let jwksCache: { keys: JwksKey[]; fetchedAt: number } | null = null;
const JWKS_TTL_MS = 5 * 60 * 1000; // 5 minutes

async function getJwks(): Promise<JwksKey[]> {
  const now = Date.now();
  if (jwksCache && now - jwksCache.fetchedAt < JWKS_TTL_MS) {
    return jwksCache.keys;
  }
  const res = await fetch(JWKS_URI, { signal: AbortSignal.timeout(5000) });
  if (!res.ok) throw new Error(`JWKS fetch failed: ${res.status}`);
  const data = await res.json() as { keys: JwksKey[] };
  jwksCache = { keys: data.keys, fetchedAt: now };
  return data.keys;
}

// ── JWT Verification (RS256 using Node crypto) ────────────────────────────────
interface JwtPayload {
  sub: string;
  email?: string;
  preferred_username?: string;
  given_name?: string;
  family_name?: string;
  name?: string;
  roles?: string[];
  tenant_id?: string;
  exp?: number;
  iat?: number;
  iss?: string;
  aud?: string | string[];
  jti?: string;
}

function base64urlToBuffer(b64url: string): Buffer {
  const b64 = b64url.replace(/-/g, '+').replace(/_/g, '/');
  return Buffer.from(b64, 'base64');
}

async function verifyJwt(token: string): Promise<JwtPayload> {
  const parts = token.split('.');
  if (parts.length !== 3) throw new Error('Invalid JWT format');

  const [headerB64, payloadB64, signatureB64] = parts;
  const header = JSON.parse(base64urlToBuffer(headerB64).toString()) as { kid?: string; alg?: string };
  const payload = JSON.parse(base64urlToBuffer(payloadB64).toString()) as JwtPayload;

  // Expiry check
  if (payload.exp && payload.exp * 1000 < Date.now()) {
    throw new Error('Token expired');
  }

  // Issuer check — accept tokens signed with either internal or public KC URL
  const allowedIssuers = new Set([
    `${KC_URL}/realms/${KC_REALM}`,
    `${KC_PUBLIC_URL}/realms/${KC_REALM}`,
  ]);
  if (!payload.iss || !allowedIssuers.has(payload.iss)) {
    throw new Error(`Invalid issuer: ${payload.iss}`);
  }

  // Signature verification via JWKS
  const keys = await getJwks();
  const key = header.kid ? keys.find(k => k.kid === header.kid) : keys[0];
  if (!key) throw new Error(`JWKS key not found: ${header.kid}`);

  // Use Node.js crypto to verify RS256 signature
  const { createVerify, createPublicKey } = await import('crypto');
  const publicKey = createPublicKey({
    key: {
      kty: 'RSA',
      n: key.n,
      e: key.e,
    },
    format: 'jwk',
  });

  const signingInput = `${headerB64}.${payloadB64}`;
  const signature = base64urlToBuffer(signatureB64);
  const verifier = createVerify('RSA-SHA256');
  verifier.update(signingInput);
  const valid = verifier.verify(publicKey, signature);
  if (!valid) throw new Error('Invalid token signature');

  return payload;
}

// ── PKCE Helpers ──────────────────────────────────────────────────────────────
function generateCodeVerifier(): string {
  return randomBytes(32).toString('base64url');
}

function generateCodeChallenge(verifier: string): string {
  return createHash('sha256').update(verifier).digest('base64url');
}

// ── Redirect validation (prevent open-redirect attacks) ──────────────────────
function sanitizeRedirect(raw: string | undefined): string {
  if (!raw) return '/';
  try {
    const url = new URL(raw, 'http://localhost');
    if (url.protocol !== 'http:' && url.protocol !== 'https:') return '/';
    if (url.hostname !== 'localhost') return url.pathname + url.search + url.hash;
    return url.pathname + url.search + url.hash;
  } catch {
    if (raw.startsWith('/') && !raw.startsWith('//')) return raw;
    return '/';
  }
}

// ── In-memory PKCE state store (keyed by state param) ─────────────────────────
// In production, move this to Redis for multi-replica deployments.
const pkceStore = new Map<string, { codeVerifier: string; redirectTo?: string; createdAt: number }>();

// Cleanup stale states every 10 minutes
setInterval(() => {
  const cutoff = Date.now() - 10 * 60 * 1000;
  for (const [k, v] of pkceStore) {
    if (v.createdAt < cutoff) pkceStore.delete(k);
  }
}, 10 * 60 * 1000);

// ── Route Handlers ────────────────────────────────────────────────────────────

/**
 * GET /api/sso/login
 * Redirects to Keycloak with PKCE. Stores code_verifier in memory keyed by state.
 * Query params:
 *   redirect  — URL to return to after login (default: '/')
 */
export function handleLogin(req: Request, res: Response) {
  const redirectTo = sanitizeRedirect(req.query.redirect as string | undefined);
  const state = randomBytes(16).toString('hex');
  const codeVerifier = generateCodeVerifier();
  const codeChallenge = generateCodeChallenge(codeVerifier);

  pkceStore.set(state, { codeVerifier, redirectTo, createdAt: Date.now() });

  // Store state in cookie so callback can read it
  res.cookie(COOKIE_STATE, state, { ...COOKIE_OPTS, maxAge: 10 * 60 * 1000 });

  const params = new URLSearchParams({
    client_id: CLIENT_ID,
    response_type: 'code',
    scope: 'openid profile email roles',
    redirect_uri: REDIRECT_URI,
    state,
    code_challenge: codeChallenge,
    code_challenge_method: 'S256',
  });

  res.redirect(`${AUTH_ENDPOINT}?${params.toString()}`);
}

/**
 * GET /api/sso/callback
 * Receives authorization code from Keycloak, exchanges for tokens, sets cookies.
 */
export async function handleCallback(req: Request, res: Response) {
  const { code, state, error, error_description } = req.query as Record<string, string>;

  if (error) {
    console.error(`[sso] Keycloak auth error: ${error} — ${error_description}`);
    return res.redirect(`/?error=${encodeURIComponent(error_description ?? error)}`);
  }

  if (!code || !state) {
    return res.status(400).send('Missing code or state parameter');
  }

  const storedState = pkceStore.get(state);
  if (!storedState) {
    return res.status(400).send('Invalid or expired state. Please try logging in again.');
  }
  pkceStore.delete(state);

  try {
    // Exchange authorization code for tokens
    const body = new URLSearchParams({
      grant_type: 'authorization_code',
      code,
      redirect_uri: REDIRECT_URI,
      client_id: CLIENT_ID,
      code_verifier: storedState.codeVerifier,
      ...(CLIENT_SECRET ? { client_secret: CLIENT_SECRET } : {}),
    });

    const tokenRes = await fetch(TOKEN_ENDPOINT, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: body.toString(),
      signal: AbortSignal.timeout(10000),
    });

    if (!tokenRes.ok) {
      const err = await tokenRes.text();
      console.error(`[sso] Token exchange failed ${tokenRes.status}: ${err}`);
      return res.redirect('/?error=token_exchange_failed');
    }

    const tokens = await tokenRes.json() as {
      access_token: string;
      refresh_token?: string;
      expires_in: number;
    };

    // Set httpOnly cookies
    res.cookie(COOKIE_ACCESS, tokens.access_token, {
      ...COOKIE_OPTS,
      maxAge: tokens.expires_in * 1000,
    });

    if (tokens.refresh_token) {
      res.cookie(COOKIE_REFRESH, tokens.refresh_token, {
        ...COOKIE_OPTS,
        maxAge: 8 * 60 * 60 * 1000, // 8h (matches Keycloak ssoSessionMaxLifespan)
      });
    }

    // Clear state cookie
    res.clearCookie(COOKIE_STATE, { path: '/' });

    // Redirect to original destination
    const destination = storedState.redirectTo ?? '/';
    return res.redirect(destination);
  } catch (err) {
    console.error('[sso] Callback error:', err);
    return res.redirect('/?error=callback_failed');
  }
}

/**
 * GET /api/sso/validate
 * Validates the kc_access cookie. Used by nginx auth_request.
 * Returns 200 with X-User-* headers on success, 401 on failure.
 * If token is expired and refresh token exists, rotates automatically.
 */
export async function handleValidate(req: Request, res: Response) {
  const accessToken = req.cookies?.[COOKIE_ACCESS] as string | undefined;

  // No token — prompt login
  if (!accessToken) {
    return res.status(401).json({ valid: false, reason: 'no_token' });
  }

  try {
    const payload = await verifyJwt(accessToken);

    // Set response headers forwarded to upstream by nginx auth_request
    res.setHeader('X-User-ID',    payload.sub);
    res.setHeader('X-User-Email', payload.email ?? '');
    res.setHeader('X-User-Role',  (payload.roles ?? []).join(','));
    res.setHeader('X-Tenant-ID',  payload.tenant_id ?? 'system');

    return res.status(200).json({
      valid: true,
      user: {
        sub:      payload.sub,
        email:    payload.email,
        name:     payload.name,
        roles:    payload.roles ?? [],
        tenant_id: payload.tenant_id,
      },
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);

    // Token expired — try to refresh
    if (msg.includes('expired')) {
      const refreshResult = await attemptRefresh(req, res);
      if (refreshResult) {
        return res.status(200).json({ valid: true, refreshed: true, user: refreshResult });
      }
    }

    return res.status(401).json({ valid: false, reason: msg });
  }
}

/**
 * GET /api/sso/me
 * Returns user info from the valid access token cookie.
 * Used by the React SPA on mount to check session state.
 * Includes `expiresIn` (seconds until token expiry) so the frontend
 * can schedule its own refresh without decoding the JWT in browser.
 */
export async function handleMe(req: Request, res: Response) {
  const accessToken = req.cookies?.[COOKIE_ACCESS] as string | undefined;
  if (!accessToken) {
    return res.status(401).json({ authenticated: false });
  }

  try {
    const payload = await verifyJwt(accessToken);
    const expiresIn = payload.exp ? Math.max(0, payload.exp - Math.floor(Date.now() / 1000)) : 0;
    return res.json({
      authenticated: true,
      expiresIn,
      user: {
        sub:       payload.sub,
        email:     payload.email,
        name:      payload.name ?? `${payload.given_name ?? ''} ${payload.family_name ?? ''}`.trim(),
        username:  payload.preferred_username,
        roles:     payload.roles ?? [],
        tenant_id: payload.tenant_id,
      },
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    if (msg.includes('expired')) {
      const refreshed = await attemptRefresh(req, res);
      if (refreshed) {
        const expiresIn = refreshed.exp ? Math.max(0, refreshed.exp - Math.floor(Date.now() / 1000)) : 0;
        return res.json({ authenticated: true, refreshed: true, expiresIn, user: refreshed });
      }
    }
    return res.status(401).json({ authenticated: false, reason: msg });
  }
}

/**
 * POST /api/sso/logout
 * Clears cookies and calls Keycloak logout to invalidate the session server-side.
 */
export async function handleLogout(req: Request, res: Response) {
  const refreshToken = req.cookies?.[COOKIE_REFRESH] as string | undefined;

  // Call Keycloak backchannel logout (best-effort, don't fail if unreachable)
  if (refreshToken) {
    try {
      const body = new URLSearchParams({
        client_id: CLIENT_ID,
        refresh_token: refreshToken,
        ...(CLIENT_SECRET ? { client_secret: CLIENT_SECRET } : {}),
      });
      await fetch(LOGOUT_ENDPOINT, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: body.toString(),
        signal: AbortSignal.timeout(5000),
      });
    } catch {
      // Keycloak logout failed — still clear local cookies
    }
  }

  res.clearCookie(COOKIE_ACCESS,  { path: '/' });
  res.clearCookie(COOKIE_REFRESH, { path: '/' });
  res.clearCookie(COOKIE_STATE,   { path: '/' });

  return res.json({ loggedOut: true });
}

/**
 * GET /api/sso/refresh
 * Rotates the access token using the refresh token.
 * Called automatically by handleValidate and handleMe on expiry.
 */
export async function handleRefresh(req: Request, res: Response) {
  const refreshed = await attemptRefresh(req, res);
  if (!refreshed) {
    return res.status(401).json({ refreshed: false, reason: 'no_valid_refresh_token' });
  }
  return res.json({ refreshed: true, user: refreshed });
}

// ── Internal: refresh token rotation ─────────────────────────────────────────
async function attemptRefresh(
  req: Request,
  res: Response,
): Promise<JwtPayload | null> {
  const refreshToken = req.cookies?.[COOKIE_REFRESH] as string | undefined;
  if (!refreshToken) return null;

  try {
    const body = new URLSearchParams({
      grant_type: 'refresh_token',
      refresh_token: refreshToken,
      client_id: CLIENT_ID,
      ...(CLIENT_SECRET ? { client_secret: CLIENT_SECRET } : {}),
    });

    const tokenRes = await fetch(TOKEN_ENDPOINT, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: body.toString(),
      signal: AbortSignal.timeout(10000),
    });

    if (!tokenRes.ok) return null;

    const tokens = await tokenRes.json() as {
      access_token: string;
      refresh_token?: string;
      expires_in: number;
    };

    res.cookie(COOKIE_ACCESS, tokens.access_token, {
      ...COOKIE_OPTS,
      maxAge: tokens.expires_in * 1000,
    });

    if (tokens.refresh_token) {
      res.cookie(COOKIE_REFRESH, tokens.refresh_token, {
        ...COOKIE_OPTS,
        maxAge: 8 * 60 * 60 * 1000,
      });
    }

    return await verifyJwt(tokens.access_token);
  } catch {
    return null;
  }
}
