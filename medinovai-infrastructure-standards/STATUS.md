# Rollout status

This file is updated by CI. To update manually:
```bash
./scripts/audit_status.sh --org myonsite-healthcare --match medinovai > .artifacts/report.csv
./scripts/render_status.py .artifacts/report.csv > STATUS.md
```
