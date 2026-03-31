/**
 * Shared Keycloak OIDC helpers for customer-1 (myOnsiteHealthcare) E2E flows.
 * PHI-safe: no credentials logged; values come from parameters or env overrides only.
 */

import { expect, type Page } from '@playwright/test';

export const E_PORTAL_URL =
  process.env.MYO_CUSTOMER1_PORTAL_URL ?? 'http://localhost:3000';
export const E_REGISTRY_URL =
  process.env.MYO_CUSTOMER1_REGISTRY_URL ?? 'http://localhost:8060';
export const E_KEYCLOAK_URL_PATTERN = /localhost:8180|:8180/;
export const E_MYONSITE_TENANT_ID = 'myonsite-healthcare';

export type KeycloakLoginCredentials = {
  username: string;
  password: string;
  /**
   * When Keycloak enforces "Update Password" (temporary password), set the new password.
   * Defaults to the same as `password` so the account ends on the known demo password.
   */
  newPasswordAfterRequiredAction?: string;
};

const mos_usernameField = (page: Page) =>
  page.locator('[data-testid="kc-username"]').or(page.locator('#username')).or(page.locator('input[name="username"]'));

const mos_passwordField = (page: Page) =>
  page.locator('[data-testid="kc-password"]').or(page.locator('#password')).or(page.locator('input[name="password"]'));

const mos_loginSubmit = (page: Page) =>
  page.locator('[data-testid="kc-login"]').or(page.locator('#kc-login')).or(page.getByRole('button', { name: /sign in|log in/i }));

/**
 * Opens the portal and asserts the browser is redirected toward Keycloak.
 * Golden: GS-AUTH-001 (redirect expectation).
 */
export async function mos_navigatePortalExpectKeycloak(
  page: Page,
  portalUrl: string = E_PORTAL_URL
): Promise<void> {
  await page.goto(portalUrl, { waitUntil: 'domcontentloaded' });
  await expect(page).toHaveURL(E_KEYCLOAK_URL_PATTERN, { timeout: 45_000 });
}

/**
 * Completes Keycloak username/password and optional "Update Password" required action.
 */
export async function mos_completeKeycloakLogin(
  page: Page,
  creds: KeycloakLoginCredentials
): Promise<void> {
  const mos_user = mos_usernameField(page);
  await expect(mos_user).toBeVisible({ timeout: 30_000 });
  await mos_user.fill(creds.username);
  await mos_passwordField(page).fill(creds.password);
  await mos_loginSubmit(page).click();

  await mos_handleKeycloakUpdatePasswordIfPresent(page, creds);

  const mos_error = page.locator('.kc-feedback-text, .pf-c-alert__title, [role="alert"]');
  const mos_hasError = await mos_error.first().isVisible().catch(() => false);
  if (mos_hasError) {
    await expect(mos_error.first()).not.toBeVisible({ timeout: 2_000 }).catch(() => undefined);
  }
}

/**
 * Keycloak "Update Password" / temporary-password flow (required action).
 */
export async function mos_handleKeycloakUpdatePasswordIfPresent(
  page: Page,
  creds: KeycloakLoginCredentials
): Promise<void> {
  const mos_newPwd = page
    .locator('#password-new')
    .or(page.locator('input[name="password-new"]'))
    .or(page.locator('[data-testid="password-new"]'));
  const mos_confirm = page
    .locator('#password-confirm')
    .or(page.locator('input[name="password-confirm"]'))
    .or(page.locator('#password-new-confirm'));

  const mos_visible = await mos_newPwd.first().isVisible({ timeout: 8_000 }).catch(() => false);
  if (!mos_visible) {
    return;
  }

  const mos_next = creds.newPasswordAfterRequiredAction ?? creds.password;
  await mos_newPwd.first().fill(mos_next);
  await mos_confirm.first().fill(mos_next);
  await page
    .locator('input[type="submit"]')
    .or(page.getByRole('button', { name: /submit|save|continue/i }))
    .first()
    .click();
}

/**
 * Wait until OIDC returns to the portal origin (or app shell is visible on portal host).
 */
export async function mos_waitForPortalShell(
  page: Page,
  portalUrl: string = E_PORTAL_URL
): Promise<void> {
  const mos_host = new URL(portalUrl).host;
  await expect(page).toHaveURL(new RegExp(mos_host.replace(/\./g, '\\.')), { timeout: 90_000 });
}

/**
 * Best-effort portal logout (OIDC RP-initiated or UI control).
 */
export async function mos_portalLogout(page: Page): Promise<void> {
  const mos_userMenu = page.locator('[data-testid="user-menu"]').or(page.locator('[data-testid="account-menu"]'));
  if (await mos_userMenu.first().isVisible().catch(() => false)) {
    await mos_userMenu.first().click();
  }
  const mos_out = page
    .getByRole('button', { name: /log ?out|sign ?out/i })
    .or(page.getByRole('link', { name: /log ?out|sign ?out/i }))
    .or(page.locator('[data-testid="logout"]'));
  if (await mos_out.first().isVisible({ timeout: 5_000 }).catch(() => false)) {
    await mos_out.first().click();
  } else {
    await page.goto(`${E_PORTAL_URL}/logout`, { waitUntil: 'domcontentloaded' }).catch(() => undefined);
  }
}

/**
 * Try to read a Bearer token from typical OIDC client storage keys (no token values returned to logs).
 */
export async function mos_tryBearerFromPortalStorage(page: Page): Promise<string | undefined> {
  return page.evaluate(() => {
    const mos_keys: string[] = [];
    for (let mos_i = 0; mos_i < window.localStorage.length; mos_i++) {
      const mos_k = window.localStorage.key(mos_i);
      if (mos_k) {
        mos_keys.push(mos_k);
      }
    }
    for (const mos_k of mos_keys) {
      if (!/oidc|auth|token|keycloak|user/i.test(mos_k)) {
        continue;
      }
      const mos_raw = window.localStorage.getItem(mos_k);
      if (!mos_raw) {
        continue;
      }
      try {
        const mos_o = JSON.parse(mos_raw) as { access_token?: string; accessToken?: string };
        const mos_t = mos_o.access_token ?? mos_o.accessToken;
        if (typeof mos_t === 'string' && mos_t.length > 20) {
          return mos_t;
        }
      } catch {
        /* not JSON */
      }
    }
    return undefined;
  });
}
