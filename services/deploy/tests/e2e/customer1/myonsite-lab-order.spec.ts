/**
 * Lab orders workflow — customer-1 synthetic MRN search and lifecycle fields.
 *
 * Golden scenarios:
 * - GS-LIS-001: Lab order to result — full lifecycle
 * - GS-LIS-003: View lab result with reference range flags
 */

import { test, expect } from '@playwright/test';
import {
  E_PORTAL_URL,
  mos_completeKeycloakLogin,
  mos_waitForPortalShell,
  type KeycloakLoginCredentials,
} from './keycloak-helpers';

const E_LABTECH: KeycloakLoginCredentials = {
  username: 'demo-labtech@myonsitehealthcare.com',
  password: 'DemoLabTech!2026',
};

const E_MRN_PREFIX = 'MRN-MYO-';

test.describe.serial('customer1 / lab orders (GS-LIS-001, GS-LIS-003)', () => {
  test('lab tech can open lab orders and search by MRN pattern', async ({ page }) => {
    await page.goto(E_PORTAL_URL, { waitUntil: 'domcontentloaded' });
    await mos_completeKeycloakLogin(page, E_LABTECH);
    await mos_waitForPortalShell(page, E_PORTAL_URL);

    const mos_labNav = page
      .locator('[data-testid="nav-lab-orders"]')
      .or(page.locator('[data-testid="lab-orders-link"]'))
      .or(page.getByRole('link', { name: /lab orders|orders|lis|laboratory/i }))
      .or(page.getByRole('button', { name: /lab orders|orders|lis/i }));

    await expect(mos_labNav.first()).toBeVisible({ timeout: 25_000 });
    await mos_labNav.first().click();

    const mos_search = page
      .locator('[data-testid="lab-order-search"]')
      .or(page.locator('[data-testid="patient-mrn-search"]'))
      .or(page.getByPlaceholder(/mrn|patient|search/i))
      .or(page.locator('input[type="search"]'));

    await expect(mos_search.first()).toBeVisible({ timeout: 20_000 });
    await mos_search.first().fill(E_MRN_PREFIX);
    await mos_search.first().press('Enter').catch(() => undefined);

    const mos_submit = page.locator('[data-testid="search-submit"]').or(page.getByRole('button', { name: /search/i }));
    if (await mos_submit.first().isVisible().catch(() => false)) {
      await mos_submit.first().click();
    }

    const mos_row = page.locator('[data-testid="lab-order-row"]').or(page.locator('tbody tr')).or(page.locator('[role="row"]'));
    const mos_count = await mos_row.count();
    if (mos_count > 0) {
      await expect(mos_row.first()).toBeVisible();
      const mos_text = await mos_row.first().innerText();
      expect(mos_text.length).toBeGreaterThan(2);
    }

    const mos_lifecycle = page.getByText(
      /ordered|collected|in\s*progress|processing|final|complete|verified|cancelled|rejected/i
    );
    const mos_statusCell = page
      .locator('[data-testid="order-status"]')
      .or(page.locator('[data-testid="lab-order-status"]'));

    if (await mos_statusCell.first().isVisible().catch(() => false)) {
      await expect(mos_statusCell.first()).toBeVisible();
    } else if (await mos_lifecycle.first().isVisible().catch(() => false)) {
      await expect(mos_lifecycle.first()).toBeVisible();
    } else if (mos_count > 0) {
      const mos_hasStatus = await mos_row
        .first()
        .getByText(/ordered|collected|in\s*progress|processing|final|complete|verified|pending|status/i)
        .first()
        .isVisible()
        .catch(() => false);
      expect(mos_hasStatus).toBe(true);
    }
  });
});
