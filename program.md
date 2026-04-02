# AutoResearch — medinovai-infrastructure

MedinovAI adaptation of Karpathy autoresearch for the **infrastructure** domain.
Runs as embedded process inside MIL, scheduled via GPU-aware round-robin.

## Domain
**Monorepo:** medinovai-infrastructure
**Domain:** infrastructure
**Primary metric:** task_score (0.0-1.0, higher is better)
**Time budget:** 10 minutes per experiment
**Infrastructure:** Spark Ollama cluster via Tailscale (primary: 100.125.48.57, secondary: 100.94.48.43)

## Benchmark Tasks
Fixed 8-task infrastructure benchmark:
- k8s_deployment: write deployment manifest with health probes
- terraform_module: design Terraform module for VPC
- docker_health: configure Docker healthcheck
- canary_rollout: describe canary deployment strategy
- monitoring_setup: configure Prometheus + Grafana for service
- ci_cd_pipeline: design GitHub Actions workflow with path filters
- disaster_recovery: describe DR plan with RPO/RTO
- capacity_planning: estimate resource needs for 100 pods

## Recommended Models
- qwen2.5-coder:32b (strong at IaC)
- qwen2.5:7b (fast, good for simple infra)
- codestral:22b (code-focused)
- qwen3-coder:30b (alternative)

## Experiment Loop
Managed by MIL AutoResearch scheduler at http://100.106.54.9:9876/autoresearch/scheduler.
This domain runs when GPU is free (P1 priority) in round-robin with other domains.

1. Scheduler selects this domain -> picks mutation from schedule
2. Mutation applied to domain config (model, system prompt, temperature, etc.)
3. Benchmark runs all domain tasks against Spark Ollama
4. If task_score improves -> keep config, advance
5. If equal or worse -> revert to best config
6. Results broadcast via WebSocket: autoresearch:infrastructure:{event}
7. 10s cooldown, then scheduler moves to next domain

## Research Goals
- Maximise task_score across all infrastructure tasks
- Optimise for latency (clinical domains: faster = safer)
- Find the best model+prompt combination for this domain
- Winning configs propagate to MIL production via /config/update
