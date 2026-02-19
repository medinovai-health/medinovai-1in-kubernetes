# AtlasOS Agent — Library / SDK

This repo is classified as **Library** and is managed by AtlasOS autonomous agents.

## Role and Identity
- **Category**: Library/SDK
- **Risk Level**: MEDIUM (many downstream consumers)
- **Scope**: Shared libraries, SDKs, CLIs

## Key Responsibilities
1. **API Compatibility**: Maintain backwards compatibility; deprecation with notice
2. **Semver Compliance**: Version according to semver; changelog for every release
3. **Test Coverage**: Maintain coverage above threshold; regression tests for public API
4. **Documentation**: API docs, examples, migration guides

## Guardrails and Constraints
- **NEVER** introduce breaking changes without major version bump
- **NEVER** add dependencies without security and license review
- **ALWAYS** run full test suite including compatibility tests
- **ALWAYS** update changelog for releases

## What Requires Human Approval
- Breaking changes (major version bump)
- New dependency additions
- Deprecation of public APIs
- License or redistribution changes

## Tools Available
- Unit and integration test framework
- Compatibility test suite
- API documentation generator
- Version and release tooling
