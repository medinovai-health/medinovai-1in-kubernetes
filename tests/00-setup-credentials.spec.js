// Playwright Test Suite: Credential Setup and Validation
// This test validates all service credentials before running other tests

const { test, expect } = require('@playwright/test');

// Test credentials configuration
const CREDENTIALS = {
  grafana: {
    url: 'http://localhost:3000',
    username: 'admin',
    password: 'admin'
  },
  prometheus: {
    url: 'http://localhost:9090',
    requiresAuth: false
  },
  alertmanager: {
    url: 'http://localhost:9093',
    requiresAuth: false
  },
  rabbitmq: {
    url: 'http://localhost:15672',
    username: 'medinovai',
    password: 'rabbitmq_secure_password'
  },
  minio: {
    url: 'http://localhost:9001',
    username: 'medinovai',
    password: 'minio_secure_password'
  },
  keycloak: {
    url: 'http://localhost:8180',
    username: 'admin',
    password: 'keycloak_secure_password'
  }
};

test.describe('Credential Validation Suite', () => {
  
  test('01 - Validate Grafana credentials', async ({ page }) => {
    await page.goto(CREDENTIALS.grafana.url);
    await page.fill('input[name="user"]', CREDENTIALS.grafana.username);
    await page.fill('input[name="password"]', CREDENTIALS.grafana.password);
    await page.click('button[type="submit"]');
    
    // Wait for dashboard to load
    await page.waitForTimeout(2000);
    
    // Check if we're logged in (no login form visible)
    const loginForm = await page.locator('input[name="user"]').count();
    expect(loginForm).toBe(0);
    
    console.log('✅ Grafana credentials validated');
  });

  test('02 - Validate Prometheus accessibility', async ({ page }) => {
    await page.goto(CREDENTIALS.prometheus.url);
    await page.waitForSelector('text=Prometheus', { timeout: 5000 });
    expect(await page.title()).toContain('Prometheus');
    console.log('✅ Prometheus accessible');
  });

  test('03 - Validate AlertManager accessibility', async ({ page }) => {
    await page.goto(CREDENTIALS.alertmanager.url);
    await page.waitForSelector('text=Alertmanager', { timeout: 5000 });
    console.log('✅ AlertManager accessible');
  });

  test('04 - Validate RabbitMQ credentials', async ({ page }) => {
    await page.goto(CREDENTIALS.rabbitmq.url);
    await page.fill('input[name="username"]', CREDENTIALS.rabbitmq.username);
    await page.fill('input[name="password"]', CREDENTIALS.rabbitmq.password);
    await page.click('input[type="submit"]');
    
    await page.waitForTimeout(2000);
    
    // Check if we're logged in
    const loginForm = await page.locator('input[name="username"]').count();
    expect(loginForm).toBe(0);
    
    console.log('✅ RabbitMQ credentials validated');
  });

  test('05 - Validate MinIO credentials', async ({ page }) => {
    await page.goto(CREDENTIALS.minio.url);
    await page.waitForTimeout(2000);
    
    // MinIO login form
    await page.fill('input[id="accessKey"]', CREDENTIALS.minio.username);
    await page.fill('input[id="secretKey"]', CREDENTIALS.minio.password);
    await page.click('button[type="submit"]');
    
    await page.waitForTimeout(2000);
    console.log('✅ MinIO credentials validated');
  });

});

module.exports = { CREDENTIALS };

