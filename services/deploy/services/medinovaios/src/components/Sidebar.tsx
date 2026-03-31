import type { ServiceCategory } from '../service-catalog';
import { CATEGORIES, CATEGORY_META, SERVICES } from '../service-catalog';
import type { HealthMap } from '../hooks/useHealthStatus';

interface Props {
  activeCategory: ServiceCategory | 'All';
  onCategoryChange: (cat: ServiceCategory | 'All') => void;
  health: HealthMap;
  lastUpdated: Date | null;
  onRefresh: () => void;
}

export function Sidebar({ activeCategory, onCategoryChange, health, lastUpdated, onRefresh }: Props) {
  const totalHealthy = SERVICES.filter((s) => health[s.id]?.status === 'healthy').length;
  const totalOffline = SERVICES.filter((s) => health[s.id]?.status === 'offline').length;

  const navItems: Array<ServiceCategory | 'All'> = ['All', ...CATEGORIES];

  return (
    <nav style={{
      width: 220,
      flexShrink: 0,
      background: '#0a0f1e',
      borderRight: '1px solid #111827',
      display: 'flex',
      flexDirection: 'column',
      padding: '20px 0',
    }}>
      {/* Platform status */}
      <div style={{ padding: '0 16px 20px', borderBottom: '1px solid #111827', marginBottom: 16 }}>
        <div style={{ fontSize: 10, color: '#334155', fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 10 }}>
          Platform Status
        </div>
        <div style={{ display: 'flex', gap: 16 }}>
          <div>
            <div style={{ fontSize: 20, fontWeight: 700, color: '#22c55e', lineHeight: 1 }}>{totalHealthy}</div>
            <div style={{ fontSize: 10, color: '#475569', marginTop: 2 }}>Healthy</div>
          </div>
          <div>
            <div style={{ fontSize: 20, fontWeight: 700, color: totalOffline > 0 ? '#ef4444' : '#334155', lineHeight: 1 }}>
              {totalOffline}
            </div>
            <div style={{ fontSize: 10, color: '#475569', marginTop: 2 }}>Offline</div>
          </div>
          <div>
            <div style={{ fontSize: 20, fontWeight: 700, color: '#475569', lineHeight: 1 }}>{SERVICES.length}</div>
            <div style={{ fontSize: 10, color: '#475569', marginTop: 2 }}>Total</div>
          </div>
        </div>
        {lastUpdated && (
          <div style={{ fontSize: 10, color: '#334155', marginTop: 10 }}>
            Updated {lastUpdated.toLocaleTimeString()}
          </div>
        )}
      </div>

      {/* Navigation */}
      <div style={{ flex: 1, padding: '0 8px' }}>
        <div style={{ fontSize: 10, color: '#334155', fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase', padding: '0 8px', marginBottom: 6 }}>
          Categories
        </div>
        {navItems.map((cat) => {
          const isActive = activeCategory === cat;
          const meta = cat !== 'All' ? CATEGORY_META[cat] : null;
          const catServices = cat !== 'All' ? SERVICES.filter((s) => s.category === cat) : SERVICES;
          const catHealthy = catServices.filter((s) => health[s.id]?.status === 'healthy').length;

          return (
            <button
              key={cat}
              onClick={() => onCategoryChange(cat)}
              style={{
                width: '100%',
                display: 'flex',
                alignItems: 'center',
                gap: 8,
                padding: '8px 10px',
                borderRadius: 8,
                border: 'none',
                background: isActive ? '#1a2540' : 'transparent',
                color: isActive ? '#f1f5f9' : '#64748b',
                cursor: 'pointer',
                textAlign: 'left',
                fontSize: 13,
                fontWeight: isActive ? 600 : 400,
                transition: 'all 0.12s ease',
                marginBottom: 2,
              }}
            >
              {meta && (
                <span style={{
                  width: 8,
                  height: 8,
                  borderRadius: '50%',
                  background: isActive ? meta.color : '#334155',
                  flexShrink: 0,
                  transition: 'background 0.12s ease',
                }} />
              )}
              {!meta && <span style={{ width: 8, height: 8, flexShrink: 0 }} />}
              <span style={{ flex: 1 }}>{cat}</span>
              <span style={{ fontSize: 11, color: isActive ? '#94a3b8' : '#334155' }}>
                {catHealthy}/{catServices.length}
              </span>
            </button>
          );
        })}
      </div>

      {/* Refresh */}
      <div style={{ padding: '16px', borderTop: '1px solid #111827', marginTop: 8 }}>
        <button
          onClick={onRefresh}
          style={{
            width: '100%',
            padding: '8px',
            borderRadius: 8,
            border: '1px solid #1e2d40',
            background: 'transparent',
            color: '#475569',
            cursor: 'pointer',
            fontSize: 12,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: 6,
            transition: 'all 0.12s ease',
          }}
          onMouseEnter={(e) => { e.currentTarget.style.borderColor = '#334155'; e.currentTarget.style.color = '#94a3b8'; }}
          onMouseLeave={(e) => { e.currentTarget.style.borderColor = '#1e2d40'; e.currentTarget.style.color = '#475569'; }}
        >
          ↻ Refresh health
        </button>
      </div>
    </nav>
  );
}
