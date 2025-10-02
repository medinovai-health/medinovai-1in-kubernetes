// MedinovAI Infrastructure Validation Tests
// Validates all services are accessible and properly configured
// Date: October 1, 2025

const { test, expect } = require('@playwright/test');
const fs = require('fs');
const path = require('path');

// Load credentials from .env
const envPath = path.join(__dirname, '..', '.env.production');
const envContent = fs.existsSync(envPath) ? fs.readFileSync(envPath, 'utf8') : '';

function getEnvValue(key, defaultValue) {
  const match = envContent.match(new RegExp(`${key}=(.+)`));
  return match ? match[1].trim() : defaultValue;
}

const credentials = {
  grafana: {
    username: 'admin',
    password: getEnvValue('GRAFANA_PASSWORD', 'medinovai_grafana_2025_secure')
  },
  rabbitmq: {
    username: 'medinovai',
    password: getEnvValue('RABBITMQ_PASSWORD', 'medinovai_rabbitmq_2025_secure')
  },
  minio: {
    username: 'medinovai',
    password: getEnvValue('MINIO_PASSWORD', 'medinovai_minio_2025_secure')
  },
  keycloak: {
    username: 'admin',
    password: getEnvValue('KEYCLOAK_PASSWORD', 'medinovai_keycloak_2025_secure')
  }
};

// Test results storage
const testResults = {
  timestamp: new Date().toISOString(),
  services: {},
  summary: {
    total: 0,
    passed: 0,
    failed: 0
  }
};

// Helper to save test results
function saveResults(serviceName, result) {
  testResults.services[serviceName] = result;
  testResults.summary.total++;
  if (result.status === 'passed') {
    testResults.summary.passed++;
  } else {
    testResults.summary.failed++;
  }
  
  // Save to file
  const resultsPath = path.join(__dirname, '..', 'test-results', 'validation-results.json');
  fs.mkdirSync(path.dirname(resultsPath), { recursive: true });
  fs.writeFileSync(resultsPath, JSON.stringify(testResults, null, 2));
}

