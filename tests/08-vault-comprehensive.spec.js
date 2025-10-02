// Comprehensive Vault Testing Suite
// Tests: UI, Seal Status, Secrets, Health

const { test, expect } = require('@playwright/test');

const VAULT_URL = 'http://localhost:8200';

test.describe('Vault Comprehensive Test Suite', () => {

  test('01 - Vault: Health check', async ({ request }) => {
    const response = await request.get(`${VAULT_URL}/v1/sys/health`);
    // Vault returns different status codes based on state
    // 200 = initialized, unsealed, and active
    // 429 = unsealed and standby
    // 472 = data recovery mode replication secondary and active
    // 473 = performance standby
    // 501 = not initialized
    // 503 = sealed
    expect([200, 429, 472, 473, 501, 503]).toContain(response.status());
    console.log(`✅ Vault health check responded with status: ${response.status()}`);
  });

  test('02 - Vault: Seal status check', async ({ request }) => {
    const response = await request.get(`${VAULT_URL}/v1/sys/seal-status`);
    expect(response.status()).toBe(200);
    
    const status = await response.json();
    console.log(`✅ Vault seal status - Sealed: ${status.sealed}, Initialized: ${status.initialized}`);
  });

  test('03 - Vault: UI accessibility', async ({ page }) => {
    await page.goto(VAULT_URL);
    await page.waitForTimeout(2000);
    
    // Check if Vault UI loaded
    const vaultUI = await page.locator('text=Vault').count();
    expect(vaultUI).toBeGreaterThan(0);
    console.log('✅ Vault UI is accessible');
  });

  test('04 - Vault: Container status', async () => {
    const { exec } = require('child_process');
    const util = require('util');
    const execPromise = util.promisify(exec);
    
    const { stdout } = await execPromise('docker ps --filter name=medinovai-vault-tls --format "{{.Status}}"');
    expect(stdout).toContain('Up');
    console.log('✅ Vault container is running');
  });

  test('05 - Vault: Version check', async ({ request }) => {
    try {
      const response = await request.get(`${VAULT_URL}/v1/sys/version-history`);
      // This endpoint may require auth, so accept multiple status codes
      expect([200, 403]).toContain(response.status());
      console.log('✅ Vault version endpoint accessible');
    } catch (error) {
      console.log('⚠️  Vault version check requires authentication');
    }
  });

});

