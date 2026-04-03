import { useState } from 'react';
import type { ServiceCategory, ServiceDef } from '../service-catalog';
import { SERVICES } from '../service-catalog';
import { Sidebar } from '../components/Sidebar';
import { TileGrid } from '../components/TileGrid';
import { EmbedPanel } from '../components/EmbedPanel';
import { Header } from '../components/Header';
import { useHealthStatus } from '../hooks/useHealthStatus';
import { getServiceById } from '../service-catalog';

interface Props {
  onLogout: () => void;
}

export function Dashboard({ onLogout }: Props) {
  const [activeCategory, setActiveCategory] = useState<ServiceCategory | 'All'>('All');
  const [searchQuery, setSearchQuery] = useState('');
  const [embeddedService, setEmbeddedService] = useState<ServiceDef | null>(null);
  const { health, lastUpdated, refresh } = useHealthStatus();

  const handleAtlasClick = () => {
    const atlasService = getServiceById('atlas');
    if (!atlasService) return;
    // Cookie-based SSO — no token in URL. Atlas validates via its own /api/sso/me.
    window.open(atlasService.externalUrl, '_blank', 'noopener,noreferrer');
  };

  // Dashboard only renders when authenticated — always true here
  const isAuthenticated = true;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100vh', overflow: 'hidden', background: '#0a0f1e' }}>
      <Header
        searchQuery={searchQuery}
        onSearchChange={(q) => {
          setSearchQuery(q);
          if (q) setActiveCategory('All');
        }}
        onAtlasClick={handleAtlasClick}
        isAuthenticated={isAuthenticated}
        onLogout={onLogout}
      />

      <div style={{ display: 'flex', flex: 1, overflow: 'hidden' }}>
        <Sidebar
          activeCategory={activeCategory}
          onCategoryChange={(cat) => {
            setActiveCategory(cat);
            setSearchQuery('');
          }}
          health={health}
          lastUpdated={lastUpdated}
          onRefresh={refresh}
        />

        <main style={{ flex: 1, overflow: 'auto', padding: 24 }}>
          {/* Welcome banner — shown only when no search and All selected */}
          {!searchQuery && activeCategory === 'All' && (
            <div style={{
              background: 'linear-gradient(135deg, #0f172a, #1a1f3a)',
              border: '1px solid #1e2d40',
              borderRadius: 12,
              padding: '20px 24px',
              marginBottom: 28,
              display: 'flex',
              alignItems: 'center',
              gap: 16,
            }}>
              <div style={{ fontSize: 32 }}>⚕</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 18, fontWeight: 700, color: '#f1f5f9', marginBottom: 4 }}>
                  MedinovAI OS
                </div>
                <div style={{ fontSize: 13, color: '#64748b', lineHeight: 1.5 }}>
                  {SERVICES.length} services · Select any tile to launch · Embed-capable services open in panel · PHI never leaves your infrastructure
                </div>
              </div>
              <div style={{ textAlign: 'right', flexShrink: 0 }}>
                <div style={{ fontSize: 11, color: '#334155', marginBottom: 4 }}>Quick links</div>
                <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                  {['security-service', 'registry', 'grafana', 'kibana', 'prometheus'].map((id) => {
                    const s = getServiceById(id);
                    if (!s) return null;
                    return (
                      <button
                        key={id}
                        onClick={() => s.embed ? setEmbeddedService(s) : window.open(s.externalUrl, '_blank')}
                        style={{
                          padding: '5px 10px',
                          background: '#1e293b',
                          border: '1px solid #334155',
                          borderRadius: 6,
                          color: '#94a3b8',
                          fontSize: 12,
                          cursor: 'pointer',
                          display: 'flex',
                          alignItems: 'center',
                          gap: 5,
                        }}
                      >
                        <span>{s.icon}</span>
                        <span>{s.name}</span>
                      </button>
                    );
                  })}
                </div>
              </div>
            </div>
          )}

          <TileGrid
            services={SERVICES}
            health={health}
            activeCategory={activeCategory}
            searchQuery={searchQuery}
            onEmbed={setEmbeddedService}
          />
        </main>
      </div>

      <EmbedPanel
        service={embeddedService}
        onClose={() => setEmbeddedService(null)}
      />
    </div>
  );
}
