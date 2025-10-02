// Playwright configuration for infrastructure validation
const { defineConfig } = require('@playwright/test');

module.exports = defineConfig({
  testDir: '.',
  timeout: 30000,
  expect: {
    timeout: 5000
  },
  fullyParallel: false,
  workers: 1,
  reporter: [['html', { outputFolder: '../test-results/playwright-report' }], ['json', { outputFile: '../test-results/results.json' }]],
  use: {
    baseURL: 'http://localhost',
    screenshot: 'on',
    video: 'retain-on-failure',
    trace: 'retain-on-failure',
  },
});

