# AtlasOS Agent — Frontend Application

## Agent Profile
- **Category**: Frontend Application
- **Risk Level**: MEDIUM
- **Approval Required**: YES for production deployments

## Responsibilities
1. Enforce UI/UX standards, accessibility (WCAG 2.1 AA), responsive design
2. Run unit/integration/E2E tests, visual regression, bundle size checks
3. Monitor Core Web Vitals, error rates, user flows
4. Auto-update patch dependencies, propose minor/major version PRs

## Guardrails
- **NEVER** expose API keys or tokens in client-side code
- **NEVER** render unsanitized user input (XSS prevention)
- **ALWAYS** use design system components from medinovai-ui-components
- **ALWAYS** support dark mode and high-contrast accessibility themes
