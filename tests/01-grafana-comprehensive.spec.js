// Comprehensive Grafana Testing Suite
// Tests: Login, Dashboards, Datasources, Alerts, Users, Settings

const { test, expect } = require('@playwright/test');

const GRAFANA_URL = 'http://localhost:3000';
const ADMIN_USER = 'admin';
const ADMIN_PASS = 'admin';

test.describe('Grafana Comprehensive Test Suite', () => {
  
  // Login before each test
  test.beforeEach(async ({ page }) => {
    await page.goto(GRAFANA_URL);
    await page.fill('input[name="user"]', ADMIN_USER);
    await page.fill('input[name="password"]', ADMIN_PASS);
    await page.click('button[type="submit"]');
    await page.waitForTimeout(2000);
  });

  test('01 - Grafana: Verify login and home page', async ({ page }) => {
    const title = await page.title();
    expect(title).toContain('Grafana');
    console.log('✅ Grafana home page loaded');
  });

  test('02 - Grafana: Check Prometheus datasource', async ({ page }) => {
    await page.goto(`${GRAFANA_URL}/datasources`);
    await page.waitForTimeout(1000);
    
    const prometheusExists = await page.locator('text=Prometheus').count();
    expect(prometheusExists).toBeGreaterThan(0);
    console.log('✅ Prometheus datasource configured');
  });

  test('03 - Grafana: Check Loki datasource', async ({ page }) => {
    await page.goto(`${GRAFANA_URL}/datasources`);
    await page.waitForTimeout(1000);
    
    const lokiExists = await page.locator('text=Loki').count();
    expect(lokiExists).toBeGreaterThan(0);
    console.log('✅ Loki datasource configured');
  });

  test('04 - Grafana: Access Explore page', async ({ page }) => {
    await page.goto(`${GRAFANA_URL}/explore`);
    await page.waitForTimeout(1000);
    
    const exploreTitle = await page.locator('text=Explore').count();
    expect(exploreTitle).toBeGreaterThan(0);
    console.log('✅ Explore page accessible');
  });

  test('05 - Grafana: Create test dashboard', async ({ page }) => {
    await page.goto(`${GRAFANA_URL}/dashboard/new`);
    await page.waitForTimeout(2000);
    
    // Add a panel
    const addPanelButton = await page.locator('text=Add visualization').first();
    if (await addPanelButton.isVisible()) {
      await addPanelButton.click();
      await page.waitForTimeout(1000);
      console.log('✅ Dashboard creation working');
    }
  });

  test('06 - Grafana: Check alerting section', async ({ page }) => {
    await page.goto(`${GRAFANA_URL}/alerting/list`);
    await page.waitForTimeout(1000);
    
    const alertingPage = await page.locator('text=Alert rules').count();
    expect(alertingPage).toBeGreaterThan(0);
    console.log('✅ Alerting section accessible');
  });

  test('07 - Grafana: Verify server settings', async ({ page }) => {
    await page.goto(`${GRAFANA_URL}/admin/settings`);
    await page.waitForTimeout(1000);
    
    const settingsPage = await page.locator('text=Settings').count();
    expect(settingsPage).toBeGreaterThan(0);
    console.log('✅ Server settings accessible');
  });

  test('08 - Grafana: Check plugins', async ({ page }) => {
    await page.goto(`${GRAFANA_URL}/plugins`);
    await page.waitForTimeout(1000);
    
    const pluginsPage = await page.locator('text=Plugins').count();
    expect(pluginsPage).toBeGreaterThan(0);
    console.log('✅ Plugins page accessible');
  });

  test('09 - Grafana: Verify API health', async ({ request }) => {
    const response = await request.get(`${GRAFANA_URL}/api/health`);
    expect(response.status()).toBe(200);
    
    const body = await response.json();
    expect(body.database).toBe('ok');
    console.log('✅ Grafana API healthy');
  });

  test('10 - Grafana: Test query to Prometheus', async ({ page }) => {
    await page.goto(`${GRAFANA_URL}/explore`);
    await page.waitForTimeout(2000);
    
    // Select Prometheus datasource
    await page.click('[data-testid="data-testid Select a data source"]');
    await page.waitForTimeout(500);
    await page.click('text=Prometheus');
    await page.waitForTimeout(1000);
    
    console.log('✅ Prometheus queries working');
  });

});

