#!/usr/bin/env bash
# ─── register_crons.sh ───────────────────────────────────────────────────────
# Registers cron jobs with MedinovAI Atlas for automated scheduled tasks.
# Run this AFTER the gateway is running.
#
# Usage:
#   bash scripts/register_crons.sh
#
# Timezone: Defaults to America/New_York. Override with TZ env var.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ─── Configuration ────────────────────────────────────────────────────────────
TIMEZONE="${TZ:-America/New_York}"
OPS_CHANNEL="${OPS_CHANNEL:?OPS_CHANNEL env var is required (e.g. channel:C01ABCDEF)}"
EXEC_CHANNEL="${EXEC_CHANNEL:?EXEC_CHANNEL env var is required (e.g. channel:C02ABCDEF)}"
SUPPORT_CHANNEL="${SUPPORT_CHANNEL:?SUPPORT_CHANNEL env var is required (e.g. channel:C03ABCDEF)}"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          MedinovAI Atlas Cron Registration                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "▸ Timezone: $TIMEZONE"
echo ""

# ─── Check MedinovAI Atlas is installed ─────────────────────────────────────────────
if ! command -v atlas &> /dev/null; then
    echo "✗ atlas not found. Run: bash scripts/install_atlas.sh"
    exit 1
fi

# ─── 1. Morning Briefing (daily at 07:00) ────────────────────────────────────
echo "▸ Registering: Morning Briefing (daily 07:00)"
atlas cron add \
    --name "Morning briefing" \
    --cron "0 7 * * *" \
    --tz "$TIMEZONE" \
    --session isolated \
    --message "Generate today's exec briefing: calendar, KPIs, risks, top tasks. Use the daily-brief skill." \
    --announce \
    --channel slack \
    --to "$EXEC_CHANNEL" \
    2>/dev/null || echo "  (may already exist — continuing)"

# ─── 2. End-of-Day Wrap (weekdays at 18:00) ──────────────────────────────────
echo "▸ Registering: End-of-Day Wrap (weekdays 18:00)"
atlas cron add \
    --name "EOD wrap" \
    --cron "0 18 * * 1-5" \
    --tz "$TIMEZONE" \
    --session isolated \
    --message "Generate end-of-day wrap: what moved, what's blocked, what's at risk, top 3 priorities for tomorrow." \
    --announce \
    --channel slack \
    --to "$EXEC_CHANNEL" \
    2>/dev/null || echo "  (may already exist — continuing)"

# ─── 3. SLA Monitor (every 30 minutes, business hours) ───────────────────────
echo "▸ Registering: SLA Monitor (every 30 min)"
atlas cron add \
    --name "SLA monitor" \
    --cron "*/30 8-18 * * 1-5" \
    --tz "$TIMEZONE" \
    --session isolated \
    --message "Check open support tickets against SLA rules. Alert on breach risk. Only post if there are tickets at risk." \
    --channel slack \
    --to "$SUPPORT_CHANNEL" \
    2>/dev/null || echo "  (may already exist — continuing)"

# ─── 4. CRM Hygiene (nightly at 22:00) ───────────────────────────────────────
echo "▸ Registering: CRM Hygiene check (nightly 22:00)"
atlas cron add \
    --name "CRM hygiene" \
    --cron "0 22 * * 1-5" \
    --tz "$TIMEZONE" \
    --session isolated \
    --message "Audit CRM deals: find missing next steps, stale close dates, and deals with no activity > 14 days. Generate a hygiene report." \
    --channel slack \
    --to "$OPS_CHANNEL" \
    2>/dev/null || echo "  (may already exist — continuing)"

# ─── 5. Weekly Competitive Intel (Monday 09:00) ──────────────────────────────
echo "▸ Registering: Competitive Intel digest (weekly Monday 09:00)"
atlas cron add \
    --name "Competitive intel" \
    --cron "0 9 * * 1" \
    --tz "$TIMEZONE" \
    --session isolated \
    --message "Generate weekly competitive intelligence digest: check competitor websites, job postings, and news. Summarize changes and suggest actions." \
    --announce \
    --channel slack \
    --to "$OPS_CHANNEL" \
    2>/dev/null || echo "  (may already exist — continuing)"

