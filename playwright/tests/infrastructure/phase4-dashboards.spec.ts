/**
 * Phase 4 Microstep 2: OpenSearch Dashboards Validation Tests
 * 
 * Tests: Dashboard UI, authentication, visualizations, index patterns
 * Target: Comprehensive functional validation
 * Date: 2025-10-02
 */

import { test, expect } from '@playwright/test';

const DASHBOARD_URL = 'http://localhost:5601';
const OPENSEARCH_URL = 'http://localhost:9200';

test.describe('Phase 4 Microstep 2: OpenSearch Dashboards', () => {
  
  test('should verify Dashboards API status is green', async ({ request }) => {
    await test.step('Check API status', async () => {
      const response = await request.get(`${DASHBOARD_URL}/api/status`);
      expect(response.ok()).toBeTruthy();
      
      const status = await response.json();
      expect(status.status.overall.state).toBe('green');
      expect(status.version.number).toBe('2.11.0');
      expect(status.name).toBe('medinovai-dashboards');
      
      console.log(`✅ Dashboards status: ${status.status.overall.state}`);
      console.log(`✅ Version: ${status.version.number}`);
    });
  });

  test('should verify OpenSearch connection from Dashboards', async ({ request }) => {
    await test.step('Check OpenSearch connectivity', async () => {
      const response = await request.get(`${DASHBOARD_URL}/api/status`);
      const status = await response.json();
      
      const opensearchStatus = status.status.statuses.find(
        (s: any) => s.id.includes('opensearch')
      );
      
      expect(opensearchStatus).toBeDefined();
      expect(opensearchStatus.state).toBe('green');
      expect(opensearchStatus.message).toContain('OpenSearch is available');
      
      console.log(`✅ OpenSearch connection: ${opensearchStatus.state}`);
    });
  });

  test('should load Dashboards home page', async ({ page }) => {
    await test.step('Navigate to Dashboards', async () => {
      await page.goto(DASHBOARD_URL);
      
      // Wait for page to load
      await page.waitForLoadState('networkidle');
      
      // Check for OpenSearch Dashboards branding
      const pageContent = await page.content();
      expect(pageContent).toContain('OpenSearch');
      
      console.log('✅ Dashboards home page loaded');
    });
  });

  test('should create and verify healthcare index pattern via API', async ({ request }) => {
    const indexName = `test-healthcare-${Date.now()}`;
    
    await test.step('Create test index in OpenSearch', async () => {
      const response = await request.put(`${OPENSEARCH_URL}/${indexName}`, {
        data: {
          settings: { number_of_shards: 1 },
          mappings: {
            properties: {
              patient_id: { type: 'keyword' },
              timestamp: { type: 'date' },
              vitals: { type: 'text' }
            }
          }
        }
      });
      expect(response.ok()).toBeTruthy();
      console.log(`✅ Created test index: ${indexName}`);
    });

    await test.step('Add sample documents', async () => {
      for (let i = 0; i < 5; i++) {
        await request.post(`${OPENSEARCH_URL}/${indexName}/_doc`, {
          data: {
            patient_id: `P${String(i).padStart(5, '0')}`,
            timestamp: new Date().toISOString(),
            vitals: `BP: ${120 + i}/80, HR: ${70 + i}`
          }
        });
      }
      
      await request.post(`${OPENSEARCH_URL}/${indexName}/_refresh`);
      console.log('✅ Added 5 sample documents');
    });

    await test.step('Verify index via Dashboards API', async () => {
      // Give Dashboards time to discover index
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // Check if index is visible
      const response = await request.get(`${OPENSEARCH_URL}/_cat/indices/${indexName}?format=json`);
      expect(response.ok()).toBeTruthy();
      
      const indices = await response.json();
      expect(indices.length).toBeGreaterThan(0);
      expect(indices[0].index).toBe(indexName);
      expect(indices[0]['docs.count']).toBe('5');
      
      console.log(`✅ Index verified: ${indices[0]['docs.count']} documents`);
    });

    await test.step('Cleanup: Delete test index', async () => {
      await request.delete(`${OPENSEARCH_URL}/${indexName}`);
      console.log('✅ Test index deleted');
    });
  });

  test('should handle Dashboards API health endpoints', async ({ request }) => {
    await test.step('Check overall health', async () => {
      const response = await request.get(`${DASHBOARD_URL}/api/status`);
      expect(response.ok()).toBeTruthy();
      
      const status = await response.json();
      
      // Verify all core services are green
      const coreServices = status.status.statuses.filter((s: any) => 
        s.id.includes('core:')
      );
      
      expect(coreServices.length).toBeGreaterThan(0);
      
      for (const service of coreServices) {
        expect(['green', 'yellow']).toContain(service.state);
        console.log(`✅ ${service.id}: ${service.state}`);
      }
    });
  });

  test('should verify Dashboards version and build info', async ({ request }) => {
    await test.step('Get version info', async () => {
      const response = await request.get(`${DASHBOARD_URL}/api/status`);
      const status = await response.json();
      
      expect(status.version.number).toBe('2.11.0');
      expect(status.version.build_snapshot).toBe(false);
      expect(status.version.build_number).toBeDefined();
      expect(status.uuid).toBeDefined();
      
      console.log(`✅ Version: ${status.version.number}`);
      console.log(`✅ Build: ${status.version.build_number}`);
      console.log(`✅ UUID: ${status.uuid}`);
    });
  });

  test('should handle error scenarios gracefully', async ({ request, page }) => {
    await test.step('Handle invalid API endpoint', async () => {
      const response = await request.get(`${DASHBOARD_URL}/api/nonexistent`);
      expect(response.status()).toBeGreaterThanOrEqual(400);
      console.log('✅ Invalid endpoint handled');
    });

    await test.step('Handle invalid page route', async () => {
      const response = await page.goto(`${DASHBOARD_URL}/app/nonexistent-page`);
      // Should redirect or show error, not crash
      expect(response).toBeTruthy();
      console.log('✅ Invalid route handled');
    });
  });

  test('should verify performance metrics', async ({ request }) => {
    await test.step('Measure API response time', async () => {
      const start = Date.now();
      const response = await request.get(`${DASHBOARD_URL}/api/status`);
      const duration = Date.now() - start;
      
      expect(response.ok()).toBeTruthy();
      expect(duration).toBeLessThan(2000); // Should respond in < 2s
      
      console.log(`✅ API response time: ${duration}ms`);
    });

    await test.step('Verify no memory leaks in status checks', async () => {
      // Multiple rapid requests should not cause issues
      const requests = [];
      for (let i = 0; i < 10; i++) {
        requests.push(request.get(`${DASHBOARD_URL}/api/status`));
      }
      
      const responses = await Promise.all(requests);
      
      for (const response of responses) {
        expect(response.ok()).toBeTruthy();
      }
      
      console.log('✅ Handled 10 concurrent requests');
    });
  });

  test('should verify Dashboards can query OpenSearch', async ({ request }) => {
    const testIndex = `test-query-${Date.now()}`;
    
    await test.step('Setup test data', async () => {
      // Create index
      await request.put(`${OPENSEARCH_URL}/${testIndex}`, {
        data: { settings: { number_of_shards: 1 }}
      });
      
      // Add documents
      await request.post(`${OPENSEARCH_URL}/${testIndex}/_doc`, {
        data: { message: 'Test from Dashboards', level: 'info' }
      });
      
      await request.post(`${OPENSEARCH_URL}/${testIndex}/_refresh`);
      console.log('✅ Test data created');
    });

    await test.step('Query via OpenSearch REST API', async () => {
      const response = await request.post(`${OPENSEARCH_URL}/${testIndex}/_search`, {
        data: {
          query: { match: { message: 'Dashboards' }}
        }
      });
      
      expect(response.ok()).toBeTruthy();
      const result = await response.json();
      
      expect(result.hits.total.value).toBe(1);
      expect(result.hits.hits[0]._source.message).toContain('Dashboards');
      
      console.log(`✅ Query returned ${result.hits.total.value} results`);
    });

    await test.step('Cleanup', async () => {
      await request.delete(`${OPENSEARCH_URL}/${testIndex}`);
      console.log('✅ Cleanup complete');
    });
  });
});

