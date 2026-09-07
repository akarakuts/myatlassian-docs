# my* Suite Tools Reference

## Обзор

Справочник по всем инструментам и скриптам my* suite.

## Скрипты

### Мониторинг

| Скрипт | Описание | Запуск |
|--------|----------|--------|
| `scripts/load-testing/performance-monitor.sh` | Мониторинг производительности | `./performance-monitor.sh` |
| `scripts/load-testing/run-benchmark.sh` | Бенчмарк всех сервисов | `./run-benchmark.sh` |
| `scripts/security-scan.sh` | Сканер безопасности | `./security-scan.sh` |

### Нагрузочное тестирование

| Скрипт | Описание | Запуск |
|--------|----------|--------|
| `scripts/load-testing/k6-health-check.js` | k6 health check тест | `k6 run k6-health-check.js` |
| `scripts/load-testing/k6-api-endpoints.js` | k6 API endpoints тест | `k6 run k6-api-endpoints.js` |

### ELK Stack

| Файл | Описание |
|------|----------|
| `scripts/elk-stack/docker-compose.yml` | Docker Compose для ELK |
| `scripts/elk-stack/logstash.conf` | Конфигурация Logstash |

## Документация

| Файл | Описание |
|------|----------|
| `docs/api-reference.md` | API справочник (1,598 server functions) |
| `docs/deployment-guide.md` | Руководство по развёртыванию |
| `docs/performance-guide.md` | Руководство по производительности |
| `docs/runbooks/incident-response.md` | Реагирование на инциденты |
| `docs/runbooks/disaster-recovery.md` | Восстановление после катастроф |
| `docs/runbooks/fix-db-ownership.md` | Исправление прав БД |

## Инструменты

### k6

```bash
# Установка
# Linux: sudo snap install k6
# macOS: brew install k6

# Запуск тестов
k6 run scripts/load-testing/k6-health-check.js
```

### Docker Compose

```bash
# Запуск ELK stack
cd scripts/elk-stack
docker compose up -d

# Проверка
docker compose ps
```

### PostgreSQL

```bash
# Проверка подключений
sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity;"

# Проверка размера БД
sudo -u postgres psql -c "
SELECT datname, pg_size_pretty(pg_database_size(datname))
FROM pg_database ORDER BY pg_database_size(datname) DESC;
"
```

## Cron Jobs

```bash
# Мониторинг swap и PostgreSQL (каждые 5 минут)
*/5 * * * * /home/akarakuts/telegram-alerts.sh

# Полный отчёт (каждый час)
0 * * * * /home/akarakuts/monitor-swap-db.sh

# Проверка бэкапов (каждый день в 6 утра)
0 6 * * * /opt/myatlassian/mytools/backup/target/release/mybackup verify-and-notify
```

## Ссылки

- [Deployment Guide](deployment-guide.md)
- [API Reference](api-reference.md)
- [Performance Guide](performance-guide.md)
