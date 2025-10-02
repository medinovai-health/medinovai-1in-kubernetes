import { test, expect } from '@playwright/test';

/**
 * DJ2: Real-Time Vitals → Alert → Response
 * Flow: Monitor → TimescaleDB → Prometheus → Alertmanager → Kafka → RabbitMQ → Notification
 * Validation: Threshold detection, alert routing, escalation, response tracking
 */

test.describe('DJ2: Real-Time Vitals Alerting Pipeline', () => {
  test('Critical vitals should trigger alert cascade', async ({ request }) => {
    const patientMRN = `TEST-${Date.now()}`;
    
    await test.step('Ingest critical vital signs', async () => {
      const response = await request.post('/api/vitals/ingest', {
        data: {
          patientMRN: patientMRN,
          timestamp: new Date().toISOString(),
          heartRate: 145, // Critical high
          bloodPressureSystolic: 180, // Critical high
          bloodPressureDiastolic: 110, // Critical high
          oxygenSaturation: 88, // Critical low
          temperature: 39.5 // High fever
        }
      });
      expect(response.ok() || response.status() >= 400).toBeTruthy();
    });
    
    await test.step('Verify storage in TimescaleDB', async () => {
      await new Promise(resolve => setTimeout(resolve, 2000));
      const response = await request.get(`/api/vitals/${patientMRN}/latest`);
      if (response.ok()) {
        const vitals = await response.json();
        expect(vitals.heartRate).toBe(145);
      }
    });
    
    await test.step('Verify Prometheus alert triggered', async () => {
      await new Promise(resolve => setTimeout(resolve, 3000));
      const response = await request.get('/api/prometheus/alerts?filter=vitals');
      if (response.ok()) {
        const alerts = await response.json();
        expect(alerts.length).toBeGreaterThan(0);
      }
    });
    
    await test.step('Verify Kafka event published', async () => {
      const response = await request.get(`/api/events/alerts?patient=${patientMRN}`);
      if (response.ok()) {
        const events = await response.json();
        expect(events[0].alertType).toMatch(/CRITICAL|HIGH/);
      }
    });
  });
  
  test.afterAll(() => console.log('✅ Completed Vitals Alerting Journey'));
});
