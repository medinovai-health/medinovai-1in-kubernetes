/**
 * Phase 4 Microstep 1: OpenSearch Validation Tests
 * 
 * Tests: OpenSearch cluster, REST API, CRUD operations
 * Target: Comprehensive functional validation
 * Date: 2025-10-02
 */

import { test, expect } from '@playwright/test';
import { request } from '@playwright/test';

const OPENSEARCH_URL = 'http://localhost:9200';

test.describe('Phase 4 Microstep 1: OpenSearch Deployment', () => {
  
  test('should verify OpenSearch cluster is healthy', async ({ request }) => {
    await test.step('Check cluster health', async () => {
      const response = await request.get(`${OPENSEARCH_URL}/_cluster/health`);
      expect(response.ok()).toBeTruthy();
      
      const health = await response.json();
      expect(health.cluster_name).toBe('medinovai-search-cluster');
      expect(health.status).toMatch(/green|yellow/); // yellow is OK for single node
      expect(health.number_of_nodes).toBe(1);
      
      console.log(`✅ Cluster status: ${health.status}`);
      console.log(`✅ Nodes: ${health.number_of_nodes}`);
    });
  });

  test('should verify OpenSearch version and info', async ({ request }) => {
    await test.step('Get cluster info', async () => {
      const response = await request.get(OPENSEARCH_URL);
      expect(response.ok()).toBeTruthy();
      
      const info = await response.json();
      expect(info.name).toBe('opensearch-node1');
      expect(info.cluster_name).toBe('medinovai-search-cluster');
      expect(info.version.number).toBe('2.11.0');
      expect(info.tagline).toContain('OpenSearch');
      
      console.log(`✅ OpenSearch ${info.version.number} running`);
    });
  });

  test('should create a healthcare index', async ({ request }) => {
    const indexName = `test-patients-${Date.now()}`;
    
    await test.step('Create index with healthcare mappings', async () => {
      const response = await request.put(`${OPENSEARCH_URL}/${indexName}`, {
        data: {
          settings: {
            number_of_shards: 1,
            number_of_replicas: 0
          },
          mappings: {
            properties: {
              patient_id: { type: 'keyword' },
              name: { type: 'text' },
              date_of_birth: { type: 'date' },
              medical_record_number: { type: 'keyword' },
              diagnosis: { type: 'text' },
              medications: { type: 'text' },
              last_visit: { type: 'date' },
              notes: { 
                type: 'text',
                analyzer: 'standard'
              }
            }
          }
        }
      });
      
      expect(response.ok()).toBeTruthy();
      const result = await response.json();
      expect(result.acknowledged).toBe(true);
      expect(result.index).toBe(indexName);
      
      console.log(`✅ Created index: ${indexName}`);
    });

    await test.step('Verify index exists', async () => {
      const response = await request.get(`${OPENSEARCH_URL}/${indexName}`);
      expect(response.ok()).toBeTruthy();
      
      const indexInfo = await response.json();
      expect(indexInfo[indexName]).toBeDefined();
      expect(indexInfo[indexName].mappings.properties.patient_id.type).toBe('keyword');
      
      console.log('✅ Index verified');
    });

    await test.step('Cleanup: Delete test index', async () => {
      const response = await request.delete(`${OPENSEARCH_URL}/${indexName}`);
      expect(response.ok()).toBeTruthy();
      console.log('✅ Test index deleted');
    });
  });

  test('should perform CRUD operations on patient documents', async ({ request }) => {
    const indexName = `test-crud-${Date.now()}`;
    
    // Create index
    await request.put(`${OPENSEARCH_URL}/${indexName}`, {
      data: {
        settings: { number_of_shards: 1, number_of_replicas: 0 }
      }
    });

    const patientDoc = {
      patient_id: 'P12345',
      name: 'John Doe',
      date_of_birth: '1980-05-15',
      medical_record_number: 'MRN-67890',
      diagnosis: 'Type 2 Diabetes',
      medications: ['Metformin 500mg', 'Lisinopril 10mg'],
      last_visit: '2025-10-01',
      notes: 'Patient shows improvement in glucose levels'
    };

    let documentId: string;

    await test.step('Create (Index) document', async () => {
      const response = await request.post(`${OPENSEARCH_URL}/${indexName}/_doc`, {
        data: patientDoc
      });
      
      expect(response.ok()).toBeTruthy();
      const result = await response.json();
      expect(result.result).toBe('created');
      documentId = result._id;
      
      console.log(`✅ Document created with ID: ${documentId}`);
    });

    await test.step('Read (Get) document', async () => {
      // Wait for indexing
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      const response = await request.get(`${OPENSEARCH_URL}/${indexName}/_doc/${documentId}`);
      expect(response.ok()).toBeTruthy();
      
      const result = await response.json();
      expect(result.found).toBe(true);
      expect(result._source.patient_id).toBe(patientDoc.patient_id);
      expect(result._source.name).toBe(patientDoc.name);
      
      console.log('✅ Document retrieved successfully');
    });

    await test.step('Update document', async () => {
      const response = await request.post(`${OPENSEARCH_URL}/${indexName}/_update/${documentId}`, {
        data: {
          doc: {
            notes: 'Patient shows significant improvement. Schedule follow-up in 3 months.',
            last_visit: '2025-10-02'
          }
        }
      });
      
      expect(response.ok()).toBeTruthy();
      const result = await response.json();
      expect(result.result).toBe('updated');
      
      console.log('✅ Document updated');
    });

    await test.step('Verify update', async () => {
      const response = await request.get(`${OPENSEARCH_URL}/${indexName}/_doc/${documentId}`);
      const result = await response.json();
      
      expect(result._source.last_visit).toBe('2025-10-02');
      expect(result._source.notes).toContain('significant improvement');
      
      console.log('✅ Update verified');
    });

    await test.step('Delete document', async () => {
      const response = await request.delete(`${OPENSEARCH_URL}/${indexName}/_doc/${documentId}`);
      expect(response.ok()).toBeTruthy();
      
      const result = await response.json();
      expect(result.result).toBe('deleted');
      
      console.log('✅ Document deleted');
    });

    await test.step('Verify deletion', async () => {
      const response = await request.get(`${OPENSEARCH_URL}/${indexName}/_doc/${documentId}`);
      const result = await response.json();
      
      expect(result.found).toBe(false);
      console.log('✅ Deletion verified');
    });

    // Cleanup
    await request.delete(`${OPENSEARCH_URL}/${indexName}`);
  });

  test('should perform full-text search', async ({ request }) => {
    const indexName = `test-search-${Date.now()}`;
    
    // Create index and add documents
    await request.put(`${OPENSEARCH_URL}/${indexName}`, {
      data: { settings: { number_of_shards: 1, number_of_replicas: 0 }}
    });

    await test.step('Index multiple patient documents', async () => {
      const patients = [
        { patient_id: 'P001', name: 'Alice Smith', diagnosis: 'Hypertension', notes: 'Patient has high blood pressure' },
        { patient_id: 'P002', name: 'Bob Johnson', diagnosis: 'Diabetes Type 2', notes: 'Patient requires insulin management' },
        { patient_id: 'P003', name: 'Carol Williams', diagnosis: 'Hypertension', notes: 'Patient responds well to medication' },
        { patient_id: 'P004', name: 'David Brown', diagnosis: 'Asthma', notes: 'Patient uses inhaler regularly' },
      ];

      for (const patient of patients) {
        await request.post(`${OPENSEARCH_URL}/${indexName}/_doc`, { data: patient });
      }

      // Refresh index for search
      await request.post(`${OPENSEARCH_URL}/${indexName}/_refresh`);
      
      console.log('✅ Indexed 4 patient documents');
    });

    await test.step('Search by diagnosis', async () => {
      const response = await request.post(`${OPENSEARCH_URL}/${indexName}/_search`, {
        data: {
          query: {
            match: { diagnosis: 'Hypertension' }
          }
        }
      });
      
      expect(response.ok()).toBeTruthy();
      const result = await response.json();
      
      expect(result.hits.total.value).toBe(2);
      expect(result.hits.hits[0]._source.diagnosis).toContain('Hypertension');
      
      console.log(`✅ Found ${result.hits.total.value} patients with Hypertension`);
    });

    await test.step('Full-text search in notes', async () => {
      const response = await request.post(`${OPENSEARCH_URL}/${indexName}/_search`, {
        data: {
          query: {
            match: { notes: 'patient medication' }
          }
        }
      });
      
      expect(response.ok()).toBeTruthy();
      const result = await response.json();
      
      expect(result.hits.total.value).toBeGreaterThan(0);
      console.log(`✅ Full-text search returned ${result.hits.total.value} results`);
    });

    await test.step('Search with filters', async () => {
      const response = await request.post(`${OPENSEARCH_URL}/${indexName}/_search`, {
        data: {
          query: {
            bool: {
              must: [
                { match: { diagnosis: 'Hypertension' }}
              ],
              filter: [
                { term: { patient_id: 'P001' }}
              ]
            }
          }
        }
      });
      
      expect(response.ok()).toBeTruthy();
      const result = await response.json();
      
      expect(result.hits.total.value).toBe(1);
      expect(result.hits.hits[0]._source.name).toBe('Alice Smith');
      
      console.log('✅ Filtered search working correctly');
    });

    // Cleanup
    await request.delete(`${OPENSEARCH_URL}/${indexName}`);
  });

  test('should handle bulk operations', async ({ request }) => {
    const indexName = `test-bulk-${Date.now()}`;
    
    await request.put(`${OPENSEARCH_URL}/${indexName}`, {
      data: { settings: { number_of_shards: 1, number_of_replicas: 0 }}
    });

    await test.step('Bulk index 100 documents', async () => {
      const bulkBody: string[] = [];
      
      for (let i = 1; i <= 100; i++) {
        bulkBody.push(JSON.stringify({ index: { _index: indexName }}));
        bulkBody.push(JSON.stringify({
          patient_id: `P${String(i).padStart(5, '0')}`,
          name: `Patient ${i}`,
          diagnosis: i % 2 === 0 ? 'Hypertension' : 'Diabetes',
          visit_count: i
        }));
      }
      
      const response = await request.post(`${OPENSEARCH_URL}/_bulk`, {
        headers: { 'Content-Type': 'application/x-ndjson' },
        data: bulkBody.join('\n') + '\n'
      });
      
      expect(response.ok()).toBeTruthy();
      const result = await response.json();
      expect(result.errors).toBe(false);
      
      console.log(`✅ Bulk indexed 100 documents in ${result.took}ms`);
    });

    await test.step('Verify document count', async () => {
      await request.post(`${OPENSEARCH_URL}/${indexName}/_refresh`);
      
      const response = await request.get(`${OPENSEARCH_URL}/${indexName}/_count`);
      const result = await response.json();
      
      expect(result.count).toBe(100);
      console.log('✅ All 100 documents indexed');
    });

    await test.step('Aggregation query', async () => {
      const response = await request.post(`${OPENSEARCH_URL}/${indexName}/_search`, {
        data: {
          size: 0,
          aggs: {
            by_diagnosis: {
              terms: { field: 'diagnosis.keyword' }
            }
          }
        }
      });
      
      expect(response.ok()).toBeTruthy();
      const result = await response.json();
      
      const buckets = result.aggregations.by_diagnosis.buckets;
      expect(buckets).toHaveLength(2);
      expect(buckets[0].doc_count).toBe(50);
      
      console.log('✅ Aggregations working correctly');
    });

    // Cleanup
    await request.delete(`${OPENSEARCH_URL}/${indexName}`);
  });

  test('should handle error scenarios gracefully', async ({ request }) => {
    await test.step('Handle non-existent index', async () => {
      const response = await request.get(`${OPENSEARCH_URL}/nonexistent-index-xyz/_search`);
      expect(response.status()).toBe(404);
      console.log('✅ 404 error handled correctly');
    });

    await test.step('Handle invalid JSON', async () => {
      const response = await request.post(`${OPENSEARCH_URL}/_search`, {
        headers: { 'Content-Type': 'application/json' },
        data: 'invalid json {'
      });
      expect(response.status()).toBeGreaterThanOrEqual(400);
      console.log('✅ Invalid JSON handled');
    });

    await test.step('Handle invalid query', async () => {
      const indexName = `test-error-${Date.now()}`;
      await request.put(`${OPENSEARCH_URL}/${indexName}`, {
        data: { settings: { number_of_shards: 1 }}
      });
      
      const response = await request.post(`${OPENSEARCH_URL}/${indexName}/_search`, {
        data: {
          query: {
            invalid_query_type: { field: 'value' }
          }
        }
      });
      
      expect(response.status()).toBeGreaterThanOrEqual(400);
      console.log('✅ Invalid query rejected');
      
      await request.delete(`${OPENSEARCH_URL}/${indexName}`);
    });
  });
});

