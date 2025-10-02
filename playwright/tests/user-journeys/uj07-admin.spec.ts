import { test, expect } from '@playwright/test';

/**
 * UJ7: System Administrator - Configuration Management
 * Components: Keycloak, Vault, PostgreSQL, MongoDB, Redis, Prometheus, Grafana, Loki
 * Security: RBAC, secrets management, audit logging
 */

test.describe('UJ7: System Administrator - Configuration Management', () => {
  test('Admin can manage system configuration', async ({ page }) => {
    await test.step('Authenticate as admin', async () => {
      await page.goto('/admin/login');
      await page.fill('input[name="username"]', 'system.admin');
      await page.fill('input[name="password"]', 'secure-password');
      await page.click('button[type="submit"]');
      await page.waitForURL('/admin/dashboard');
    });
    
    await test.step('Access user management', async () => {
      await page.click('a[href="/admin/users"]');
      await expect(page.locator('.user-list')).toBeVisible();
    });
    
    await test.step('Create new user', async () => {
      await page.click('button[id="add-user"]');
      await page.fill('input[name="username"]', 'new.nurse');
      await page.fill('input[name="email"]', 'new.nurse@medinovai.com');
      await page.fill('input[name="firstName"]', 'New');
      await page.fill('input[name="lastName"]', 'Nurse');
      await page.click('button[id="save-user"]');
      await expect(page.locator('.alert-success')).toContainText('User created');
    });
    
    await test.step('Assign roles', async () => {
      await page.click('.user-item:has-text("new.nurse")');
      await page.click('button[id="manage-roles"]');
      await page.check('input[name="role-nurse"]');
      await page.check('input[name="role-medication-admin"]');
      await page.click('button[id="save-roles"]');
      await expect(page.locator('.alert-success')).toContainText('Roles assigned');
    });
    
    await test.step('Configure system settings', async () => {
      await page.click('a[href="/admin/settings"]');
      await page.fill('input[name="session-timeout"]', '30');
      await page.check('input[name="mfa-required"]');
      await page.click('button[id="save-settings"]');
      await expect(page.locator('.alert-success')).toContainText('Settings saved');
    });
    
    await test.step('View audit logs', async () => {
      await page.click('a[href="/admin/audit"]');
      await expect(page.locator('.audit-log')).toBeVisible();
      const logs = page.locator('.audit-entry');
      expect(await logs.count()).toBeGreaterThan(0);
    });
  });
  
  test.afterAll(() => console.log('✅ Completed Admin Journey'));
});
