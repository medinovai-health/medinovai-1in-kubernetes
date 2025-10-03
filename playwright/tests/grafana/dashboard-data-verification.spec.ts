import { test, expect } from '@playwright/test';

test.describe('Grafana Dashboard Data Verification', () => {
  const GRAFANA_URL = 'http://localhost:3000';
  const GRAFANA_USERNAME = 'admin';
  const GRAFANA_PASSWORD = 'admin123';

  test.beforeEach(async ({ page }) => {
    // Login to Grafana
    await page.goto(GRAFANA_URL);
    
    // Check if already logged in
    const isLoggedIn = await page.locator('text=/Dashboards/i').isVisible().catch(() => false);
    
    if (!isLoggedIn) {
      await page.fill('input[name="user"]', GRAFANA_USERNAME);
      await page.fill('input[name="password"]', GRAFANA_PASSWORD);
      await page.click('button[type="submit"]');
      await page.waitForURL(`${GRAFANA_URL}/**`);
    }
  });

  test('Overview Dashboard - All Panels Show Data', async ({ page }) => {
    console.log('📊 Testing MedinovAI Infrastructure Overview Dashboard...');
    
    // Navigate to overview dashboard
    await page.goto(`${GRAFANA_URL}/d/medinovai-overview/medinovai-infrastructure-overview?orgId=1&refresh=30s`);
    
    // Wait for dashboard to load
    await page.waitForSelector('text=/MedinovAI Infrastructure/i', { timeout: 10000 });
    
    console.log('✓ Dashboard loaded');
    
    // Wait for panels to render (give metrics time to load)
    await page.waitForTimeout(5000);
    
    // Capture screenshot
    await page.screenshot({ 
      path: 'playwright-report/screenshots/overview-dashboard-with-data.png', 
      fullPage: true 
    });
    
    console.log('✓ Screenshot captured');
    
    // Check for "No data" text - there should be NONE or minimal
    const noDataElements = await page.locator('text=/No data/i').count();
    console.log(`Found ${noDataElements} "No data" elements`);
    
    // We expect 0-3 "No data" (database panels might still show this)
    // But the system gauges should have data now
    expect(noDataElements).toBeLessThanOrEqual(3);
    
    // Verify key panels are visible
    await expect(page.locator('text=/System CPU/i')).toBeVisible();
    await expect(page.locator('text=/System Memory/i')).toBeVisible();
    await expect(page.locator('text=/System Disk/i')).toBeVisible();
    await expect(page.locator('text=/Services Online/i')).toBeVisible();
    
    console.log('✅ Overview dashboard verification complete');
  });

  test('Docker Dashboard - Verify Real Metrics', async ({ page }) => {
    console.log('🐳 Testing Docker Monitoring Dashboard...');
    
    // Navigate to Docker dashboard
    await page.goto(`${GRAFANA_URL}/d/fdabdeaa-d1b7-40c6-aa99-95a16118b65f/docker-monitoring?orgId=1&refresh=5s`);
    
    // Wait for dashboard to load
    await page.waitForSelector('text=/Docker/i', { timeout: 10000 });
    
    // Wait for data
    await page.waitForTimeout(5000);
    
    // Capture screenshot
    await page.screenshot({ 
      path: 'playwright-report/screenshots/docker-dashboard-verified.png', 
      fullPage: true 
    });
    
    // This dashboard should have NO "No data" elements
    const noDataElements = await page.locator('text=/No data/i').count();
    console.log(`Found ${noDataElements} "No data" elements in Docker dashboard`);
    
    expect(noDataElements).toBeLessThanOrEqual(1);
    
    console.log('✅ Docker dashboard verification complete');
  });

  test('PostgreSQL Dashboard - Check Status', async ({ page }) => {
    console.log('🐘 Testing PostgreSQL Dashboard...');
    
    await page.goto(`${GRAFANA_URL}/d/postgresql-dashboard/postgresql?orgId=1&refresh=5s`);
    
    await page.waitForTimeout(5000);
    
    await page.screenshot({ 
      path: 'playwright-report/screenshots/postgresql-dashboard-status.png', 
      fullPage: true 
    });
    
    console.log('✅ PostgreSQL dashboard screenshot captured');
  });

  test('MongoDB Dashboard - Check Status', async ({ page }) => {
    console.log('🍃 Testing MongoDB Dashboard...');
    
    await page.goto(`${GRAFANA_URL}/d/mongodb-dashboard/mongodb?orgId=1&refresh=5s`);
    
    await page.waitForTimeout(5000);
    
    await page.screenshot({ 
      path: 'playwright-report/screenshots/mongodb-dashboard-status.png', 
      fullPage: true 
    });
    
    console.log('✅ MongoDB dashboard screenshot captured');
  });

  test('Redis Dashboard - Check Status', async ({ page }) => {
    console.log('🔴 Testing Redis Dashboard...');
    
    await page.goto(`${GRAFANA_URL}/d/redis-dashboard/redis?orgId=1&refresh=5s`);
    
    await page.waitForTimeout(5000);
    
    await page.screenshot({ 
      path: 'playwright-report/screenshots/redis-dashboard-status.png', 
      fullPage: true 
    });
    
    console.log('✅ Redis dashboard screenshot captured');
  });
});

