import { test, expect } from '@playwright/test';

test.describe('Grafana Dashboards Verification', () => {
  const GRAFANA_URL = 'http://localhost:3000';
  const GRAFANA_USERNAME = 'admin';
  const GRAFANA_PASSWORD = 'admin123';

  test.beforeEach(async ({ page }) => {
    // Login to Grafana
    await page.goto(GRAFANA_URL);
    
    // Wait for login page
    await page.waitForSelector('input[name="user"]', { timeout: 10000 });
    
    // Fill in credentials
    await page.fill('input[name="user"]', GRAFANA_USERNAME);
    await page.fill('input[name="password"]', GRAFANA_PASSWORD);
    
    // Click login
    await page.click('button[type="submit"]');
    
    // Wait for dashboard to load
    await page.waitForURL('**/dashboards', { timeout: 10000 }).catch(() => {
      // If not redirected to dashboards, we're likely already logged in
      console.log('Already logged in or different redirect');
    });
  });

  test('1. Verify MedinovAI Infrastructure Overview Dashboard', async ({ page }) => {
    console.log('Testing MedinovAI Infrastructure Overview Dashboard...');
    
    // Navigate to dashboards
    await page.goto(`${GRAFANA_URL}/dashboards`);
    await page.waitForTimeout(2000);
    
    // Search for the dashboard
    await page.goto(`${GRAFANA_URL}/d/medinovai-overview`);
    await page.waitForTimeout(5000); // Wait for panels to load data
    
    // Take screenshot
    await page.screenshot({ 
      path: 'playwright-report/screenshots/dashboard-overview.png',
      fullPage: true 
    });
    
    // Verify title
    await expect(page.locator('text=/MedinovAI Infrastructure Overview/i')).toBeVisible();
    
    // Check for "No data" messages
    const noDataCount = await page.locator('text="No data"').count();
    console.log(`Found ${noDataCount} "No data" panels`);
    
    // Take screenshot of page source for debugging
    const content = await page.content();
    console.log('Page loaded successfully');
  });

  test('2. Verify Docker Container Monitoring Dashboard', async ({ page }) => {
    console.log('Testing Docker Container Monitoring Dashboard...');
    
    // Navigate directly to Docker dashboard
    await page.goto(`${GRAFANA_URL}/dashboards`);
    await page.waitForTimeout(2000);
    
    // Click on Infrastructure folder
    await page.locator('text=/Infrastructure/i').first().click();
    await page.waitForTimeout(1000);
    
    // Look for Docker dashboard
    await page.locator('text=/Docker/i').first().click();
    await page.waitForTimeout(5000);
    
    // Take screenshot
    await page.screenshot({ 
      path: 'playwright-report/screenshots/dashboard-docker.png',
      fullPage: true 
    });
    
    console.log('Docker dashboard screenshot captured');
  });

  test('3. Verify PostgreSQL Dashboard', async ({ page }) => {
    console.log('Testing PostgreSQL Dashboard...');
    
    await page.goto(`${GRAFANA_URL}/dashboards`);
    await page.waitForTimeout(2000);
    
    // Click on Infrastructure folder
    await page.locator('text=/Infrastructure/i').first().click();
    await page.waitForTimeout(1000);
    
    // Look for PostgreSQL dashboard
    await page.locator('text=/PostgreSQL/i').first().click();
    await page.waitForTimeout(5000);
    
    // Take screenshot
    await page.screenshot({ 
      path: 'playwright-report/screenshots/dashboard-postgresql.png',
      fullPage: true 
    });
    
    console.log('PostgreSQL dashboard screenshot captured');
  });

  test('4. Verify MongoDB Dashboard', async ({ page }) => {
    console.log('Testing MongoDB Dashboard...');
    
    await page.goto(`${GRAFANA_URL}/dashboards`);
    await page.waitForTimeout(2000);
    
    // Click on Infrastructure folder
    await page.locator('text=/Infrastructure/i').first().click();
    await page.waitForTimeout(1000);
    
    // Look for MongoDB dashboard
    await page.locator('text=/MongoDB/i').first().click();
    await page.waitForTimeout(5000);
    
    // Take screenshot
    await page.screenshot({ 
      path: 'playwright-report/screenshots/dashboard-mongodb.png',
      fullPage: true 
    });
    
    console.log('MongoDB dashboard screenshot captured');
  });

  test('5. Verify Redis Dashboard', async ({ page }) => {
    console.log('Testing Redis Dashboard...');
    
    await page.goto(`${GRAFANA_URL}/dashboards`);
    await page.waitForTimeout(2000);
    
    // Click on Infrastructure folder
    await page.locator('text=/Infrastructure/i').first().click();
    await page.waitForTimeout(1000);
    
    // Look for Redis dashboard
    await page.locator('text=/Redis/i').first().click();
    await page.waitForTimeout(5000);
    
    // Take screenshot
    await page.screenshot({ 
      path: 'playwright-report/screenshots/dashboard-redis.png',
      fullPage: true 
    });
    
    console.log('Redis dashboard screenshot captured');
  });

  test('6. Verify Node Exporter Dashboard', async ({ page }) => {
    console.log('Testing Node Exporter Dashboard...');
    
    await page.goto(`${GRAFANA_URL}/dashboards`);
    await page.waitForTimeout(2000);
    
    // Click on Infrastructure folder
    await page.locator('text=/Infrastructure/i').first().click();
    await page.waitForTimeout(1000);
    
    // Look for Node Exporter dashboard
    await page.locator('text=/Node/i').first().click();
    await page.waitForTimeout(5000);
    
    // Take screenshot
    await page.screenshot({ 
      path: 'playwright-report/screenshots/dashboard-node-exporter.png',
      fullPage: true 
    });
    
    console.log('Node Exporter dashboard screenshot captured');
  });

  test('7. Verify all dashboards are listed', async ({ page }) => {
    console.log('Verifying all dashboards are accessible...');
    
    await page.goto(`${GRAFANA_URL}/dashboards`);
    await page.waitForTimeout(2000);
    
    // Take screenshot of dashboard list
    await page.screenshot({ 
      path: 'playwright-report/screenshots/dashboards-list.png',
      fullPage: true 
    });
    
    // Count dashboards
    const dashboardCount = await page.locator('[data-testid="dashboard-card"]').count();
    console.log(`Found ${dashboardCount} dashboards`);
    
    // Verify Infrastructure folder exists
    await expect(page.locator('text=/Infrastructure/i').first()).toBeVisible();
    
    console.log('Dashboard list verified');
  });

  test('8. Check Prometheus Data Sources', async ({ page }) => {
    console.log('Checking Prometheus data source...');
    
    // Navigate to data sources
    await page.goto(`${GRAFANA_URL}/connections/datasources`);
    await page.waitForTimeout(2000);
    
    // Take screenshot
    await page.screenshot({ 
      path: 'playwright-report/screenshots/datasources.png',
      fullPage: true 
    });
    
    // Verify Prometheus exists
    await expect(page.locator('text=Prometheus')).toBeVisible();
    
    console.log('Data sources verified');
  });
});

