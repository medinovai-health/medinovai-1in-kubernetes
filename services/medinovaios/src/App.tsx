import { useState, useEffect } from 'react';
import { Login } from './pages/Login';
import { Dashboard } from './pages/Dashboard';

const TOKEN_KEY = 'medinovaios_token';

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

export default function App() {
  const [token, setToken] = useState<string | null>(() => {
    // Check URL for token passthrough from Atlas (SSO handoff)
    const params = new URLSearchParams(window.location.search);
    const urlToken = params.get('token');
    if (urlToken) {
      localStorage.setItem(TOKEN_KEY, urlToken);
      // Clean the token from URL without reload
      window.history.replaceState({}, '', window.location.pathname);
      return urlToken;
    }
    return localStorage.getItem(TOKEN_KEY);
  });

  const handleLogin = (t: string) => {
    localStorage.setItem(TOKEN_KEY, t);
    setToken(t);
  };

  const handleLogout = () => {
    localStorage.removeItem(TOKEN_KEY);
    setToken(null);
  };

  // Validate stored token on mount (non-blocking)
  useEffect(() => {
    if (!token || token === 'guest') return;
    fetch('/api/sso/validate', {
      headers: { Authorization: `Bearer ${token}` },
      signal: AbortSignal.timeout(5000),
    })
      .then((r) => { if (!r.ok) handleLogout(); })
      .catch(() => { /* network error — keep token, will re-validate next time */ });
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  if (!token) {
    return <Login onLogin={handleLogin} />;
  }

  return <Dashboard token={token} onLogout={handleLogout} />;
}