# ─── 6. AR Aging / Collections Check (daily 08:00) ───────────────────────────
echo "▸ Registering: AR Aging & Collections check (daily 08:00)"
atlas cron add \
    --name "AR aging collections" \
    --cron "0 8 * * 1-5" \
    --tz "$TIMEZONE" \
    --session isolated \
    --message "Run AR aging report. Identify overdue invoices and draft collections emails using tiered templates. Post summary to #finance." \
    --channel slack \
    --to "$OPS_CHANNEL" \
    2>/dev/null || echo "  (may already exist — continuing)"

# ─── 7. Weekly Dependency Scan (Wednesday 10:00) ─────────────────────────────
echo "▸ Registering: Dependency upgrade scan (weekly Wednesday 10:00)"
atlas cron add \
    --name "Dependency scan" \
    --cron "0 10 * * 3" \
    --tz "$TIMEZONE" \
    --session isolated \
    --message "Scan all repos for outdated dependencies and known CVEs. Group safe upgrades. Produce a rollout plan. Post to #eng." \
    --announce \
    --channel slack \
    --to "$OPS_CHANNEL" \
    2>/dev/null || echo "  (may already exist — continuing)"

# ─── 8. Customer Health Scoring (weekly Monday 08:00) ────────────────────────
echo "▸ Registering: Customer health scores (weekly Monday 08:00)"
atlas cron add \
    --name "Customer health" \
    --cron "0 8 * * 1" \
    --tz "$TIMEZONE" \
    --session isolated \
    --message "Calculate customer health scores using the health model. Flag at-risk and critical accounts. Create CS tickets for low-health accounts. Post summary to #support." \
    --announce \
    --channel slack \
    --to "$SUPPORT_CHANNEL" \
    2>/dev/null || echo "  (may already exist — continuing)"

# ─── 9. PR Review Digest (daily 09:00) ───────────────────────────────────────
echo "▸ Registering: PR review digest (daily 09:00)"
atlas cron add \
    --name "PR review digest" \
    --cron "0 9 * * 1-5" \
    --tz "$TIMEZONE" \
    --session isolated \
    --message "Summarize open PRs needing review: list by age, highlight PRs without reviewers, flag PRs older than 48h. Post to #eng." \
    --channel slack \
    --to "$OPS_CHANNEL" \
    2>/dev/null || echo "  (may already exist — continuing)"

# ─── 10. Monthly Invoice Generation (1st of month 07:00) ────────────────────
echo "▸ Registering: Monthly invoice generation (1st of month 07:00)"
atlas cron add \
    --name "Monthly invoicing" \
    --cron "0 7 1 * *" \
    --tz "$TIMEZONE" \
    --session isolated \
    --message "Generate invoices for all active customers based on contract terms and last month's usage. Post drafts to #finance for approval before sending." \
    --announce \
    --channel slack \
    --to "$OPS_CHANNEL" \
    2>/dev/null || echo "  (may already exist — continuing)"

# ─── 11. Weekly Memory Reflection (Sunday 22:00) ─────────────────────────────
echo "▸ Registering: Weekly memory reflection (Sunday 22:00)"
atlas cron add \
    --name "Memory reflection" \
    --cron "0 22 * * 0" \
    --tz "$TIMEZONE" \
    --session isolated \
    --message "Review accumulated memories across all agents. Consolidate patterns from experiences into beliefs. Prune stale world knowledge. Update entity relationships. Log reflection summary." \
    --channel slack \
    --to "$OPS_CHANNEL" \
    2>/dev/null || echo "  (may already exist — continuing)"

# ─── 12. Weekly Feedback Digest (Friday 17:00) ───────────────────────────────
echo "▸ Registering: Weekly feedback digest (Friday 17:00)"
atlas cron add \
    --name "Feedback digest" \
    --cron "0 17 * * 5" \
    --tz "$TIMEZONE" \
    --session isolated \
    --message "Aggregate feedback from all agent state/feedback/ directories for the past 7 days. Generate a digest with thumbsup/thumbsdown ratios per skill. Highlight skills with less than 70 percent positive feedback. Post to #exec." \
    --announce \
    --channel slack \
    --to "$OPS_CHANNEL" \
    2>/dev/null || echo "  (may already exist — continuing)"

# ═══════════════════════════════════════════════════════════════════════════════
# SOCIAL MEDIA & RESEARCH CRON JOBS (Beacon / Marketing Agent)
# These run 24/7 for continuous social media monitoring and content creation.
# ═══════════════════════════════════════════════════════════════════════════════

