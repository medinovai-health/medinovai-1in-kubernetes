// Login page — redirects to Keycloak for authentication.
// No credentials are entered here. The entire auth flow lives in Keycloak.
// After Keycloak authenticates the user, it calls /api/sso/callback which
// sets httpOnly cookies and redirects back here.

import { useEffect, useState } from 'react';

interface Props {
  onAuthenticated: () => void;
}

export function Login({ onAuthenticated }: Props) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const err = params.get('error');
    if (err) {
      setError(decodeURIComponent(err).replace(/_/g, ' '));
      window.history.replaceState({}, '', window.location.pathname);
    }
  }, []);

  const handleLogin = () => {
    setLoading(true);
    setError('');
    // Redirect to the server-side OIDC login handler.
    // The server generates PKCE, stores the code_verifier, and redirects to Keycloak.
    const returnTo = encodeURIComponent(window.location.pathname + window.location.search);
    window.location.href = `/api/sso/login?redirect=${returnTo}`;
  };

  return (
    <div style={{
      minHeight: '100vh',
      background: '#0a0f1e',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      padding: 20,
    }}>
      <div style={{
        width: '100%',
        maxWidth: 400,
        display: 'flex',
        flexDirection: 'column',
        gap: 32,
      }}>
        {/* Logo */}
        <div style={{ textAlign: 'center' }}>
          <div style={{
            width: 56,
            height: 56,
            borderRadius: 14,
            background: 'linear-gradient(135deg, #6366f1, #8b5cf6)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontSize: 28,
            margin: '0 auto 16px',
            boxShadow: '0 0 40px #6366f140',
          }}>
            ⚕
          </div>
          <div style={{ fontSize: 24, fontWeight: 700, color: '#f1f5f9' }}>
            MedinovAI <span style={{ color: '#6366f1' }}>OS</span>
          </div>
          <div style={{ fontSize: 14, color: '#475569', marginTop: 6 }}>
            Unified access to every MedinovAI product and service
          </div>
        </div>

        {/* Login card */}
        <div style={{
          background: '#0f172a',
          border: '1px solid #1e2d40',
          borderRadius: 14,
          padding: 32,
          display: 'flex',
          flexDirection: 'column',
          gap: 20,
          alignItems: 'center',
          textAlign: 'center',
        }}>
          {error && (
            <div style={{
              width: '100%',
              padding: '10px 12px',
              background: '#ef444415',
              border: '1px solid #ef444440',
              borderRadius: 8,
              fontSize: 13,
              color: '#f87171',
            }}>
              {error}. Please try again.
            </div>
          )}

          <div style={{ color: '#94a3b8', fontSize: 14, lineHeight: 1.6 }}>
            {loading
              ? 'Redirecting to secure login...'
              : 'Sign in with your MedinovAI account to access all products and services.'}
          </div>

          <button
            onClick={handleLogin}
            disabled={loading}
            style={{
              width: '100%',
              padding: '13px',
              background: loading ? '#334155' : 'linear-gradient(135deg, #6366f1, #8b5cf6)',
              border: 'none',
              borderRadius: 8,
              color: '#fff',
              fontSize: 15,
              fontWeight: 600,
              cursor: loading ? 'not-allowed' : 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: 8,
              transition: 'opacity 0.15s ease',
            }}
          >
            {loading ? (
              <>
                <span style={{ display: 'inline-block', width: 16, height: 16, border: '2px solid #ffffff40', borderTopColor: '#fff', borderRadius: '50%', animation: 'spin 0.8s linear infinite' }} />
                Signing in...
              </>
            ) : (
              <>
                <span>⚕</span>
                Sign in with MedinovAI
              </>
            )}
          </button>

          <div style={{ fontSize: 11, color: '#334155' }}>
            Single sign-on — one login for all MedinovAI products
          </div>
        </div>

        <div style={{ textAlign: 'center', fontSize: 12, color: '#1e293b' }}>
          All traffic encrypted in transit · PHI stays on-device
        </div>
      </div>

      <style>{`
        @keyframes spin {
          to { transform: rotate(360deg); }
        }
      `}</style>
    </div>
  );
}
