/**
 * metrics-store.ts — Shared Metrics Store
 * MedinovAI Command Center v3.0
 * (c) 2026 Copyright MedinovAI. All Rights Reserved.
 */

export const mos_metrics = {
  http_requests_total: 0,
  http_errors_total: 0,
  nexus_queries_total: 0,
  nexus_actions_approved: 0,
  nexus_actions_rejected: 0,
  brain_syncs_total: 0,
  brain_sync_failures: 0,
  active_sessions: 0,
  memory_usage_bytes: 0,
};

export function incrementMetric(key: keyof typeof mos_metrics, value = 1) {
  mos_metrics[key] += value;
}
