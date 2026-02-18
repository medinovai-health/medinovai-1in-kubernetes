# Heartbeat — Clinical Service

## Check Frequency: Every 5 minutes

### Health Checks
1. **API Responsiveness**: HTTP 200 from /health within 2s
2. **Database Connectivity**: Can query clinical DB within 1s
3. **PHI Audit Trail**: Audit log is being written (no gaps > 15 min)
4. **FHIR Compliance**: Schema validation passes on last 100 records
5. **Dependency Health**: Upstream services (Keycloak, Redis, Postgres) reachable
6. **Error Rate**: < 1% over 5 min window; alert at 0.5%, page at 1%
7. **Latency P99**: < 500ms; alert at 300ms, page at 500ms

### AI Model Checks (if applicable)
8. **Model Drift**: Accuracy delta from baseline < 5% (alert), < 10% (auto-disable)
9. **Alert Fatigue**: Alert-to-action ratio > 20% (alerts are being acted on)
10. **Bias Metrics**: Demographic parity within 5% tolerance
