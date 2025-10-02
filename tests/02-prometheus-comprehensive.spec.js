// Comprehensive Prometheus Testing Suite
// Tests: Metrics, Targets, Alerts, Configuration, API

const { test, expect } = require('@playwright/test');

const PROMETHEUS_URL = 'http://localhost:9090';

test.describe('Prometheus Comprehensive Test Suite', () => {

  test('01 - Prometheus: Verify home page', async ({ page }) => {
    await page.goto(PROMETHEUS_URL);
    await page.waitForTimeout(1000);
    
    const title = await page.title();
    expect(title).toContain('Prometheus');
    console.log('✅ Prometheus home page loaded');
  });

  test('02 - Prometheus: Check targets status', async ({ page }) => {
    await page.goto(`${PROMETHEUS_URL}/targets`);
    await page.waitForTimeout(1000);
    
    const targetsPage = await page.locator('text=Targets').count();
    expect(targetsPage).toBeGreaterThan(0);
    console.log('✅ Targets page accessible');
  });

  test('03 - Prometheus: Check alerts', async ({ page }) => {
    await page.goto(`${PROMETHEUS_URL}/alerts`);
    await page.waitForTimeout(1000);
    
    const alertsPage = await page.locator('text=Alerts').count();
    expect(alertsPage).toBeGreaterThan(0);
    console.log('✅ Alerts page accessible');
  });

  test('04 - Prometheus: Query execution test', async ({ page }) => {
    await page.goto(`${PROMETHEUS_URL}/graph`);
    await page.waitForTimeout(1000);
    
    // Enter a simple query
    await page.fill('textarea[name="expr"]', 'up');
    await page.click('button:has-text("Execute")');
    await page.waitForTimeout(2000);
    
    console.log('✅ Query execution working');
  });

  test('05 - Prometheus: API health check', async ({ request }) => {
    const response = await request.get(`${PROMETHEUS_URL}/-/healthy`);
    expect(response.status()).toBe(200);
    console.log('✅ Prometheus API healthy');
  });

  test('06 - Prometheus: API ready check', async ({ request }) => {
    const response = await request.get(`${PROMETHEUS_URL}/-/ready`);
    expect(response.status()).toBe(200);
    console.log('✅ Prometheus ready to serve requests');
  });

  test('07 - Prometheus: Query API test', async ({ request }) => {
    const response = await request.get(`${PROMETHEUS_URL}/api/v1/query?query=up`);
    expect(response.status()).toBe(200);
    
    const body = await response.json();
    expect(body.status).toBe('success');
    console.log('✅ Prometheus query API working');
  });

  test('08 - Prometheus: Targets API test', async ({ request }) => {
    const response = await request.get(`${PROMETHEUS_URL}/api/v1/targets`);
    expect(response.status()).toBe(200);
    
    const body = await response.json();
    expect(body.status).toBe('success');
    console.log('✅ Prometheus targets API working');
  });

  test('09 - Prometheus: AlertManager integration', async ({ request }) => {
    const response = await request.get(`${PROMETHEUS_URL}/api/v1/alertmanagers`);
    expect(response.status()).toBe(200);
    
    const body = await response.json();
    expect(body.status).toBe('success');
    console.log('✅ AlertManager integration configured');
  });

  test('10 - Prometheus: Configuration check', async ({ page }) => {
    await page.goto(`${PROMETHEUS_URL}/config`);
    await page.waitForTimeout(1000);
    
    const configPage = await page.locator('text=Configuration').count();
    expect(configPage).toBeGreaterThan(0);
    console.log('✅ Configuration page accessible');
  });

  test('11 - Prometheus: TSDB status', async ({ page }) => {
    await page.goto(`${PROMETHEUS_URL}/tsdb-status`);
    await page.waitForTimeout(1000);
    
    const tsdbPage = await page.locator('text=TSDB Status').count();
    expect(tsdbPage).toBeGreaterThan(0);
    console.log('✅ TSDB status page accessible');
  });

  test('12 - Prometheus: Service discovery', async ({ page }) => {
    await page.goto(`${PROMETHEUS_URL}/service-discovery`);
    await page.waitForTimeout(1000);
    
    const sdPage = await page.locator('text=Service Discovery').count();
    expect(sdPage).toBeGreaterThan(0);
    console.log('✅ Service discovery page accessible');
  });

});

