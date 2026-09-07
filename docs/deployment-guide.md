# my* Suite — Production Deployment Guide

## Обзор

Это руководство описывает развёртывание полного комплекта my* suite (27 приложений) в production.

### Архитектура

```
┌─────────────────────────────────────────────────────────────┐
│                     Load Balancer (Caddy/Nginx)              │
│                     TLS termination + routing                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │ myjira   │  │ myconf   │  │ mycrowd  │  │ myportal │  │
│  │ :3001    │  │ :3000    │  │ :8080    │  │ :3004    │  │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │ mybitbucket│ │ mybamboo │  │ mystatus │  │ myopsgenie│ │
│  │ :3002    │  │ :3003    │  │ :8090    │  │ :3005    │  │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │
│                                                             │
│  ... (26 сервисов)                                          │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                    PostgreSQL (pgvector)                     │
│                    27 баз данных                             │
└─────────────────────────────────────────────────────────────┘
```

## Требования

### Аппаратное обеспечение
- **CPU**: 8+ cores
- **RAM**: 32+ GB (рекомендуется 64 GB)
- **Disk**: 500+ GB SSD
- **Network**: 1 Gbps+

### Программное обеспечение
- Docker 24+
- Docker Compose v2+
- PostgreSQL 16+ (с расширением pgvector)
- Домен с wildcard DNS (*.example.com)

## Шаг 1: Подготовка сервера

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Установка Docker Compose
sudo apt install docker-compose-plugin -y

# Проверка
docker --version
docker compose version
```

## Шаг 2: Клонирование репозитория

```bash
cd /opt
git clone https://github.com/akarakuts/myatlassian.git
cd myatlassian/mycrowd/deploy/suite
```

## Шаг 3: Конфигурация

### 3.1 Создание .env файла

```bash
cp suite.env.example suite.env
```

### 3.2 Основные переменные

```bash
# Безопасность (ОБЯЗАТЕЛЬНО изменить!)
SUITE_ADMIN_PASSWORD=<сильный-пароль>
SESSION_SECRET=<случайная-строка-32+символа>
JWT_SECRET=<случайная-строка-32+символа>

# Домены
PUBLIC_BASE_URL=https://suite.example.com
MYCROWD_URL=https://crowd.example.com
MYJIRA_URL=https://jira.example.com
MYCONF_URL=https://conf.example.com
# ... остальные URL

# База данных
DATABASE_URL=postgres://suite:suite@db:5432/myjira

# OIDC (если используется mycrowd как IdP)
OIDC_ISSUER_URL=https://crowd.example.com
OIDC_CLIENT_ID=<client-id>
OIDC_CLIENT_SECRET=<client-secret>

# Безопасность
COOKIE_SECURE=true
```

### 3.3 Генерация секретов

```bash
# Генерация случайных секретов
openssl rand -hex 32  # для SESSION_SECRET
openssl rand -hex 32  # для JWT_SECRET
openssl rand -hex 32  # для AUDIT_WEBHOOK_SECRET
openssl rand -hex 32  # для NOTIFY_WEBHOOK_SECRET
```

## Шаг 4: Запуск

### 4.1 Первый запуск (two-pass)

```bash
# Pass 1: Запуск БД и mycrowd
docker compose up -d db mycrowd
sleep 30  # Ожидание инициализации

# Bootstrap OIDC
./bootstrap.sh

# Pass 2: Запуск всех сервисов
source suite-oidc.env
docker compose up -d --build

# Bootstrap мониторов
./bootstrap_monitors.sh
```

### 4.2 Проверка статуса

```bash
# Проверка всех контейнеров
docker compose ps

# Проверка логов
docker compose logs -f myjira

# Smoke test
./smoke.sh
```

## Шаг 5: Настройка TLS (Caddy)

### 5.1 Установка Caddy

```bash
sudo apt install caddy -y
```

### 5.2 Конфигурация Caddy

```caddyfile
# /etc/caddy/Caddyfile

