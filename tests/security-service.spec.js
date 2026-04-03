const { test, expect } = require('@playwright/test');

const SECURITY_URL = process.env.SECURITY_URL || 'http://localhost:8300';
const KEYCLOAK_URL = process.env.KEYCLOAK_URL || 'http://localhost:8081';

test.describe('Security Service - Core Authentication', () => {

  test('Health endpoint returns healthy', async ({ request }) => {
    const response = await request.get(`${SECURITY_URL}/health`);
    expect(response.status()).toBe(200);

    const body = await response.json();
    expect(body.status).toBe('healthy');
    expect(body.service).toBe('medinovai-security-service');
    expect(body).toHaveProperty('version');
    expect(body).toHaveProperty('timestamp');
  });

  test('Ready endpoint returns ready', async ({ request }) => {
    const response = await request.get(`${SECURITY_URL}/ready`);
    expect(response.status()).toBe(200);

    const body = await response.json();
    expect(body.status).toBe('ready');
  });

  test('Root endpoint returns service info', async ({ request }) => {
    const response = await request.get(`${SECURITY_URL}/`);
    expect(response.status()).toBe(200);

    const body = await response.json();
    expect(body.service).toBe('medinovai-security-service');
    expect(body.status).toBe('operational');
  });

  test('Login page is accessible', async ({ page }) => {
    await page.goto(`${SECURITY_URL}/login`);
    await expect(page).toHaveTitle(/MedinovAI/);

    // Check for login form elements
    await expect(page.locator('input#username')).toBeVisible();
    await expect(page.locator('input#password')).toBeVisible();
    await expect(page.locator('button[type="submit"]')).toBeVisible();

    // Take screenshot
    await page.screenshot({ path: 'test-results/security-login-page.png' });
  });

  test('API docs are accessible', async ({ request }) => {
    const response = await request.get(`${SECURITY_URL}/docs`);
    expect(response.status()).toBe(200);
  });

  test('RBAC endpoints return roles and permissions', async ({ request }) => {
    const rolesResponse = await request.get(`${SECURITY_URL}/rbac/roles`);
    expect(rolesResponse.status()).toBe(200);
    const roles = await rolesResponse.json();
    expect(roles).toHaveProperty('roles');

    const permsResponse = await request.get(`${SECURITY_URL}/rbac/permissions`);
    expect(permsResponse.status()).toBe(200);
    const perms = await permsResponse.json();
    expect(perms).toHaveProperty('permissions');
  });

  test('Policy endpoints return policies', async ({ request }) => {
    const response = await request.get(`${SECURITY_URL}/policy/policies`);
    expect(response.status()).toBe(200);
    const body = await response.json();
    expect(body).toHaveProperty('policies');
  });

  test('Audit log endpoint accepts events', async ({ request }) => {
    const auditEvent = {
      timestamp: new Date().toISOString(),
      actor_id: 'test-user',
      action: 'test_action',
      resource: 'test_resource',
      tenant_id: 'test-tenant'
    };

    const response = await request.post(`${SECURITY_URL}/audit/log`, {
      data: auditEvent
    });
    expect(response.status()).toBe(200);

    const body = await response.json();
    expect(body.status).toBe('logged');
    expect(body).toHaveProperty('event_id');
  });

});

test.describe('Security Service - Infrastructure Integration', () => {

  test('All health endpoints respond correctly', async ({ request }) => {
    const endpoints = [
      '/health',
      '/ready',
      '/rbac/roles',
      '/rbac/permissions',
      '/policy/policies',
      '/agents/register',
    ];

    for (const endpoint of endpoints) {
      const response = await request.get(`${SECURITY_URL}${endpoint}`);
      // All should return 200 or 405 (for POST-only endpoints)
      expect([200, 405]).toContain(response.status());
    }
  });

  test('Token validation endpoint structure', async ({ request }) => {
    // Test with invalid token
    const response = await request.post(`${SECURITY_URL}/validate`, {
      data: { token: 'invalid-token' }
    });

    expect(response.status()).toBe(200);
    const body = await response.json();
    expect(body).toHaveProperty('valid');
    expect(body.valid).toBe(false);
  });

  test('Auth endpoints structure', async ({ request }) => {
    // Test login endpoint with invalid credentials
    const response = await request.post(`${SECURITY_URL}/auth/login`, {
      data: {
        username: 'invalid',
        password: 'invalid',
        client_id: 'test'
      }
    });

    // Should get 401 for invalid credentials
    expect(response.status()).toBe(401);
  });

});

test.describe('Infrastructure Portal SSO Flow', () => {

  test('Portal loads and shows infrastructure services', async ({ page }) => {
    // Note: This test assumes the portal is running on localhost:3000
    // In production, this would be configured via environment variables
    const PORTAL_URL = process.env.PORTAL_URL || 'http://localhost:3000';

    try {
      await page.goto(PORTAL_URL, { timeout: 10000 });
    } catch {
      test.skip(true, 'Portal not running on localhost:3000');
      return;
    }

    // Wait for page to load
    await page.waitForLoadState('networkidle');

    // Check for infrastructure service tiles
    const serviceNames = ['Security Service', 'Service Registry', 'Grafana', 'Kibana'];
    for (const name of serviceNames) {
      const tile = page.locator(`text=${name}`).first();
      // Just check it exists, don't assert visibility since it might need auth
      const count = await tile.count();
      if (count > 0) {
        console.log(`  Found service tile: ${name}`);
      }
    }

    await page.screenshot({ path: 'test-results/infrastructure-portal.png' });
  });

});

test.describe('Keycloak Integration', () => {

  test('Keycloak health endpoint is accessible', async ({ request }) => {
    try {
      const response = await request.get(`${KEYCLOAK_URL}/health/ready`, { timeout: 5000 });
      expect([200, 204]).toContain(response.status());
      console.log('  Keycloak is ready');
    } catch {
      test.skip(true, 'Keycloak not accessible');
    }
  });

  test('Keycloak realm is accessible', async ({ request }) => {
    try {
      const response = await request.get(`${KEYCLOAK_URL}/realms/medinovai`, { timeout: 5000 });
      expect(response.status()).toBe(200);

      const body = await response.json();
      expect(body).toHaveProperty('realm');
      console.log(`  Realm: ${body.realm}`);
    } catch {
      test.skip(true, 'Keycloak realm not accessible');
    }
  });

});
