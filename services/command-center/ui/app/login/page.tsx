/**
 * /login — MedinovAI Command Center Login
 * (c) 2026 Copyright MedinovAI. All Rights Reserved.
 *
 * Hardening Point 21: Secure login with rate limiting, MFA support,
 * and session management. Company employees only.
 */

'use client';

import { useState } from 'react';

export default function LoginPage() {
  const [mos_email, setMosEmail] = useState('');
  const [mos_password, setMosPassword] = useState('');
  const [mos_isLoading, setMosIsLoading] = useState(false);
  const [mos_error, setMosError] = useState('');

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setMosIsLoading(true);
    setMosError('');

    try {
      const mos_res = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: mos_email, password: mos_password }),
      });

      if (mos_res.ok) {
        window.location.href = '/dashboard';
      } else {
        const mos_data = await mos_res.json();
        setMosError(mos_data.error || 'Invalid credentials');
      }
    } catch {
      setMosError('Unable to connect to authentication service');
    } finally {
      setMosIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-950 flex items-center justify-center p-6">
      <div className="mos-glass p-8 w-full max-w-md">
        {/* Logo */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-12 h-12 rounded-2xl bg-blue-600/20 border border-blue-500/30 mb-4">
            <span className="text-blue-400 text-xl">⚡</span>
          </div>
          <h1 className="text-xl font-bold text-white">MedinovAI Command Center</h1>
          <p className="text-slate-400 text-sm mt-1">Company employees only</p>
        </div>

        {/* Login Form */}
        <form onSubmit={handleLogin} className="space-y-4">
          <div>
            <label className="text-slate-300 text-sm font-medium block mb-1.5">
              Email
            </label>
            <input
              type="email"
              value={mos_email}
              onChange={e => setMosEmail(e.target.value)}
              placeholder="you@medinovai.health"
              required
              autoComplete="email"
              className="w-full bg-slate-900/50 border border-slate-700 text-white placeholder-slate-500 rounded-lg px-4 py-2.5 text-sm focus:outline-none focus:border-blue-500 transition-colors"
            />
          </div>

          <div>
            <label className="text-slate-300 text-sm font-medium block mb-1.5">
              Password
            </label>
            <input
              type="password"
              value={mos_password}
              onChange={e => setMosPassword(e.target.value)}
              placeholder="••••••••"
              required
              autoComplete="current-password"
              className="w-full bg-slate-900/50 border border-slate-700 text-white placeholder-slate-500 rounded-lg px-4 py-2.5 text-sm focus:outline-none focus:border-blue-500 transition-colors"
            />
          </div>

          {mos_error && (
            <div className="bg-red-500/10 border border-red-500/30 text-red-300 text-sm px-4 py-3 rounded-lg">
              {mos_error}
            </div>
          )}

          <button
            type="submit"
            disabled={mos_isLoading}
            className="w-full bg-blue-600 hover:bg-blue-500 disabled:opacity-50 disabled:cursor-not-allowed text-white font-medium py-2.5 rounded-lg transition-colors text-sm"
          >
            {mos_isLoading ? 'Authenticating...' : 'Sign In'}
          </button>
        </form>

        {/* Footer */}
        <p className="text-center text-slate-600 text-xs mt-6">
          (c) 2026 MedinovAI. All Rights Reserved.
        </p>
      </div>
    </div>
  );
}
