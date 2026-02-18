import { useState } from 'react';

interface Props {
  onLogin: (token: string) => void;
}

export function Login({ onLogin }: Props) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const res = await fetch('/api/sso/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      });

      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        setError(body.message ?? 'Invalid credentials');
        return;
      }

      const { token } = await res.json();
      onLogin(token);
    } catch {
      setError('Could not reach auth service. Ensure the platform is running.');
    } finally {
      setLoading(false);
    }
  };

  const handleGuestAccess = () => {
    // Grant read-only access without auth — for local/dev environments
    onLogin('guest');
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
          padding: 28,
          display: 'flex',
          flexDirection: 'column',
          gap: 18,
        }}>
          <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            <div>
              <label style={{ fontSize: 12, color: '#64748b', fontWeight: 500, display: 'block', marginBottom: 6 }}>
                Email
              </label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="you@medinovai.com"
                required
                style={{
                  width: '100%',
                  padding: '10px 12px',
                  background: '#0a0f1e',
                  border: '1px solid #1e2d40',
                  borderRadius: 8,
                  color: '#e2e8f0',
                  fontSize: 14,
                  outline: 'none',
                  transition: 'border-color 0.15s ease',
                }}
                onFocus={(e) => { e.target.style.borderColor = '#6366f1'; }}
                onBlur={(e) => { e.target.style.borderColor = '#1e2d40'; }}
              />
            </div>

            <div>
              <label style={{ fontSize: 12, color: '#64748b', fontWeight: 500, display: 'block', marginBottom: 6 }}>
                Password
              </label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                required
                style={{
                  width: '100%',
                  padding: '10px 12px',
                  background: '#0a0f1e',
                  border: '1px solid #1e2d40',
                  borderRadius: 8,
                  color: '#e2e8f0',
                  fontSize: 14,
                  outline: 'none',
                  transition: 'border-color 0.15s ease',
                }}
                onFocus={(e) => { e.target.style.borderColor = '#6366f1'; }}
                onBlur={(e) => { e.target.style.borderColor = '#1e2d40'; }}
              />
            </div>

            {error && (
              <div style={{
                padding: '10px 12px',
                background: '#ef444415',
                border: '1px solid #ef444440',
                borderRadius: 8,
                fontSize: 13,
                color: '#f87171',
              }}>
                {error}
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              style={{
                padding: '11px',
                background: loading ? '#334155' : 'linear-gradient(135deg, #6366f1, #8b5cf6)',
                border: 'none',
                borderRadius: 8,
                color: '#fff',
                fontSize: 14,
                fontWeight: 600,
                cursor: loading ? 'not-allowed' : 'pointer',
                transition: 'opacity 0.15s ease',
              }}
            >
              {loading ? 'Signing in...' : 'Sign in'}
            </button>
          </form>

          <div style={{ textAlign: 'center', color: '#334155', fontSize: 12 }}>or</div>

          <button
            onClick={handleGuestAccess}
            style={{
              padding: '10px',
              background: 'transparent',
              border: '1px solid #1e2d40',
              borderRadius: 8,
              color: '#64748b',
              fontSize: 13,
              cursor: 'pointer',
              transition: 'all 0.15s ease',
            }}
            onMouseEnter={(e) => { e.currentTarget.style.borderColor = '#334155'; e.currentTarget.style.color = '#94a3b8'; }}
            onMouseLeave={(e) => { e.currentTarget.style.borderColor = '#1e2d40'; e.currentTarget.style.color = '#64748b'; }}
          >
            Continue without login (local dev)
          </button>
        </div>

        <div style={{ textAlign: 'center', fontSize: 12, color: '#334155' }}>
          All traffic encrypted in transit · PHI stays on-device
        </div>
      </div>
    </div>
  );
}
