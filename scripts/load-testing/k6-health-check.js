// k6 Load Test: Health Check для всех 27 сервисов my* suite
// Запуск: k6 run k6-health-check.js

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Метрики
const errorRate = new Rate('errors');
const responseTime = new Trend('response_time');

// Конфигурация
export const options = {
  stages: [
    { duration: '30s', target: 10 },  // Ramp up
    { duration: '1m', target: 10 },   // Stay at 10 users
    { duration: '30s', target: 0 },   // Ramp down
  ],
  thresholds: {
    'http_req_duration': ['p(95)<500'],  // 95% < 500ms
    'errors': ['rate<0.01'],              // <1% errors
  },
};

// Сервисы для тестирования
const SERVICES = [
  { name: 'myjira', port: 3001 },
  { name: 'myconf', port: 3100 },
  { name: 'mycrowd', port: 8080 },
  { name: 'mystatuspage', port: 8090 },
  { name: 'mybitbucket', port: 3002 },
  { name: 'mybamboo', port: 3003 },
  { name: 'myportal', port: 3004 },
  { name: 'myopsgenie', port: 3005 },
  { name: 'myservicedesk', port: 3006 },
  { name: 'mycompass', port: 3007 },
  { name: 'mycalendars', port: 3008 },
  { name: 'myrovo', port: 3010 },
  { name: 'myanalytics', port: 3011 },
  { name: 'mymarketplace', port: 3012 },
  { name: 'myalign', port: 3013 },
  { name: 'mynotifications', port: 3014 },
  { name: 'mychat', port: 3015 },
  { name: 'mytrello', port: 3016 },
  { name: 'mydiscovery', port: 3017 },
  { name: 'myatlas', port: 3018 },
  { name: 'myflow', port: 3020 },
  { name: 'mysearch', port: 3021 },
  { name: 'myjam', port: 3022 },
  { name: 'myrunbook', port: 3023 },
  { name: 'mytimesheets', port: 3024 },
  { name: 'myforms', port: 3025 },
];

export default function () {
  // Случайный сервис
  const service = SERVICES[Math.floor(Math.random() * SERVICES.length)];
  const url = `http://localhost:${service.port}/healthz`;
  
  const response = http.get(url);
  
  // Проверки
  const success = check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
    'response body contains ok': (r) => r.body && r.body.includes('ok'),
  });
  
  // Метрики
  errorRate.add(!success);
  responseTime.add(response.timings.duration);
  
  sleep(0.1);
}

export function handleSummary(data) {
  return {
    '/home/akarakuts/projects/myatlassian/scripts/load-testing/results.json': JSON.stringify(data, null, 2),
    stdout: textSummary(data, { indent: ' ', enableColors: true }),
  };
}
