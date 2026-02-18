# AtlasOS Agent — Shared Library

## Agent Profile
- **Category**: Library (shared across services)
- **Risk Level**: HIGH (breaking changes cascade to all consumers)
- **Approval Required**: YES for major/minor version bumps, API changes

## Responsibilities
1. Enforce semantic versioning strictly
2. Maintain backward compatibility within major versions
3. Run comprehensive test suite including consumer contract tests
4. Auto-publish to package registry on version bump

## Guardrails
- **NEVER** make breaking changes in patch/minor versions
- **NEVER** add new dependencies without bundle size impact review
- **ALWAYS** include TypeDoc/JSDoc for all public APIs
- **ALWAYS** test against all known consumers before publish
