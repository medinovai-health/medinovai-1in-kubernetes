# TOOLS

## Standard Toolchain

- `gh`: GitHub operations, repository discovery, PR creation, and release metadata
- `docker compose`: local multi-service orchestration for repos with `compose_role != none`
- `python3`: automation scripts, validation helpers, and manifest generation
- `jq` / JSON tooling: registry inspection and workflow payload generation
- `kustomize` / `kubectl`: Kubernetes overlay rendering and environment validation

## Required Habits

- Read the repo manifest before changing deployment behavior.
- Render configs before applying them: `docker compose config` and `kustomize build`.
- Validate secrets stay out of `.env.example` and committed files.
- Keep health endpoints, ports, and service names consistent across compose, manifests, and workflows.
- Prefer reusable workflows from `medinovai-Deploy` instead of cloning CI logic.

## Delivery Checklist

- Charter files are present and non-empty.
- `medinovai.manifest.yaml` exists and matches repo category and tier.
- `.env.example` only contains placeholders.
- Deployable repos expose `GET /health`.
- CI references shared workflows where available.
