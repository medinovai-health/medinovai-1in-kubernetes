// @ts-check
const { defineConfig, devices } = require('@playwright/test');

/**
 * MedinovAI Infrastructure Validation Playwright Configuration
 * This configuration is used for validating MedinovAI infrastructure changes
 */
module.exports = defineConfig({
  testDir: './playwright',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['html', { outputFolder: 'playwright-report' }],
    ['json', { outputFile: 'playwright-results.json' }],
    ['junit', { outputFile: 'playwright-results.xml' }]
  ],
  use: {
    baseURL: process.env.MEDINOVAI_BASE_URL || 'https://medinovai.local',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    actionTimeout: 10000,
    navigationTimeout: 30000,
  },
  
  // Global test configuration
  globalSetup: require.resolve('./playwright/global-setup.js'),
  globalTeardown: require.resolve('./playwright/global-teardown.js'),
  
  // Test timeout configuration
  timeout: 60000,
  expect: {
    timeout: 10000,
  },
  
  // Projects for different browsers and environments
  projects: [
    {
      name: 'chromium',
      use: { 
        ...devices['Desktop Chrome'],
        // Additional Chrome-specific settings
        launchOptions: {
          args: ['--disable-web-security', '--disable-features=VizDisplayCompositor']
        }
      },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
    // Mobile testing
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] },
    },
    {
      name: 'Mobile Safari',
      use: { ...devices['iPhone 12'] },
    },
    // API testing
    {
      name: 'API Tests',
      testMatch: '**/api-*.spec.js',
      use: {
        baseURL: process.env.API_BASE_URL || 'https://api.medinovai.local',
      },
    },
  ],
  
  // Web server configuration for local development
  webServer: process.env.CI ? undefined : {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
    timeout: 120000,
  },
  
  // Output directory for test artifacts
  outputDir: 'test-results/',
  
  // Test metadata
  metadata: {
    testType: 'infrastructure-validation',
    environment: process.env.NODE_ENV || 'development',
    version: process.env.MEDINOVAI_VERSION || 'latest',
  },
});

