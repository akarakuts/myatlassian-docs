#!/bin/bash
# my* Suite Performance Benchmark
# Запуск: ./run-benchmark.sh

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          my* Suite Performance Benchmark                    ║"
echo "║          $(date '+%Y-%m-%d %H:%M:%S')                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Проверка инструментов
echo "=== ПРОВЕРКА ИНСТРУМЕНТОВ ==="
if command -v k6 &> /dev/null; then
  echo "✅ k6 установлен"
else
  echo "❌ k6 не установлен"
  exit 1
fi
echo ""

# Запуск тестов
echo "=== ЗАПУСК НАГРУЗОЧНЫХ ТЕСТОВ ==="
echo ""

# 1. Health check для всех сервисов
echo "1. Health Check (все сервисы)..."
cd /home/akarakuts/projects/myatlassian/scripts/load-testing
k6 run --quiet k6-health-check.js 2>&1 | grep -E "✓|✗|http_req_duration|errors"
echo ""

# 2. Проверка ответа каждого сервиса
echo "2. Response Time Check..."
for port in 3001 3100 8080 8090 3002 3003 3004 3005 3006 3007 3008 3010 3011 3012 3013 3014 3015 3016 3017 3018 3020 3021 3022 3023 3024 3025; do
  start=$(date +%s%N)
  status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost:$port/healthz 2>/dev/null)
  end=$(date +%s%N)
  elapsed=$(( (end - start) / 1000000 ))
  if [ "$status" = "200" ]; then
    echo "  ✅ Port $port: ${elapsed}ms"
  else
    echo "  ❌ Port $port: HTTP $status"
  fi
done
echo ""

# 3. Проверка использования ресурсов
echo "3. Resource Usage..."
echo "  CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')%"
echo "  Memory: $(free -h | grep Mem | awk '{print $3 "/" $2}')"
echo "  Disk: $(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}')"
echo ""

# 4. Проверка PostgreSQL
echo "4. PostgreSQL Performance..."
sudo -u postgres psql -c "
SELECT 
  count(*) as active_connections,
  sum(case when state = 'active' then 1 else 0 end) as active_queries
FROM pg_stat_activity;
" 2>/dev/null
echo ""

echo "=== БЕНЧМАРК ЗАВЕРШЁН ==="
