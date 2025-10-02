import { test, expect } from '@playwright/test';

/**
 * UJ8: Clinical Researcher - Data Analytics
 * Components: Keycloak, PostgreSQL, MongoDB, Elasticsearch, Kafka, Prometheus, Grafana, MLflow
 * HIPAA: De-identification, research protocols, data lineage
 */

test.describe('UJ8: Clinical Researcher - Data Analytics', () => {
  test('Researcher can perform compliant data analysis', async ({ page }) => {
    await test.step('Authenticate', async () => {
      await page.goto('/research/login');
      await page.fill('input[name="username"]', 'researcher.jones');
      await page.fill('input[name="password"]', 'secure-password');
      await page.click('button[type="submit"]');
      await page.waitForURL('/research/dashboard');
    });
    
    await test.step('Define cohort', async () => {
      await page.click('a[href="/research/cohorts"]');
      await page.click('button[id="new-cohort"]');
      await page.fill('input[name="cohort-name"]', 'Diabetes Study 2025');
      await page.fill('textarea[name="inclusion-criteria"]', 'Patients with ICD-10 E11 (Type 2 Diabetes)');
      await page.click('button[id="run-query"]');
      await page.waitForSelector('.cohort-results');
      await expect(page.locator('.patient-count')).toContainText(/\d+ patients/);
    });
    
    await test.step('Request de-identified data', async () => {
      await page.click('button[id="request-deidentified"]');
      await page.check('input[name="confirm-irb-approval"]');
      await page.fill('input[name="irb-number"]', 'IRB-2025-0123');
      await page.click('button[id="submit-request"]');
      await expect(page.locator('.alert-success')).toContainText('Data request submitted');
    });
    
    await test.step('Run analysis', async () => {
      await page.click('a[href="/research/analysis"]');
      await page.selectOption('select[name="analysis-type"]', 'descriptive-statistics');
      await page.click('button[id="run-analysis"]');
      await page.waitForSelector('.analysis-results');
      await expect(page.locator('.results-table')).toBeVisible();
    });
    
    await test.step('Export results', async () => {
      await page.click('button[id="export-results"]');
      await page.selectOption('select[name="format"]', 'csv');
      await page.click('button[id="download"]');
      // Verify download initiated
      await expect(page.locator('.alert-success')).toContainText('Export complete');
    });
  });
  
  test.afterAll(() => console.log('✅ Completed Research Journey'));
});
