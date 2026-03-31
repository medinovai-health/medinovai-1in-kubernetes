# Access Provisioning Pipeline

An approval-gated workflow for granting, modifying, or revoking system access.

## Pipeline Steps

```
[1] Parse Request → [2] Validate Policy → [3] Preview Changes → [4] APPROVAL GATE
    → [5] Execute Changes → [6] Verify → [7] Audit Log → [8] Notify
```

## Step 1: Parse Request
- **Tool**: `llm-task`
- **Action**: Extract structured request from Slack message or webhook
- **Input**: Free-text request (e.g., "Give Alice admin access to the staging DB")
- **Output**:
  ```json
  {
    "requester": "bob",
    "target_user": "alice",
    "action": "grant|modify|revoke",
    "system": "staging_db",
    "role": "admin",
    "justification": "Needs access for Q1 migration project",
    "duration": "permanent|temporary",
    "expiry": "ISO-8601 (if temporary)"
  }
  ```
- **On parse failure**: Ask requester for clarification

## Step 2: Validate Policy
- **Tool**: `exec` (sandbox)
- **Action**: Check request against access policy rules
- **Checks**:
  - Is the requester authorized to request this access?
  - Does the target user exist in the directory?
  - Is the role valid for this system?
  - Does this violate separation of duties?
  - Is there an existing access that conflicts?
- **Output**: `{"valid": true|false, "violations": [...], "warnings": [...]}`
- **On violation**: Stop pipeline, explain why, suggest alternative

## Step 3: Preview Changes
- **Tool**: Slack delivery
- **Action**: Post a preview of what will change
- **Format**:
  ```
  :key: Access Change Request
  Requester: @bob
  Target: @alice
  System: staging_db
  Change: Grant admin role
  Justification: Q1 migration project
  Duration: Permanent
  Policy check: PASSED
  ```

## Step 4: APPROVAL GATE
- **Type**: Human approval required
- **Approvers**: Based on system sensitivity:
  - Low (read-only access): Team lead
  - Medium (write access): Department head
  - High (admin, production DB, secrets): CTO/CISO
- **Timeout**: 48h
- **On reject**: Notify requester with reason
- **On timeout**: Notify requester, escalate to backup approver

## Step 5: Execute Changes
- **Tool**: `exec` (gateway — elevated access)
- **Action**: Run provisioning script
- **Command**: `echo '<request_json>' | python3 scripts/provision_access.py --json-in`
- **Output**: `{"provisioned": true, "details": {...}}`
- **On failure**: Retry once, then alert ops
- **Idempotent**: Running twice should not duplicate access

## Step 6: Verify
- **Tool**: `exec` (sandbox)
- **Action**: Confirm the access change took effect
- **Check**: Query the system to verify the user has the expected role
- **Output**: `{"verified": true|false}`
- **On failure**: Alert ops, do NOT rollback automatically (manual review needed)

## Step 7: Audit Log
- **Tool**: `exec` (sandbox)
- **Action**: Write a durable audit entry
- **Output file**: `outputs/access-audit/{date}_{request_id}.json`
- **Fields**: requester, approver, target, system, role, action, timestamp, verification_status

## Step 8: Notify
- **Tool**: Slack delivery
- **Notify**:
  - Target user: "You now have {role} access to {system}"
  - Requester: "Access granted for @{target}"
  - #access-log channel: Full audit entry

## Configuration

```json
{
  "pipeline": "access-provisioning",
  "version": "1.0",
  "timeout_total": "50h",
  "output_cap_bytes": 10000,
  "resume_enabled": true,
  "sensitivity_levels": {
    "low": ["read_only", "viewer"],
    "medium": ["editor", "writer", "developer"],
    "high": ["admin", "owner", "superuser", "production_db"]
  },
  "notifications": {
    "on_complete": ["#access-log", "requester_dm", "target_dm"],
    "on_failure": ["#ops", "requester_dm"]
  }
}
```
