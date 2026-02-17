# Data Quality Agent -- Heartbeat Checks

Run these checks proactively. Only alert when something needs attention. Silence means healthy.

## Checks

### 1. Schema Validation
- **Detect**: Verify all data tables/collections have schema definitions. Check for schema drift between code and actual database state.
- **Remediate**: Update schema definitions. Add migration for drift. Add validation at ingestion points.
- **Verify**: Validate actual schema matches defined schema.
- **Alert if**: Schema drift detected or tables lack schema definitions.

### 2. PII/PHI Detection
- **Detect**: Scan data stores, logs, and temporary files for unprotected PII/PHI patterns (SSN, MRN, DOB, names, emails, phone numbers).
- **Remediate**: Apply encryption, tokenization, or redaction. Update pipeline to handle at ingestion.
- **Verify**: Re-scan after remediation.
- **Alert if**: Any unprotected PII/PHI detected. NEVER suppress.

### 3. Pipeline Health
- **Detect**: Check ETL/ELT job status, duration, and record counts. Compare against historical baselines. Identify failed or hung jobs.
- **Remediate**: Restart failed jobs from checkpoint. Investigate hung jobs. Fix root cause.
- **Verify**: Confirm pipeline completes successfully and output data is valid.
- **Alert if**: Pipeline failure, significant duration increase (>2x baseline), or record count anomaly (>20% deviation).

### 4. Data Freshness
- **Detect**: Check last update timestamps for critical datasets. Compare against freshness SLAs.
- **Remediate**: Trigger pipeline re-run for stale data. Investigate source for missing updates.
- **Verify**: Confirm data is refreshed within SLA.
- **Alert if**: Any critical dataset exceeds its freshness SLA.

### 5. Referential Integrity
- **Detect**: Check for orphaned records, broken foreign key references, and dangling pointers across related tables.
- **Remediate**: Identify the broken relationships. Draft cleanup or backfill scripts.
- **Verify**: Re-check integrity after fix.
- **Alert if**: Referential integrity violations found in production data.

### 6. Query Performance
- **Detect**: Identify slow queries, missing indexes, and full table scans on large datasets.
- **Remediate**: Add indexes. Optimize query patterns. Add pagination for large result sets.
- **Verify**: Compare query performance before and after.
- **Alert if**: Queries exceed 5s on production-sized datasets.

### 7. Dead Letter Queue
- **Detect**: Check DLQ for accumulated rejected records. Analyze rejection reasons.
- **Remediate**: Group by error type. Fix root cause for the largest group. Reprocess after fix.
- **Verify**: DLQ depth decreases after remediation.
- **Alert if**: DLQ depth exceeds threshold or items older than 24 hours.

### 8. Backup and Recovery
- **Detect**: Verify backup configurations exist for all data stores. Check backup freshness and integrity.
- **Remediate**: Add missing backup configuration. Fix failed backups.
- **Verify**: Test restore from latest backup.
- **Alert if**: Critical data store lacks backup or latest backup is older than retention policy.

## Suppression Rules

- Do NOT alert if all checks pass.
- Do NOT re-alert on the same issue within the current session.
- PII/PHI exposure alerts are NEVER suppressed.
