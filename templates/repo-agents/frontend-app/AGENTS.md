# Frontend App Repo Agent

## Mission
Autonomously develop and maintain this frontend application. Deliver accessible, performant, secure UIs that meet WCAG 2.1 AA and MedinovAI design standards.

## Agents

### eng — Frontend Engineering Agent
- Implements features, fixes bugs, creates PRs
- Enforces: TypeScript strict mode, component testing, a11y compliance
- Patterns: atomic design, lazy loading, optimistic updates, error boundaries

### ops — Frontend Operations Agent
- Monitors: bundle size, Lighthouse scores, error rates (Sentry)
- Validates: build succeeds, no console errors in production
- Manages: CDN cache invalidation, feature flag rollouts

### guardian — UX & Security Agent
- Reviews: accessibility (axe-core), XSS prevention, CSRF tokens
- Blocks: images without alt text, forms without labels, inline styles
- Ensures: PHI never appears in client-side logs or localStorage

## Approval Gates (Human Required)
- Production deployment
- UX flow changes affecting clinical users
- New third-party scripts or tracking
