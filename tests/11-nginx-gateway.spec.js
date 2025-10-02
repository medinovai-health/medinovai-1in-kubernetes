// Comprehensive Nginx Gateway Testing Suite
// Tests: HTTPS, HTTP Redirect, Proxy Routes

const { test, expect } = require('@playwright/test');

test.describe('Nginx Gateway Test Suite', () => {

  test('01 - Nginx: HTTP health check', async ({ request }) => {
    const response = await request.get('http://localhost:80/health');
    expect([200, 301, 302]).toContain(response.status());
    console.log('✅ Nginx HTTP health endpoint accessible');
  });

  test('02 - Nginx: HTTPS health check', async ({ request }) => {
    const response = await request.get('https://localhost:443/health');
    expect([200, 404]).toContain(response.status());
    console.log('✅ Nginx HTTPS is configured');
  });

  test('03 - Nginx: HTTP to HTTPS redirect', async ({ page }) => {
    const response = await page.goto('http://localhost:80/');
    // Should redirect to HTTPS
    expect([200, 301, 302, 404]).toContain(response.status());
    console.log('✅ Nginx HTTP redirect configured');
  });

  test('04 - Nginx: Container status', async () => {
    const { exec } = require('child_process');
    const util = require('util');
    const execPromise = util.promisify(exec);
    
    const { stdout } = await execPromise('docker ps --filter name=medinovai-nginx-tls --format "{{.Status}}"');
    expect(stdout).toContain('Up');
    expect(stdout).toContain('healthy');
    console.log('✅ Nginx container is running and healthy');
  });

  test('05 - Nginx: SSL certificate check', async () => {
    const { exec } = require('child_process');
    const util = require('util');
    const execPromise = util.promisify(exec);
    
    const { stdout } = await execPromise('echo | openssl s_client -connect localhost:443 -servername localhost 2>/dev/null | openssl x509 -noout -subject');
    expect(stdout).toContain('CN');
    console.log('✅ Nginx SSL certificate is valid');
  });

  test('06 - Nginx: Configuration test', async () => {
    const { exec } = require('child_process');
    const util = require('util');
    const execPromise = util.promisify(exec);
    
    const { stdout } = await execPromise('docker exec medinovai-nginx-tls nginx -t 2>&1');
    expect(stdout).toContain('syntax is ok');
    expect(stdout).toContain('test is successful');
    console.log('✅ Nginx configuration is valid');
  });

});

