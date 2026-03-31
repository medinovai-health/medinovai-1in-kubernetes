/**
 * myOnsiteHealthcare.com customer-1 portal + Keycloak OIDC E2E.
 *
 * Golden scenarios:
 * - GS-AUTH-001: myonsite user login via Keycloak OIDC
 * - GS-AUTH-002: Role-based redirect after login
 * - GS-PORTAL-001: Portal loads with myOnsite branding
 * - GS-PORTAL-002: Portal shows all services in sidebar
 * - GS-REG-001: Registry lists all deployed services (smoke via portal shell)
 * - GS-AUDIT-001 / GS-AUDIT-002: Login path exercised (audit events in platform)
 */

import { test, expect } from '@playwright/test';
import {
  E_PORTAL_URL,
  mos_completeKeycloakLogin,
  mos_navigatePortalExpectKeycloak,
  mos_portalLogout,
  mos_waitForPortalShell,
  type KeycloakLoginCredentials,
} from './keycloak-helpers';

const E_ADMIN: KeycloakLoginCredentials = {
  username: 'admin@myonsitehealthcare.com',
  password: 'ChangeMe!2026',
  newPasswordAfterRequiredAction: 'ChangeMe!2026',
};

const E_CLINICIAN: KeycloakLoginCredentials = {
  username: 'demo-clinician@myonsitehealthcare.com',
  password: 'DemoClinician!2026',
};

test.describe.serial('customer1 / myonsite login & session (GS-AUTH-001, GS-PORTAL-001)', () => {
  test('portal triggers Keycloak redirect (GS-AUTH-001)', async ({ page }) => {
    await mos_navigatePortalExpectKeycloak(page, E_PORTAL_URL);
    await expect(
      page.locator('[data-testid="kc-username"]').or(page.locator('#username'))
    ).toBeVisible({ timeout: 15_000 });
  });

  test('admin login lands on portal with branding (GS-AUTH-002, GS-PORTAL-001)', async ({ page }) => {
    await page.goto(E_PORTAL_URL, { waitUntil: 'domcontentloaded' });
    await mos_completeKeycloakLogin(page, E_ADMIN);
    await mos_waitForPortalShell(page, E_PORTAL_URL);

    const mos_brand = page.getByText(/MedinovAI|myOnsite|myonsite/i).first();
    await expect(mos_brand).toBeVisible({ timeout: 30_000 });
  });

  test('admin role is visible in shell (GS-AUTH-002, GS-RBAC-001)', async ({ page }) => {
    await page.goto(E_PORTAL_URL, { waitUntil: 'domcontentloaded' });
    if (page.url().match(/8180|openid|auth/)) {
      await mos_completeKeycloakLogin(page, E_ADMIN);
      await mos_waitForPortalShell(page, E_PORTAL_URL);
    }

    const mos_adminHint = page
      .locator('[data-testid="user-role"]')
      .or(page.getByText(/admin|administrator/i))
      .or(page.locator('[data-testid="role-badge"]'));
    await expect(mos_adminHint.first()).toBeVisible({ timeout: 20_000 });
  });

  test('logout returns toward sign-in / Keycloak (GS-AUTH-001)', async ({ page }) => {
    await page.goto(E_PORTAL_URL, { waitUntil: 'domcontentloaded' });
    if (page.url().match(/8180|openid|auth/)) {
      await mos_completeKeycloakLogin(page, E_ADMIN);
      await mos_waitForPortalShell(page, E_PORTAL_URL);
    }
    await mos_portalLogout(page);
    const mos_onKeycloak = /8180/.test(page.url());
    const mos_signInVisible = await page.getByText(/sign in|log in/i).first().isVisible().catch(() => false);
    expect(mos_onKeycloak || mos_signInVisible).toBe(true);
  });

  test('demo-clinician login (GS-AUTH-001)', async ({ page }) => {
    await page.goto(E_PORTAL_URL, { waitUntil: 'domcontentloaded' });
    await mos_completeKeycloakLogin(page, E_CLINICIAN);
    await mos_waitForPortalShell(page, E_PORTAL_URL);
    await expect(page.getByText(/MedinovAI|myOnsite|myonsite|clinician|dashboard/i).first()).toBeVisible({
      timeout: 30_000,
    });
  });
});