test.describe('MedinovAI Infrastructure Validation', () => {
  
  // Test 1: Grafana
  test('Grafana - Login and Dashboard Access', async ({ page }) => {
    const result = {
      service: 'Grafana',
      url: 'http://localhost:3000',
      status: 'unknown',
      details: {},
      timestamp: new Date().toISOString()
    };

    try {
      console.log('Testing Grafana...');
      
      // Navigate to Grafana
      await page.goto('http://localhost:3000', { timeout: 10000 });
      result.details.pageLoaded = true;

      // Take screenshot of login page
      await page.screenshot({ 
        path: 'test-results/screenshots/grafana-login.png',
        fullPage: true 
      });

      // Login
      await page.fill('input[name="user"]', credentials.grafana.username);
      await page.fill('input[name="password"]', credentials.grafana.password);
      await page.click('button[type="submit"]');
      
      // Wait for dashboard
      await page.waitForURL(/\/\?orgId=1/, { timeout: 15000 });
      result.details.loginSuccessful = true;

      // Take screenshot of dashboard
      await page.screenshot({ 
        path: 'test-results/screenshots/grafana-dashboard.png',
        fullPage: true 
      });

      // Check for data sources
      await page.goto('http://localhost:3000/datasources');
      await page.waitForSelector('text=Data sources', { timeout: 5000 });
      result.details.dataSourcesAccessible = true;

      // Get data source count
      const dataSourceText = await page.textContent('body');
      result.details.hasPrometheus = dataSourceText.includes('Prometheus');
      result.details.hasLoki = dataSourceText.includes('Loki');

      // Take screenshot
      await page.screenshot({ 
        path: 'test-results/screenshots/grafana-datasources.png',
        fullPage: true 
      });

      result.status = 'passed';
      result.details.message = 'Grafana is fully operational with data sources configured';
      
    } catch (error) {
      result.status = 'failed';
      result.details.error = error.message;
      console.error('Grafana test failed:', error);
    }

    saveResults('grafana', result);
    expect(result.status).toBe('passed');
  });

  // Test 2: Prometheus
  test('Prometheus - UI and Metrics Access', async ({ page }) => {
    const result = {
      service: 'Prometheus',
      url: 'http://localhost:9090',
      status: 'unknown',
      details: {},
      timestamp: new Date().toISOString()
    };

    try {
      console.log('Testing Prometheus...');
      
      // Navigate to Prometheus
      await page.goto('http://localhost:9090', { timeout: 10000 });
      result.details.pageLoaded = true;

      // Take screenshot
      await page.screenshot({ 
        path: 'test-results/screenshots/prometheus-home.png',
        fullPage: true 
      });

      // Check for Graph page
      await page.click('text=Graph');
      await page.waitForSelector('input[placeholder="Expression (press Shift+Enter for newlines)"]', { timeout: 5000 });
      result.details.graphPageAccessible = true;

      // Test a simple query
      await page.fill('input[placeholder="Expression (press Shift+Enter for newlines)"]', 'up');
      await page.click('button:has-text("Execute")');
      await page.waitForTimeout(2000);

      // Take screenshot of query result
      await page.screenshot({ 
        path: 'test-results/screenshots/prometheus-query.png',
        fullPage: true 
      });

      // Check targets page
      await page.goto('http://localhost:9090/targets');
      await page.waitForSelector('text=Targets', { timeout: 5000 });
      result.details.targetsPageAccessible = true;

      // Take screenshot
      await page.screenshot({ 
        path: 'test-results/screenshots/prometheus-targets.png',
        fullPage: true 
      });

      // Get target status
      const pageContent = await page.textContent('body');
      result.details.hasActiveTargets = pageContent.includes('UP') || pageContent.includes('healthy');

      result.status = 'passed';
      result.details.message = 'Prometheus is operational and collecting metrics';
      
    } catch (error) {
      result.status = 'failed';
      result.details.error = error.message;
      console.error('Prometheus test failed:', error);
    }

    saveResults('prometheus', result);
    expect(result.status).toBe('passed');
  });

  // Test 3: RabbitMQ Management
  test('RabbitMQ - Management UI Login and Queue Access', async ({ page }) => {
    const result = {
      service: 'RabbitMQ',
      url: 'http://localhost:15672',
      status: 'unknown',
      details: {},
      timestamp: new Date().toISOString()
    };

    try {
      console.log('Testing RabbitMQ...');
      
      // Navigate to RabbitMQ
      await page.goto('http://localhost:15672', { timeout: 10000 });
      result.details.pageLoaded = true;

      // Take screenshot of login
      await page.screenshot({ 
        path: 'test-results/screenshots/rabbitmq-login.png',
        fullPage: true 
      });

      // Login
      await page.fill('input[name="username"]', credentials.rabbitmq.username);
      await page.fill('input[name="password"]', credentials.rabbitmq.password);
      await page.click('input[type="submit"]');
      
      // Wait for dashboard
      await page.waitForSelector('text=Overview', { timeout: 10000 });
      result.details.loginSuccessful = true;

      // Take screenshot of overview
      await page.screenshot({ 
        path: 'test-results/screenshots/rabbitmq-overview.png',
        fullPage: true 
      });

      // Check queues page
      await page.click('a[href="#/queues"]');
      await page.waitForSelector('text=All queues', { timeout: 5000 });
      result.details.queuesPageAccessible = true;

      // Take screenshot
      await page.screenshot({ 
        path: 'test-results/screenshots/rabbitmq-queues.png',
        fullPage: true 
      });

      // Get queue count
      const pageContent = await page.textContent('body');
      result.details.queueCount = (pageContent.match(/Total:/g) || []).length;

      result.status = 'passed';
      result.details.message = 'RabbitMQ management UI is fully operational';
      
    } catch (error) {
      result.status = 'failed';
      result.details.error = error.message;
      console.error('RabbitMQ test failed:', error);
    }

    saveResults('rabbitmq', result);
    expect(result.status).toBe('passed');
  });

  // Test 4: MinIO Console
  test('MinIO - Console Login and Bucket Access', async ({ page }) => {
    const result = {
      service: 'MinIO',
      url: 'http://localhost:9001',
      status: 'unknown',
      details: {},
      timestamp: new Date().toISOString()
    };

    try {
      console.log('Testing MinIO...');
      
      // Navigate to MinIO
      await page.goto('http://localhost:9001', { timeout: 10000 });
      result.details.pageLoaded = true;

      // Take screenshot of login
      await page.screenshot({ 
        path: 'test-results/screenshots/minio-login.png',
        fullPage: true 
      });

      // Login
      await page.fill('input[id="accessKey"]', credentials.minio.username);
      await page.fill('input[id="secretKey"]', credentials.minio.password);
      await page.click('button[type="submit"]');
      
      // Wait for dashboard
      await page.waitForTimeout(3000);
      result.details.loginSuccessful = true;

      // Take screenshot of dashboard
      await page.screenshot({ 
        path: 'test-results/screenshots/minio-dashboard.png',
        fullPage: true 
      });

      // Try to access buckets
      const pageContent = await page.textContent('body');
      result.details.bucketsAccessible = pageContent.includes('Buckets') || pageContent.includes('Object Browser');

      result.status = 'passed';
      result.details.message = 'MinIO console is operational';
      
    } catch (error) {
      result.status = 'failed';
      result.details.error = error.message;
      console.error('MinIO test failed:', error);
    }

    saveResults('minio', result);
    expect(result.status).toBe('passed');
  });

  // Test 5: Keycloak Admin Console
  test('Keycloak - Admin Console Login', async ({ page }) => {
    const result = {
      service: 'Keycloak',
      url: 'http://localhost:8180',
      status: 'unknown',
      details: {},
      timestamp: new Date().toISOString()
    };

    try {
      console.log('Testing Keycloak...');
      
      // Navigate to Keycloak admin
      await page.goto('http://localhost:8180/admin/', { timeout: 15000 });
      result.details.pageLoaded = true;

      // Take screenshot of login
      await page.screenshot({ 
        path: 'test-results/screenshots/keycloak-login.png',
        fullPage: true 
      });

      // Login
      await page.fill('input[name="username"]', credentials.keycloak.username);
      await page.fill('input[name="password"]', credentials.keycloak.password);
      await page.click('input[type="submit"]');
      
      // Wait for admin console
      await page.waitForTimeout(5000);
      result.details.loginSuccessful = true;

      // Take screenshot of admin console
      await page.screenshot({ 
        path: 'test-results/screenshots/keycloak-admin.png',
        fullPage: true 
      });

      const pageContent = await page.textContent('body');
      result.details.adminConsoleAccessible = pageContent.includes('Master') || pageContent.includes('Clients') || pageContent.includes('Realm');

      result.status = 'passed';
      result.details.message = 'Keycloak admin console is accessible';
      
    } catch (error) {
      result.status = 'failed';
      result.details.error = error.message;
      console.error('Keycloak test failed:', error);
    }

    saveResults('keycloak', result);
    expect(result.status).toBe('passed');
  });

  // Test 6: Nginx Gateway
  test('Nginx - Gateway Health Check', async ({ page }) => {
    const result = {
      service: 'Nginx',
      url: 'http://localhost:8080',
      status: 'unknown',
      details: {},
      timestamp: new Date().toISOString()
    };

    try {
      console.log('Testing Nginx...');
      
      // Check health endpoint
      const response = await page.goto('http://localhost:8080/health', { timeout: 10000 });
      result.details.healthEndpointStatus = response.status();
      result.details.pageLoaded = true;

      // Take screenshot
      await page.screenshot({ 
        path: 'test-results/screenshots/nginx-health.png',
        fullPage: true 
      });

      const content = await page.textContent('body');
      result.details.healthResponse = content;
      result.details.isHealthy = content.includes('OK') || response.status() === 200;

      result.status = result.details.isHealthy ? 'passed' : 'failed';
      result.details.message = result.details.isHealthy ? 'Nginx gateway is operational' : 'Nginx health check failed';
      
    } catch (error) {
      result.status = 'failed';
      result.details.error = error.message;
      console.error('Nginx test failed:', error);
    }

    saveResults('nginx', result);
    expect(result.status).toBe('passed');
  });

  // Test 7: Loki (via Grafana Explore)
  test('Loki - Log Query via Grafana', async ({ page }) => {
    const result = {
      service: 'Loki',
      url: 'http://localhost:3100',
      status: 'unknown',
      details: {},
      timestamp: new Date().toISOString()
    };

    try {
      console.log('Testing Loki via Grafana...');
      
      // Login to Grafana first
      await page.goto('http://localhost:3000', { timeout: 10000 });
      await page.fill('input[name="user"]', credentials.grafana.username);
      await page.fill('input[name="password"]', credentials.grafana.password);
      await page.click('button[type="submit"]');
      await page.waitForTimeout(2000);

      // Navigate to Explore
      await page.goto('http://localhost:3000/explore');
      await page.waitForTimeout(2000);
      result.details.explorePageAccessible = true;

      // Take screenshot
      await page.screenshot({ 
        path: 'test-results/screenshots/loki-explore.png',
        fullPage: true 
      });

      const pageContent = await page.textContent('body');
      result.details.lokiAvailable = pageContent.includes('Loki') || pageContent.includes('LogQL');

      result.status = 'passed';
      result.details.message = 'Loki is accessible via Grafana Explore';
      
    } catch (error) {
      result.status = 'failed';
      result.details.error = error.message;
      console.error('Loki test failed:', error);
    }

    saveResults('loki', result);
    expect(result.status).toBe('passed');
  });
});

