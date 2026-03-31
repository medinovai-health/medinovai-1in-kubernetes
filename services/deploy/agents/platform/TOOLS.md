# Platform Operations Agent — Tool Access

## Allowed Tools

| Tool | Access Level | Purpose |
|------|-------------|---------|
| `exec` (sandbox) | Full | Run Terraform plan, kubectl get, health checks, validation scripts |
| `exec` (gateway) | Elevated — approval required for destructive ops | Terraform apply, kubectl apply, secret rotation |
| `web_fetch` | Full | Health endpoint checks, cloud status pages, cost APIs |
| `approval_pipeline` | Full | Trigger deploy, infra-change, and DR workflows |

## Terraform Access

| Operation | Allowed | Notes |
|-----------|---------|-------|
| `terraform init` | Yes | Always safe |
| `terraform plan` | Yes | Read-only |
| `terraform validate` | Yes | Read-only |
| `terraform apply` (non-destructive) | With approval | Changes/additions only |
| `terraform apply` (destructive) | With CTO approval | Any operation that destroys resources |
| `terraform destroy` | NEVER autonomously | Requires explicit human command |

## Kubernetes Access

| Operation | Allowed | Notes |
|-----------|---------|-------|
| `kubectl get/describe/logs` | Yes | Read-only |
| `kubectl apply` (non-production) | Yes | Dev/staging |
| `kubectl apply` (production) | With approval | Via deploy pipeline |
| `kubectl delete` (non-production) | Yes | Dev/staging cleanup |
| `kubectl delete` (production) | With CTO approval | Emergency only |
| `kubectl exec` | Limited | Debugging only, never in production |

## Cloud CLI Access

| Operation | Allowed | Notes |
|-----------|---------|-------|
| Describe/list/get operations | Yes | Read-only |
| Create/update operations | With approval | Via Terraform or approved scripts |
| Delete operations | With CTO approval | Emergency only |
| IAM modifications | With Security lead approval | Never autonomous |

## Monitoring Access

| Tool | Access |
|------|--------|
| Prometheus queries | Full read |
| Grafana dashboards | Full read, create dashboards |
| Alertmanager | Read, silence alerts (with justification) |
| CloudWatch | Full read |
| PagerDuty | Read, acknowledge (never resolve without verification) |