echo ""
echo "▸ Registering Social Media cron jobs..."
echo ""

# ─── 13. Feed Scan (every 30 minutes, 24/7) ────────────────────────────────
echo "▸ Registering: Social Feed Scan (every 30 min)"
atlas cron add \
    --name "Social feed scan" \
    --cron "*/30 * * * *" \
    --tz "$TIMEZONE" \
    --session isolated \
    --agent marketing \
    --message "Run the feed-scanner skill. Scan LinkedIn, X/Twitter, Facebook, Instagram feeds for engagement opportunities. Identify top posts from key connections and industry leaders. Draft contextual replies for the best opportunities. Queue drafts in state/engagement_queue.json for WhatsApp approval. Only alert if high-priority engagement opportunities found." \
    2>/dev/null || echo "  (may already exist — continuing)"

# ─── 14. Trend Analysis (every 2 hours, 24/7) ──────────────────────────────
echo "▸ Registering: Cross-Platform Trend Analysis (every 2h)"
atlas cron add \
    --name "Trend analysis" \
    --cron "0 */2 * * *" \
    --tz "$TIMEZONE" \
    --session isolated \
    --agent marketing \
    --message "Run the trend-analyzer skill. Aggregate trending topics across LinkedIn, X/Twitter, TikTok, and web news. Match trends against content pillars (Healthcare AI, AI/ML Trends, Startup/Leadership). Score by relevance, velocity, and timeliness. Write results to state/trend_report.json. Flag any trend that needs immediate content response." \
    2>/dev/null || echo "  (may already exist — continuing)"

# ─── 15. Mention Tracker (every 15 minutes, 24/7) ──────────────────────────
echo "▸ Registering: Social Mention Tracker (every 15 min)"
atlas cron add \
    --name "Mention tracker" \
    --cron "*/15 * * * *" \
    --tz "$TIMEZONE" \
    --session isolated \
    --agent marketing \
    --message "Check all social platforms for new mentions, tags, replies, and DMs directed at our accounts. Draft responses for each mention prioritized by engagement value. Queue responses for WhatsApp approval. Alert immediately if a high-profile account mentions us." \
    2>/dev/null || echo "  (may already exist — continuing)"

# ─── 16. Morning Content Plan (daily 07:00) ────────────────────────────────
echo "▸ Registering: Morning Content Plan (daily 07:00)"
atlas cron add \
    --name "Morning content plan" \
    --cron "0 7 * * *" \
    --tz "$TIMEZONE" \
    --session isolated \
    --agent marketing \
    --message "Generate today's social media content plan. Read state/content_calendar.json for planned posts. Cross-reference with latest state/trend_report.json for any needed pivots. Draft all planned posts for the day across LinkedIn, X/Twitter, Facebook, Instagram. Queue drafts for WhatsApp approval. Send a summary of today's plan to WhatsApp." \
    --announce \
    2>/dev/null || echo "  (may already exist — continuing)"

# ─── 17. LinkedIn Engagement (3x daily, weekdays) ──────────────────────────
echo "▸ Registering: LinkedIn Engagement (9am, 12pm, 5pm weekdays)"
atlas cron add \
    --name "LinkedIn engagement" \
    --cron "0 9,12,17 * * 1-5" \
    --tz "$TIMEZONE" \
    --session isolated \
    --agent marketing \
    --message "Run linkedin-manager skill in engagement mode. Read LinkedIn feed for top posts from connections and industry leaders. Draft 3-5 thoughtful comments that add genuine value (insight, data, experience, question). Follow SOUL.md LinkedIn voice. Queue drafts for WhatsApp approval. Never write generic comments." \
    2>/dev/null || echo "  (may already exist — continuing)"

# ─── 18. Twitter Engagement (4x daily) ─────────────────────────────────────
echo "▸ Registering: Twitter Engagement (8am, 11am, 2pm, 6pm)"
atlas cron add \
    --name "Twitter engagement" \
    --cron "0 8,11,14,18 * * *" \
    --tz "$TIMEZONE" \
    --session isolated \
    --agent marketing \
    --message "Run twitter-manager skill in engagement mode. Check X/Twitter timeline and monitored hashtags. Draft replies, quote tweets with commentary, and thread ideas. Follow SOUL.md X voice — sharp, concise, opinionated. Queue for WhatsApp approval." \
    2>/dev/null || echo "  (may already exist — continuing)"

