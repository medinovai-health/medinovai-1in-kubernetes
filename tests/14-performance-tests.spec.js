// Comprehensive Performance Testing Suite
// Tests: Response Times, Resource Usage, Latency

const { test, expect } = require('@playwright/test');
const { exec } = require('child_process');
const util = require('util');
const execPromise = util.promisify(exec);

test.describe('Performance Test Suite', () => {

  test('01 - Grafana: Response time check', async ({ page }) => {
    const start = Date.now();
    await page.goto('http://localhost:3000', { timeout: 10000 });
    const duration = Date.now() - start;
    
    expect(duration).toBeLessThan(5000); // Should load in under 5 seconds
    console.log(`✅ Grafana loaded in ${duration}ms`);
  });

  test('02 - Prometheus: API response time', async ({ request }) => {
    const start = Date.now();
    await request.get('http://localhost:9090/-/healthy');
    const duration = Date.now() - start;
    
    expect(duration).toBeLessThan(1000); // Should respond in under 1 second
    console.log(`✅ Prometheus API responded in ${duration}ms`);
  });

  test('03 - Database: Connection time', async () => {
    const start = Date.now();
    await execPromise('docker exec medinovai-postgres-tls psql -U medinovai -c "SELECT 1;"');
    const duration = Date.now() - start;
    
    expect(duration).toBeLessThan(2000); // Should connect in under 2 seconds
    console.log(`✅ PostgreSQL connection took ${duration}ms`);
  });

  test('04 - Docker: Resource usage check', async () => {
    const { stdout } = await execPromise('docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | head -5');
    expect(stdout).toContain('medinovai');
    console.log('✅ Docker resource usage accessible');
  });

  test('05 - System: Overall health', async () => {
    // Count running medinovai containers
    const { stdout } = await execPromise('docker ps --filter name=medinovai | wc -l');
    const containerCount = parseInt(stdout.trim());
    
    expect(containerCount).toBeGreaterThan(10); // Should have at least 10 containers
    console.log(`✅ System health check: ${containerCount} containers running`);
  });

});

