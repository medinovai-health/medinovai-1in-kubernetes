import { useState, useEffect, useCallback, useRef } from 'react';
import type { HealthStatus } from '../service-catalog';

export interface ServiceHealth {
  id: string;
  status: HealthStatus;
  latencyMs?: number;
  checkedAt?: string;
  error?: string;
}

export interface HealthMap {
  [serviceId: string]: ServiceHealth;
}

const POLL_INTERVAL_MS = 30_000;

export function useHealthStatus() {
  const [health, setHealth] = useState<HealthMap>({});
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null);
  const [loading, setLoading] = useState(true);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const fetchHealth = useCallback(async () => {
    try {
      const res = await fetch('/api/services/health', { signal: AbortSignal.timeout(8000) });
      if (!res.ok) return;
      const data: ServiceHealth[] = await res.json();
      const map: HealthMap = {};
      for (const item of data) {
        map[item.id] = item;
      }
      setHealth(map);
      setLastUpdated(new Date());
    } catch {
      // Network error — keep last known state, don't clear
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchHealth();
    timerRef.current = setInterval(fetchHealth, POLL_INTERVAL_MS);
    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
    };
  }, [fetchHealth]);

  const getStatus = useCallback(
    (serviceId: string): HealthStatus => health[serviceId]?.status ?? 'unknown',
    [health]
  );

  return { health, lastUpdated, loading, getStatus, refresh: fetchHealth };
}
