# medinovai-infrastructure (standards repo)

**Owner:** myonsite-healthcare • **Scope:** Org-wide infra + deployment standards for all *medinovai* repos.

## What this repo provides
- Reusable GitHub Actions workflows (CI, security, release).
- Kustomize skeletons for apps (`deploy/`).
- Policy pack (Kyverno + PSA labels).
- Cluster add-ons via Argo CD ApplicationSet.
- Gateway API defaults (Envoy Gateway), cert-manager, ExternalDNS.
- Bulk-update + audit scripts for 120 repos named `*medinovai*`.
- BMAD method (3 passes) for safe rollout.

Jump to:
- [`/templates/medinovai-app`](templates/medinovai-app/) – files injected into app repos.
- [`/policies/kyverno`](policies/kyverno/) – cluster safeguards.
- [`/platform/addons`](platform/addons/) – Argo CD ApplicationSets for add-ons.
- [`/scripts`](scripts/) – bulk PRs, auditing, status reports.
- [`/docs/BMAD.md`](docs/BMAD.md) – the 3-pass rollout.
- [`/STATUS.md`](STATUS.md) – auto-updated rollout status.

## Quick start (operators)
1. **Bootstrap Argo CD** in each cluster and point it to the `clusters/` tree (see `docs/OPERATIONS.md`).
2. **Install add-ons** via the Argo CD ApplicationSet in `platform/addons/`.
3. **Run the bulk sync** from your laptop (or a runner): `./scripts/bulk_sync.sh --org myonsite-healthcare --match medinovai --dry-run`.
4. Review the PRs, merge by wave (dev → stage → prod).
5. Track progress in `STATUS.md` (updated by CI).

## Quick start (app teams)
- Merge the “Adopt org standards” PR.
- Use `deploy/overlays/{dev,stage,prod}` to roll out your service via GitOps.
- CI builds, signs, scans, and publishes images; Rollouts handle canary/blue‑green.
