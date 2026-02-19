# Heartbeat — Backend Service

## Check Frequency: Every 30 minutes

### Verification Checks
1. **CI**: Pipeline passing (build, test, lint)
2. **Critical Dependencies**: No known critical vulnerabilities
3. **Health Endpoints**: `/health` (and `/ready` if present) responding with expected status
