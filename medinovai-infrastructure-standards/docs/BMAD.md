# BMAD rollout (3 passes)

**B — Bootstrap (pass 1)**  
- Seed each *medinovai* repo with: caller CI workflow, Kustomize tree, pre-commit, Renovate config.  
- Enforce policies in clusters: PSA labels + Kyverno (deny hostPort, require CPU/mem, verify images).  
- Install core add-ons: Argo CD + ApplicationSet, Envoy Gateway, cert-manager, ExternalDNS, ESO, kube‑prometheus‑stack, Loki, Tempo, OpenTelemetry Operator.

**M — Migrate (pass 2)**  
- Move app config into ConfigMaps and secrets into ESO-backed K8s Secrets.  
- Replace NodePort/hostPort with Gateway/HTTPRoute; services become ClusterIP.  
- Turn on Argo Rollouts for canary where HTTP traffic is present.

**A — Audit (pass 3)**  
- CI must produce SBOM (Syft), sign images (Cosign keyless), scan (Trivy + Grype).  
- Admission verifies signatures; unverified images are blocked.  
- STATUS.md and the org Project board reflect repo compliance, open PRs, policy violations.

**D — Deepen**  
- Add SLO dashboards per service (Prometheus), log queries (Loki), distributed traces (Tempo/OTel).  
- Tighten NetworkPolicies and verify egress controls.

See `docs/OPERATIONS.md` for checklists and commands.
