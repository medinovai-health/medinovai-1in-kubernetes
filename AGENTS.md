# medinovai-Deploy — AtlasOS Agent Operating Rules

**Module:** medinovai-Deploy
**Category:** ai-ml
**Managed by:** AtlasOS Autonomous Operations

## Identity

This repository is managed by AtlasOS agents. All operations are observable,
auditable, and subject to approval gates for critical actions.

## Agent Configuration

Agent definitions: `config/atlasos/agents/`
Event triggers: `config/atlasos/events/`
Squad membership: `config/atlasos/squads/`

## OODA Protocol

All agents follow Observe-Orient-Decide-Act:
1. **Observe**: Capture error type, context, and blast radius
2. **Orient**: Classify as transient, structural, or logic
3. **Decide**: Retry (transient), escalate (structural), fix (logic)
4. **Act**: Execute with full audit logging

## Approval Gates

Critical actions require human approval. See `config/atlasos/agents/` for tier assignments.
