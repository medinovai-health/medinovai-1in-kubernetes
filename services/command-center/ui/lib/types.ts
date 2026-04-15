/**
 * types.ts — Shared Type Definitions
 * MedinovAI Command Center v3.0
 * (c) 2026 Copyright MedinovAI. All Rights Reserved.
 */

export type Alert = {
  id: string;
  severity: 'critical' | 'high' | 'medium' | 'low';
  title: string;
  description: string;
  service: string;
  environment: string;
  timestamp: string;
  acknowledged: boolean;
  acknowledgedBy?: string;
  resolvedAt?: string;
  nexusTriaged: boolean;
};

export type Deployment = {
  id: string;
  service: string;
  version: string;
  environment: string;
  status: 'pending_approval' | 'approved' | 'in_progress' | 'success' | 'failed' | 'rolled_back';
  requestedBy: string;
  approvedBy?: string;
  startedAt?: string;
  completedAt?: string;
  rollbackVersion?: string;
  nexusRecommendation?: string;
  createdAt: string;
};
