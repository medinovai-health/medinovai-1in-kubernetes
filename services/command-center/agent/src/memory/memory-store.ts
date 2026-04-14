/**
 * memory-store.ts — Nexus Agent Memory Store
 * MedinovAI Command Center v3.0
 * (c) 2026 Copyright MedinovAI. All Rights Reserved.
 *
 * Implements a persistent, searchable memory store for the Nexus agent.
 * Uses a hybrid approach: in-memory for speed, file system for persistence.
 *
 * Self-learning architecture:
 * - Short-term memory: last 1000 entries (in-memory)
 * - Long-term memory: high-confidence patterns (persisted to disk)
 * - Knowledge base: Brain sync data (refreshed every 5 minutes)
 */

import { EventEmitter } from 'events';
import * as fs from 'fs';
import * as path from 'path';

// ── Constants ──────────────────────────────────────────────────────────────
const E_SHORT_TERM_LIMIT = 1000;
const E_LONG_TERM_THRESHOLD = 0.85; // Confidence threshold for long-term storage
const E_MEMORY_DIR = process.env.NEXUS_MEMORY_DIR || '/app/agent/memory';
const E_LONG_TERM_FILE = path.join(E_MEMORY_DIR, 'long-term.json');
const E_KNOWLEDGE_FILE = path.join(E_MEMORY_DIR, 'knowledge.json');
const E_PERSIST_INTERVAL_MS = 60 * 1000; // Persist every minute

// ── Types ──────────────────────────────────────────────────────────────────
export type MemoryEntry = {
  id: string;
  type: 'observation' | 'action' | 'learning' | 'incident' | 'knowledge';
  content: string;
  timestamp: Date;
  environment: string;
  tags: string[];
  confidence: number;
  accessCount: number;
  lastAccessedAt: Date;
};

export type LearningPattern = {
  id: string;
  pattern: string;
  response: string;
  confidence: number;
  occurrences: number;
  lastSeenAt: Date;
  tags: string[];
};

// ── Memory Store ──────────────────────────────────────────────────────────
export class MemoryStore extends EventEmitter {
  private mos_shortTerm: MemoryEntry[] = [];
  private mos_longTerm: Map<string, MemoryEntry> = new Map();
  private mos_patterns: Map<string, LearningPattern> = new Map();
  private mos_persistTimer: NodeJS.Timeout | null = null;

  constructor() {
    super();
    this.loadFromDisk();
    this.startPersistTimer();
  }

  /**
   * Add an entry to short-term memory.
   * High-confidence entries are automatically promoted to long-term.
   */
  add(entry: MemoryEntry): void {
    // Add to short-term
    this.mos_shortTerm.push(entry);

    // Trim short-term if over limit (FIFO)
    if (this.mos_shortTerm.length > E_SHORT_TERM_LIMIT) {
      this.mos_shortTerm.shift();
    }

    // Promote to long-term if high confidence
    if (entry.confidence >= E_LONG_TERM_THRESHOLD) {
      this.mos_longTerm.set(entry.id, entry);
      this.emit('promoted_to_long_term', entry);
    }

    // Extract patterns from learning entries
    if (entry.type === 'learning') {
      this.extractPattern(entry);
    }
  }

  /**
   * Search memory for relevant entries using keyword matching.
   * Returns top-K entries sorted by relevance score.
   */
  search(query: string, topK = 5): MemoryEntry[] {
    const mos_queryWords = query.toLowerCase().split(/\s+/).filter(w => w.length > 2);
    const mos_allMemory = [
      ...this.mos_shortTerm,
      ...Array.from(this.mos_longTerm.values()),
    ];

    // Score each entry
    const mos_scored = mos_allMemory.map(entry => {
      const mos_contentLower = entry.content.toLowerCase();
      const mos_tagMatches = mos_queryWords.filter(w =>
        entry.tags.some(t => t.includes(w))
      ).length;
      const mos_contentMatches = mos_queryWords.filter(w =>
        mos_contentLower.includes(w)
      ).length;

      const mos_score =
        (mos_tagMatches * 2) +
        mos_contentMatches +
        entry.confidence +
        (entry.accessCount * 0.1);

      return { entry, score: mos_score };
    });

    // Sort by score and return top-K
    return mos_scored
      .filter(s => s.score > 0)
      .sort((a, b) => b.score - a.score)
      .slice(0, topK)
      .map(s => {
        // Update access count
        s.entry.accessCount++;
        s.entry.lastAccessedAt = new Date();
        return s.entry;
      });
  }

