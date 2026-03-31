import type { ServiceDef, ServiceCategory } from '../service-catalog';
import { CATEGORY_META } from '../service-catalog';
import { ServiceTile } from './ServiceTile';
import type { HealthStatus } from '../service-catalog';
import type { HealthMap } from '../hooks/useHealthStatus';

interface Props {
  services: ServiceDef[];
  health: HealthMap;
  activeCategory: ServiceCategory | 'All';
  searchQuery: string;
  onEmbed: (service: ServiceDef) => void;
}

export function TileGrid({ services, health, activeCategory, searchQuery, onEmbed }: Props) {
  const filtered = services.filter((s) => {
    if (activeCategory !== 'All' && s.category !== activeCategory) return false;
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      return (
        s.name.toLowerCase().includes(q) ||
        s.description.toLowerCase().includes(q) ||
        s.tags?.some((t) => t.toLowerCase().includes(q))
      );
    }
    return true;
  });

  if (filtered.length === 0) {
    return (
      <div style={{ textAlign: 'center', padding: '60px 20px', color: '#475569' }}>
        <div style={{ fontSize: 32, marginBottom: 12 }}>🔍</div>
        <div style={{ fontSize: 15, fontWeight: 500 }}>No services match "{searchQuery}"</div>
        <div style={{ fontSize: 13, marginTop: 6 }}>Try a different search term</div>
      </div>
    );
  }

  // Group by category when showing All
  if (activeCategory === 'All') {
    const grouped: Partial<Record<ServiceCategory, ServiceDef[]>> = {};
    for (const s of filtered) {
      if (!grouped[s.category]) grouped[s.category] = [];
      grouped[s.category]!.push(s);
    }

    return (
      <div style={{ display: 'flex', flexDirection: 'column', gap: 36 }}>
        {(Object.keys(grouped) as ServiceCategory[]).map((cat) => (
          <CategorySection
            key={cat}
            category={cat}
            services={grouped[cat]!}
            health={health}
            onEmbed={onEmbed}
          />
        ))}
      </div>
    );
  }

  return (
    <div style={gridStyle}>
      {filtered.map((s) => (
        <ServiceTile
          key={s.id}
          service={s}
          status={(health[s.id]?.status ?? 'unknown') as HealthStatus}
          onEmbed={onEmbed}
        />
      ))}
    </div>
  );
}

function CategorySection({
  category,
  services,
  health,
  onEmbed,
}: {
  category: ServiceCategory;
  services: ServiceDef[];
  health: HealthMap;
  onEmbed: (service: ServiceDef) => void;
}) {
  const meta = CATEGORY_META[category];
  const healthyCount = services.filter((s) => health[s.id]?.status === 'healthy').length;

  return (
    <section>
      <div style={{
        display: 'flex',
        alignItems: 'center',
        gap: 12,
        marginBottom: 16,
        paddingBottom: 12,
        borderBottom: `1px solid #1e2d40`,
      }}>
        <div style={{
          width: 3,
          height: 20,
          borderRadius: 2,
          background: meta.color,
          flexShrink: 0,
        }} />
        <h2 style={{ fontSize: 15, fontWeight: 700, color: '#e2e8f0', letterSpacing: '0.01em' }}>
          {category}
        </h2>
        <span style={{ fontSize: 12, color: '#475569' }}>{meta.description}</span>
        <div style={{ marginLeft: 'auto', fontSize: 12, color: '#475569' }}>
          <span style={{ color: '#22c55e', fontWeight: 600 }}>{healthyCount}</span>
          <span> / {services.length} healthy</span>
        </div>
      </div>
      <div style={gridStyle}>
        {services.map((s) => (
          <ServiceTile
            key={s.id}
            service={s}
            status={(health[s.id]?.status ?? 'unknown') as HealthStatus}
            onEmbed={onEmbed}
          />
        ))}
      </div>
    </section>
  );
}

const gridStyle: React.CSSProperties = {
  display: 'grid',
  gridTemplateColumns: 'repeat(auto-fill, minmax(240px, 1fr))',
  gap: 14,
};
