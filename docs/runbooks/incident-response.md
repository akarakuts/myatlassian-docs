# Runbook: Incident Response

## Обзор

Этот runbook описывает процедуру реагирования на инциденты в my* suite.

## Уровни инцидентов

| Уровень | Описание | Время реакции | Примеры |
|---------|----------|---------------|---------|
| **P0 - Critical** | Сервис полностью недоступен | 15 мин | Все сервисы упали, БД недоступна |
| **P1 - High** | Основной сервис недоступен | 30 мин | myjira/myconf упали, SSO не работает |
| **P2 - Medium** | Функциональность ограничена | 2 часа | Медленный ответ,部分功能不可用 |
| **P3 - Low** | Минимальное влияние | 24 часа | Косметические проблемы, лог-ошибки |

## Процедура реагирования

### Шаг 1: Обнаружение и оценка (0-5 мин)

```bash
# Проверить статус всех сервисов
./status.sh

# Проверить логи
docker compose logs --tail=50

# Проверить метрики
curl -s http://localhost:3001/metrics | head -20
```

### Шаг 2: Изоляция (5-15 мин)

```bash
# Если проблема в одном сервисе - перезапустить его
docker compose restart myjira

# Если проблема в БД - проверить подключения
sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity;"

# Если проблема в ресурсах - проверить использование
free -h
df -h
```

### Шаг 3: Восстановление (15-60 мин)

```bash
# Восстановление из бэкапа
cd /opt/myatlassian/mytools/backup
./target/release/mybackup restore --manifest /path/to/manifest.json --yes

# Перезапуск всех сервисов
cd /opt/myatlassian/mycrowd/deploy/suite
docker compose down
docker compose up -d --build
```

### Шаг 4: Пост-инцидент (после восстановления)

1. Записать хронологию инцидента
2. Определить корневую причину
3. Создать задачи для исправления
4. Обновить runbook если нужно

## Типичные инциденты и решения

### Инцидент: Сервис не запускается

**Симптомы:** `docker compose up` падает с ошибкой

**Решение:**
```bash
# Проверить логи
docker compose logs myjira

# Проверить миграции
docker compose exec myjira sqlx migrate status

# Перезапустить с очисткой
docker compose down -v
docker compose up -d --build
```

### Инцидент: БД недоступна

**Симптомы:** Ошибки подключения к БД

**Решение:**
```bash
# Проверить статус PostgreSQL
sudo systemctl status postgresql

# Проверить подключения
sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity;"

# Перезапустить PostgreSQL
sudo systemctl restart postgresql
```

### Инцидент: Высокая нагрузка на CPU

**Симптомы:** Медленный ответ, таймауты

**Решение:**
```bash
# Найти тяжелые процессы
top -bn1 | head -20

# Проверить логи на ошибки
docker compose logs --tail=100 | grep -i error

# Масштабировать если нужно
docker compose up -d --scale myjira=3
```

### Инцидент: Утечка памяти

**Симптомы:** Растущее потребление памяти

**Решение:**
```bash
# Проверить потребление памяти
ps aux --sort=-%mem | head -10

# Перезапустить сервисы
docker compose restart

# Если проблема сохраняется - пересобрать
docker compose down
docker compose up -d --build
```

## Инструменты мониторинга

### Prometheus + Grafana

```bash
# Проверить метрики
curl -s http://localhost:9090/api/v1/query?query=up

# Проверить алерты
curl -s http://localhost:9090/api/v1/alerts
```

### Telegram алерты

```bash
# Проверить логи алертов
cat /home/akarakuts/telegram-alerts.log

# Тестовый алерт
/home/akarakuts/test-telegram.sh
```

## Контакты

- **On-call инженер:** [Добавить контакт]
- **Руководитель:** [Добавить контакт]
- **Escalation:** [Добавить контакт]

## Ссылки

- [Deployment Guide](deployment-guide.md)
- [API Reference](api-reference.md)
- [DB Ownership Runbook](fix-db-ownership.md)
