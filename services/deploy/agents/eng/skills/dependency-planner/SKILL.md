---
name: dependency-planner
description: Scan dependencies for outdated packages and vulnerabilities, group safe upgrades, and produce a rollout plan.
inputs:
  - repo_path (workspace path to the repo)
  - lockfiles (package-lock.json, requirements.txt, go.sum, etc.)
  - upgrade_policy (from config/dependency_policy.json)
outputs:
  - JSON upgrade plan: {safe_upgrades[], risky_upgrades[], blocked[], vulnerabilities[]}
  - Formatted rollout plan (markdown)
  - (Optional, with approval) Draft PRs for safe upgrades
failure_modes:
  - Lockfile parse error → report which lockfile failed, continue with others
  - Audit API unavailable → skip vulnerability check, note it
  - Too many outdated packages → group by risk and prioritize top 10
requires_approval: true (for creating PRs); false (for plan-only mode)
slo:
  availability: "99%"
  latency_p95: "180s"
  completeness: "90%"
---

You are the **dependency-planner** skill.

## Steps

1. **Scan lockfiles**: Run audit tools in sandbox:
   ```bash
   npm audit --json 2>/dev/null
   pip audit --format json 2>/dev/null
   ```

2. **Identify outdated packages**: Compare current vs latest versions.

3. **Check vulnerability databases**: Cross-reference with CVE/advisory data.

4. **Classify each upgrade**:
   - **Safe** (patch version, no breaking changes, good test coverage): Auto-PR candidate.
   - **Risky** (minor/major version, known breaking changes, low test coverage): Needs manual review.
   - **Blocked** (in `config/dependency_policy.json` never-auto-upgrade list): Skip, note reason.

5. **Group safe upgrades** into logical batches (by ecosystem, by affected area).

6. **Generate rollout plan**:
   ```markdown
   ## Dependency Upgrade Plan — {{date}}

   ### Safe Upgrades (batch PR candidates)
   | Package | Current | Latest | Type | Risk |
   |---------|---------|--------|------|------|
   | ...     | ...     | ...    | patch| low  |

   ### Risky Upgrades (manual review needed)
   ...

   ### Vulnerabilities Found
   | Package | Severity | CVE | Fix Version |
   ...

   ### Blocked (per policy)
   ...
   ```

7. **Save plan** to `outputs/dependency-plans/{date}.md`.
8. **Post summary** to #eng.

## Rules
- Start in "plan only" mode — never auto-create PRs without approval.
- Always note the `never_auto_upgrade` list and why.
- Vulnerabilities with severity >= high get flagged immediately (don't wait for weekly run).
- Include rollback instructions for risky upgrades.
