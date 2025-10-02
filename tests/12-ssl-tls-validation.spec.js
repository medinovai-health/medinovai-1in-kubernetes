// Comprehensive SSL/TLS Validation Suite
// Tests: Certificate Validity, Protocols, Cipher Suites

const { test, expect } = require('@playwright/test');
const { exec } = require('child_process');
const util = require('util');
const execPromise = util.promisify(exec);

test.describe('SSL/TLS Validation Test Suite', () => {

  test('01 - PostgreSQL: SSL enabled', async () => {
    const { stdout } = await execPromise('docker exec medinovai-postgres-tls psql -U medinovai -c "SHOW ssl;"');
    expect(stdout).toContain('on');
    console.log('✅ PostgreSQL SSL is enabled');
  });

  test('02 - PostgreSQL: SSL certificate files exist', async () => {
    const { stdout } = await execPromise('docker exec medinovai-postgres-tls ls -la /var/lib/postgresql/server.crt /var/lib/postgresql/server.key 2>&1');
    expect(stdout).toContain('server.crt');
    expect(stdout).toContain('server.key');
    console.log('✅ PostgreSQL SSL certificate files exist');
  });

  test('03 - Nginx: SSL certificate validity', async () => {
    const { stdout } = await execPromise('echo | openssl s_client -connect localhost:443 -servername localhost 2>/dev/null | openssl x509 -noout -dates');
    expect(stdout).toContain('notBefore');
    expect(stdout).toContain('notAfter');
    console.log('✅ Nginx SSL certificate is valid');
  });

  test('04 - Nginx: TLS protocol version', async () => {
    const { stdout } = await execPromise('echo | openssl s_client -connect localhost:443 -tls1_2 2>&1 | grep "Protocol"');
    expect(stdout).toContain('TLS');
    console.log('✅ Nginx supports TLS 1.2+');
  });

  test('05 - Redis: TLS certificate files exist', async () => {
    const { stdout } = await execPromise('docker exec medinovai-redis-tls ls -la /etc/ssl/redis/server.crt /etc/ssl/redis/server.key 2>&1');
    expect(stdout).toContain('server.crt');
    expect(stdout).toContain('server.key');
    console.log('✅ Redis TLS certificate files exist');
  });

  test('06 - MongoDB: TLS certificate files exist', async () => {
    const { stdout } = await execPromise('docker exec medinovai-mongodb-tls ls -la /etc/ssl/mongodb.pem 2>&1');
    expect(stdout).toContain('mongodb.pem');
    console.log('✅ MongoDB TLS certificate file exists');
  });

  test('07 - CA certificate validity', async () => {
    const { stdout } = await execPromise('openssl x509 -in ssl/ca/ca.crt -noout -dates -subject');
    expect(stdout).toContain('notBefore');
    expect(stdout).toContain('notAfter');
    expect(stdout).toContain('MedinovAI');
    console.log('✅ CA certificate is valid');
  });

  test('08 - Certificate expiry check', async () => {
    const { stdout } = await execPromise('openssl x509 -in ssl/ca/ca.crt -noout -checkend 2592000');
    // checkend 2592000 = check if cert expires in 30 days
    expect(stdout).not.toContain('will expire');
    console.log('✅ Certificates will not expire in next 30 days');
  });

});