  /**
   * Get all patterns learned from operational data.
   */
  getPatterns(): LearningPattern[] {
    return Array.from(this.mos_patterns.values())
      .sort((a, b) => b.confidence - a.confidence);
  }

  /**
   * Get memory statistics for the agent status endpoint.
   */
  getStats() {
    return {
      shortTermCount: this.mos_shortTerm.length,
      longTermCount: this.mos_longTerm.size,
      patternCount: this.mos_patterns.size,
      totalEntries: this.mos_shortTerm.length + this.mos_longTerm.size,
    };
  }

  /**
   * Extract a reusable pattern from a learning entry.
   */
  private extractPattern(entry: MemoryEntry): void {
    // Simple pattern extraction — upgrade to NLP in v4
    const mos_lines = entry.content.split('\n').filter(l => l.trim());
    if (mos_lines.length < 2) return;

    const mos_patternKey = mos_lines[0].substring(0, 100);
    const mos_existing = this.mos_patterns.get(mos_patternKey);

    if (mos_existing) {
      mos_existing.occurrences++;
      mos_existing.confidence = Math.min(1.0, mos_existing.confidence + 0.05);
      mos_existing.lastSeenAt = new Date();
    } else {
      this.mos_patterns.set(mos_patternKey, {
        id: crypto.randomUUID(),
        pattern: mos_patternKey,
        response: mos_lines.slice(1).join('\n').substring(0, 500),
        confidence: entry.confidence,
        occurrences: 1,
        lastSeenAt: new Date(),
        tags: entry.tags,
      });
    }
  }

  /**
   * Load memory from disk on startup.
   */
  private loadFromDisk(): void {
    try {
      if (!fs.existsSync(E_MEMORY_DIR)) {
        fs.mkdirSync(E_MEMORY_DIR, { recursive: true });
        return;
      }

      if (fs.existsSync(E_LONG_TERM_FILE)) {
        const mos_data = JSON.parse(fs.readFileSync(E_LONG_TERM_FILE, 'utf-8'));
        for (const entry of mos_data) {
          this.mos_longTerm.set(entry.id, {
            ...entry,
            timestamp: new Date(entry.timestamp),
            lastAccessedAt: new Date(entry.lastAccessedAt),
          });
        }
        console.log(`[Memory] Loaded ${this.mos_longTerm.size} long-term entries`);
      }
    } catch (mos_error) {
      console.error('[Memory] Failed to load from disk:', mos_error);
    }
  }

  /**
   * Start periodic persistence to disk.
   */
  private startPersistTimer(): void {
    this.mos_persistTimer = setInterval(() => {
      this.persistToDisk();
    }, E_PERSIST_INTERVAL_MS);
  }

  /**
   * Persist long-term memory to disk.
   */
  persistToDisk(): void {
    try {
      if (!fs.existsSync(E_MEMORY_DIR)) {
        fs.mkdirSync(E_MEMORY_DIR, { recursive: true });
      }

      const mos_longTermArray = Array.from(this.mos_longTerm.values());
      fs.writeFileSync(E_LONG_TERM_FILE, JSON.stringify(mos_longTermArray, null, 2));
    } catch (mos_error) {
      console.error('[Memory] Failed to persist to disk:', mos_error);
    }
  }

  /**
   * Stop the persist timer.
   */
  stop(): void {
    if (this.mos_persistTimer) {
      clearInterval(this.mos_persistTimer);
      this.persistToDisk(); // Final persist on stop
    }
  }
}
