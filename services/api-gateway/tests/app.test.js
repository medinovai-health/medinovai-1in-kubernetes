const request = require('supertest');
const app = require('../src/index');

describe('api_gateway API', () => {
  describe('GET /health', () => {
    it('should return health status', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);
        
      expect(response.body).toHaveProperty('status', 'healthy');
      expect(response.body).toHaveProperty('service', 'api_gateway');
    });
  });
  
  describe('GET /ready', () => {
    it('should return readiness status', async () => {
      const response = await request(app)
        .get('/ready')
        .expect(200);
        
      expect(response.body).toHaveProperty('status', 'ready');
      expect(response.body).toHaveProperty('service', 'api_gateway');
    });
  });
});
