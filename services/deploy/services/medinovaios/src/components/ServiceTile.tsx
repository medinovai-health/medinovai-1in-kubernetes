import { useState } from 'react';
import type { ServiceDef } from '../service-catalog';
import { CATEGORY_META } from '../service-catalog';
import { HealthBadge } from './HealthBadge';
import type { HealthStatus } from '../service-catalog';

interface Props {
  service: ServiceDef;
  status: HealthStatus;
  onEmbed: (service: ServiceDef) => void;
}

export function ServiceTile({ service, status, onEmbed }: Props) {
  const [hovered, setHovered] = useState(false);
  const categoryColor = CATEGORY_META[service.category].color;

  const handleLaunch = () => {
    if (service.embed) {
      onEmbed(service);
    } else {
      const token = localStorage.getItem('medinovaios_token');
      const url = service.requiresAuth && token
        ? `${service.externalUrl}?token=${encodeURIComponent(token)}`
        : service.externalUrl;
      window.open(url, '_blank', 'noopener,noreferrer');
    }
  };

  return (
    <div
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      style={{
        background: hovered ? '#1a2540' : '#111827',
        border: `1px solid ${hovered ? categoryColor + '60' : '#1e2d40'}`,
        borderRadius: 12,
        padding: '18px 20px',
        cursor: 'pointer',
        transition: 'all 0.18s ease',
        display: 'flex',
        flexDirection: 'column',
        gap: 12,
        position: 'relative',
        overflow: 'hidden',
        boxShadow: hovered ? `0 0 20px ${categoryColor}20` : 'none',
      }}
      onClick={handleLaunch}
    >
      {/* Category accent stripe */}
      <div style={{
        position: 'absolute',
        top: 0,
        left: 0,
        right: 0,
        height: 2,
        background: `linear-gradient(90deg, ${categoryColor}, transparent)`,
        opacity: hovered ? 1 : 0.4,
        transition: 'opacity 0.18s ease',
      }} />

      {/* Header row */}
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 8 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <span style={{ fontSize: 22, lineHeight: 1 }}>{service.icon}</span>
          <div>
            <div style={{ fontSize: 14, fontWeight: 600, color: '#f1f5f9', lineHeight: 1.2 }}>
              {service.name}
            </div>
            {service.port && (
              <div style={{ fontSize: 10, color: '#475569', fontFamily: 'monospace', marginTop: 2 }}>
                {service.port}
              </div>
            )}
          </div>
        </div>
        <HealthBadge status={status} showLabel size="sm" />
      </div>

      {/* Description */}
      <div style={{ fontSize: 12, color: '#64748b', lineHeight: 1.5, flex: 1 }}>
        {service.description}
      </div>

      {/* Tags */}
      {service.tags && service.tags.length > 0 && (
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4 }}>
          {service.tags.slice(0, 3).map((tag) => (
            <span
              key={tag}
              style={{
                fontSize: 10,
                padding: '2px 7px',
                borderRadius: 99,
                background: `${categoryColor}15`,
                color: categoryColor,
                border: `1px solid ${categoryColor}30`,
                fontWeight: 500,
              }}
            >
              {tag}
            </span>
          ))}
        </div>
      )}

      {/* Launch button hint */}
      <div style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'flex-end',
        gap: 5,
        marginTop: 2,
      }}>
        <span style={{ fontSize: 11, color: hovered ? categoryColor : '#334155', transition: 'color 0.18s ease', fontWeight: 500 }}>
          {service.embed ? 'Open in panel' : 'Open'}
        </span>
        <span style={{ fontSize: 13, color: hovered ? categoryColor : '#334155', transition: 'color 0.18s ease' }}>
          {service.embed ? '⊞' : '↗'}
        </span>
      </div>
    </div>
  );
}
