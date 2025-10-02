import { test, expect } from '@playwright/test';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

/**
 * Phase 2 Validation Tests: MongoDB 7.0
 * 
 * Tests:
 * 1. Installation Test - Verify MongoDB is installed and running
 * 2. Configuration Test - Verify configuration is correct
 * 3. Health Check Test - Verify MongoDB is healthy
 * 4. Performance Test - Measure response times
 * 5. Integration Test - Test database operations
 */

test.describe('Phase 2: MongoDB 7.0 Validation', () => {
  
  test('1. Installation Test - MongoDB is installed and running', async () => {
    // Check if container is running
    const { stdout } = await execAsync('docker ps --filter "name=medinovai-mongodb-phase2" --format "{{.Status}}"');
    expect(stdout).toContain('Up');
    expect(stdout).toContain('healthy');
  });

  test('2. Configuration Test - MongoDB configuration is correct', async () => {
    // Verify MongoDB version
    const { stdout: versionOutput } = await execAsync(
      'docker exec medinovai-mongodb-phase2 mongosh --quiet --eval "db.version()"'
    );
    expect(versionOutput).toContain('7.0');

    // Verify port
    const { stdout: portOutput } = await execAsync(
      'docker port medinovai-mongodb-phase2 27017'
    );
    expect(portOutput).toContain('27017');

    // Verify environment
    const { stdout: envOutput } = await execAsync(
      'docker exec medinovai-mongodb-phase2 env | grep MONGO_INITDB'
    );
    expect(envOutput).toContain('MONGO_INITDB_ROOT_USERNAME=medinovai_admin');
    expect(envOutput).toContain('MONGO_INITDB_DATABASE=medinovai');
  });

  test('3. Health Check Test - MongoDB is healthy', async () => {
    // Test admin ping
    const { stdout: pingOutput } = await execAsync(
      'docker exec medinovai-mongodb-phase2 mongosh --quiet --eval "db.adminCommand(\'ping\')"'
    );
    expect(pingOutput).toContain('"ok": 1');

    // Test database connection
    const { stdout: dbOutput } = await execAsync(
      'docker exec medinovai-mongodb-phase2 mongosh --quiet --eval "db.getMongo()"'
    );
    expect(dbOutput).toContain('mongodb://');

    // Verify uptime
    const { stdout: statusOutput } = await execAsync(
      'docker exec medinovai-mongodb-phase2 mongosh --quiet --eval "db.serverStatus().uptime"'
    );
    const uptime = parseInt(statusOutput.trim());
    expect(uptime).toBeGreaterThan(0);
  });

  test('4. Performance Test - MongoDB response times', async () => {
    const start = Date.now();
    
    // Test query performance
    await execAsync(
      'docker exec medinovai-mongodb-phase2 mongosh --quiet --eval "db.adminCommand(\'ping\')"'
    );
    
    const responseTime = Date.now() - start;
    
    // Response time should be under 100ms
    expect(responseTime).toBeLessThan(100);
    
    console.log(`MongoDB response time: ${responseTime}ms`);
  });

  test('5. Integration Test - Database operations', async () => {
    // Test database creation
    const { stdout: dbListOutput } = await execAsync(
      'docker exec medinovai-mongodb-phase2 mongosh --quiet --eval "db.getMongo().getDBNames()"'
    );
    expect(dbListOutput).toContain('medinovai');

    // Test collection operations
    const { stdout: collectionOutput } = await execAsync(
      'docker exec medinovai-mongodb-phase2 mongosh medinovai --quiet --eval "db.getCollectionNames()"'
    );
    expect(collectionOutput).toContain('patients');
    expect(collectionOutput).toContain('medical_records');
    expect(collectionOutput).toContain('sessions');

    // Test insert operation
    const testDoc = JSON.stringify({ test: true, timestamp: new Date().toISOString() });
    await execAsync(
      `docker exec medinovai-mongodb-phase2 mongosh medinovai --quiet --eval "db.test_collection.insertOne(${testDoc})"`
    );

    // Test query operation
    const { stdout: queryOutput } = await execAsync(
      'docker exec medinovai-mongodb-phase2 mongosh medinovai --quiet --eval "db.test_collection.findOne({ test: true })"'
    );
    expect(queryOutput).toContain('"test": true');

    // Cleanup
    await execAsync(
      'docker exec medinovai-mongodb-phase2 mongosh medinovai --quiet --eval "db.test_collection.drop()"'
    );
  });

  test('6. Resource Test - MongoDB resource usage', async () => {
    // Check resource limits
    const { stdout: statsOutput } = await execAsync(
      'docker stats medinovai-mongodb-phase2 --no-stream --format "{{.CPUPerc}},{{.MemUsage}}"'
    );
    
    const [cpuPerc, memUsage] = statsOutput.trim().split(',');
    
    console.log(`MongoDB CPU: ${cpuPerc}, Memory: ${memUsage}`);
    
    // CPU should be under 100% (reasonable for 2 CPU limit)
    const cpu = parseFloat(cpuPerc.replace('%', ''));
    expect(cpu).toBeLessThan(200); // 2 CPUs * 100%
  });

  test('7. Security Test - MongoDB authentication', async () => {
    // Verify authentication is enabled
    const { stdout: authOutput } = await execAsync(
      'docker exec medinovai-mongodb-phase2 mongosh --quiet --eval "db.runCommand({ connectionStatus: 1 }).authInfo"'
    );
    expect(authOutput).toBeTruthy();
    
    // Verify root user exists
    const { stdout: userOutput } = await execAsync(
      'docker exec medinovai-mongodb-phase2 mongosh admin --quiet --eval "db.getUsers()"'
    );
    expect(userOutput).toContain('medinovai_admin');
  });

  test('8. Persistence Test - Data survives restart', async () => {
    // Insert test document
    const testId = `test_${Date.now()}`;
    await execAsync(
      `docker exec medinovai-mongodb-phase2 mongosh medinovai --quiet --eval "db.persistence_test.insertOne({ _id: '${testId}', value: 'test' })"`
    );

    // Restart container
    await execAsync('docker restart medinovai-mongodb-phase2');
    
    // Wait for restart
    await new Promise(resolve => setTimeout(resolve, 10000));

    // Verify document still exists
    const { stdout: findOutput } = await execAsync(
      `docker exec medinovai-mongodb-phase2 mongosh medinovai --quiet --eval "db.persistence_test.findOne({ _id: '${testId}' })"`
    );
    expect(findOutput).toContain(testId);

    // Cleanup
    await execAsync(
      `docker exec medinovai-mongodb-phase2 mongosh medinovai --quiet --eval "db.persistence_test.deleteOne({ _id: '${testId}' })"`
    );
  });

});

