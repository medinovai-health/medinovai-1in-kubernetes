# Contributing

- Link requirement IDs in PR titles (e.g., `REQ-123: Add API endpoint`).
- Keep blocks ≤ 40 lines; follow variable prefixes (`mos_`, `e_`).
- Tests required; coverage ≥ 80% (unless exempted with approval).
- All data access via DTO/DAL; never inline SQL without DAL.
- Commit message format: `REQ-<id> scope: summary`.
