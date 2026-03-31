# Skill: Release Manager

## Purpose

Manage semantic versioning, changelog generation, and release creation for MedinovAI services.

## Trigger

- Manual: "Create release for {service}"
- Cron: Weekly release candidate check
- PR merge: Auto-tag if configured

## Inputs

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| service | string | Yes | Service to release |
| bump_type | string | No | major, minor, patch (auto-detect from commits if omitted) |
| dry_run | boolean | No | Preview release without creating (default: false) |

## Steps

1. **Analyze commits**: Scan commits since last release for conventional commit types
2. **Determine version**: Calculate next version based on commit types
3. **Generate changelog**: Create human-readable changelog from commits
4. **Validate**: Ensure all tests pass on the release branch
5. **Create release**: Tag, create GitHub release, attach changelog
6. **Trigger deploy**: Kick off deploy-staging pipeline

## Outputs

```json
{
  "status": "ok",
  "service": "api-gateway",
  "previous_version": "v1.2.2",
  "new_version": "v1.3.0",
  "bump_type": "minor",
  "changelog": "...",
  "release_url": "https://github.com/..."
}
```

## Version Bump Rules

| Commit Prefix | Bump | Example |
|--------------|------|---------|
| `feat:` | minor | New feature |
| `fix:` | patch | Bug fix |
| `BREAKING CHANGE:` | major | Breaking API change |
| `perf:` | patch | Performance improvement |
| `refactor:` | patch | Code refactoring |
| `docs:` | none | Documentation only |
| `chore:` | none | Maintenance |
