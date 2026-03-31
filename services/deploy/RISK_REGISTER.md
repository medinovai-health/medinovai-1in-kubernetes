# Risk Register — medinovai-Deploy (ISO 14971 inspired)

| Risk ID | Hazard | Cause | Situation | Harm | Severity | Probability | Detectability | RPN | Mitigation | Verification | Status |
|---|---|---|---|---|---:|---:|---:|---:|---|---|---|
| RISK-medinovai-De-SEC-001 | Secret exfiltration | Agent prints env vars | Unredacted logs | Credential compromise | 2 | 2 | 3 | 12 | Redaction + blocklist | Secret leak tests | Open |
| RISK-medinovai-De-COMP-001 | Missing traceability | Skipped trace update | PR merged without evidence | Audit failure | 4 | 3 | 2 | 24 | Evidence gate in CI | Compliance tests | Open |
| RISK-medinovai-De-PHI-001 | PHI in logs | Unredacted patient data | Log aggregation | Privacy breach | 5 | 2 | 2 | 20 | PHI redaction at source | Log audit scan | Open |

## Risk Workflow
1. Identify risk when adding requirements or changing autonomy policy.
2. Assign mitigation owner.
3. Add verification tests/evidence.
4. Review at release and quarterly.
