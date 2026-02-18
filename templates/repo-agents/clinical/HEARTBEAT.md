# Clinical Heartbeat Protocol

## Schedule: Every 30 minutes

## Checks
1. **Test Suite**: Run unit tests, ensure 100% pass rate
2. **Dependency Audit**: Check for CVEs in clinical dependencies (daily)
3. **PHI Scan**: Grep for patterns matching SSN, MRN, DOB in non-encrypted fields
4. **Audit Trail**: Verify audit logging is active and writing
5. **Schema Drift**: Compare DB schema to migration history
6. **API Contract**: Validate OpenAPI spec matches implementation
7. **Compliance Score**: Run regulatory compliance checks (21 CFR Part 11 checklist)
8. **FHIR Validation**: Validate FHIR resource schemas (where applicable)

## Escalation
- PHI exposure detected → IMMEDIATE: Notify guardian + security team
- Test failures → within 1 hour: eng agent auto-fixes or creates issue
- Compliance drift → within 4 hours: guardian opens corrective action
