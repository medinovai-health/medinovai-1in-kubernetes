import { useState, useEffect, useRef, useCallback } from 'react';
import { Login } from './pages/Login';
import { Dashboard } from './pages/Dashboard';

// Inject global animations
const style = document.createElement('style');
style.textContent = `
  @keyframes pulse-ring {
    0%   { box-shadow: 0 0 0 0 currentColor; }
    70%  { box-shadow: 0 0 0 5px transparent; }
    100% { box-shadow: 0 0 0 0 transparent; }
  }
  @keyframes fadeIn {
    from { opacity: 0; }
    to   { opacity: 1; }
  }
  @keyframes slideInRight {
    from { transform: translateX(40px); opacity: 0; }
    to   { transform: translateX(0);    opacity: 1; }
  }
  button { font-family: inherit; }
  input  { font-family: inherit; }
`;
document.head.appendChild(style);

type AuthState = 'checking' | 'authenticated' | 'unauthenticated';

// ── Session Management Constants ──────────────────────────────────────────────
// Token is refreshed silently every REFRESH_INTERVAL_MS.
// If the user has been idle for IDLE_WARN_MS, show a warning.
// If still idle after IDLE_LOGOUT_MS, auto-logout.
const REFRESH_INTERVAL_MS = 4 * 60 * 1000;    // 4 min  (access tokens expire at 5m)
const IDLE_WARN_MS        = 25 * 60 * 1000;   // 25 min
const IDLE_LOGOUT_MS      = 30 * 60 * 1000;   // 30 min

// User activity events that reset the idle clock
const ACTIVITY_EVENTS = ['mousemove', 'keydown', 'click', 'scroll', 'touchstart', 'pointerdown'];

// ── Countdown helper ──────────────────────────────────────────────────────────
function formatCountdown(ms: number): string {
  const totalSec = Math.ceil(ms / 1000);
  const min = Math.floor(totalSec / 60);
  const sec = totalSec % 60;
  return min > 0 ? `${min}:${sec.toString().padStart(2, '0')}` : `${sec}s`;
}

