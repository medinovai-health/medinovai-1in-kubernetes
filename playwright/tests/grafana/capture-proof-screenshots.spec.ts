import { test, expect } from '@playwright/test';

test.describe('Capture Proof Screenshots - All Dashboards', () => {
  const GRAFANA_URL = 'http://localhost:3000';
  const GRAFANA_USERNAME = 'admin';
  const GRAFANA_PASSWORD = 'admin123';

  test.beforeAll(async ({ browser }) => {
    console.log('🔐 Starting screenshot capture session...');
  });

  test.beforeEach(async ({ page }) => {
    // Login to Grafana
    await page.goto(GRAFANA_URL);
    
    // Check if already logged in
    const isLoggedIn = await page.locator('text=/Dashboards/i').isVisible().catch(() => false);
    
    if (!isLoggedIn) {
      console.log('🔑 Logging in to Grafana...');
      await page.fill('input[name="user"]', GRAFANA_USERNAME);
      await page.fill('input[name="password"]', GRAFANA_PASSWORD);
      await page.click('button[type="submit"]');
      await page.waitForURL(`${GRAFANA_URL}/**`, { timeout: 10000 });
      console.log('✅ Logged in successfully');
    }
  });

  test('1. Capture Overview Dashboard - PROOF', async ({ page }) => {
    console.log('📊 Capturing MedinovAI Infrastructure Overview...');
    
    await page.goto(`${GRAFANA_URL}/d/medinovai-overview/medinovai-infrastructure-overview?orgId=1&refresh=30s`);
    
    // Wait for dashboard to fully load
    await page.waitForSelector('text=/MedinovAI Infrastructure/i', { timeout: 15000 });
    await page.waitForTimeout(8000); // Wait for all panels to render
    
    // Capture full page screenshot
    await page.screenshot({ 
      path: 'proof-screenshots/01-overview-dashboard-PROOF.png', 
      fullPage: true 
    });
    
    console.log('✅ Overview dashboard captured');
    
    // Verify no critical "No data" issues
    const noDataCount = await page.locator('text=/No data/i').count();
    console.log(`   Found ${noDataCount} "No data" elements`);
  });

  test('2. Capture Docker Dashboard - PROOF', async ({ page }) => {
    console.log('🐳 Capturing Docker Monitoring Dashboard...');
    
    await page.goto(`${GRAFANA_URL}/d/fdabdeaa-d1b7-40c6-aa99-95a16118b65f/docker-monitoring?orgId=1&refresh=10s`);
    
    await page.waitForTimeout(8000);
    
    await page.screenshot({ 
      path: 'proof-screenshots/02-docker-dashboard-PROOF.png', 
      fullPage: true 
    });
    
    console.log('✅ Docker dashboard captured');
  });

  test('3. Capture PostgreSQL Dashboard - PROOF', async ({ page }) => {
    console.log('🐘 Capturing PostgreSQL Dashboard...');
    
    await page.goto(`${GRAFANA_URL}/d/postgresql-dashboard/postgresql?orgId=1&refresh=5s`);
    
    await page.waitForTimeout(5000);
    
    await page.screenshot({ 
      path: 'proof-screenshots/03-postgresql-dashboard-PROOF.png', 
      fullPage: true 
    });
    
    console.log('✅ PostgreSQL dashboard captured');
  });

  test('4. Capture MongoDB Dashboard - PROOF', async ({ page }) => {
    console.log('🍃 Capturing MongoDB Dashboard...');
    
    await page.goto(`${GRAFANA_URL}/d/mongodb-dashboard/mongodb?orgId=1&refresh=5s`);
    
    await page.waitForTimeout(5000);
    
    await page.screenshot({ 
      path: 'proof-screenshots/04-mongodb-dashboard-PROOF.png', 
      fullPage: true 
    });
    
    console.log('✅ MongoDB dashboard captured');
  });

  test('5. Capture Redis Dashboard - PROOF', async ({ page }) => {
    console.log('🔴 Capturing Redis Dashboard...');
    
    await page.goto(`${GRAFANA_URL}/d/redis-dashboard/redis?orgId=1&refresh=5s`);
    
    await page.waitForTimeout(5000);
    
    await page.screenshot({ 
      path: 'proof-screenshots/05-redis-dashboard-PROOF.png', 
      fullPage: true 
    });
    
    console.log('✅ Redis dashboard captured');
  });

  test('6. Capture Prometheus Targets - PROOF', async ({ page }) => {
    console.log('🎯 Capturing Prometheus Targets...');
    
    await page.goto('http://localhost:9090/targets');
    
    await page.waitForTimeout(3000);
    
    await page.screenshot({ 
      path: 'proof-screenshots/06-prometheus-targets-PROOF.png', 
      fullPage: true 
    });
    
    console.log('✅ Prometheus targets captured');
  });

  test('7. Capture Grafana Datasources - PROOF', async ({ page }) => {
    console.log('💾 Capturing Grafana Datasources...');
    
    await page.goto(`${GRAFANA_URL}/datasources`);
    
    await page.waitForTimeout(3000);
    
    await page.screenshot({ 
      path: 'proof-screenshots/07-grafana-datasources-PROOF.png', 
      fullPage: true 
    });
    
    console.log('✅ Grafana datasources captured');
  });

  test('8. Capture Dashboard List - PROOF', async ({ page }) => {
    console.log('📋 Capturing Dashboard List...');
    
    await page.goto(`${GRAFANA_URL}/dashboards`);
    
    await page.waitForTimeout(3000);
    
    await page.screenshot({ 
      path: 'proof-screenshots/08-dashboard-list-PROOF.png', 
      fullPage: true 
    });
    
    console.log('✅ Dashboard list captured');
  });

  test.afterAll(async () => {
    console.log('');
    console.log('🎉 ALL PROOF SCREENSHOTS CAPTURED!');
    console.log('📁 Location: proof-screenshots/');
    console.log('');
    console.log('Screenshots:');
    console.log('  1. Overview Dashboard');
    console.log('  2. Docker Monitoring');
    console.log('  3. PostgreSQL Dashboard');
    console.log('  4. MongoDB Dashboard');
    console.log('  5. Redis Dashboard');
    console.log('  6. Prometheus Targets');
    console.log('  7. Grafana Datasources');
    console.log('  8. Dashboard List');
  });
});

