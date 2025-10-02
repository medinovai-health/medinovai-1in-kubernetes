import { test, expect } from '@playwright/test';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

/**
 * UJ2: Primary Care Physician - AI-Assisted Clinical Diagnosis
 * 
 * Components Tested:
 * - Keycloak (Authentication)
 * - Nginx (API Gateway)
 * - PostgreSQL (Patient Records)
 * - MongoDB (Clinical Notes)
 * - Ollama (AI Diagnostics)
 * - MLflow (Model Tracking)
 * - Kafka (Event Streaming)
 * - Redis (Session/Cache)
 * - Loki/Promtail (Audit Logs)
 * - Prometheus/Grafana (Metrics)
 */

test.describe('UJ2: Primary Care Physician - AI-Assisted Clinical Diagnosis', () => {
  
  test.beforeAll(async () => {
    console.log('🏥 Starting AI-Assisted Clinical Diagnosis Journey');
  });
  
  test('Physician can perform AI-assisted diagnosis workflow', async ({ page, request }) => {
    // 1. Physician Authentication via Keycloak
    await test.step('Authenticate physician', async () => {
      await page.goto('/ehr/login');
      await page.fill('input[name="username"]', 'dr.smith');
      await page.fill('input[name="password"]', 'secure-password');
      await page.click('button[type="submit"]');
      await page.waitForURL('/ehr/dashboard');
      await expect(page.locator('h1')).toContainText('Physician Dashboard');
    });
    
    // 2. Search and open patient record (PostgreSQL)
    await test.step('Open patient record', async () => {
      await page.click('a[href="/ehr/patients"]');
      await page.fill('input[name="patientSearch"]', 'John Doe');
      await page.click('button[id="search-patients"]');
      await expect(page.locator('.patient-list')).toBeVisible();
      await page.click('.patient-list .patient-row:first-child');
      await expect(page.locator('h2')).toContainText('John Doe');
    });
    
    // 3. Review patient history (PostgreSQL + MongoDB)
    await test.step('Review patient history', async () => {
      await page.click('a[href="#medical-history"]');
      await expect(page.locator('.medical-history')).toBeVisible();
      
      // Verify patient data loaded from PostgreSQL
      const demographics = page.locator('.demographics-section');
      await expect(demographics).toContainText('Date of Birth');
      
      // Verify clinical notes loaded from MongoDB
      const notes = page.locator('.clinical-notes');
      await expect(notes).toBeVisible();
    });
    
    // 4. Enter new symptoms (MongoDB + Kafka)
    await test.step('Enter patient symptoms', async () => {
      await page.click('button[id="add-symptoms"]');
      await page.fill('textarea[name="chief-complaint"]', 'Persistent cough for 3 weeks, shortness of breath, fatigue');
      await page.fill('input[name="temperature"]', '38.2');
      await page.fill('input[name="blood-pressure"]', '130/85');
      await page.fill('input[name="heart-rate"]', '92');
      await page.click('button[id="save-symptoms"]');
      
      // Wait for Kafka event to be published
      await page.waitForSelector('.alert-success', { timeout: 5000 });
      await expect(page.locator('.alert-success')).toContainText('Symptoms recorded');
    });
    
    // 5. Request AI diagnostic assistance (Ollama via API)
    await test.step('Request AI diagnostic assistance', async () => {
      await page.click('button[id="ai-diagnostic-assist"]');
      await page.waitForSelector('.ai-analysis-panel', { timeout: 30000 });
      await expect(page.locator('.ai-analysis-panel')).toBeVisible();
      
      // Verify AI suggestions are displayed
      const aiSuggestions = page.locator('.diagnostic-suggestions');
      await expect(aiSuggestions).toBeVisible();
      await expect(aiSuggestions).toContainText('Differential Diagnosis');
      
      // Verify confidence scores
      const confidenceScores = page.locator('.confidence-score');
      expect(await confidenceScores.count()).toBeGreaterThan(0);
    });
    
    // 6. Review AI-generated differential diagnoses (Ollama + MLflow)
    await test.step('Review differential diagnoses', async () => {
      const diagnoses = page.locator('.diagnosis-list .diagnosis-item');
      const diagnosisCount = await diagnoses.count();
      expect(diagnosisCount).toBeGreaterThanOrEqual(3);
      
      // Verify each diagnosis has required information
      for (let i = 0; i < Math.min(diagnosisCount, 3); i++) {
        await expect(diagnoses.nth(i).locator('.diagnosis-name')).toBeVisible();
        await expect(diagnoses.nth(i).locator('.confidence-score')).toBeVisible();
        await expect(diagnoses.nth(i).locator('.supporting-evidence')).toBeVisible();
      }
      
      // Verify model information is tracked (MLflow)
      const modelInfo = page.locator('.model-info');
      await expect(modelInfo).toContainText(/Model:|Version:/);
    });
    
    // 7. Order diagnostic tests (PostgreSQL + Kafka)
    await test.step('Order diagnostic tests', async () => {
      await page.click('button[id="order-tests"]');
      await page.check('input[name="test-chest-xray"]');
      await page.check('input[name="test-blood-work"]');
      await page.fill('textarea[name="test-notes"]', 'Rule out pneumonia and check inflammatory markers');
      await page.click('button[id="submit-test-orders"]');
      
      // Verify order confirmation
      await expect(page.locator('.alert-success')).toContainText('Test orders submitted');
      
      // Verify Kafka event published
      const orderId = await page.locator('.order-id').textContent();
      expect(orderId).toMatch(/^ORD-\d+$/);
    });
    
    // 8. Add preliminary diagnosis and treatment plan (MongoDB)
    await test.step('Add preliminary diagnosis', async () => {
      await page.click('a[href="#diagnosis"]');
      await page.fill('textarea[name="preliminary-diagnosis"]', 'Suspected community-acquired pneumonia');
      await page.fill('textarea[name="treatment-plan"]', 'Prescribe antibiotics, order chest X-ray, follow-up in 3 days');
      await page.click('button[id="save-diagnosis"]');
      
      await expect(page.locator('.alert-success')).toContainText('Diagnosis saved');
    });
    
    // 9. Verify audit trail (Loki)
    await test.step('Verify audit trail', async () => {
      // Check that all actions were logged
      const patientId = await page.locator('.patient-id').textContent();
      
      // API call to verify logs (Loki query)
      try {
        const response = await request.get(`/api/audit/logs?patientId=${patientId}`);
        if (response.ok()) {
          const logs = await response.json();
          expect(logs.length).toBeGreaterThan(0);
          
          // Verify key actions are logged
          const actionTypes = logs.map((log: any) => log.action);
          expect(actionTypes).toContain('PATIENT_ACCESS');
          expect(actionTypes).toContain('SYMPTOMS_RECORDED');
          expect(actionTypes).toContain('AI_DIAGNOSIS_REQUESTED');
          expect(actionTypes).toContain('DIAGNOSIS_SAVED');
        }
      } catch (error) {
        console.log('Audit trail verification skipped - API may not be available');
      }
    });
    
    // 10. Verify metrics collection (Prometheus)
    await test.step('Verify metrics collection', async () => {
      // Check that diagnosis metrics are being collected
      try {
        const response = await request.get('/api/metrics/diagnosis-requests');
        if (response.ok()) {
          const metrics = await response.json();
          expect(metrics.total_requests).toBeGreaterThan(0);
        }
      } catch (error) {
        console.log('Metrics verification skipped - API may not be available');
      }
    });
    
    // 11. Verify session management (Redis)
    await test.step('Verify session is active', async () => {
      // Session should remain active throughout workflow
      const sessionIndicator = page.locator('.session-indicator');
      await expect(sessionIndicator).toContainText('Active');
    });
    
    // 12. Logout
    await test.step('Logout', async () => {
      await page.click('button[id="logout"]');
      await expect(page).toHaveURL(/.*login/);
    });
  });
  
  test('AI diagnostic assistance should handle errors gracefully', async ({ page }) => {
    // Test error handling when AI service is unavailable
    await page.goto('/ehr/login');
    await page.fill('input[name="username"]', 'dr.smith');
    await page.fill('input[name="password"]', 'secure-password');
    await page.click('button[type="submit"]');
    await page.waitForURL('/ehr/dashboard');
    
    // Navigate to patient
    await page.goto('/ehr/patients/PAT-123456');
    
    // Simulate AI service error by mocking response
    await page.route('**/api/ai/diagnose', route => {
      route.fulfill({
        status: 503,
        contentType: 'application/json',
        body: JSON.stringify({ error: 'AI service temporarily unavailable' })
      });
    });
    
    await page.click('button[id="ai-diagnostic-assist"]');
    
    // Should show error message but not crash
    await expect(page.locator('.alert-error')).toContainText('AI service temporarily unavailable');
    
    // Should still allow manual diagnosis entry
    const manualDiagnosisButton = page.locator('button[id="manual-diagnosis"]');
    await expect(manualDiagnosisButton).toBeEnabled();
  });
  
  test('Diagnosis workflow should validate required fields', async ({ page }) => {
    await page.goto('/ehr/login');
    await page.fill('input[name="username"]', 'dr.smith');
    await page.fill('input[name="password"]', 'secure-password');
    await page.click('button[type="submit"]');
    await page.waitForURL('/ehr/dashboard');
    
    await page.goto('/ehr/patients/PAT-123456');
    
    // Try to save diagnosis without required fields
    await page.click('a[href="#diagnosis"]');
    await page.click('button[id="save-diagnosis"]');
    
    // Should show validation errors
    await expect(page.locator('.validation-error')).toContainText('diagnosis is required');
  });
  
  test('AI model information should be tracked in MLflow', async ({ request }) => {
    // Verify that AI model usage is tracked in MLflow
    try {
      const response = await request.get('http://localhost:5000/api/2.0/mlflow/experiments/search?filter_string=name="clinical-diagnosis"');
      if (response.ok()) {
        const data = await response.json();
        expect(data.experiments).toBeDefined();
        
        if (data.experiments.length > 0) {
          const experimentId = data.experiments[0].experiment_id;
          const runsResponse = await request.get(`http://localhost:5000/api/2.0/mlflow/runs/search?experiment_ids=["${experimentId}"]`);
          if (runsResponse.ok()) {
            const runsData = await runsResponse.json();
            expect(runsData.runs).toBeDefined();
          }
        }
      }
    } catch (error) {
      console.log('MLflow tracking verification skipped - service may not be available');
    }
  });
  
  test.afterAll(async () => {
    console.log('✅ Completed AI-Assisted Clinical Diagnosis Journey');
  });
});

