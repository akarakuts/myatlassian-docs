# my* Suite — Disaster Recovery Plan

## Обзор

Этот документ описывает полный план восстановления my* suite после катастрофического сбоя.

## RTO/RPO цели

| Уровень | RTO (Recovery Time) | RPO (Recovery Point) | Описание |
|---------|---------------------|----------------------|----------|
| **P0 - Critical** | 1 час | 0 данных | Полная потеря сервера |
| **P1 - High** | 30 минут | 5 минут | Повреждение БД |
| **P2 - Medium** | 15 минут | 1 час | Частичный сбой сервиса |
| **P3 - Low** | 5 минут | 24 часа | Потеря одного сервиса |

## Архитектура восстановления

```
┌─────────────────────────────────────────────────────────────┐
│                     PRIMARY SITE                            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │ myjira   │  │ myconf   │  │ mycrowd  │  │ myportal │  │
│  │ :3001    │  │ :3100    │  │ :8080    │  │ :3004    │  │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │
│                    │                                        │
│                    ▼                                        │
│            ┌──────────────┐                                │
│            │  PostgreSQL  │                                │
│            │  (primary)   │                                │
│            └──────────────┘                                │
│                    │                                        │
│                    ▼                                        │
│            ┌──────────────┐                                │
│            │   Backups    │                                │
│            │  (S3/local)  │                                │
│            └──────────────┘                                │
└─────────────────────────────────────────────────────────────┘
                    │
                    ▼ (async replication)
┌─────────────────────────────────────────────────────────────┐
│                    SECONDARY SITE                           │
│            ┌──────────────┐                                │
│            │  PostgreSQL  │                                │
│            │  (standby)   │                                │
│            └──────────────┘                                │
└─────────────────────────────────────────────────────────────┘
```

## Процедуры восстановления

### Сценарий 1: Полная потеря сервера (P0)

**RTO:** 1 час | **RPO:** 0 данных

#### Шаги:

1. **Подготовка нового сервера (10 мин)**
```bash
# Установить Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Клонировать репозиторий
cd /opt
git clone https://github.com/akarakuts/myatlassian.git
```

2. **Восстановить конфигурацию (5 мин)**
```bash
cd /opt/myatlassian/mycrowd/deploy/suite
cp suite.env.example suite.env
# Заполнить переменные из безопасного хранилища
```

3. **Восстановить БД (30 мин)**
```bash
cd /opt/myatlassian/mytools/backup
./target/release/mybackup restore --manifest /path/to/manifest.json --yes
```

4. **Запустить сервисы (10 мин)**
```bash
cd /opt/myatlassian/mycrowd/deploy/suite
docker compose up -d --build
```

5. **Проверить работу (5 мин)**
```bash
./smoke.sh
```

### Сценарий 2: Повреждение БД (P1)

**RTO:** 30 минут | **RPO:** 5 минут

#### Шаги:

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

### Сценарий 3: Частичный сбой сервиса (P2)

**RTO:** 15 минут | **RPO:** 1 час

#### Шаги:

1. **Определить проблемный сервис**
```bash
./scripts/load-testing/performance-monitor.sh
```

2. **Перезапустить сервис**
```bash
docker compose restart myjira
```

3. **Проверить работу**
```bash
curl -s http://localhost:3001/healthz
```

### Сценарий 4: Потеря одного сервиса (P3)

**RTO:** 5 минут | **RPO:** 24 часа

#### Шаги:

1. **Перезапустить сервис**
```bash
docker compose restart myjira
```

2. **Проверить работу**
```bash
curl -s http://localhost:3001/healthz
```

## Автоматические бэкапы

### Расписание

| Тип | Частота | Хранение | Описание |
|-----|---------|----------|----------|
| Полный | Ежедневно 2:00 | 30 дней | Все БД + файлы |
| Инкрементальный | Каждые 6 часов | 7 дней | Только изменения |
| Логи | Непрерывно | 3 дня | WAL архивы |

### Проверка бэкапов

```bash
# Ежедневная проверка
0 6 * * * /opt/myatlassian/mytools/backup/target/release/mybackup verify-and-notify

# Еженедельная полная проверка
0 2 * * 0 /opt/myatlassian/mytools/backup/target/release/mybackup full
```

## Мониторинг

### Prometheus метрики

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'my-suite'
    static_configs:
      - targets:
        - 'localhost:3001'  # myjira
        - 'localhost:3100'  # myconf
        - 'localhost:8080'  # mycrowd
        # ... остальные сервисы
```

### Telegram алерты

```bash
# Настройка алертов
export TELEGRAM_BOT_TOKEN="your-token"
export TELEGRAM_CHAT_ID="your-chat-id"

# Запуск мониторинга
/home/akarakuts/telegram-alerts.sh
```

## Контакты

| Роль | Контакт | Телефон |
|------|---------|---------|
| On-call инженер | [Добавить] | [Добавить] |
| Руководитель | [Добавить] | [Добавить] |
| Escalation | [Добавить] | [Добавить] |

## Ссылки

- [Backup Strategy](backup-strategy.md)
- [High Availability](high-availability.md)
- [Incident Response](incident-response.md)
- [Deployment Guide](../deployment-guide.md)
