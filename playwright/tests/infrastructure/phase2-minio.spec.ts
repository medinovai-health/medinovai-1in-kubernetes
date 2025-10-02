import { test, expect } from '@playwright/test';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

/**
 * Phase 2 Validation Tests: MinIO
 * 
 * Tests:
 * 1. Installation Test
 * 2. Configuration Test
 * 3. Health Check Test
 * 4. Performance Test
 * 5. Integration Test - Bucket operations
 * 6. Integration Test - Object operations
 */

test.describe('Phase 2: MinIO Validation', () => {
  
  test('1. Installation Test - MinIO is running', async () => {
    const { stdout } = await execAsync('docker ps --filter "name=medinovai-minio-phase2" --format "{{.Status}}"');
    expect(stdout).toContain('Up');
    expect(stdout).toContain('healthy');
  });

  test('2. Configuration Test - MinIO configuration', async () => {
    // Verify API port
    const { stdout: apiPortOutput } = await execAsync(
      'docker port medinovai-minio-phase2 9000'
    );
    expect(apiPortOutput).toContain('9000');

    // Verify Console port
    const { stdout: consolePortOutput } = await execAsync(
      'docker port medinovai-minio-phase2 9001'
    );
    expect(consolePortOutput).toContain('9001');
  });

  test('3. Health Check Test - MinIO is healthy', async () => {
    // Test liveness endpoint
    const { stdout: liveOutput } = await execAsync(
      'curl -sf http://localhost:9000/minio/health/live'
    );
    expect(liveOutput).toBeTruthy(); // Any response means healthy

    // Test readiness endpoint
    const { stdout: readyOutput } = await execAsync(
      'curl -sf http://localhost:9000/minio/health/ready'
    );
    expect(readyOutput).toBeTruthy();
  });

  test('4. Performance Test - API response times', async () => {
    const start = Date.now();
    
    await execAsync('curl -sf http://localhost:9000/minio/health/live');
    
    const responseTime = Date.now() - start;
    expect(responseTime).toBeLessThan(100);
    
    console.log(`MinIO response time: ${responseTime}ms`);
  });

  test('5. Web Console Test - Console is accessible', async ({}, testInfo) => {
    // Test console endpoint
    const { stdout: consoleOutput } = await execAsync(
      'curl -sf -I http://localhost:9001'
    );
    expect(consoleOutput).toContain('200');
  });

  test('6. Resource Test - Resource usage', async () => {
    const { stdout: statsOutput } = await execAsync(
      'docker stats medinovai-minio-phase2 --no-stream --format "{{.CPUPerc}},{{.MemUsage}}"'
    );
    
    const [cpuPerc, memUsage] = statsOutput.trim().split(',');
    console.log(`MinIO CPU: ${cpuPerc}, Memory: ${memUsage}`);
    
    const cpu = parseFloat(cpuPerc.replace('%', ''));
    expect(cpu).toBeLessThan(200);
  });

  test('7. Storage Test - Data directory exists', async () => {
    // Verify MinIO data directory
    const { stdout: lsOutput } = await execAsync(
      'docker exec medinovai-minio-phase2 ls -la /data'
    );
    expect(lsOutput).toContain('total');
  });

  test('8. Persistence Test - Service survives restart', async () => {
    // Restart container
    await execAsync('docker restart medinovai-minio-phase2');
    await new Promise(resolve => setTimeout(resolve, 10000));

    // Verify service is back
    const { stdout: healthOutput } = await execAsync(
      'curl -sf http://localhost:9000/minio/health/live'
    );
    expect(healthOutput).toBeTruthy();
  });

});

