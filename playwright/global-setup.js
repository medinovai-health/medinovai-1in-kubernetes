// Global setup for MedinovAI Playwright tests
// This file runs before all tests to set up the test environment

const { chromium } = require('@playwright/test');

async function globalSetup(config) {
  console.log('🔧 Setting up MedinovAI test environment...');
  
  // Set up test environment variables
  process.env.MEDINOVAI_BASE_URL = process.env.MEDINOVAI_BASE_URL || 'https://medinovai.local';
  process.env.API_BASE_URL = process.env.API_BASE_URL || 'https://api.medinovai.local';
  process.env.TEST_USER_EMAIL = process.env.TEST_USER_EMAIL || 'test@medinovai.com';
  process.env.TEST_USER_PASSWORD = process.env.TEST_USER_PASSWORD || 'testpassword';
  
  // Launch browser for setup
  const browser = await chromium.launch();
  const context = await browser.newContext();
  const page = await context.newPage();
  
  try {
    // Check if the application is accessible
    console.log('🔍 Checking application accessibility...');
    const response = await page.goto(process.env.MEDINOVAI_BASE_URL, { 
      waitUntil: 'networkidle',
      timeout: 30000 
    });
    
    if (response && response.status() < 400) {
      console.log('✅ Application is accessible');
    } else {
      console.log('⚠️  Application may not be fully accessible, but tests will continue');
    }
    
    // Check API accessibility
    console.log('🔍 Checking API accessibility...');
    const apiResponse = await page.request.get(`${process.env.API_BASE_URL}/health`);
    
    if (apiResponse.status() === 200) {
      console.log('✅ API is accessible');
    } else {
      console.log('⚠️  API may not be fully accessible, but tests will continue');
    }
    
    // Set up test data if needed
    console.log('📊 Setting up test data...');
    await setupTestData(page);
    
    console.log('✅ Global setup completed successfully');
    
  } catch (error) {
    console.log('⚠️  Global setup encountered issues:', error.message);
    console.log('Tests will continue with limited functionality');
  } finally {
    await browser.close();
  }
}

async function setupTestData(page) {
  try {
    // Create test users if needed
    const testUsers = [
      { email: 'doctor@medinovai.com', password: 'doctor123', role: 'doctor' },
      { email: 'admin@medinovai.com', password: 'admin123', role: 'admin' },
      { email: 'nurse@medinovai.com', password: 'nurse123', role: 'nurse' }
    ];
    
    for (const user of testUsers) {
      try {
        const response = await page.request.post(`${process.env.API_BASE_URL}/api/users`, {
          data: user
        });
        
        if (response.status() === 201) {
          console.log(`✅ Created test user: ${user.email}`);
        } else if (response.status() === 409) {
          console.log(`ℹ️  Test user already exists: ${user.email}`);
        }
      } catch (error) {
        console.log(`⚠️  Could not create test user ${user.email}:`, error.message);
      }
    }
    
    // Create test patients if needed
    const testPatients = [
      { firstName: 'John', lastName: 'Doe', email: 'john.doe@example.com' },
      { firstName: 'Jane', lastName: 'Smith', email: 'jane.smith@example.com' }
    ];
    
    for (const patient of testPatients) {
      try {
        const response = await page.request.post(`${process.env.API_BASE_URL}/api/patients`, {
          data: patient
        });
        
        if (response.status() === 201) {
          console.log(`✅ Created test patient: ${patient.firstName} ${patient.lastName}`);
        } else if (response.status() === 409) {
          console.log(`ℹ️  Test patient already exists: ${patient.firstName} ${patient.lastName}`);
        }
      } catch (error) {
        console.log(`⚠️  Could not create test patient ${patient.firstName} ${patient.lastName}:`, error.message);
      }
    }
    
  } catch (error) {
    console.log('⚠️  Test data setup encountered issues:', error.message);
  }
}

module.exports = globalSetup;

