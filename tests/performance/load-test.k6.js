// k6 Load Test for medinovai-1in-kubernetes
// (c) 2026 MedinovAI — Sprint 13: Performance Optimization & Caching
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const errorRate = new Rate('errors');
const responseTime = new Trend('response_time');

export const options = {
  scenarios: {
    smoke: {
      executor: 'constant-vus',
      vus: 5,
      duration: '30s',
    },
    load: {
      executor: 'ramping-vus',
      startTime: '30s',
      stages: [
        { duration: '2m', target: 50 },
        { duration: '5m', target: 100 },
        { duration: '2m', target: 0 },
      ],
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<200', 'p(99)<500'],
    errors: ['rate<0.01'],
  },
};

export default function () {
  const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';
  
  // Health check
  const healthRes = http.get(`${BASE_URL}/api/health`);
  check(healthRes, {
    'health status 200': (r) => r.status === 200,
    'health response < 50ms': (r) => r.timings.duration < 50,
  });
  responseTime.add(healthRes.timings.duration);
  errorRate.add(healthRes.status !== 200);
  
  sleep(1);
}
