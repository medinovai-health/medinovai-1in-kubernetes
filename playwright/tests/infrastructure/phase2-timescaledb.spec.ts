import { test, expect } from '@playwright/test';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

/**
 * Phase 2 Validation Tests: TimescaleDB latest-pg15
 * 
 * Tests:
 * 1. Installation Test
 * 2. Configuration Test
 * 3. Health Check Test
 * 4. Performance Test
 * 5. Integration Test
 * 6. TimescaleDB Extension Test
 */

test.describe('Phase 2: TimescaleDB Validation', () => {
  
  test('1. Installation Test - TimescaleDB is running', async () => {
    const { stdout } = await execAsync('docker ps --filter "name=medinovai-timescaledb-phase2" --format "{{.Status}}"');
    expect(stdout).toContain('Up');
    expect(stdout).toContain('healthy');
  });

  test('2. Configuration Test - TimescaleDB configuration', async () => {
    // Verify PostgreSQL version
    const { stdout: versionOutput } = await execAsync(
      'docker exec medinovai-timescaledb-phase2 psql -U medinovai_admin -d medinovai_timeseries -t -c "SELECT version();"'
    );
    expect(versionOutput).toContain('PostgreSQL 15');

    // Verify port
    const { stdout: portOutput } = await execAsync(
      'docker port medinovai-timescaledb-phase2 5432'
    );
    expect(portOutput).toContain('5433');
  });

  test('3. Health Check Test - Database is healthy', async () => {
    // Test pg_isready
    const { stdout: readyOutput } = await execAsync(
      'docker exec medinovai-timescaledb-phase2 pg_isready -U medinovai_admin'
    );
    expect(readyOutput).toContain('accepting connections');

    // Test database connection
    const { stdout: dbOutput } = await execAsync(
      'docker exec medinovai-timescaledb-phase2 psql -U medinovai_admin -d medinovai_timeseries -t -c "SELECT 1;"'
    );
    expect(dbOutput.trim()).toBe('1');
  });

  test('4. TimescaleDB Extension Test - Extension is installed', async () => {
    // Check TimescaleDB extension
    const { stdout: extOutput } = await execAsync(
      'docker exec medinovai-timescaledb-phase2 psql -U medinovai_admin -d medinovai_timeseries -t -c "SELECT extname FROM pg_extension WHERE extname = \'timescaledb\';"'
    );
    expect(extOutput.trim()).toBe('timescaledb');

    // Check TimescaleDB version
    const { stdout: versionOutput } = await execAsync(
      'docker exec medinovai-timescaledb-phase2 psql -U medinovai_admin -d medinovai_timeseries -t -c "SELECT extversion FROM pg_extension WHERE extname = \'timescaledb\';"'
    );
    expect(versionOutput.trim()).toMatch(/^\d+\.\d+\.\d+$/);
  });

  test('5. Performance Test - Query response times', async () => {
    const start = Date.now();
    
    await execAsync(
      'docker exec medinovai-timescaledb-phase2 psql -U medinovai_admin -d medinovai_timeseries -t -c "SELECT 1;"'
    );
    
    const responseTime = Date.now() - start;
    expect(responseTime).toBeLessThan(100);
    
    console.log(`TimescaleDB response time: ${responseTime}ms`);
  });

  test('6. Integration Test - Hypertable operations', async () => {
    // Create test table
    await execAsync(
      'docker exec medinovai-timescaledb-phase2 psql -U medinovai_admin -d medinovai_timeseries -c "CREATE TABLE IF NOT EXISTS test_metrics (time TIMESTAMPTZ NOT NULL, value DOUBLE PRECISION);"'
    );

    // Convert to hypertable
    await execAsync(
      'docker exec medinovai-timescaledb-phase2 psql -U medinovai_admin -d medinovai_timeseries -c "SELECT create_hypertable(\'test_metrics\', \'time\', if_not_exists => TRUE);"'
    );

    // Insert test data
    await execAsync(
      'docker exec medinovai-timescaledb-phase2 psql -U medinovai_admin -d medinovai_timeseries -c "INSERT INTO test_metrics VALUES (NOW(), 42.0);"'
    );

    // Query data
    const { stdout: queryOutput } = await execAsync(
      'docker exec medinovai-timescaledb-phase2 psql -U medinovai_admin -d medinovai_timeseries -t -c "SELECT value FROM test_metrics LIMIT 1;"'
    );
    expect(queryOutput.trim()).toBe('42');

    // Cleanup
    await execAsync(
      'docker exec medinovai-timescaledb-phase2 psql -U medinovai_admin -d medinovai_timeseries -c "DROP TABLE test_metrics;"'
    );
  });

  test('7. Resource Test - Resource usage', async () => {
    const { stdout: statsOutput } = await execAsync(
      'docker stats medinovai-timescaledb-phase2 --no-stream --format "{{.CPUPerc}},{{.MemUsage}}"'
    );
    
    const [cpuPerc, memUsage] = statsOutput.trim().split(',');
    console.log(`TimescaleDB CPU: ${cpuPerc}, Memory: ${memUsage}`);
    
    const cpu = parseFloat(cpuPerc.replace('%', ''));
    expect(cpu).toBeLessThan(200);
  });

  test('8. Persistence Test - Data survives restart', async () => {
    // Create test table and insert data
    const testValue = Math.random();
    await execAsync(
      `docker exec medinovai-timescaledb-phase2 psql -U medinovai_admin -d medinovai_timeseries -c "CREATE TABLE IF NOT EXISTS persistence_test (id SERIAL PRIMARY KEY, value DOUBLE PRECISION); INSERT INTO persistence_test (value) VALUES (${testValue});"`
    );

    // Restart container
    await execAsync('docker restart medinovai-timescaledb-phase2');
    await new Promise(resolve => setTimeout(resolve, 10000));

    // Verify data exists
    const { stdout: queryOutput } = await execAsync(
      'docker exec medinovai-timescaledb-phase2 psql -U medinovai_admin -d medinovai_timeseries -t -c "SELECT value FROM persistence_test LIMIT 1;"'
    );
    expect(parseFloat(queryOutput.trim())).toBeCloseTo(testValue, 5);

    // Cleanup
    await execAsync(
      'docker exec medinovai-timescaledb-phase2 psql -U medinovai_admin -d medinovai_timeseries -c "DROP TABLE persistence_test;"'
    );
  });

});

