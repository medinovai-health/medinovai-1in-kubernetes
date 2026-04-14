# Contributing to medinovai-1in-kubernetes

> (c) 2025 MedinovAI — Empowering human will for cure.

## Code of Conduct

All contributors must follow the MedinovAI Code of Conduct.

## Development Setup

1. Fork and clone the repository
2. Install dependencies
3. Create a feature branch
4. Make your changes with tests
5. Submit a pull request

## Coding Standards

- Follow MedinovAI coding conventions (see `ai-standards` repo)
- `E_` prefix for constants, `mos_` prefix for variables
- Max 40 lines per method
- Google-style docstrings
- No hardcoded secrets
- 80%+ test coverage required

## PR Guidelines

- One feature per PR
- Include tests for all new code
- Update documentation
- Reference issue number in PR title
- Ensure CI passes before requesting review

## Compliance Requirements

For Tier 1 (Clinical/PHI) repos:
- HIPAA compliance review required
- PHI must never appear in logs
- Audit trail entry required
- Security review for all data mutations

## Review Process

1. Automated CI checks
2. Code review by 2+ team members
3. Security review (Tier 1/2 repos)
4. Compliance review (Tier 1 repos)
5. Merge on approval
