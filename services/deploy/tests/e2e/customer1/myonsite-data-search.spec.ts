/**
 * Patient / data search — SDG MRN pattern and tenant scoping.
 *
 * Golden scenarios:
 * - GS-LIS-002: Search synthetic patient by MRN
 * - GS-DATA-001: Patient list returns SDG-seeded records
 */

import { test, expect } from '@playwright/test';
import {
  E_PORTAL_URL,
  E_MYONSITE_TENANT_ID,
  mos_completeKeycloakLogin,
  mos_waitForPortalShell,
  type KeycloakLoginCredentials,
} from './keycloak-helpers';

const E_CLINICIAN: KeycloakLoginCredentials = {
  username: 'demo-clinician@myonsitehealthcare.com',
  password: 'DemoClinician!2026',
};

const E_MRN_PREFIX = 'MRN-MYO-';

test.describe.serial('customer1 / patient data search (GS-LIS-002, GS-DATA-001)', () => {
  test('clinician finds SDG patients and tenant context is myonsite-healthcare', async ({ page }) => {
    await page.goto(E_PORTAL_URL, { waitUntil: 'domcontentloaded' });
    await mos_completeKeycloakLogin(page, E_CLINICIAN);
    await mos_waitForPortalShell(page, E_PORTAL_URL);

    const mos_searchNav = page
      .locator('[data-testid="nav-patient-search"]')
      .or(page.locator('[data-testid="nav-data-search"]'))
      .or(page.getByRole('link', { name: /patients|patient search|directory|data search/i }))
      .or(page.getByRole('button', { name: /patients|search/i }));

    await expect(mos_searchNav.first()).toBeVisible({ timeout: 25_000 });
    await mos_searchNav.first().click();

    const mos_query = page
      .locator('[data-testid="patient-search-input"]')
      .or(page.locator('[data-testid="global-search"]'))
      .or(page.getByPlaceholder(/mrn|patient|search/i))
      .or(page.locator('input[type="search"]'));

    await expect(mos_query.first()).toBeVisible({ timeout: 20_000 });
    await mos_query.first().fill(E_MRN_PREFIX);
    await mos_query.first().press('Enter').catch(() => undefined);

    const mos_go = page.locator('[data-testid="search-submit"]').or(page.getByRole('button', { name: /search/i }));
    if (await mos_go.first().isVisible().catch(() => false)) {
      await mos_go.first().click();
    }

    const mos_results = page.locator('[data-testid="patient-result"]').or(page.locator('[data-testid="search-result-row"]'));
    await expect(mos_results.or(page.getByText(E_MRN_PREFIX)).first()).toBeVisible({ timeout: 25_000 });

    const mos_tenantHint = page
      .locator('[data-testid="tenant-id"]')
      .or(page.locator('[data-testid="active-tenant"]'))
      .or(page.locator(`[data-tenant-id="${E_MYONSITE_TENANT_ID}"]`))
      .or(page.getByText(new RegExp(E_MYONSITE_TENANT_ID, 'i')));

    await expect(mos_tenantHint.first()).toBeVisible({ timeout: 25_000 });
  });
});
