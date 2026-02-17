# Skill: Health Audit

## Purpose

Perform a comprehensive health audit across all layers of the MedinovAI platform.

## Trigger

- Cron: Daily at 04:00 UTC
- Manual request: "Run health audit"
- Post-deploy: After any production deployment
- Incident: As part of incident investigation

## Inputs

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| scope | string | No | Layer to check: all, infra, services, databases, monitoring (default: all) |
| environment | string | No | Target environment (default: production) |

## Steps

1. **Infrastructure**: Check cluster nodes, node pressure, disk utilization
2. **Services**: Verify all service health and readiness endpoints
3. **Databases**: Check RDS/Redis health, replication lag, connection pool
4. **Monitoring**: Verify Prometheus, Grafana, Alertmanager, Loki are operational
5. **Certificates**: Check SSL certificate expiry across all domains
6. **Backups**: Verify latest backup exists and is within retention policy
7. **Security**: Check for new CVEs in deployed images
8. **Cost**: Flag any cost anomalies in the last 24 hours
9. **Compliance**: Verify GOV controls are satisfied

## Outputs

```json
{
  "status": "healthy|degraded|unhealthy",
  "timestamp": "ISO-8601",
  "checks": {
    "infrastructure": {"status": "ok", "details": {...}},
    "services": {"status": "ok", "details": {...}},
    "databases": {"status": "ok", "details": {...}},
    "monitoring": {"status": "ok", "details": {...}},
    "certificates": {"status": "ok", "details": {...}},
    "backups": {"status": "ok", "details": {...}},
    "security": {"status": "warn", "details": {...}},
    "cost": {"status": "ok", "details": {...}},
    "compliance": {"status": "ok", "details": {...}}
  },
  "passed": 8,
  "failed": 0,
  "warnings": 1
}
```

## Alert Escalation

| Finding | Severity | Action |
|---------|----------|--------|
| Service down | P1 | Page on-call immediately |
| Database unhealthy | P1 | Page on-call + DBA |
| Certificate expires < 7 days | P2 | Alert #eng, auto-renew |
| Backup missing or stale | P2 | Alert #eng, run manual backup |
| Critical CVE in deployed image | P2 | Alert #eng + security |
| Cost anomaly > 30% | P3 | Alert #eng + finance |
| IaC drift detected | P3 | Alert #eng |
| Non-critical CVE | P4 | Log for next maintenance window |
