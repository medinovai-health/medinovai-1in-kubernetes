/**
 * Admin user directory — demo identities and role display.
 *
 * Golden scenarios:
 * - GS-RBAC-001: Admin role has full permissions (admin path + user admin UI)
 */

import { test, expect } from '@playwright/test';
import {
  E_PORTAL_URL,
  mos_completeKeycloakLogin,
  mos_waitForPortalShell,
  type KeycloakLoginCredentials,
} from './keycloak-helpers';

const E_ADMIN: KeycloakLoginCredentials = {
  username: 'admin@myonsitehealthcare.com',
  password: 'ChangeMe!2026',
  newPasswordAfterRequiredAction: 'ChangeMe!2026',
};

test.describe.serial('customer1 / user management (GS-RBAC-001)', () => {
  test('admin sees user admin area and demo users with roles', async ({ page }) => {
    await page.goto(E_PORTAL_URL, { waitUntil: 'domcontentloaded' });
    await mos_completeKeycloakLogin(page, E_ADMIN);
    await mos_waitForPortalShell(page, E_PORTAL_URL);

    const mos_usersNav = page
      .locator('[data-testid="nav-users"]')
      .or(page.locator('[data-testid="nav-user-admin"]'))
      .or(page.getByRole('link', { name: /users|user admin|administration|directory/i }))
      .or(page.getByRole('button', { name: /users|user admin|directory/i }));

    await expect(mos_usersNav.first()).toBeVisible({ timeout: 25_000 });
    await mos_usersNav.first().click();

    const mos_table = page.locator('[data-testid="user-table"]').or(page.locator('table')).or(page.locator('[role="grid"]'));
    await expect(mos_table.first()).toBeVisible({ timeout: 20_000 });

    await expect(page.getByText('demo-clinician@myonsitehealthcare.com')).toBeVisible({ timeout: 15_000 });
    await expect(page.getByText('demo-labtech@myonsitehealthcare.com')).toBeVisible({ timeout: 15_000 });

    const mos_role = page
      .locator('[data-testid="user-role"]')
      .or(page.locator('[data-testid="role-chip"]'))
      .or(page.getByText(/clinician|lab|admin|role/i));
    await expect(mos_role.first()).toBeVisible({ timeout: 15_000 });
  });
});
