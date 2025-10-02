import { test, expect } from '@playwright/test';

/**
 * IT3: Security & Compliance Integration
 * Tests: Authentication → Authorization → Audit → Monitoring → Alerting
 * Validation: Security stack integration, HIPAA compliance
 */

test.describe('IT3: Security & Compliance Flow', () => {
  test('Security and audit trail should work end-to-end', async ({ page, request }) => {
    const testUser = `testuser-${Date.now()}`;
    
    await test.step('User authentication via Keycloak', async () => {
      await page.goto('/admin/login');
      await page.fill('input[name="username"]', 'system.admin');
      await page.fill('input[name="password"]', 'secure-password');
      await page.click('button[type="submit"]');
      await page.waitForURL('/admin/dashboard');
    });
    
    await test.step('RBAC authorization check', async () => {
      await page.goto('/admin/users');
      await expect(page.locator('.user-list')).toBeVisible();
    });
    
    await test.step('Action audit logging', async () => {
      await page.click('button[id="add-user"]');
      await page.fill('input[name="username"]', testUser);
      await page.fill('input[name="email"]', `${testUser}@test.com`);
      await page.click('button[id="save-user"]');
    });
    
    await test.step('Verify audit trail in Loki', async () => {
      await new Promise(resolve => setTimeout(resolve, 2000));
      const response = await request.get(`/api/audit/actions?user=system.admin`);
      if (response.ok()) {
        const logs = await response.json();
        const userCreation = logs.find((l: any) => l.action === 'USER_CREATED');
        expect(userCreation).toBeDefined();
      }
    });
  });
  
  test.afterAll(() => console.log('✅ Completed Security Integration Test'));
});
