interface Props {
  searchQuery: string;
  onSearchChange: (q: string) => void;
  onAtlasClick: () => void;
  isAuthenticated: boolean;
  onLogout: () => void;
}

export function Header({ searchQuery, onSearchChange, onAtlasClick, isAuthenticated, onLogout }: Props) {
  return (
    <header style={{
      height: 56,
      background: '#060b18',
      borderBottom: '1px solid #0f172a',
      display: 'flex',
      alignItems: 'center',
      padding: '0 20px',
      gap: 20,
      flexShrink: 0,
      zIndex: 10,
    }}>
      {/* Logo */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, flexShrink: 0 }}>
        <div style={{
          width: 28,
          height: 28,
          borderRadius: 7,
          background: 'linear-gradient(135deg, #6366f1, #8b5cf6)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontSize: 14,
        }}>
          ⚕
        </div>
        <div>
          <span style={{ fontSize: 15, fontWeight: 700, color: '#f1f5f9', letterSpacing: '-0.01em' }}>
            MedinovAI
          </span>
          <span style={{ fontSize: 13, fontWeight: 400, color: '#6366f1', marginLeft: 4 }}>
            OS
          </span>
        </div>
      </div>

      {/* Search */}
      <div style={{ flex: 1, maxWidth: 440, position: 'relative' }}>
        <span style={{
          position: 'absolute',
          left: 12,
          top: '50%',
          transform: 'translateY(-50%)',
          color: '#334155',
          fontSize: 14,
          pointerEvents: 'none',
        }}>
          🔍
        </span>
        <input
          type="text"
          placeholder="Search services, tools, products..."
          value={searchQuery}
          onChange={(e) => onSearchChange(e.target.value)}
          style={{
            width: '100%',
            padding: '8px 12px 8px 36px',
            background: '#0f172a',
            border: '1px solid #1e2d40',
            borderRadius: 8,
            color: '#e2e8f0',
            fontSize: 13,
            outline: 'none',
            transition: 'border-color 0.15s ease',
          }}
          onFocus={(e) => { e.target.style.borderColor = '#6366f1'; }}
          onBlur={(e) => { e.target.style.borderColor = '#1e2d40'; }}
        />
        {searchQuery && (
          <button
            onClick={() => onSearchChange('')}
            style={{
              position: 'absolute',
              right: 10,
              top: '50%',
              transform: 'translateY(-50%)',
              background: 'none',
              border: 'none',
              color: '#475569',
              cursor: 'pointer',
              fontSize: 14,
              lineHeight: 1,
            }}
          >
            ✕
          </button>
        )}
      </div>

      {/* Right side */}
      <div style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: 10 }}>
        {/* Atlas cross-link */}
        <button
          onClick={onAtlasClick}
          title="Open Atlas AI Platform"
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 7,
            padding: '6px 12px',
            background: '#1e293b',
            border: '1px solid #334155',
            borderRadius: 7,
            color: '#94a3b8',
            cursor: 'pointer',
            fontSize: 12,
            fontWeight: 500,
            transition: 'all 0.15s ease',
          }}
          onMouseEnter={(e) => {
            e.currentTarget.style.borderColor = '#6366f1';
            e.currentTarget.style.color = '#a5b4fc';
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.borderColor = '#334155';
            e.currentTarget.style.color = '#94a3b8';
          }}
        >
          <span>🗺️</span>
          <span>Atlas</span>
          <span style={{ opacity: 0.6, fontSize: 11 }}>↗</span>
        </button>

        {/* Auth state — always show sign out when authenticated */}
        {isAuthenticated && (
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            {/* Session status dot */}
            <div
              title="Session active"
              style={{
                width: 7,
                height: 7,
                borderRadius: '50%',
                background: '#4ade80',
                boxShadow: '0 0 6px #4ade8080',
                flexShrink: 0,
              }}
            />
            <button
              onClick={onLogout}
              title="Sign out of MedinovAI"
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 5,
                padding: '6px 12px',
                background: 'transparent',
                border: '1px solid #1e2d40',
                borderRadius: 7,
                color: '#475569',
                cursor: 'pointer',
                fontSize: 12,
                transition: 'all 0.15s ease',
              }}
              onMouseEnter={(e) => { e.currentTarget.style.borderColor = '#ef4444'; e.currentTarget.style.color = '#ef4444'; }}
              onMouseLeave={(e) => { e.currentTarget.style.borderColor = '#1e2d40'; e.currentTarget.style.color = '#475569'; }}
            >
              <span style={{ fontSize: 11 }}>⏻</span>
              Sign out
            </button>
          </div>
        )}
      </div>
    </header>
  );
}
