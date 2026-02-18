import { useEffect, useRef } from 'react';
import type { ServiceDef } from '../service-catalog';
import { CATEGORY_META } from '../service-catalog';

interface Props {
  service: ServiceDef | null;
  onClose: () => void;
}

export function EmbedPanel({ service, onClose }: Props) {
  const iframeRef = useRef<HTMLIFrameElement>(null);

  useEffect(() => {
    const handleKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    document.addEventListener('keydown', handleKey);
    return () => document.removeEventListener('keydown', handleKey);
  }, [onClose]);

  if (!service) return null;

  const categoryColor = CATEGORY_META[service.category].color;
  const token = localStorage.getItem('medinovaios_token');
  const iframeUrl = service.requiresAuth && token
    ? `${service.externalUrl}?token=${encodeURIComponent(token)}`
    : service.externalUrl;

  return (
    <>
      {/* Backdrop */}
      <div
        onClick={onClose}
        style={{
          position: 'fixed',
          inset: 0,
          background: 'rgba(0,0,0,0.6)',
          zIndex: 100,
          animation: 'fadeIn 0.15s ease',
        }}
      />

      {/* Panel */}
      <div style={{
        position: 'fixed',
        top: 0,
        right: 0,
        bottom: 0,
        width: 'min(85vw, 1100px)',
        background: '#0a0f1e',
        borderLeft: `1px solid ${categoryColor}40`,
        zIndex: 101,
        display: 'flex',
        flexDirection: 'column',
        animation: 'slideInRight 0.2s ease',
        boxShadow: `-20px 0 60px rgba(0,0,0,0.5)`,
      }}>
        {/* Panel toolbar */}
        <div style={{
          display: 'flex',
          alignItems: 'center',
          gap: 12,
          padding: '12px 16px',
          borderBottom: `1px solid #1e2d40`,
          background: '#0f172a',
          flexShrink: 0,
        }}>
          <span style={{ fontSize: 18 }}>{service.icon}</span>
          <div>
            <div style={{ fontSize: 14, fontWeight: 600, color: '#f1f5f9' }}>{service.name}</div>
            <div style={{ fontSize: 11, color: '#475569', fontFamily: 'monospace' }}>{service.externalUrl}</div>
          </div>
          <div style={{ marginLeft: 'auto', display: 'flex', gap: 8, alignItems: 'center' }}>
            <button
              onClick={() => window.open(service.externalUrl, '_blank', 'noopener,noreferrer')}
              style={{
                background: '#1e293b',
                border: '1px solid #334155',
                borderRadius: 6,
                padding: '5px 10px',
                color: '#94a3b8',
                fontSize: 12,
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: 5,
              }}
            >
              <span>↗</span> Open full
            </button>
            <button
              onClick={onClose}
              style={{
                background: 'transparent',
                border: '1px solid #334155',
                borderRadius: 6,
                padding: '5px 10px',
                color: '#94a3b8',
                fontSize: 16,
                cursor: 'pointer',
                lineHeight: 1,
              }}
            >
              ✕
            </button>
          </div>
        </div>

        {/* iframe */}
        <iframe
          ref={iframeRef}
          src={iframeUrl}
          style={{
            flex: 1,
            border: 'none',
            background: '#fff',
          }}
          title={service.name}
          sandbox="allow-same-origin allow-scripts allow-forms allow-popups allow-popups-to-escape-sandbox"
          referrerPolicy="no-referrer"
        />
      </div>
    </>
  );
}
