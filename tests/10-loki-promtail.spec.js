// Comprehensive Loki & Promtail Testing Suite
// Tests: Health, Log Ingestion, Query API

const { test, expect } = require('@playwright/test');

const LOKI_URL = 'http://localhost:3100';

test.describe('Loki & Promtail Test Suite', () => {

  test('01 - Loki: Health check', async ({ request }) => {
    const response = await request.get(`${LOKI_URL}/ready`);
    expect(response.status()).toBe(200);
    console.log('✅ Loki is ready');
  });

  test('02 - Loki: Metrics endpoint', async ({ request }) => {
    const response = await request.get(`${LOKI_URL}/metrics`);
    expect(response.status()).toBe(200);
    
    const metrics = await response.text();
    expect(metrics).toContain('loki_');
    console.log('✅ Loki metrics endpoint working');
  });

  test('03 - Loki: Query API', async ({ request }) => {
    const response = await request.get(`${LOKI_URL}/loki/api/v1/labels`);
    expect(response.status()).toBe(200);
    
    const body = await response.json();
    expect(body.status).toBe('success');
    console.log('✅ Loki query API working');
  });

  test('04 - Promtail: Container status', async () => {
    const { exec } = require('child_process');
    const util = require('util');
    const execPromise = util.promisify(exec);
    
    const { stdout } = await execPromise('docker ps --filter name=medinovai-promtail-tls --format "{{.Status}}"');
    expect(stdout).toContain('Up');
    console.log('✅ Promtail container is running');
  });

  test('05 - Loki: Log query test', async ({ request }) => {
    // Query for any logs
    const query = encodeURIComponent('{job=~".+"}');
    const response = await request.get(`${LOKI_URL}/loki/api/v1/query?query=${query}&limit=1`);
    expect(response.status()).toBe(200);
    
    const body = await response.json();
    expect(body.status).toBe('success');
    console.log('✅ Loki log queries working');
  });

});

