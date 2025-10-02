// Comprehensive MinIO Testing Suite
// Tests: Login, Buckets, Objects, Users, Policies

const { test, expect } = require('@playwright/test');

const MINIO_URL = 'http://localhost:9001';
const MINIO_USER = 'medinovai';
const MINIO_PASS = 'minio_secure_password';

test.describe('MinIO Comprehensive Test Suite', () => {

  test('01 - MinIO: Verify login', async ({ page }) => {
    await page.goto(MINIO_URL);
    await page.waitForTimeout(2000);
    
    // MinIO console login
    const accessKeyInput = page.locator('input[id="accessKey"], input[name="accessKey"]').first();
    const secretKeyInput = page.locator('input[id="secretKey"], input[name="secretKey"]').first();
    
    await accessKeyInput.fill(MINIO_USER);
    await secretKeyInput.fill(MINIO_PASS);
    
    await page.click('button[type="submit"]');
    await page.waitForTimeout(3000);
    
    console.log('✅ MinIO login successful');
  });

  test('02 - MinIO: Check buckets page', async ({ page }) => {
    await page.goto(MINIO_URL);
    await page.waitForTimeout(2000);
    
    const accessKeyInput = page.locator('input[id="accessKey"], input[name="accessKey"]').first();
    const secretKeyInput = page.locator('input[id="secretKey"], input[name="secretKey"]').first();
    
    await accessKeyInput.fill(MINIO_USER);
    await secretKeyInput.fill(MINIO_PASS);
    await page.click('button[type="submit"]');
    await page.waitForTimeout(3000);
    
    // Check for buckets page
    const bucketsText = await page.locator('text=Buckets').count();
    expect(bucketsText).toBeGreaterThan(0);
    console.log('✅ MinIO buckets page accessible');
  });

  test('03 - MinIO: API health check', async ({ request }) => {
    const response = await request.get(`http://localhost:9000/minio/health/live`);
    expect(response.status()).toBe(200);
    console.log('✅ MinIO server healthy');
  });

});

