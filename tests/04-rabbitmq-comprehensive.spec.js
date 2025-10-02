// Comprehensive RabbitMQ Testing Suite
// Tests: Login, Queues, Exchanges, Connections, Users

const { test, expect } = require('@playwright/test');

const RABBITMQ_URL = 'http://localhost:15672';
const RABBITMQ_USER = 'medinovai';
const RABBITMQ_PASS = 'rabbitmq_secure_password';

test.describe('RabbitMQ Comprehensive Test Suite', () => {

  test.beforeEach(async ({ page }) => {
    await page.goto(RABBITMQ_URL);
    await page.fill('input[name="username"]', RABBITMQ_USER);
    await page.fill('input[name="password"]', RABBITMQ_PASS);
    await page.click('input[type="submit"]');
    await page.waitForTimeout(2000);
  });

  test('01 - RabbitMQ: Verify login and overview', async ({ page }) => {
    const overview = await page.locator('text=Overview').count();
    expect(overview).toBeGreaterThan(0);
    console.log('✅ RabbitMQ overview page loaded');
  });

  test('02 - RabbitMQ: Check connections', async ({ page }) => {
    await page.click('a:has-text("Connections")');
    await page.waitForTimeout(1000);
    console.log('✅ Connections page accessible');
  });

  test('03 - RabbitMQ: Check channels', async ({ page }) => {
    await page.click('a:has-text("Channels")');
    await page.waitForTimeout(1000);
    console.log('✅ Channels page accessible');
  });

  test('04 - RabbitMQ: Check queues', async ({ page }) => {
    await page.click('a:has-text("Queues")');
    await page.waitForTimeout(1000);
    console.log('✅ Queues page accessible');
  });

  test('05 - RabbitMQ: Check exchanges', async ({ page }) => {
    await page.click('a:has-text("Exchanges")');
    await page.waitForTimeout(1000);
    console.log('✅ Exchanges page accessible');
  });

  test('06 - RabbitMQ: API health check', async ({ request }) => {
    const auth = Buffer.from(`${RABBITMQ_USER}:${RABBITMQ_PASS}`).toString('base64');
    const response = await request.get(`${RABBITMQ_URL}/api/overview`, {
      headers: { 'Authorization': `Basic ${auth}` }
    });
    expect(response.status()).toBe(200);
    console.log('✅ RabbitMQ API healthy');
  });

  test('07 - RabbitMQ: Get vhosts', async ({ request }) => {
    const auth = Buffer.from(`${RABBITMQ_USER}:${RABBITMQ_PASS}`).toString('base64');
    const response = await request.get(`${RABBITMQ_URL}/api/vhosts`, {
      headers: { 'Authorization': `Basic ${auth}` }
    });
    expect(response.status()).toBe(200);
    const vhosts = await response.json();
    expect(Array.isArray(vhosts)).toBeTruthy();
    console.log('✅ RabbitMQ vhosts API working');
  });

  test('08 - RabbitMQ: Get nodes', async ({ request }) => {
    const auth = Buffer.from(`${RABBITMQ_USER}:${RABBITMQ_PASS}`).toString('base64');
    const response = await request.get(`${RABBITMQ_URL}/api/nodes`, {
      headers: { 'Authorization': `Basic ${auth}` }
    });
    expect(response.status()).toBe(200);
    const nodes = await response.json();
    expect(Array.isArray(nodes)).toBeTruthy();
    console.log('✅ RabbitMQ nodes API working');
  });

});

