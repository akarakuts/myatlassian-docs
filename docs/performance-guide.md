# my* Suite Performance Guide

## Обзор

Это руководство описывает нагрузочное тестирование, мониторинг производительности и оптимизацию my* suite.

## Нагрузочное тестирование

### k6 Load Tests

```bash
# Установка k6
# Linux: sudo snap install k6
# macOS: brew install k6

# Запуск health check теста
cd scripts/load-testing
k6 run k6-health-check.js

# Запуск API endpoints теста
k6 run k6-api-endpoints.js

# Запуск бенчмарка
./run-benchmark.sh
```

### Результаты тестирования

| Метрика | Цель | Текущее |
|---------|------|---------|
| Health endpoint | <100ms | ~10ms |
| API response | <500ms | ~50ms |
| Error rate | <1% | 0% |
| Concurrent users | 100+ | 10 |

## Мониторинг производительности

### Prometheus + Grafana

```bash
# Запуск мониторинга
cd scripts/load-testing
./performance-monitor.sh
```

### Метрики

| Метрика | Описание | Источник |
|---------|----------|----------|
| http_requests_total | Количество запросов | /metrics |
| http_request_duration_seconds | Время ответа | /metrics |
| db_connections | Подключения к БД | PostgreSQL |
| memory_usage | Использование памяти | System |

## Оптимизация

### База данных

```sql
-- Проверка медленных запросов
SELECT query, calls, mean_exec_time, total_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;

-- Проверка индексов
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;
```

### Приложения

1. **Кэширование**: Используйте Redis для частых запросов
2. **Пагинация**: Ограничьте выборки (LIMIT/OFFSET)
3. **Индексы**: Добавьте индексы для частых запросов
4. **Коннект пулы**: Настройте размер пула под нагрузку

## Troubleshooting

### Медленный ответ

```bash
# Проверить CPU
top -bn1 | head -20

# Проверить память
free -h

# Проверить диск
df -h

# Проверить PostgreSQL
sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity;"
```

### Высокое потребление памяти

```bash
# Найти тяжелые процессы
ps aux --sort=-%mem | head -10

# Проверить PostgreSQL
sudo -u postgres psql -c "
SELECT datname, pg_size_pretty(pg_database_size(datname))
FROM pg_database ORDER BY pg_database_size(datname) DESC;
"
```

## Ссылки

- [Deployment Guide](deployment-guide.md)
- [API Reference](api-reference.md)
- [Incident Response](runbooks/incident-response.md)