# ─── 19. EOD Social Summary (weekdays 18:00) ───────────────────────────────
echo "▸ Registering: EOD Social Summary (weekdays 18:00)"
atlas cron add \
    --name "EOD social summary" \
    --cron "0 18 * * 1-5" \
    --tz "$TIMEZONE" \
    --session isolated \
    --agent marketing \
    --message "Generate end-of-day social media summary. Report: what was published today across all platforms, engagement metrics for today's posts, top engagement opportunities acted on, pending approval items, content calendar adherence. Send summary to WhatsApp." \
    --announce \
    2>/dev/null || echo "  (may already exist — continuing)"

# ─── 20. Weekly Content Calendar (Sunday 20:00) ────────────────────────────
echo "▸ Registering: Weekly Content Calendar (Sunday 20:00)"
atlas cron add \
    --name "Weekly content calendar" \
    --cron "0 20 * * 0" \
    --tz "$TIMEZONE" \
    --session isolated \
    --agent marketing \
    --message "Run the content-calendar skill. Generate next week's content calendar across all platforms (LinkedIn, X/Twitter, Facebook, Instagram, TikTok, YouTube, Medium). Use trend data from state/trend_report.json and content pillars from config/content_strategy.md. Balance pillars (Healthcare AI, AI/ML, Startup/Leadership). Include daily post outlines with hooks, topics, and optimal posting times. Write to state/content_calendar.json. Send summary to WhatsApp for review." \
    --announce \
    2>/dev/null || echo "  (may already exist — continuing)"

# ─── 21. Weekly Research Topic Selection (Monday 09:00) ────────────────────
echo "▸ Registering: Weekly Research Topic (Monday 09:00)"
atlas cron add \
    --name "Weekly research topic" \
    --cron "0 9 * * 1" \
    --tz "$TIMEZONE" \
    --session isolated \
    --agent marketing \
    --message "Run the research-engine skill in topic selection mode. Select this week's research paper topic based on trends, content pillars, and rotating theme schedule (Week 1: landscape, Week 2: technical, Week 3: policy, Week 4: market). Begin deep research — gather 20+ sources. Write initial findings to outputs/research/. Send topic selection summary to WhatsApp and Mattermost #research-review." \
    --announce \
    2>/dev/null || echo "  (may already exist — continuing)"

# ─── 22. Research Paper Draft Submission (Thursday 09:00) ───────────────────
echo "▸ Registering: Research Paper Draft (Thursday 09:00)"
atlas cron add \
    --name "Research paper draft" \
    --cron "0 9 * * 4" \
    --tz "$TIMEZONE" \
    --session isolated \
    --agent marketing \
    --message "Run the research-engine skill in draft mode. Complete this week's research paper draft. Structure: Abstract, Introduction, Background, Analysis, Findings, Discussion, Implications, Conclusion, References. Minimum 20 sources, 3000-8000 words. Run self-review quality gate. Submit to Mattermost #research-review channel for PhD staff review via the research-paper-publish Approval Pipeline workflow. Tag PhD reviewers." \
    --announce \
    2>/dev/null || echo "  (may already exist — continuing)"

# ─── 23. Monthly Social Analytics Report (1st of month 08:00) ──────────────
echo "▸ Registering: Monthly Social Analytics (1st of month 08:00)"
atlas cron add \
    --name "Monthly social analytics" \
    --cron "0 8 1 * *" \
    --tz "$TIMEZONE" \
    --session isolated \
    --agent marketing \
    --message "Generate monthly cross-platform social media analytics report. For each platform (LinkedIn, X, Facebook, Instagram, TikTok, YouTube, Medium): total posts, impressions, engagement rate, follower growth, top performing content. Include: month-over-month trends, content pillar performance, recommendations for next month. Send report to WhatsApp and Mattermost." \
    --announce \
    2>/dev/null || echo "  (may already exist — continuing)"

# ─── List registered crons ───────────────────────────────────────────────────
echo ""
echo "▸ Registered cron jobs:"
atlas cron list 2>/dev/null || echo "  (list command may require gateway running)"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✓ Cron jobs registered! (12 ops + 11 social media)         ║"
echo "║                                                             ║"
echo "║  Debug commands:                                            ║"
echo "║    atlas cron status                                     ║"
echo "║    atlas cron list                                       ║"
echo "║    atlas cron runs --id <job-id> --limit 20              ║"
echo "║    atlas logs --follow                                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
