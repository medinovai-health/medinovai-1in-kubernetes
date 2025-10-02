// Comprehensive AlertManager Testing Suite
// Tests: Alerts, Silences, Configuration, API

const { test, expect } = require('@playwright/test');

const ALERTMANAGER_URL = 'http://localhost:9093';

test.describe('AlertManager Comprehensive Test Suite', () => {

  test('01 - AlertManager: Verify home page', async ({ page }) => {
    await page.goto(ALERTMANAGER_URL);
    await page.waitForTimeout(1000);
    
    const alertmanagerText = await page.locator('text=Alertmanager').count();
    expect(alertmanagerText).toBeGreaterThan(0);
    console.log('✅ AlertManager home page loaded');
  });

  test('02 - AlertManager: Check alerts view', async ({ page }) => {
    await page.goto(`${ALERTMANAGER_URL}/#/alerts`);
    await page.waitForTimeout(1000);
    
    const alertsView = await page.locator('text=Alerts').count();
    expect(alertsView).toBeGreaterThan(0);
    console.log('✅ Alerts view accessible');
  });

  test('03 - AlertManager: Check silences view', async ({ page }) => {
    await page.goto(`${ALERTMANAGER_URL}/#/silences`);
    await page.waitForTimeout(1000);
    
    const silencesView = await page.locator('text=Silences').count();
    expect(silencesView).toBeGreaterThan(0);
    console.log('✅ Silences view accessible');
  });

  test('04 - AlertManager: API health check', async ({ request }) => {
    const response = await request.get(`${ALERTMANAGER_URL}/-/healthy`);
    expect(response.status()).toBe(200);
    console.log('✅ AlertManager API healthy');
  });

  test('05 - AlertManager: API ready check', async ({ request }) => {
    const response = await request.get(`${ALERTMANAGER_URL}/-/ready`);
    expect(response.status()).toBe(200);
    console.log('✅ AlertManager ready');
  });

  test('06 - AlertManager: Get alerts via API', async ({ request }) => {
    const response = await request.get(`${ALERTMANAGER_URL}/api/v1/alerts`);
    expect(response.status()).toBe(200);
    
    const body = await response.json();
    expect(Array.isArray(body)).toBeTruthy();
    console.log('✅ Alerts API working');
  });

  test('07 - AlertManager: Get status via API', async ({ request }) => {
    const response = await request.get(`${ALERTMANAGER_URL}/api/v1/status`);
    expect(response.status()).toBe(200);
    
    const body = await response.json();
    expect(body.config).toBeDefined();
    console.log('✅ Status API working');
  });

  test('08 - AlertManager: Get silences via API', async ({ request }) => {
    const response = await request.get(`${ALERTMANAGER_URL}/api/v1/silences`);
    expect(response.status()).toBe(200);
    
    const body = await response.json();
    expect(Array.isArray(body)).toBeTruthy();
    console.log('✅ Silences API working');
  });

  test('09 - AlertManager: Post test alert', async ({ request }) => {
    const testAlert = [{
      labels: {
        alertname: 'PlaywrightTestAlert',
        severity: 'info',
        instance: 'playwright-test'
      },
      annotations: {
        summary: 'Test alert from Playwright',
        description: 'This is a test alert to verify AlertManager is working'
      },
      startsAt: new Date().toISOString()
    }];

    const response = await request.post(`${ALERTMANAGER_URL}/api/v1/alerts`, {
      data: testAlert
    });
    
    expect(response.status()).toBe(200);
    console.log('✅ Test alert posted successfully');
  });

  test('10 - AlertManager: Verify test alert received', async ({ request }) => {
    // Wait a bit for alert to process
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    const response = await request.get(`${ALERTMANAGER_URL}/api/v1/alerts`);
    const alerts = await response.json();
    
    const testAlert = alerts.find(a => a.labels.alertname === 'PlaywrightTestAlert');
    expect(testAlert).toBeDefined();
    console.log('✅ Test alert verified in AlertManager');
  });

});

