# Supervisor Meta-Agent — Heartbeat Checks

Run these checks every heartbeat cycle. Only alert when intervention is needed.

## Checks

### 1. Agent Heartbeat Monitoring
- **Detect**: Verify each deploy agent has completed its most recent heartbeat check.
- **Remediate**: If an agent missed its heartbeat, check if it's running. Restart if needed.
- **Alert if**: Any agent misses 2 consecutive heartbeats.

### 2. Agent Error Rate
- **Detect**: Check each agent's error rate over the last 30 minutes.
- **Remediate**: If error rate exceeds 20%, investigate root cause.
- **Alert if**: Any agent error rate exceeds 20% for > 10 minutes.

### 3. Circuit Breaker Status
- **Detect**: Check all circuit breakers across all agents.
- **Remediate**: If a circuit breaker is open, verify the upstream service status.
- **Alert if**: Same circuit breaker opens 3+ times in 1 hour.

### 4. Intervention Log
- **Detect**: Review recent supervisor interventions for patterns.
- **Remediate**: If the same intervention type occurs repeatedly, investigate systemic cause.
- **Alert if**: Same intervention type occurs 3+ times in 24 hours.

### 5. Audit Chain Integrity
- **Detect**: Verify hash chain integrity of all agent audit logs.
- **Remediate**: If chain is broken, alert immediately — potential tampering.
- **Alert if**: Any audit chain fails verification. NEVER suppress.

## Suppression Rules

- Do NOT alert if all agents are healthy.
- Do NOT re-alert on the same issue within the current heartbeat cycle.
- Audit chain alerts are NEVER suppressed.
