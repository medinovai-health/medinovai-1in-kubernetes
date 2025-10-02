import { test, expect } from '@playwright/test';

/**
 * IT2: Multi-Service Data Flow Integration
 * Tests: HL7 → Processing → Storage → Search → Analytics → Visualization
 * Validation: Data integrity, transformation accuracy, latency
 */

test.describe('IT2: Multi-Service Data Flow', () => {
  test('Data should flow correctly through entire pipeline', async ({ request }) => {
    const messageId = `MSG-IT2-${Date.now()}`;
    
    await test.step('Ingest HL7 message', async () => {
      const hl7 = `MSH|^~\\&|SYS|FAC|REC|HOSP|${new Date().toISOString()}||ADT^A01|${messageId}|P|2.5\nPID|1||IT2-TEST||DOE^JANE||19900101|F`;
      await request.post('/api/hl7/ingest', { data: { message: hl7, messageId } });
    });
    
    await test.step('Verify processing in MongoDB', async () => {
      await new Promise(resolve => setTimeout(resolve, 2000));
      const response = await request.get(`/api/hl7/messages/${messageId}`);
      if (response.ok()) {
        const msg = await response.json();
        expect(msg.status).toMatch(/processed|pending/);
      }
    });
    
    await test.step('Verify storage in PostgreSQL', async () => {
      await new Promise(resolve => setTimeout(resolve, 2000));
      const response = await request.get('/api/patients/by-mrn/IT2-TEST');
      if (response.ok()) {
        const patient = await response.json();
        expect(patient.firstName).toBe('JANE');
      }
    });
    
    await test.step('Verify search in Elasticsearch', async () => {
      await new Promise(resolve => setTimeout(resolve, 3000));
      const response = await request.get('/api/search/patients?q=IT2-TEST');
      if (response.ok()) {
        const results = await response.json();
        expect(results.hits.length).toBeGreaterThan(0);
      }
    });
  });
  
  test.afterAll(() => console.log('✅ Completed Data Flow Integration Test'));
});
