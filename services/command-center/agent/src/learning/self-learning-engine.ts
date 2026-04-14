/**
 * self-learning-engine.ts — Nexus Self-Learning Engine
 * MedinovAI Command Center v3.0
 * (c) 2026 Copyright MedinovAI. All Rights Reserved.
 *
 * Implements the self-learning cycle for the Nexus agent:
 * 1. Observe operational patterns from interactions
 * 2. Identify high-confidence patterns for promotion
 * 3. Generate improvement proposals for human review
 * 4. Apply approved improvements to agent behavior
 *
 * OmnoBox constraint: Nexus CANNOT approve its own proposals.
 * All self-improvement proposals require human review and approval.
 */

import { EventEmitter } from 'events';
import type { MemoryEntry, LearningPattern } from '../memory/memory-store';

// ── Constants ──────────────────────────────────────────────────────────────
const E_MIN_OCCURRENCES_FOR_PROPOSAL = 5;
const E_MIN_CONFIDENCE_FOR_PROPOSAL = 0.8;
const E_IMPROVEMENT_CYCLE_INTERVAL_MS = 24 * 60 * 60 * 1000; // Daily
const E_MAX_PROPOSALS_PER_CYCLE = 10;

// ── Types ──────────────────────────────────────────────────────────────────
export type ImprovementProposal = {
  id: string;
  type: 'new_pattern' | 'updated_response' | 'new_capability' | 'behavior_change';
  title: string;
  description: string;
  evidence: string[];
  confidence: number;
  estimatedImpact: 'low' | 'medium' | 'high';
  status: 'pending' | 'approved' | 'rejected' | 'applied';
  createdAt: Date;
  reviewedAt?: Date;
  reviewedBy?: string;
  appliedAt?: Date;
};

// ── Self-Learning Engine ───────────────────────────────────────────────────
export class SelfLearningEngine extends EventEmitter {
  private mos_proposals: Map<string, ImprovementProposal> = new Map();
  private mos_cycleTimer: NodeJS.Timeout | null = null;
  private mos_improvementCount = 0;

  constructor() {
    super();
  }

  /**
   * Start the self-learning cycle.
   */
  start(): void {
    // Run immediately, then on schedule
    this.runLearningCycle([]);

    this.mos_cycleTimer = setInterval(() => {
      this.runLearningCycle([]);
    }, E_IMPROVEMENT_CYCLE_INTERVAL_MS);

    console.log('[SelfLearning] Engine started');
  }

  /**
   * Stop the self-learning cycle.
   */
  stop(): void {
    if (this.mos_cycleTimer) {
      clearInterval(this.mos_cycleTimer);
    }
  }

  /**
   * Run a learning cycle — analyze patterns and generate proposals.
   */
  async runLearningCycle(patterns: LearningPattern[]): Promise<void> {
    const mos_eligiblePatterns = patterns.filter(p =>
      p.occurrences >= E_MIN_OCCURRENCES_FOR_PROPOSAL &&
      p.confidence >= E_MIN_CONFIDENCE_FOR_PROPOSAL
    );

    if (mos_eligiblePatterns.length === 0) return;

    const mos_newProposals: ImprovementProposal[] = [];

    for (const mos_pattern of mos_eligiblePatterns.slice(0, E_MAX_PROPOSALS_PER_CYCLE)) {
      const mos_proposal = this.generateProposal(mos_pattern);
      if (mos_proposal) {
        mos_newProposals.push(mos_proposal);
        this.mos_proposals.set(mos_proposal.id, mos_proposal);
      }
    }

    if (mos_newProposals.length > 0) {
      this.emit('proposals_generated', {
        count: mos_newProposals.length,
        proposals: mos_newProposals,
        timestamp: new Date(),
      });

      console.log(`[SelfLearning] Generated ${mos_newProposals.length} improvement proposals`);
    }
  }

  /**
   * Generate an improvement proposal from a learned pattern.
   */
  private generateProposal(pattern: LearningPattern): ImprovementProposal | null {
    // Don't generate duplicate proposals for the same pattern
    const mos_existing = Array.from(this.mos_proposals.values()).find(
      p => p.title.includes(pattern.pattern.substring(0, 50))
    );
    if (mos_existing) return null;

    return {
      id: crypto.randomUUID(),
      type: 'new_pattern',
      title: `Learned pattern: ${pattern.pattern.substring(0, 80)}`,
      description: `This pattern has been observed ${pattern.occurrences} times with ${Math.round(pattern.confidence * 100)}% confidence. Promoting to permanent knowledge base.`,
      evidence: [
        `Observed ${pattern.occurrences} times`,
        `Confidence: ${Math.round(pattern.confidence * 100)}%`,
        `Last seen: ${pattern.lastSeenAt.toISOString()}`,
        `Tags: ${pattern.tags.join(', ')}`,
      ],
      confidence: pattern.confidence,
      estimatedImpact: pattern.occurrences > 20 ? 'high' : pattern.occurrences > 10 ? 'medium' : 'low',
      status: 'pending',
      createdAt: new Date(),
    };
  }

  /**
   * Apply an approved improvement proposal.
   * Called by human reviewer after approval.
   */
  applyProposal(proposalId: string, reviewedBy: string): boolean {
    const mos_proposal = this.mos_proposals.get(proposalId);
    if (!mos_proposal || mos_proposal.status !== 'approved') return false;

    mos_proposal.status = 'applied';
    mos_proposal.appliedAt = new Date();
    this.mos_improvementCount++;

    this.emit('proposal_applied', {
      proposal: mos_proposal,
      appliedBy: reviewedBy,
      timestamp: new Date(),
    });

    console.log(`[SelfLearning] Applied improvement: ${mos_proposal.title}`);
    return true;
  }

  /**
   * Approve a proposal (must be called by human, not by Nexus itself).
   */
  approveProposal(proposalId: string, reviewedBy: string): boolean {
    const mos_proposal = this.mos_proposals.get(proposalId);
    if (!mos_proposal || mos_proposal.status !== 'pending') return false;

    mos_proposal.status = 'approved';
    mos_proposal.reviewedAt = new Date();
    mos_proposal.reviewedBy = reviewedBy;

    return true;
  }

  /**
   * Reject a proposal.
   */
  rejectProposal(proposalId: string, reviewedBy: string): boolean {
    const mos_proposal = this.mos_proposals.get(proposalId);
    if (!mos_proposal) return false;

    mos_proposal.status = 'rejected';
    mos_proposal.reviewedAt = new Date();
    mos_proposal.reviewedBy = reviewedBy;

    return true;
  }

  /**
   * Get all proposals for the review queue.
   */
  getProposals(status?: ImprovementProposal['status']): ImprovementProposal[] {
    const mos_all = Array.from(this.mos_proposals.values());
    return status ? mos_all.filter(p => p.status === status) : mos_all;
  }

  /**
   * Get self-improvement statistics.
   */
  getStats() {
    const mos_proposals = Array.from(this.mos_proposals.values());
    return {
      totalProposals: mos_proposals.length,
      pendingProposals: mos_proposals.filter(p => p.status === 'pending').length,
      approvedProposals: mos_proposals.filter(p => p.status === 'approved').length,
      appliedImprovements: this.mos_improvementCount,
      rejectedProposals: mos_proposals.filter(p => p.status === 'rejected').length,
    };
  }
}
