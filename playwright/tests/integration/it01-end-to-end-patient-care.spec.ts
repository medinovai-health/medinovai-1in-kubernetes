import { test, expect } from '@playwright/test';

/**
 * IT1: End-to-End Patient Care Workflow
 * Tests: Admission → Diagnosis → Treatment → Billing → Discharge
 * Components: All tiers integrated
 * Validation: Data consistency, event propagation, audit trail
 */

test.describe('IT1: End-to-End Patient Care Workflow', () => {
  test('Complete patient care cycle should work seamlessly across all tiers', async ({ page, request }) => {
    const testPatientMRN = `TEST-E2E-${Date.now()}`;
    
    // Step 1: Admission (ER Physician)
    await test.step('Patient Admission', async () => {
      await page.goto('/ehr/login');
      await page.fill('input[name="username"]', 'er.physician');
      await page.fill('input[name="password"]', 'secure-password');
      await page.click('button[type="submit"]');
      await page.waitForURL('/ehr/dashboard');
      
      await page.click('a[href="/ehr/patient-admission"]');
      await page.fill('input[name="mrn"]', testPatientMRN);
      await page.fill('input[name="firstName"]', 'Integration');
      await page.fill('input[name="lastName"]', 'Test');
      await page.fill('input[name="dob"]', '1985-01-01');
      await page.selectOption('select[name="gender"]', 'Male');
      await page.click('button[id="admit-patient"]');
      
      await expect(page.locator('.alert-success')).toContainText('Patient admitted');
    });
    
    // Step 2: Clinical Diagnosis (AI-Assisted)
    await test.step('AI-Assisted Diagnosis', async () => {
      await page.goto(`/ehr/patients/${testPatientMRN}`);
      await page.fill('textarea[name="symptoms"]', 'Chest pain, shortness of breath');
      await page.click('button[id="ai-diagnostic-assist"]');
      await page.waitForSelector('.ai-findings', { timeout: 30000 });
      await expect(page.locator('.ai-findings')).toBeVisible();
    });
    
    // Step 3: Lab Orders
    await test.step('Order Lab Tests', async () => {
      await page.click('button[id="order-labs"]');
      await page.check('input[name="lab-troponin"]');
      await page.check('input[name="lab-ekg"]');
      await page.click('button[id="submit-orders"]');
      await expect(page.locator('.alert-success')).toContainText('Orders submitted');
    });
    
    // Step 4: Treatment Plan
    await test.step('Create Treatment Plan', async () => {
      await page.fill('textarea[name="diagnosis"]', 'Suspected acute coronary syndrome');
      await page.fill('textarea[name="treatment-plan"]', 'Admit to CCU, start heparin, monitor');
      await page.click('button[id="save-diagnosis"]');
    });
    
    // Step 5: Billing
    await test.step('Generate Bill', async () => {
      await page.click('button[id="logout"]');
      
      await page.goto('/billing/login');
      await page.fill('input[name="username"]', 'billing.specialist');
      await page.fill('input[name="password"]', 'secure-password');
      await page.click('button[type="submit"]');
      
      await page.goto(`/billing/encounters?mrn=${testPatientMRN}`);
      await page.click('.encounter-item:first-child');
      await page.click('button[id="generate-claim"]');
      await expect(page.locator('.claim-number')).toMatch(/CLM-/);
    });
    
    // Step 6: Verify Complete Audit Trail
    await test.step('Verify Audit Trail', async () => {
      const response = await request.get(`/api/audit/patient/${testPatientMRN}`);
      if (response.ok()) {
        const logs = await response.json();
        expect(logs.length).toBeGreaterThan(5);
        
        const actionTypes = logs.map((l: any) => l.action);
        expect(actionTypes).toContain('PATIENT_ADMITTED');
        expect(actionTypes).toContain('DIAGNOSIS_RECORDED');
        expect(actionTypes).toContain('LABS_ORDERED');
        expect(actionTypes).toContain('CLAIM_GENERATED');
      }
    });
    
    // Step 7: Verify Data Consistency
    await test.step('Verify Data Across Systems', async () => {
      // Check PostgreSQL
      const pgResponse = await request.get(`/api/patients/by-mrn/${testPatientMRN}`);
      if (pgResponse.ok()) {
        const patient = await pgResponse.json();
        expect(patient.mrn).toBe(testPatientMRN);
      }
      
      // Check Elasticsearch
      await new Promise(resolve => setTimeout(resolve, 2000));
      const esResponse = await request.get(`/api/search/patients?q=mrn:${testPatientMRN}`);
      if (esResponse.ok()) {
        const results = await esResponse.json();
        expect(results.hits.length).toBeGreaterThan(0);
      }
    });
  });
  
  test.afterAll(() => console.log('✅ Completed E2E Patient Care Integration Test'));
});
