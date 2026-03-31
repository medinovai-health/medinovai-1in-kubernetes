# medinovai-infrastructure Workspace Guide

**Monorepo:** medinovai-infrastructure
**Domain:** infrastructure
**Created:** 2026-03-30

## Adding a Service via Subtree

```bash
# 1. Add the legacy repo as a remote
git remote add legacy-<service> git@github.com:medinovai-health/<service>.git
git fetch legacy-<service>

# 2. Import with history preserved
git subtree add --prefix=services/<service> legacy-<service>/main

# 3. Create service manifest
cp docs/templates/service.yaml.template services/<service>/service.yaml
# Edit the service.yaml with correct metadata

# 4. Add path-filtered CI workflow
cp .github/workflows/templates/python-service.yml .github/workflows/services-<service>.yml
# Edit trigger paths

# 5. Test
cd services/<service> && pytest (or npm test)

# 6. Commit and PR
git add . && git commit -m "Migrated <service> via subtree"
gh pr create --title "Migrate <service> to monorepo"
```

## Shared Libraries

Place shared code in `libs/<name>/`. Services reference via relative path
or internal package index. No circular dependencies between services.

## Pulling Updates from Legacy (During Transition)

```bash
git fetch legacy-<service>
git subtree pull --prefix=services/<service> legacy-<service> main
```

## Splitting History Back Out (Emergency Only)

```bash
git subtree split --prefix=services/<service> -b split-<service>
```