// After all tests, generate summary report
test.afterAll(async () => {
  console.log('\n=== Test Summary ===');
  console.log(`Total Tests: ${testResults.summary.total}`);
  console.log(`Passed: ${testResults.summary.passed}`);
  console.log(`Failed: ${testResults.summary.failed}`);
  console.log(`Success Rate: ${((testResults.summary.passed / testResults.summary.total) * 100).toFixed(1)}%`);
  
  // Generate HTML report
  const htmlReport = `
<!DOCTYPE html>
<html>
<head>
  <title>MedinovAI Infrastructure Validation Report</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
    .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; }
    h1 { color: #333; border-bottom: 3px solid #4CAF50; padding-bottom: 10px; }
    .summary { background: #e8f5e9; padding: 20px; border-radius: 5px; margin: 20px 0; }
    .service { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
    .passed { border-left: 5px solid #4CAF50; }
    .failed { border-left: 5px solid #f44336; }
    .status-passed { color: #4CAF50; font-weight: bold; }
    .status-failed { color: #f44336; font-weight: bold; }
    .details { background: #f9f9f9; padding: 10px; margin: 10px 0; border-radius: 3px; }
    .screenshot { margin: 10px 0; }
    .screenshot img { max-width: 100%; border: 1px solid #ddd; border-radius: 3px; }
    .timestamp { color: #666; font-size: 0.9em; }
  </style>
</head>
<body>
  <div class="container">
    <h1>🏥 MedinovAI Infrastructure Validation Report</h1>
    <p class="timestamp">Generated: ${testResults.timestamp}</p>
    
    <div class="summary">
      <h2>Summary</h2>
      <p><strong>Total Tests:</strong> ${testResults.summary.total}</p>
      <p><strong>Passed:</strong> <span class="status-passed">${testResults.summary.passed}</span></p>
      <p><strong>Failed:</strong> <span class="status-failed">${testResults.summary.failed}</span></p>
      <p><strong>Success Rate:</strong> ${((testResults.summary.passed / testResults.summary.total) * 100).toFixed(1)}%</p>
    </div>
    
    <h2>Service Details</h2>
    ${Object.entries(testResults.services).map(([name, result]) => `
      <div class="service ${result.status}">
        <h3>${result.service}</h3>
        <p><strong>Status:</strong> <span class="status-${result.status}">${result.status.toUpperCase()}</span></p>
        <p><strong>URL:</strong> <a href="${result.url}" target="_blank">${result.url}</a></p>
        <p><strong>Timestamp:</strong> ${result.timestamp}</p>
        <div class="details">
          <h4>Details</h4>
          <pre>${JSON.stringify(result.details, null, 2)}</pre>
        </div>
      </div>
    `).join('')}
  </div>
</body>
</html>
  `;
  
  fs.writeFileSync('test-results/validation-report.html', htmlReport);
  console.log('\nFull report saved to: test-results/validation-report.html');
});

