import { defineConfig, devices } from '@playwright/test';

/**
 * MedinovAI Infrastructure Journey Validation - Playwright Configuration
 * 
 * This configuration supports testing of:
 * - Infrastructure components (Tier 1-9)
 * - User journeys (10 scenarios)
 * - Data journeys (10 flows)
 * - Integration tests (end-to-end)
 */

export default defineConfig({
  testDir: './playwright/tests',
  
  // Test execution settings
  fullyParallel: false, // Sequential for infrastructure tests
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : 3,
  
  // Reporter configuration
  reporter: [
    ['html', { outputFolder: 'playwright-report' }],
    ['json', { outputFile: 'playwright-results.json' }],
    ['junit', { outputFile: 'playwright-results.xml' }],
    ['list']
  ],
  
  // Global test settings
  use: {
    baseURL: 'http://localhost:8080',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    
    // Extended timeout for infrastructure tests
    actionTimeout: 30000,
    navigationTimeout: 30000,
  },
  
  // Test timeout
  timeout: 60000,
  expect: {
    timeout: 10000,
  },
  
  // Test projects for different scenarios
  projects: [
    {
      name: 'infrastructure-tier1-containers',
      testMatch: /infrastructure\/tier1.*\.spec\.ts/,
      timeout: 120000,
    },
    {
      name: 'infrastructure-tier2-networking',
      testMatch: /infrastructure\/tier2.*\.spec\.ts/,
      timeout: 120000,
    },
    {
      name: 'infrastructure-tier3-databases',
      testMatch: /infrastructure\/tier3.*\.spec\.ts/,
      timeout: 120000,
    },
    {
      name: 'infrastructure-tier4-messaging',
      testMatch: /infrastructure\/tier4.*\.spec\.ts/,
      timeout: 120000,
    },
    {
      name: 'infrastructure-tier5-monitoring',
      testMatch: /infrastructure\/tier5.*\.spec\.ts/,
      timeout: 120000,
    },
    {
      name: 'infrastructure-tier6-security',
      testMatch: /infrastructure\/tier6.*\.spec\.ts/,
      timeout: 120000,
    },
    {
      name: 'infrastructure-tier7-ai-ml',
      testMatch: /infrastructure\/tier7.*\.spec\.ts/,
      timeout: 120000,
    },
    {
      name: 'infrastructure-tier8-backup',
      testMatch: /infrastructure\/tier8.*\.spec\.ts/,
      timeout: 120000,
    },
    {
      name: 'infrastructure-tier9-testing',
      testMatch: /infrastructure\/tier9.*\.spec\.ts/,
      timeout: 120000,
    },
    {
      name: 'user-journeys',
      testMatch: /user-journeys\/.*\.spec\.ts/,
      timeout: 300000, // 5 minutes for complex user journeys
    },
    {
      name: 'data-journeys',
      testMatch: /data-journeys\/.*\.spec\.ts/,
      timeout: 300000,
    },
    {
      name: 'integration',
      testMatch: /integration\/.*\.spec\.ts/,
      timeout: 600000, // 10 minutes for full integration tests
    },
  ],
  
  // Web server configuration (if needed)
  // webServer: {
  //   command: 'npm run start',
  //   url: 'http://localhost:8080',
  //   reuseExistingServer: !process.env.CI,
  // },
});

