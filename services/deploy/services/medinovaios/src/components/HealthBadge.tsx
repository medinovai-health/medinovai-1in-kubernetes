import type { HealthStatus } from '../service-catalog';

interface Props {
  status: HealthStatus;
  showLabel?: boolean;
  size?: 'sm' | 'md';
}

const CONFIG: Record<HealthStatus, { color: string; label: string; pulse: boolean }> = {
  healthy: { color: '#22c55e', label: 'Healthy', pulse: true },
  degraded: { color: '#f59e0b', label: 'Degraded', pulse: true },
  offline: { color: '#ef4444', label: 'Offline', pulse: false },
  unknown: { color: '#64748b', label: 'Unknown', pulse: false },
};

export function HealthBadge({ status, showLabel = false, size = 'md' }: Props) {
  const cfg = CONFIG[status];
  const dotSize = size === 'sm' ? 7 : 9;

  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 5 }}>
      <span
        style={{
          display: 'inline-block',
          width: dotSize,
          height: dotSize,
          borderRadius: '50%',
          background: cfg.color,
          boxShadow: cfg.pulse ? `0 0 0 0 ${cfg.color}40` : 'none',
          animation: cfg.pulse ? 'pulse-ring 2s ease-in-out infinite' : 'none',
          flexShrink: 0,
        }}
      />
      {showLabel && (
        <span style={{ fontSize: 11, color: cfg.color, fontWeight: 500, letterSpacing: '0.02em' }}>
          {cfg.label}
        </span>
      )}
    </span>
  );
}
