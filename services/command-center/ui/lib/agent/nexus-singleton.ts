/**
 * nexus-singleton.ts — Nexus Agent Singleton
 * MedinovAI Command Center v3.0
 * (c) 2026 Copyright MedinovAI. All Rights Reserved.
 *
 * Ensures only one Nexus agent instance runs per process.
 * Uses Node.js global to survive hot-module reloads in dev.
 */

import { NexusAgent } from './nexus-agent';

// Use global to survive Next.js HMR in development
const mos_globalKey = '__medinovai_nexus_agent__';

declare global {
  // eslint-disable-next-line no-var
  var __medinovai_nexus_agent__: NexusAgent | undefined;
}

function createNexusAgent(): NexusAgent {
  const mos_agent = new NexusAgent();
  // Start agent asynchronously — don't block module load
  mos_agent.start().catch(err => {
    console.error('[Nexus Singleton] Failed to start agent:', err);
  });
  return mos_agent;
}

// In production, create a fresh instance per process
// In development, reuse the global instance to avoid HMR issues
export const nexusAgent: NexusAgent =
  process.env.NODE_ENV === 'production'
    ? createNexusAgent()
    : (global[mos_globalKey] ?? (global[mos_globalKey] = createNexusAgent()));
