// k6 Load Test: API Endpoints для my* suite
// Запуск: k6 run k6-api-endpoints.js

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const errorRate = new Rate('errors');
const responseTime = new Trend('response_time');

export const options = {
  stages: [
    { duration: '1m', target: 5 },
    { duration: '2m', target: 5 },
    { duration: '1m', target: 0 },
  ],
  thresholds: {
    'http_req_duration': ['p(95)<1000'],
    'errors': ['rate<0.05'],
  },
};

const ENDPOINTS = [
  // Public endpoints
  { name: 'myjira-health', url: 'http://localhost:3001/healthz' },
  { name: 'myconf-health', url: 'http://localhost:3100/healthz' },
  { name: 'mycrowd-health', url: 'http://localhost:8080/healthz' },
  { name: 'myjira-widget', url: 'http://localhost:3001/api/v1/widget' },
  { name: 'myconf-widget', url: 'http://localhost:3100/api/v1/widget' },
  { name: 'myflow-widget', url: 'http://localhost:3020/api/v1/widget' },
  { name: 'mysearch-widget', url: 'http://localhost:3021/api/v1/widget' },
  { name: 'myforms-widget', url: 'http://localhost:3025/api/v1/widget' },
  { name: 'myjira-metrics', url: 'http://localhost:3001/metrics' },
  { name: 'myconf-metrics', url: 'http://localhost:3100/metrics' },
  { name: 'myflow-metrics', url: 'http://localhost:3020/metrics' },
];

export default function () {
  const endpoint = ENDPOINTS[Math.floor(Math.random() * ENDPOINTS.length)];
  
  const response = http.get(endpoint.url);
  
  const success = check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 1000ms': (r) => r.timings.duration < 1000,
  });
  
  errorRate.add(!success);
  responseTime.add(response.timings.duration);
  
  sleep(0.5);
}
