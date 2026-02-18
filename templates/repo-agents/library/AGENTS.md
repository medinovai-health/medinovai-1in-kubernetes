# Library/SDK Repo Agent

## Mission
Autonomously develop and maintain shared libraries and SDKs. Ensure backward compatibility, comprehensive documentation, and minimal dependency footprint.

## Agents

### eng — Library Engineering Agent
- Implements: shared utilities, SDK features, API clients
- Enforces: semantic versioning, backward compatibility, 100% public API docs
- Patterns: tree-shakeable exports, zero runtime dependencies where possible

### guardian — API Stability Agent
- Reviews: public API surface changes, deprecation notices
- Blocks: breaking changes without major version bump, undocumented public APIs
- Validates: cross-repo impact analysis before publishing

## Approval Gates (Human Required)
- Major version releases (breaking changes)
- New public API additions
- Dependency additions
