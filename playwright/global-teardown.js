// Global teardown for MedinovAI Playwright tests
// This file runs after all tests to clean up the test environment

const { chromium } = require('@playwright/test');

async function globalTeardown(config) {
  console.log('🧹 Cleaning up MedinovAI test environment...');
  
  // Launch browser for cleanup
  const browser = await chromium.launch();
  const context = await browser.newContext();
  const page = await context.newPage();
  
  try {
    // Clean up test data
    console.log('🗑️  Cleaning up test data...');
    await cleanupTestData(page);
    
    // Generate test summary
    console.log('📊 Generating test summary...');
    await generateTestSummary();
    
    console.log('✅ Global teardown completed successfully');
    
  } catch (error) {
    console.log('⚠️  Global teardown encountered issues:', error.message);
  } finally {
    await browser.close();
  }
}

async function cleanupTestData(page) {
  try {
    // Clean up test users
    const testUsers = [
      'doctor@medinovai.com',
      'admin@medinovai.com',
      'nurse@medinovai.com',
      'test@medinovai.com'
    ];
    
    for (const email of testUsers) {
      try {
        const response = await page.request.delete(`${process.env.API_BASE_URL}/api/users/${email}`);
        
        if (response.status() === 200) {
          console.log(`✅ Cleaned up test user: ${email}`);
        } else if (response.status() === 404) {
          console.log(`ℹ️  Test user not found: ${email}`);
        }
      } catch (error) {
        console.log(`⚠️  Could not clean up test user ${email}:`, error.message);
      }
    }
    
    // Clean up test patients
    const testPatients = [
      'john.doe@example.com',
      'jane.smith@example.com'
    ];
    
    for (const email of testPatients) {
      try {
        const response = await page.request.delete(`${process.env.API_BASE_URL}/api/patients/${email}`);
        
        if (response.status() === 200) {
          console.log(`✅ Cleaned up test patient: ${email}`);
        } else if (response.status() === 404) {
          console.log(`ℹ️  Test patient not found: ${email}`);
        }
      } catch (error) {
        console.log(`⚠️  Could not clean up test patient ${email}:`, error.message);
      }
    }
    
  } catch (error) {
    console.log('⚠️  Test data cleanup encountered issues:', error.message);
  }
}

async function generateTestSummary() {
  try {
    const fs = require('fs');
    const path = require('path');
    
    // Read test results if available
    const resultsPath = path.join(__dirname, '..', 'playwright-results.json');
    if (fs.existsSync(resultsPath)) {
      const results = JSON.parse(fs.readFileSync(resultsPath, 'utf8'));
      
      const summary = {
        timestamp: new Date().toISOString(),
        totalTests: results.stats?.total || 0,
        passed: results.stats?.passed || 0,
        failed: results.stats?.failed || 0,
        skipped: results.stats?.skipped || 0,
        duration: results.stats?.duration || 0,
        successRate: results.stats?.total > 0 ? 
          ((results.stats.passed / results.stats.total) * 100).toFixed(2) + '%' : '0%'
      };
      
      console.log('📊 Test Summary:');
      console.log(`  Total Tests: ${summary.totalTests}`);
      console.log(`  Passed: ${summary.passed}`);
      console.log(`  Failed: ${summary.failed}`);
      console.log(`  Skipped: ${summary.skipped}`);
      console.log(`  Success Rate: ${summary.successRate}`);
      console.log(`  Duration: ${summary.duration}ms`);
      
      // Write summary to file
      const summaryPath = path.join(__dirname, '..', 'test-summary.json');
      fs.writeFileSync(summaryPath, JSON.stringify(summary, null, 2));
      console.log(`📄 Test summary written to: ${summaryPath}`);
    }
    
  } catch (error) {
    console.log('⚠️  Could not generate test summary:', error.message);
  }
}

module.exports = globalTeardown;