*.suite.example.com {
    tls {
        dns cloudflare {env.CF_API_TOKEN}
    }

    @crowd host crowd.suite.example.com
    handle @crowd {
        reverse_proxy localhost:8080
    }

    @jira host jira.suite.example.com
    handle @jira {
        reverse_proxy localhost:3001
    }

    @conf host conf.suite.example.com
    handle @conf {
        reverse_proxy localhost:3000
    }

    # ... остальные сервисы

    handle {
        respond "Not found" 404
    }
}
```

### 5.3 Запуск Caddy

```bash
sudo systemctl enable caddy
sudo systemctl start caddy
```

## Шаг 6: Мониторинг

### 6.1 Prometheus + Grafana

```bash
cd monitoring
docker compose up -d
```

### 6.2 Telegram алерты

```bash
# Настройка в crontab
crontab -e

# Добавить:
0 * * * * /opt/myatlassian/monitor-swap-db.sh
*/5 * * * * /opt/myatlassian/telegram-alerts.sh
0 6 * * * /opt/myatlassian/mytools/backup/target/release/mybackup verify-and-notify
```

## Шаг 7: Бэкапы

### 7.1 Настройка автоматических бэкапов

```bash
# Запуск бэкапа
cd /opt/myatlassian/mytools/backup
./target/release/mybackup full

# Проверка бэкапа
./target/release/mybackup verify-and-notify

# Настройка cron
./scripts/setup-backup-verify.sh
```

### 7.2 Восстановление

```bash
# Восстановление из бэкапа
./target/release/mybackup restore --manifest /path/to/manifest.json --yes
```

## Шаг 8: Обновление

### 8.1 Обновление одного сервиса

```bash
cd /opt/myatlassian
git pull
cd myjira
docker build -t my-suite/myjira:latest .
docker compose up -d myjira
```

### 8.2 Обновление всего комплекта

```bash
cd /opt/myatlassian/mycrowd/deploy/suite
git pull
docker compose up -d --build
```

## Шаг 9: Проверка после развёртывания

### 9.1 Smoke test

```bash
./smoke.sh
```

### 9.2 Ручная проверка

```bash
# Проверка health endpoints
for port in 3001 3100 8080 8090 3002 3003 3004 3005 3006 3007 3008 3010 3011 3012 3013 3014 3015 3016 3017 3018 3020 3021 3022 3023 3024 3025; do
  curl -s http://localhost:$port/healthz || echo "FAIL: $port"
done
```

### 9.3 Проверка логов

```bash
# Просмотр логов всех сервисов
docker compose logs --tail=100

# Просмотр логов конкретного сервиса
docker compose logs -f myjira
```

## Troubleshooting

### Проблема: Сервис не запускается

```bash
# Проверка логов
docker compose logs myjira

# Проверка БД
docker compose exec db psql -U suite -d myjira -c "SELECT 1;"
```

### Проблема: Миграции не применяются

```bash
# Ручной запуск миграций
docker compose exec myjira sqlx migrate run --source migrations
```

### Проблема: OIDC не работает

```bash
# Проверка конфигурации
docker compose exec myjira env | grep OIDC

# Проверка доступности mycrowd
curl https://crowd.suite.example.com/.well-known/openid-configuration
```

## Безопасность

### Чеклист

- [ ] Все пароли изменены (не дефолтные)
- [ ] `COOKIE_SECURE=true` в production
- [ ] TLS настроен и работает
- [ ] Файрвол настроен (только нужные порты)
- [ ] Бэкапы настроены и проверены
- [ ] Мониторинг работает
- [ ] Telegram алерты настроены
- [ ] Логи агрегируются

### Рекомендации

1. **Изолируйте БД** — не暴露ывайте PostgreSQL наружу
2. **Используйте secrets** — храните секреты в env, не в коде
3. **Регулярно обновляйте** — обновляйте зависимости
4. **Мониторьте** — настройте алерты на аномалии
5. **Бэкапьте** — проверяйте восстановление регулярно
