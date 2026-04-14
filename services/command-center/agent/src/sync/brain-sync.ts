/**
 * brain-sync.ts — Brain Knowledge Sync Tool
 * MedinovAI Command Center v3.0
 * (c) 2026 Copyright MedinovAI. All Rights Reserved.
 *
 * Syncs knowledge from medinovai-platform-brain to the Nexus agent.
 * Implements Hardening Point 36: Log integrity monitoring.
 */

import { EventEmitter } from 'events';

// ── Constants ──────────────────────────────────────────────────────────────
const E_BRAIN_REPO = 'medinovai-health/medinovai-platform-brain';
const E_KNOWLEDGE_FILES = [
  'agent-knowledge/AGENT_BOOT.md',
  'agent-knowledge/MODULE_INDEX.json',
  'agent-knowledge/COMPETITIVE_INTEL.json',
  'agent-knowledge/DEPLOYMENT_ARCHITECTURE.md',
  'agent-knowledge/CORTEX_RAG_CORPUS.md',
  'agent-knowledge/PLATFORM_INTEGRATION_MAP.json',
];
const E_SYNC_TIMEOUT_MS = 10000; // 10 second timeout per file

// ── Types ──────────────────────────────────────────────────────────────────
export type SyncResult = {
  file: string;
  status: 'success' | 'error' | 'unchanged';
  contentHash?: string;
  contentLength?: number;
  error?: string;
};

export type BrainSyncState = {
  lastSyncAt: Date | null;
  lastSuccessfulSyncAt: Date | null;
  syncCount: number;
  failureCount: number;
  files: Map<string, { hash: string; syncedAt: Date }>;
};

// ── Brain Sync ─────────────────────────────────────────────────────────────
export class BrainSync extends EventEmitter {
  private mos_state: BrainSyncState = {
    lastSyncAt: null,
    lastSuccessfulSyncAt: null,
    syncCount: 0,
    failureCount: 0,
    files: new Map(),
  };

  private mos_cachedContent: Map<string, string> = new Map();

  /**
   * Sync all knowledge files from Brain.
   * Returns the synced content for the agent to process.
   */
  async syncAll(): Promise<{ results: SyncResult[]; content: Map<string, string> }> {
    const mos_results: SyncResult[] = [];
    const mos_newContent: Map<string, string> = new Map();

    this.mos_state.lastSyncAt = new Date();
    this.mos_state.syncCount++;

    for (const mos_file of E_KNOWLEDGE_FILES) {
      const mos_result = await this.syncFile(mos_file);
      mos_results.push(mos_result);

      if (mos_result.status === 'success' && mos_result.contentHash) {
        const mos_content = this.mos_cachedContent.get(mos_file);
        if (mos_content) {
          mos_newContent.set(mos_file, mos_content);
        }
      }
    }

    const mos_successCount = mos_results.filter(r => r.status !== 'error').length;
    const mos_errorCount = mos_results.filter(r => r.status === 'error').length;

    if (mos_errorCount === 0) {
      this.mos_state.lastSuccessfulSyncAt = new Date();
    } else {
      this.mos_state.failureCount++;
    }

    this.emit('sync_complete', {
      results: mos_results,
      successCount: mos_successCount,
      errorCount: mos_errorCount,
      timestamp: new Date(),
    });

    return { results: mos_results, content: mos_newContent };
  }

  /**
   * Sync a single file from Brain.
   */
  private async syncFile(filePath: string): Promise<SyncResult> {
    try {
      const mos_url = `https://api.github.com/repos/${E_BRAIN_REPO}/contents/${filePath}`;
      const mos_res = await fetch(mos_url, {
        headers: {
          Authorization: `token ${process.env.GITHUB_TOKEN}`,
          Accept: 'application/vnd.github.v3+json',
        },
        signal: AbortSignal.timeout(E_SYNC_TIMEOUT_MS),
      });

      if (!mos_res.ok) {
        return {
          file: filePath,
          status: 'error',
          error: `HTTP ${mos_res.status}: ${mos_res.statusText}`,
        };
      }

      const mos_data = await mos_res.json();
      const mos_content = Buffer.from(mos_data.content, 'base64').toString('utf-8');
      const mos_hash = mos_data.sha;

      // Check if content has changed
      const mos_existing = this.mos_state.files.get(filePath);
      if (mos_existing?.hash === mos_hash) {
        return {
          file: filePath,
          status: 'unchanged',
          contentHash: mos_hash,
          contentLength: mos_content.length,
        };
      }

      // Content changed — update cache
      this.mos_cachedContent.set(filePath, mos_content);
      this.mos_state.files.set(filePath, { hash: mos_hash, syncedAt: new Date() });

      return {
        file: filePath,
        status: 'success',
        contentHash: mos_hash,
        contentLength: mos_content.length,
      };
    } catch (mos_error) {
      return {
        file: filePath,
        status: 'error',
        error: String(mos_error),
      };
    }
  }

  /**
   * Get cached content for a specific file.
   */
  getContent(filePath: string): string | null {
    return this.mos_cachedContent.get(filePath) || null;
  }

  /**
   * Get sync state for health checks.
   */
  getState(): Omit<BrainSyncState, 'files'> & { fileCount: number } {
    return {
      lastSyncAt: this.mos_state.lastSyncAt,
      lastSuccessfulSyncAt: this.mos_state.lastSuccessfulSyncAt,
      syncCount: this.mos_state.syncCount,
      failureCount: this.mos_state.failureCount,
      fileCount: this.mos_state.files.size,
    };
  }
}
