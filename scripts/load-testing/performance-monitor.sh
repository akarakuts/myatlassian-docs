#!/bin/bash
# my* Suite Performance Monitor
# Запуск: ./performance-monitor.sh

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          my* Suite Performance Monitor                      ║"
echo "║          $(date '+%Y-%m-%d %H:%M:%S')                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Проверка ответа каждого сервиса
echo "=== RESPONSE TIMES ==="
for port in 3001 3100 8080 8090 3002 3003 3004 3005 3006 3007 3008 3010 3011 3012 3013 3014 3015 3016 3017 3018 3020 3021 3022 3023 3024 3025; do
  start=$(date +%s%N)
  status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost:$port/healthz 2>/dev/null)
  end=$(date +%s%N)
  elapsed=$(( (end - start) / 1000000 ))
  if [ "$status" = "200" ]; then
    if [ $elapsed -lt 100 ]; then
      echo "  ✅ Port $port: ${elapsed}ms (fast)"
    elif [ $elapsed -lt 500 ]; then
      echo "  ⚠️  Port $port: ${elapsed}ms (moderate)"
    else
      echo "  ❌ Port $port: ${elapsed}ms (slow)"
    fi
  else
    echo "  ❌ Port $port: HTTP $status"
  fi
done
echo ""

# Проверка PostgreSQL
echo "=== POSTGRESQL ==="
sudo -u postgres psql -c "
SELECT 
  count(*) as total_connections,
  sum(case when state = 'active' then 1 else 0 end) as active_queries,
  sum(case when state = 'idle' then 1 else 0 end) as idle_connections
FROM pg_stat_activity;
" 2>/dev/null
echo ""

# Проверка ресурсов
echo "=== SYSTEM RESOURCES ==="
echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')%"
echo "Memory: $(free -h | grep Mem | awk '{print $3 "/" $2}')"
echo "Swap: $(free -h | grep Swap | awk '{print $3 "/" $2}')"
echo ""

echo "=== MONITORING COMPLETE ==="
