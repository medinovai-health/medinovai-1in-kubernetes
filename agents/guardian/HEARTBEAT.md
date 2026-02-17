# Guardian Meta-Agent — Heartbeat Checks

## Checks

### 1. Policy Consistency
- **Detect**: Verify all governance control definitions are present and consistent across agents.
- **Remediate**: Flag missing or inconsistent policy definitions.
- **Alert if**: Any GOV control is undefined or conflicts between agents.

### 2. Validation Coverage
- **Detect**: Verify all recent deploy and infra actions were validated.
- **Remediate**: Flag any actions that bypassed validation.
- **Alert if**: Any significant action executed without validation. NEVER suppress.

### 3. Approval Audit
- **Detect**: Verify all approvals are legitimate (approved by authorized approvers).
- **Alert if**: Approval from unauthorized user or expired approval used.

### 4. Compliance Status
- **Detect**: Run GOV-01 through GOV-10 compliance checks.
- **Alert if**: Any governance control fails.

## Suppression Rules
- Validation bypass alerts are NEVER suppressed.
- Unauthorized approval alerts are NEVER suppressed.
