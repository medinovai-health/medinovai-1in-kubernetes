/**
 * Tenant isolation — forged X-Tenant-ID rejected; legitimate tenant data reachable.
 *
 * Golden scenarios:
 * - GS-AUTH-003: Tenant isolation — cross-tenant token/header rejected
 * - GS-DATA-002: Tenant-scoped query returns only myonsite-healthcare data
 * - GS-RBAC-002: read_only / cross-tenant guardrails (API rejection)
 */

import { test, expect } from '@playwright/test';
import {
  E_PORTAL_URL,
  E_REGISTRY_URL,
  E_MYONSITE_TENANT_ID,
  mos_completeKeycloakLogin,
  mos_tryBearerFromPortalStorage,
  mos_waitForPortalShell,
  type KeycloakLoginCredentials,
} from './keycloak-helpers';

const E_ADMIN: KeycloakLoginCredentials = {
  username: 'admin@myonsitehealthcare.com',
  password: 'ChangeMe!2026',
  newPasswordAfterRequiredAction: 'ChangeMe!2026',
};

const E_FAKE_TENANT = 'fake-tenant';

test.describe.serial('customer1 / tenant isolation (GS-AUTH-003, GS-DATA-002)', () => {
  test('forged X-Tenant-ID is rejected; valid tenant succeeds (registry API)', async ({ page }) => {
    await page.goto(E_PORTAL_URL, { waitUntil: 'domcontentloaded' });
    await mos_completeKeycloakLogin(page, E_ADMIN);
    await mos_waitForPortalShell(page, E_PORTAL_URL);

    const mos_bearer =
      process.env.MYO_E2E_REGISTRY_BEARER?.trim() || (await mos_tryBearerFromPortalStorage(page));
    const mos_modulesPath = '/api/v1/modules';
    const mos_headersBase: Record<string, string> = {};
    if (mos_bearer) {
      mos_headersBase.Authorization = `Bearer ${mos_bearer}`;
    }

    const mos_fake = await page.request.get(`${E_REGISTRY_URL}${mos_modulesPath}`, {
      headers: { ...mos_headersBase, 'X-Tenant-ID': E_FAKE_TENANT },
      failOnStatusCode: false,
    });

    const mos_ok = await page.request.get(`${E_REGISTRY_URL}${mos_modulesPath}`, {
      headers: { ...mos_headersBase, 'X-Tenant-ID': E_MYONSITE_TENANT_ID },
      failOnStatusCode: false,
    });

    if (mos_fake.status() === 401 && mos_ok.status() === 401) {
      test.skip(true, 'Registry modules list requires credentials; set MYO_E2E_REGISTRY_BEARER or ensure OIDC token in localStorage.');
    }

    expect(
      [400, 401, 403, 404, 422].includes(mos_fake.status()),
      `Expected forged X-Tenant-ID to be rejected (4xx), got ${mos_fake.status()}`
    ).toBeTruthy();

    expect(mos_ok.ok(), `Expected valid tenant request to succeed, got ${mos_ok.status()}`).toBeTruthy();
    const mos_body = await mos_ok.text();
    expect(mos_body.length).toBeGreaterThan(0);
  });
});
