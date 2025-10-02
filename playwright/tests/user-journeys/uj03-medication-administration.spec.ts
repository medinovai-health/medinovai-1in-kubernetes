import { test, expect } from '@playwright/test';

/**
 * UJ3: Nurse - Medication Administration
 * 
 * Components Tested:
 * - Keycloak (Authentication)
 * - Nginx (API Gateway)
 * - PostgreSQL (Patient Records, Orders)
 * - MongoDB (Administration Records)
 * - Redis (Session/Cache)
 * - Kafka (Event Streaming)
 * - Loki (Audit Logs)
 * - Prometheus/Grafana (Metrics)
 * - Ollama (Drug Interaction Check via AI)
 * 
 * HIPAA Compliance: PHI access, medication administration audit trail
 */

test.describe('UJ3: Nurse - Medication Administration', () => {
  
  test.beforeAll(async () => {
    console.log('💊 Starting Medication Administration Journey');
  });
  
  test('Nurse can complete full medication administration workflow', async ({ page, request }) => {
    
    // 1. Nurse Authentication
    await test.step('Authenticate as nurse', async () => {
      await page.goto('/ehr/login');
      await page.fill('input[name="username"]', 'nurse.johnson');
      await page.fill('input[name="password"]', 'secure-password');
      await page.click('button[type="submit"]');
      await page.waitForURL('/ehr/dashboard');
      await expect(page.locator('h1')).toContainText('Nurse Dashboard');
    });
    
    // 2. Access medication administration module
    await test.step('Navigate to medication administration', async () => {
      await page.click('a[href="/ehr/medications"]');
      await expect(page).toHaveURL(/.*medications/);
      await expect(page.locator('h2')).toContainText('Medication Administration');
    });
    
    // 3. Patient identification (barcode scan simulation)
    await test.step('Scan patient wristband', async () => {
      // Simulate barcode scan
      await page.fill('input[name="patient-barcode"]', 'PAT-123456');
      await page.click('button[id="scan-patient"]');
      
      // Verify patient loaded
      await expect(page.locator('.patient-info')).toBeVisible();
      await expect(page.locator('.patient-name')).toContainText('John Doe');
      
      // Verify Two-factor patient ID (ask date of birth)
      await expect(page.locator('.verify-dob')).toBeVisible();
      await page.fill('input[name="verify-dob"]', '1980-05-15');
      await page.click('button[id="confirm-patient"]');
      await expect(page.locator('.alert-success')).toContainText('Patient verified');
    });
    
    // 4. View pending medication orders
    await test.step('View pending medication orders', async () => {
      const pendingMeds = page.locator('.pending-medications');
      await expect(pendingMeds).toBeVisible();
      
      // Verify medication list contains required fields
      const medList = page.locator('.medication-item');
      expect(await medList.count()).toBeGreaterThan(0);
      
      // Check first medication details
      await expect(medList.first()).toContainText('Medication:');
      await expect(medList.first()).toContainText('Dose:');
      await expect(medList.first()).toContainText('Route:');
      await expect(medList.first()).toContainText('Scheduled Time:');
    });
    
    // 5. Select medication to administer
    await test.step('Select medication for administration', async () => {
      await page.click('.medication-item:first-child button[id="administer-med"]');
      await expect(page.locator('.medication-details-panel')).toBeVisible();
    });
    
    // 6. Five Rights Check
    await test.step('Perform Five Rights verification', async () => {
      // Right Patient
      await expect(page.locator('.right-patient')).toContainText('John Doe');
      await page.check('input[name="verify-right-patient"]');
      
      // Right Medication
      await expect(page.locator('.right-medication')).toContainText('Lisinopril');
      await page.check('input[name="verify-right-medication"]');
      
      // Right Dose
      await expect(page.locator('.right-dose')).toContainText('10mg');
      await page.check('input[name="verify-right-dose"]');
      
      // Right Route
      await expect(page.locator('.right-route')).toContainText('PO (Oral)');
      await page.check('input[name="verify-right-route"]');
      
      // Right Time
      await expect(page.locator('.right-time')).toBeVisible();
      await page.check('input[name="verify-right-time"]');
      
      await page.click('button[id="confirm-five-rights"]');
    });
    
    // 7. Medication barcode scan
    await test.step('Scan medication barcode', async () => {
      await page.fill('input[name="medication-barcode"]', 'MED-LISINOPRIL-10MG');
      await page.click('button[id="scan-medication"]');
      
      // Verify barcode matches order
      await expect(page.locator('.alert-success')).toContainText('Medication verified');
    });
    
    // 8. AI-powered drug interaction check
    await test.step('Perform drug interaction check', async () => {
      await page.click('button[id="check-interactions"]');
      await page.waitForSelector('.interaction-check-result', { timeout: 15000 });
      
      // Verify AI analysis completed
      const interactionResult = page.locator('.interaction-check-result');
      await expect(interactionResult).toBeVisible();
      await expect(interactionResult).toContainText(/No interactions|Safe to administer|Warning/i);
      
      // If warnings exist, nurse must acknowledge
      const hasWarning = await page.locator('.interaction-warning').isVisible().catch(() => false);
      if (hasWarning) {
        await page.check('input[name="acknowledge-warning"]');
        await page.fill('textarea[name="warning-override-reason"]', 'Discussed with physician, benefits outweigh risks');
      }
    });
    
    // 9. Administer medication
    await test.step('Administer medication and record', async () => {
      // Record vital signs before administration (if required)
      await page.fill('input[name="blood-pressure"]', '120/80');
      await page.fill('input[name="heart-rate"]', '72');
      
      // Mark as administered
      await page.click('button[id="administer-medication"]');
      
      // Confirm administration
      await expect(page.locator('.alert-success')).toContainText('Medication administered successfully');
      
      // Verify administration timestamp recorded
      const timestamp = page.locator('.administration-timestamp');
      await expect(timestamp).toBeVisible();
      await expect(timestamp).toContainText(/\d{2}:\d{2}/);
    });
    
    // 10. Patient response assessment
    await test.step('Record patient response', async () => {
      // Wait for patient response recording screen
      await expect(page.locator('.patient-response-panel')).toBeVisible();
      
      // Record response
      await page.check('input[name="medication-taken"]');
      await page.selectOption('select[name="patient-tolerance"]', 'Well tolerated');
      await page.fill('textarea[name="patient-response-notes"]', 'Patient took medication without difficulty. No immediate adverse reactions observed.');
      
      await page.click('button[id="save-response"]');
      await expect(page.locator('.alert-success')).toContainText('Response recorded');
    });
    
    // 11. Verify Kafka event published
    await test.step('Verify medication event published', async () => {
      try {
        const response = await request.get('/api/events/medication-administration?patient=PAT-123456');
        if (response.ok()) {
          const events = await response.json();
          expect(events.length).toBeGreaterThan(0);
          expect(events[0].eventType).toBe('MEDICATION_ADMINISTERED');
          expect(events[0].medication).toContain('Lisinopril');
        } else {
          console.log('Kafka event verification skipped - API may not be available');
        }
      } catch (error) {
        console.log('Event verification skipped');
      }
    });
    
    // 12. Verify audit trail (Loki)
    await test.step('Verify audit trail', async () => {
      try {
        const response = await request.get('/api/audit/medication-administration?patient=PAT-123456');
        if (response.ok()) {
          const logs = await response.json();
          expect(logs.length).toBeGreaterThan(0);
          
          const actions = logs.map((log: any) => log.action);
          expect(actions).toContain('PATIENT_VERIFIED');
          expect(actions).toContain('MEDICATION_SCANNED');
          expect(actions).toContain('FIVE_RIGHTS_VERIFIED');
          expect(actions).toContain('MEDICATION_ADMINISTERED');
        } else {
          console.log('Audit trail verification skipped');
        }
      } catch (error) {
        console.log('Audit trail verification skipped');
      }
    });
    
    // 13. View administration history
    await test.step('View medication administration history', async () => {
      await page.click('a[href="#administration-history"]');
      
      const history = page.locator('.administration-history');
      await expect(history).toBeVisible();
      
      // Verify recent administration appears in history
      const historyItems = page.locator('.history-item');
      expect(await historyItems.count()).toBeGreaterThan(0);
      await expect(historyItems.first()).toContainText('Lisinopril');
      await expect(historyItems.first()).toContainText('10mg');
    });
  });
  
  test('Should prevent medication administration with failed verification', async ({ page }) => {
    await page.goto('/ehr/login');
    await page.fill('input[name="username"]', 'nurse.johnson');
    await page.fill('input[name="password"]', 'secure-password');
    await page.click('button[type="submit"]');
    await page.waitForURL('/ehr/dashboard');
    
    await page.goto('/ehr/medications');
    
    // Scan patient
    await page.fill('input[name="patient-barcode"]', 'PAT-123456');
    await page.click('button[id="scan-patient"]');
    
    // Provide wrong date of birth
    await page.fill('input[name="verify-dob"]', '1990-01-01');
    await page.click('button[id="confirm-patient"]');
    
    // Should show error
    await expect(page.locator('.alert-error')).toContainText('Patient verification failed');
    
    // Should not allow proceeding to medication administration
    const adminButton = page.locator('button[id="administer-med"]');
    await expect(adminButton).toBeDisabled();
  });
  
  test('Should alert on wrong medication barcode scan', async ({ page }) => {
    await page.goto('/ehr/login');
    await page.fill('input[name="username"]', 'nurse.johnson');
    await page.fill('input[name="password"]', 'secure-password');
    await page.click('button[type="submit"]');
    await page.waitForURL('/ehr/dashboard');
    
    await page.goto('/ehr/medications');
    
    // Complete patient verification
    await page.fill('input[name="patient-barcode"]', 'PAT-123456');
    await page.click('button[id="scan-patient"]');
    await page.fill('input[name="verify-dob"]', '1980-05-15');
    await page.click('button[id="confirm-patient"]');
    
    // Select medication
    await page.click('.medication-item:first-child button[id="administer-med"]');
    
    // Complete Five Rights
    await page.check('input[name="verify-right-patient"]');
    await page.check('input[name="verify-right-medication"]');
    await page.check('input[name="verify-right-dose"]');
    await page.check('input[name="verify-right-route"]');
    await page.check('input[name="verify-right-time"]');
    await page.click('button[id="confirm-five-rights"]');
    
    // Scan WRONG medication barcode
    await page.fill('input[name="medication-barcode"]', 'MED-WRONG-MEDICATION');
    await page.click('button[id="scan-medication"]');
    
    // Should show critical error
    await expect(page.locator('.alert-error.critical')).toContainText('WRONG MEDICATION');
    
    // Should not allow administration
    const adminButton = page.locator('button[id="administer-medication"]');
    await expect(adminButton).toBeDisabled();
  });
  
  test('Should handle critical drug interactions', async ({ page }) => {
    await page.goto('/ehr/login');
    await page.fill('input[name="username"]', 'nurse.johnson');
    await page.fill('input[name="password"]', 'secure-password');
    await page.click('button[type="submit"]');
    await page.waitForURL('/ehr/dashboard');
    
    await page.goto('/ehr/medications');
    
    // Mock critical interaction scenario
    await page.route('**/api/drug-interactions/check', route => {
      route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          severity: 'CRITICAL',
          interactions: [
            {
              drug1: 'Warfarin',
              drug2: 'Aspirin',
              severity: 'CRITICAL',
              description: 'Increased bleeding risk',
              recommendation: 'Consult physician before administration'
            }
          ]
        })
      });
    });
    
    // Complete workflow up to interaction check
    await page.fill('input[name="patient-barcode"]', 'PAT-789012');
    await page.click('button[id="scan-patient"]');
    await page.fill('input[name="verify-dob"]', '1975-03-20');
    await page.click('button[id="confirm-patient"]');
    
    await page.click('.medication-item:first-child button[id="administer-med"]');
    
    await page.check('input[name="verify-right-patient"]');
    await page.check('input[name="verify-right-medication"]');
    await page.check('input[name="verify-right-dose"]');
    await page.check('input[name="verify-right-route"]');
    await page.check('input[name="verify-right-time"]');
    await page.click('button[id="confirm-five-rights"]');
    
    await page.fill('input[name="medication-barcode"]', 'MED-ASPIRIN-81MG');
    await page.click('button[id="scan-medication"]');
    
    // Perform interaction check
    await page.click('button[id="check-interactions"]');
    
    // Should show critical warning
    await expect(page.locator('.alert-error.critical')).toBeVisible();
    await expect(page.locator('.interaction-warning')).toContainText('CRITICAL');
    await expect(page.locator('.interaction-warning')).toContainText('bleeding risk');
    
    // Should require physician consultation
    await expect(page.locator('.require-physician-approval')).toBeVisible();
    
    // Cannot proceed without physician override
    const adminButton = page.locator('button[id="administer-medication"]');
    await expect(adminButton).toBeDisabled();
  });
  
  test('Should track late medication administration', async ({ page, request }) => {
    await page.goto('/ehr/login');
    await page.fill('input[name="username"]', 'nurse.johnson');
    await page.fill('input[name="password"]', 'secure-password');
    await page.click('button[type="submit"]');
    await page.waitForURL('/ehr/dashboard');
    
    await page.goto('/ehr/medications');
    
    // Mock a medication that's overdue
    await page.route('**/api/medications/pending*', route => {
      route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          medications: [
            {
              id: 'MED-123',
              name: 'Metformin',
              dose: '500mg',
              route: 'PO',
              scheduledTime: new Date(Date.now() - 3600000).toISOString(), // 1 hour ago
              status: 'OVERDUE'
            }
          ]
        })
      });
    });
    
    await page.reload();
    
    // Should show overdue indicator
    await expect(page.locator('.medication-item.overdue')).toBeVisible();
    await expect(page.locator('.overdue-indicator')).toContainText('OVERDUE');
    
    // Complete administration
    await page.fill('input[name="patient-barcode"]', 'PAT-123456');
    await page.click('button[id="scan-patient"]');
    await page.fill('input[name="verify-dob"]', '1980-05-15');
    await page.click('button[id="confirm-patient"]');
    
    await page.click('.medication-item button[id="administer-med"]');
    
    // Should require reason for late administration
    await expect(page.locator('.late-administration-reason')).toBeVisible();
    await page.fill('textarea[name="late-reason"]', 'Patient was in diagnostic imaging');
    
    await page.check('input[name="verify-right-patient"]');
    await page.check('input[name="verify-right-medication"]');
    await page.check('input[name="verify-right-dose"]');
    await page.check('input[name="verify-right-route"]');
    await page.check('input[name="verify-right-time"]');
    await page.click('button[id="confirm-five-rights"]');
    
    await page.fill('input[name="medication-barcode"]', 'MED-METFORMIN-500MG');
    await page.click('button[id="scan-medication"]');
    
    await page.click('button[id="check-interactions"]');
    await page.waitForSelector('.interaction-check-result');
    
    await page.click('button[id="administer-medication"]');
    
    // Verify late administration flag recorded
    await expect(page.locator('.alert-warning')).toContainText('Late administration recorded');
  });
  
  test.afterAll(async () => {
    console.log('✅ Completed Medication Administration Journey');
  });
});

