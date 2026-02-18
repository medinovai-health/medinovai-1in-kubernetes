import { useState, useEffect } from 'react';
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

export default function App() {
  const [authState, setAuthState] = useState<AuthState>('checking');

  // Check session via cookie-based /api/sso/me (no token in browser memory)
  const checkSession = async () => {
    try {
      const res = await fetch('/api/sso/me', {
        credentials: 'include',
        signal: AbortSignal.timeout(8000),
      });
      if (res.ok) {
        const data = await res.json() as { authenticated: boolean };
        if (data.authenticated) {
          setAuthState('authenticated');
          return;
        }
      }
    } catch {
      // Network error — fall through to unauthenticated
    }
    setAuthState('unauthenticated');
  };

  useEffect(() => {
    checkSession();
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  const handleAuthenticated = () => {
    setAuthState('checking');
    checkSession();
  };

  const handleLogout = async () => {
    try {
      await fetch('/api/sso/logout', {
        method: 'POST',
        credentials: 'include',
        signal: AbortSignal.timeout(5000),
      });
    } catch {
      // Logout best-effort
    }
    setAuthState('unauthenticated');
    window.location.href = '/api/sso/login';
  };

  // Loading state while checking session
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

  return <Dashboard onLogout={handleLogout} />;
}
