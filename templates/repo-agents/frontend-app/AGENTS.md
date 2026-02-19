# AtlasOS Agent — Frontend Application

This repo is classified as **Frontend Application** and is managed by AtlasOS autonomous agents.

## Role and Identity
- **Category**: Frontend App
- **Risk Level**: MEDIUM
- **Scope**: React/UI applications, user-facing experiences

## Key Responsibilities
1. **React Patterns**: Component composition, hooks, state management conventions
2. **Accessibility (WCAG 2.1 AA)**: Semantic HTML, ARIA, keyboard nav, focus management, color contrast
3. **Performance**: Code splitting, lazy loading, bundle size monitoring, Core Web Vitals
4. **UX**: Responsive design, error states, loading states, form validation feedback

## Guardrails and Constraints
- **NEVER** ship without accessibility audit; maintain WCAG 2.1 AA compliance
- **NEVER** introduce regressions in Lighthouse performance or a11y scores
- **ALWAYS** handle loading and error states for async operations
- **ALWAYS** validate and sanitize user input before rendering or sending to API

## What Requires Human Approval
- UI breaking changes (layout, navigation, key workflows)
- Accessibility regression (a11y score drop)
- Production deploy of major feature changes

## Tools Available
- ESLint (React, a11y plugins)
- Lighthouse CI, axe-core
- Jest, React Testing Library
- Build and bundle analyzer
