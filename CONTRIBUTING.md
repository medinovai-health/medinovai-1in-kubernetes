# Contributing to medinovai-deploy

**Standard:** `medinovai-ai-standards/REPO_BOOTSTRAP.md` | MedinovAI Platform v3.0.0

Thank you for contributing! Please follow these guidelines to maintain code quality,
regulatory compliance, and platform consistency.

---

## Getting Started

```bash
git clone https://github.com/medinovai-health/medinovai-deploy.git
cd medinovai-deploy
# Follow setup in README.md
```

## Branch Naming

| Type       | Pattern                   | Example                      |
|------------|---------------------------|------------------------------|
| Feature    | `feature/TICKET-description` | `feature/MED-123-add-hl7-parser` |
| Bug fix    | `fix/TICKET-description`  | `fix/MED-456-null-patient-id`  |
| Hotfix     | `hotfix/TICKET-description` | `hotfix/MED-789-auth-bypass` |
| Release    | `release/vX.Y.Z`          | `release/v2.1.0`             |
| Chore      | `chore/description`       | `chore/update-dependencies`   |

**Never push directly to `main`.** All changes via PRs.

## Commit Message Convention

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`, `ci`

Examples:
```
feat(patient): add HL7 FHIR R4 patient resource endpoint
fix(auth): handle expired JWT tokens gracefully
docs(api): update OpenAPI spec with pagination params
test(clinical): add integration tests for decision engine
```

## Pull Request Process

1. **Create PR** using `.github/PULL_REQUEST_TEMPLATE.md` checklist
2. **All CI checks must pass** before requesting review
3. **Minimum reviewers:** 1 for Tier 3, 2 for Tier 2, 2 + Clinical Safety for Tier 1
4. **Code coverage** must meet tier minimum (see `tests/README.md`)
5. **Security scan** must pass (no new HIGH/CRITICAL vulnerabilities)
6. **Squash merge** to `main` after approval


## Code Standards

All code must follow `medinovai-ai-standards/CODING_STANDARDS.md`:
- Variables: `mos_` prefix (lowerCamelCase)
- Constants: `E_` prefix (UPPER_CASE)
- Methods: ≤ 40 lines
- Line length: 120 characters max
- Language: Python 3.10+ / C# 10+ / TypeScript 5+

## PHI/PII Handling

**NEVER commit:**
- Patient data (even anonymized/fake)
- Real user credentials
- `.env` files with actual secrets
- API keys, certificates, or tokens

Use the pre-commit hook in `scripts/hooks/` to prevent accidental commits.

## Testing Requirements

- Write tests BEFORE or WITH implementation (TDD preferred)
- Unit tests in `tests/unit/`
- Integration tests in `tests/integration/`
- Run tests locally before pushing: see `tests/README.md`

## Documentation

Update relevant docs with every feature PR:
- `README.md` if setup/usage changes
- `CHANGELOG.md` under `[Unreleased]`
- `schemas/openapi.yaml` for API changes
- `docs/RISK_REGISTER.md` for new risk items (Tier 1)

## Questions?

- Engineering questions: `#engineering` on Slack
- Standards questions: `#platform-standards` on Slack
- Security concerns: `security@medinovai.com`
