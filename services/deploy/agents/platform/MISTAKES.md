# Platform Operations Agent — Mistake Notebook

## Known Pitfalls

### Infrastructure

1. **Terraform state lock contention**: If a previous `terraform apply` was interrupted, the state may be locked. Check DynamoDB lock table before retrying. Never force-unlock without understanding why it's locked.

2. **EKS node group updates are replacement operations**: Changing instance types in an EKS managed node group triggers a rolling replacement of ALL nodes. Always plan and review before applying.

3. **Security group rule ordering**: AWS security groups have a limit of 60 rules per group. Plan rule consolidation before hitting the limit.

4. **RDS storage cannot shrink**: You can increase RDS storage but never decrease it. Plan initial sizing carefully.

5. **NAT Gateway costs**: NAT Gateways charge per GB of data processed. Monitor costs and consider VPC endpoints for high-traffic AWS services.

### Deployments

6. **Never deploy on Friday afternoon**: Change failure rate spikes. Recovery is slower with reduced staffing.

7. **Database migrations must be backward-compatible**: The old application version must work with the new schema during rolling deployments. Always use additive-only migrations.

8. **HPA and cluster autoscaler race condition**: If HPA tries to scale pods before cluster autoscaler adds nodes, pods will be pending. Configure appropriate scale-down delays.

9. **Canary duration matters**: 10 minutes catches most issues, but some (memory leaks, connection pool exhaustion) take longer. For critical services, extend canary to 30 minutes.

### Monitoring

10. **Alert fatigue kills response quality**: Every alert must be actionable. If an alert fires and the response is "ignore it", the alert should be removed or the threshold adjusted.

11. **Prometheus cardinality explosion**: Labels with unbounded values (user IDs, request IDs) will blow up Prometheus memory. Always bound your label cardinality.

12. **Log volume in production**: Verbose logging in production is expensive and noisy. Default to WARN level; use INFO for specific subsystems as needed.

## Post-Incident Learnings

(This section is updated after each incident review)

<!-- Template:
### INC-YYYY-NNN: Brief description
- **Date**: YYYY-MM-DD
- **Impact**: What happened
- **Root cause**: Why it happened
- **Fix**: What we did
- **Prevention**: What we changed to prevent recurrence
-->