export default function App() {
  const [authState, setAuthState] = useState<AuthState>('checking');
  const [showIdleWarning, setShowIdleWarning] = useState(false);
  const [idleCountdown, setIdleCountdown] = useState(IDLE_LOGOUT_MS - IDLE_WARN_MS);

  const lastActivityRef    = useRef<number>(Date.now());
  const idleWarningTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const idleLogoutTimerRef  = useRef<ReturnType<typeof setTimeout> | null>(null);
  const refreshIntervalRef  = useRef<ReturnType<typeof setInterval> | null>(null);
  const countdownIntervalRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const authStateRef = useRef(authState);
  authStateRef.current = authState;

  // ── Session check ─────────────────────────────────────────────────────────
  const checkSession = useCallback(async (): Promise<boolean> => {
    try {
      const res = await fetch('/api/sso/me', {
        credentials: 'include',
        signal: AbortSignal.timeout(8000),
      });
      if (res.ok) {
        const data = await res.json() as { authenticated: boolean };
        if (data.authenticated) return true;
      }
    } catch {
      // Network error — assume still authenticated (transient)
      return authStateRef.current === 'authenticated';
    }
    return false;
  }, []);

  // ── Silent token refresh ───────────────────────────────────────────────────
  const silentRefresh = useCallback(async () => {
    if (authStateRef.current !== 'authenticated') return;
    try {
      const res = await fetch('/api/sso/refresh', {
        credentials: 'include',
        signal: AbortSignal.timeout(8000),
      });
      if (!res.ok) {
        // Refresh token expired — force re-login
        console.info('[session] Refresh token expired — logging out');
        performLogout(false);
      }
    } catch {
      // Network error — keep session, will retry next interval
    }
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  // ── Logout ────────────────────────────────────────────────────────────────
  const performLogout = useCallback(async (callServer = true) => {
    clearAllTimers();
    if (callServer) {
      try {
        await fetch('/api/sso/logout', {
          method: 'POST',
          credentials: 'include',
          signal: AbortSignal.timeout(5000),
        });
      } catch { /* best-effort */ }
    }
    setAuthState('unauthenticated');
    setShowIdleWarning(false);
    window.location.href = '/api/sso/login';
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  // ── Timer management ──────────────────────────────────────────────────────
  function clearAllTimers() {
    if (idleWarningTimerRef.current)  clearTimeout(idleWarningTimerRef.current);
    if (idleLogoutTimerRef.current)   clearTimeout(idleLogoutTimerRef.current);
    if (refreshIntervalRef.current)   clearInterval(refreshIntervalRef.current);
    if (countdownIntervalRef.current) clearInterval(countdownIntervalRef.current);
  }

  const resetIdleTimers = useCallback(() => {
    if (authStateRef.current !== 'authenticated') return;

    lastActivityRef.current = Date.now();
    setShowIdleWarning(false);

    if (idleWarningTimerRef.current) clearTimeout(idleWarningTimerRef.current);
    if (idleLogoutTimerRef.current)  clearTimeout(idleLogoutTimerRef.current);
    if (countdownIntervalRef.current) clearInterval(countdownIntervalRef.current);

    // Warn at 25 min idle
    idleWarningTimerRef.current = setTimeout(() => {
      setShowIdleWarning(true);
      setIdleCountdown(IDLE_LOGOUT_MS - IDLE_WARN_MS);

      // Tick countdown every second
      countdownIntervalRef.current = setInterval(() => {
        setIdleCountdown(prev => {
          if (prev <= 1000) {
            clearInterval(countdownIntervalRef.current!);
            return 0;
          }
          return prev - 1000;
        });
      }, 1000);
    }, IDLE_WARN_MS);

    // Auto-logout at 30 min idle
    idleLogoutTimerRef.current = setTimeout(() => {
      console.info('[session] Idle timeout — logging out');
      performLogout(true);
    }, IDLE_LOGOUT_MS);
  }, [performLogout]);

  // ── Start session management (called once on authenticated) ───────────────
  const startSessionManagement = useCallback(() => {
    clearAllTimers();

    // Silent refresh every 4 min
    refreshIntervalRef.current = setInterval(silentRefresh, REFRESH_INTERVAL_MS);

    // Idle timers
    resetIdleTimers();

    // Activity listeners
    const handleActivity = () => resetIdleTimers();
    ACTIVITY_EVENTS.forEach(event => window.addEventListener(event, handleActivity, { passive: true }));

    return () => {
      ACTIVITY_EVENTS.forEach(event => window.removeEventListener(event, handleActivity));
      clearAllTimers();
    };
  }, [silentRefresh, resetIdleTimers]);

  // ── Mount: check session once ─────────────────────────────────────────────
  useEffect(() => {
    let cleanup: (() => void) | undefined;

    (async () => {
      const ok = await checkSession();
      if (ok) {
        setAuthState('authenticated');
        cleanup = startSessionManagement();
      } else {
        setAuthState('unauthenticated');
      }
    })();

    return () => {
      clearAllTimers();
      cleanup?.();
    };
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  const handleAuthenticated = () => {
    setAuthState('checking');
    checkSession().then(ok => {
      if (ok) {
        setAuthState('authenticated');
        startSessionManagement();
      } else {
        setAuthState('unauthenticated');
      }
    });
  };

  // ── Loading ───────────────────────────────────────────────────────────────
  if (authState === 'checking') {
    return (
      <div style={{
        minHeight: '100vh',
        background: '#0a0f1e',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        flexDirection: 'column',
        gap: 16,
      }}>
        <div style={{
          width: 40, height: 40,
          border: '3px solid #1e293b',
          borderTopColor: '#6366f1',
          borderRadius: '50%',
          animation: 'spin 0.8s linear infinite',
        }} />
        <div style={{ color: '#475569', fontSize: 14 }}>Checking session...</div>
        <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
      </div>
    );
  }

  if (authState === 'unauthenticated') {
    return <Login onAuthenticated={handleAuthenticated} />;
  }

  return (
    <>
      <Dashboard onLogout={() => performLogout(true)} />

      {/* ── Idle Session Warning Modal ──────────────────────────────────── */}
      {showIdleWarning && (
        <div style={{
          position: 'fixed',
          inset: 0,
          background: 'rgba(0,0,0,0.75)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 9999,
          animation: 'fadeIn 0.2s ease',
        }}>
          <div style={{
            background: '#0f172a',
            border: '1px solid #334155',
            borderRadius: 14,
            padding: 32,
            maxWidth: 380,
            width: '90%',
            textAlign: 'center',
            boxShadow: '0 20px 60px rgba(0,0,0,0.5)',
          }}>
            {/* Warning icon */}
            <div style={{
              width: 52,
              height: 52,
              borderRadius: '50%',
              background: '#fbbf2415',
              border: '1px solid #fbbf2440',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: 22,
              margin: '0 auto 18px',
            }}>
              ⏱
            </div>

            <div style={{ fontSize: 18, fontWeight: 700, color: '#f1f5f9', marginBottom: 10 }}>
              Session expiring soon
            </div>

            <div style={{ fontSize: 14, color: '#94a3b8', marginBottom: 8, lineHeight: 1.6 }}>
              You've been inactive for a while. For security, you'll be signed out in:
            </div>

            <div style={{
              fontSize: 36,
              fontWeight: 800,
              color: idleCountdown < 60_000 ? '#ef4444' : '#fbbf24',
              marginBottom: 24,
              fontVariantNumeric: 'tabular-nums',
              letterSpacing: '-0.02em',
            }}>
              {formatCountdown(idleCountdown)}
            </div>

            <div style={{ display: 'flex', gap: 10 }}>
              <button
                onClick={() => performLogout(true)}
                style={{
                  flex: 1,
                  padding: '10px',
                  background: 'transparent',
                  border: '1px solid #334155',
                  borderRadius: 8,
                  color: '#64748b',
                  cursor: 'pointer',
                  fontSize: 14,
                  transition: 'all 0.15s ease',
                }}
                onMouseEnter={(e) => { e.currentTarget.style.borderColor = '#ef4444'; e.currentTarget.style.color = '#ef4444'; }}
                onMouseLeave={(e) => { e.currentTarget.style.borderColor = '#334155'; e.currentTarget.style.color = '#64748b'; }}
              >
                Sign out
              </button>

              <button
                onClick={() => resetIdleTimers()}
                style={{
                  flex: 2,
                  padding: '10px',
                  background: 'linear-gradient(135deg, #6366f1, #8b5cf6)',
                  border: 'none',
                  borderRadius: 8,
                  color: '#fff',
                  cursor: 'pointer',
                  fontSize: 14,
                  fontWeight: 600,
                  transition: 'opacity 0.15s ease',
                }}
                onMouseEnter={(e) => { e.currentTarget.style.opacity = '0.9'; }}
                onMouseLeave={(e) => { e.currentTarget.style.opacity = '1'; }}
              >
                Stay signed in
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
