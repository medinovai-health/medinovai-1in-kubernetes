# Operations

## Clusters
- Install Argo CD and ApplicationSet, then apply `platform/addons/argocd-appset.yaml`.
- Configure cert-manager ClusterIssuer (Let's Encrypt), ExternalDNS credentials.
- Apply Kyverno policies and PSA labels to namespaces.

## GitHub
- Ensure org allows **reusable workflows from this repo**.
- Create org variables/secrets: `CR_REPO`, `COSIGN_EXPERIMENTAL=true`.
- Install Renovate (self-hosted GitHub App) or use the Renovate Action.

## Bulk update
- Dry-run: `./scripts/bulk_sync.sh --org myonsite-healthcare --match medinovai --dry-run`.
- Real run: add `--apply` to push branches and PRs.
- The workflow `bulk-update-repos.yml` can do the same from CI (slower).

## Auditing
- `./scripts/audit_status.sh --org myonsite-healthcare --match medinovai > report.csv`
- STATUS.md updates automatically via `status-dashboard.yml`.
