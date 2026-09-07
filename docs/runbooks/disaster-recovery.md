# Runbook: Disaster Recovery

## Обзор

Этот runbook описывает процедуру восстановления my* suite после катастрофического сбоя.

## Сценарии восстановления

### Сценарий 1: Полная потеря сервера

**Время восстановления:** 2-4 часа

**Шаги:**

1. **Подготовка нового сервера**
```bash
# Установить Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Клонировать репозиторий
cd /opt
git clone https://github.com/akarakuts/myatlassian.git
cd myatlassian/mycrowd/deploy/suite
```

2. **Восстановить конфигурацию**
```bash
# Скопировать .env файл с бэкапа
cp /path/to/backup/suite.env .env

# Или создать новый
cp suite.env.example suite.env
# Заполнить переменные
```

3. **Восстановить БД**
```bash
# Если есть бэкап БД
cd /opt/myatlassian/mytools/backup
./target/release/mybackup restore --manifest /path/to/manifest.json --yes

# Или создать новые БД
docker compose up -d db
sleep 30
./bootstrap.sh
```

4. **Запустить сервисы**
```bash
cd /opt/myatlassian/mycrowd/deploy/suite
docker compose up -d --build
```

5. **Проверить работу**
```bash
./smoke.sh
```

### Сценарий 2: Повреждение БД

**Время восстановления:** 30-60 минут

**Шаги:**

1. **Остановить сервисы**
```bash
docker compose down
```

2. **Восстановить из бэкапа**
```bash
cd /opt/myatlassian/mytools/backup
./target/release/mybackup restore --manifest /path/to/manifest.json --yes
```

3. **Запустить сервисы**
```bash
cd /opt/myatlassian/mycrowd/deploy/suite
docker compose up -d
```

4. **Проверить целостность**
```bash
./smoke.sh
```

### Сценарий 3: Потеря данных

**Время восстановления:** 1-2 часа

**Шаги:**

1. **Остановить запись новых данных**
```bash
# Перевести в режим только для чтения
docker compose down
```

2. **Восстановить из бэкапа**
```bash
cd /opt/myatlassian/mytools/backup
./target/release/mybackup restore --manifest /path/to/manifest.json --yes
```

3. **Проверить восстановленные данные**
```bash
# Проверить количество записей
sudo -u postgres psql -c "
SELECT 'myjira' as db, count(*) FROM myjira.public.issues
UNION ALL
SELECT 'myconf', count(*) FROM myconf.public.pages
UNION ALL
SELECT 'mybitbucket', count(*) FROM mybitbucket.public.repositories;
"
```

4. **Запустить сервисы**
```bash
cd /opt/myatlassian/mycrowd/deploy/suite
docker compose up -d
```

## Автоматические бэкапы

### Настройка

```bash
# Настройка cron для автоматических бэкапов
cd /opt/myatlassian/mytools/backup
./scripts/setup-backup-verify.sh

# Проверить расписание
crontab -l | grep backup
```

### Проверка бэкапов

```bash
# Проверить последний бэкап
./target/release/mybackup verify-and-notify

# Проверить все бэкапы
./target/release/mybackup list
```

## Процедура восстановления

### Шаг 1: Оценка ситуации

```bash
# Определить тип сбоя
echo "=== ОЦЕНКА СИТУАЦИИ ==="

# Проверить доступность сервера
ping -c 3 localhost

# Проверить Docker
docker ps

# Проверить БД
sudo -u postgres psql -c "SELECT 1;"

# Проверить дисковое пространство
df -h
```

### Шаг 2: Выбор стратегии восстановления

| Ситуация | Стратегия | Время |
|----------|-----------|-------|
| Потеря данных | Восстановить из бэкапа | 1-2 часа |
| Повреждение БД | Восстановить из бэкапа | 30-60 мин |
| Потеря сервера | Развернуть на новом | 2-4 часа |
| Частичный сбой | Перезапустить сервисы | 5-15 мин |

### Шаг 3: Восстановление

```bash
# Пример восстановления из бэкапа
cd /opt/myatlassian/mytools/backup

# Найти последний бэкап
./target/release/mybackup list

# Восстановить
./target/release/mybackup restore --manifest /path/to/latest/manifest.json --yes

# Проверить
./target/release/mybackup verify
```

### Шаг 4: Проверка

```bash
# Запустить сервисы
cd /opt/myatlassian/mycrowd/deploy/suite
docker compose up -d

# Smoke test
./smoke.sh

# Проверить логи
docker compose logs --tail=50
```

## Профилактика

### Регулярные проверки

```bash
# Ежедневная проверка бэкапов
0 6 * * * /opt/myatlassian/mytools/backup/target/release/mybackup verify-and-notify

# Еженедельная полная проверка
0 2 * * 0 /opt/myatlassian/mytools/backup/target/release/mybackup full
```

### Мониторинг

```bash
# Проверить свободное место
df -h | grep -E "(/$|/data)"

# Проверить размер БД
sudo -u postgres psql -c "
SELECT datname, pg_size_pretty(pg_database_size(datname))
FROM pg_database ORDER BY pg_database_size(datname) DESC;
"
```

## Ссылки

- [Deployment Guide](deployment-guide.md)
- [Incident Response](incident-response.md)
- [DB Ownership Runbook](fix-db-ownership.md)
