# my* Suite — High Availability Architecture

## Обзор

Архитектура высокой доступности для my* suite (27 сервисов).

## Текущая архитектура

```
┌─────────────────────────────────────────────────────────────┐
│                     Load Balancer                           │
│                   (Caddy/Nginx/HAProxy)                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                 PRIMARY NODE                         │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐          │  │
│  │  │ myjira   │  │ myconf   │  │ mycrowd  │          │  │
│  │  │ :3001    │  │ :3100    │  │ :8080    │          │  │
│  │  └──────────┘  └──────────┘  └──────────┘          │  │
│  │                                                     │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐          │  │
│  │  │ mybitbucket│ │ mybamboo │  │ myportal │          │  │
│  │  │ :3002    │  │ :3003    │  │ :3004    │          │  │
│  │  └──────────┘  └──────────┘  └──────────┘          │  │
│  │                                                     │  │
│  │  ... (26 сервисов)                                  │  │
│  │                                                     │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                 DATABASE LAYER                       │  │
│  │  ┌──────────────┐  ┌──────────────┐                  │  │
│  │  │  PostgreSQL  │  │  PostgreSQL  │                  │  │
│  │  │  (primary)   │──│  (standby)   │                  │  │
│  │  └──────────────┘  └──────────────┘                  │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Компоненты высокой доступности

### 1. Load Balancer

**Цель:** Распределение трафика между сервисами

```caddyfile
# /etc/caddy/Caddyfile

*.suite.example.com {
    tls {
        dns cloudflare {env.CF_API_TOKEN}
    }

    @jira host jira.suite.example.com
    handle @jira {
        reverse_proxy localhost:3001
    }

    @conf host conf.suite.example.com
    handle @conf {
        reverse_proxy localhost:3100
    }

    # ... остальные сервисы
}
```

### 2. Database Replication

**Цель:** Автоматическое переключение при сбое primary

```bash
# Настройка streaming replication
# На primary:
wal_level = replica
max_wal_senders = 3
wal_keep_size = '1GB'

# На standby:
primary_conninfo = 'host=primary port=5432 user=replicator'
```

### 3. Health Checks

**Цель:** Обнаружение и восстановление после сбоев

```bash
# Проверка здоровья сервисов
for port in 3001 3100 8080 8090 3002 3003 3004 3005 3006 3007 3008 3010 3011 3012 3013 3014 3015 3016 3017 3018 3020 3021 3022 3023 3024 3025; do
  status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost:$port/healthz 2>/dev/null)
  if [ "$status" != "200" ]; then
    echo "ALERT: Service on port $port is down!"
    # Автоматическое восстановление
    docker compose restart myservice
  fi
done
```

## Стратегии высокой доступности

### 1. Active-Passive (для БД)

```
Primary DB ──replication──> Standby DB
     │                        │
     │                        │
     └───── Load Balancer ────┘
```

**Преимущества:**
- Простая настройка
- Автоматическое переключение при сбое

**Недостатки:**
- Standby простаивает
- Задержка репликации

### 2. Active-Active (для сервисов)

```
Load Balancer
     │
     ├── Service Instance 1
     ├── Service Instance 2
     └── Service Instance 3
```

**Преимущества:**
- Высокая производительность
- Нет простоя при обновлениях

**Недостатки:**
- Сложная настройка
- Требует stateless сервисы

### 3. Multi-Region (для Disaster Recovery)

```
Region 1 (Primary)     Region 2 (DR)
┌──────────────┐       ┌──────────────┐
│  Services    │       │  Services    │
│  Database    │───────│  Database    │
└──────────────┘       └──────────────┘
```

## Docker Compose для HA

```yaml
# docker-compose.ha.yml
version: '3.8'

services:
  # Load Balancer
  nginx:
    image: nginx:latest
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - myjira
      - myconf
      - mycrowd

  # myjira с репликацией
  myjira:
    build: ./myjira
    deploy:
      replicas: 2
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3001/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3

  # PostgreSQL с репликацией
  postgres-primary:
    image: pgvector/pgvector:pg18
    environment:
      POSTGRES_USER: suite
      POSTGRES_PASSWORD: suite
    volumes:
      - postgres-primary:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U suite"]
      interval: 5s
      timeout: 3s
      retries: 20

  postgres-standby:
    image: pgvector/pgvector:pg18
    environment:
      POSTGRES_USER: suite
      POSTGRES_PASSWORD: suite
      PGUSER: suite
    volumes:
      - postgres-standby:/var/lib/postgresql/data
    depends_on:
      postgres-primary:
        condition: service_healthy
```

## Мониторинг HA

### Prometheus метрики

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'my-suite-ha'
    static_configs:
      - targets:
        - 'localhost:3001'  # myjira
        - 'localhost:3100'  # myconf
        - 'localhost:8080'  # mycrowd
    metrics_path: '/metrics'
    scrape_interval: 15s
```

### Grafana Dashboard

```json
{
  "dashboard": {
    "title": "my* Suite HA",
    "panels": [
      {
        "title": "Service Health",
        "type": "stat",
        "targets": [
          {
            "expr": "up{job=\"my-suite-ha\"}"
          }
        ]
      },
      {
        "title": "Response Time",
        "type": "graph",
        "targets": [
          {
            "expr": "http_request_duration_seconds{job=\"my-suite-ha\"}"
          }
        ]
      }
    ]
  }
}
```

## Failover Procedures

### Automatic Failover (Database)

```bash
# Настройка automatic failover
# Использовать pg_auto_failover или Patroni

# Проверка статуса
pg_autoctl show state

# Ручное переключение (если нужно)
pg_autoctl perform failover
```

### Manual Failover (Services)

```bash
# Остановить проблемный сервис
docker compose stop myjira

# Запустить на standby
docker compose -f docker-compose.standby.yml up -d myjira

# Проверить работу
curl -s http://localhost:3001/healthz
```

## Performance Optimization

### Connection Pooling

```bash
# Настройка PgBouncer
[databases]
myjira = host=localhost port=5432 dbname=myjira

[pgbouncer]
listen_port = 6432
pool_mode = transaction
max_client_conn = 100
default_pool_size = 20
```

### Caching

```bash
# Настройка Redis для кэширования
redis-server --maxmemory 256mb --maxmemory-policy allkeys-lru
```

### Load Balancing

```bash
# Настройка Nginx для load balancing
upstream myjira {
    server localhost:3001;
    server localhost:3001 backup;
}

server {
    listen 80;
    server_name jira.suite.example.com;
    
    location / {
        proxy_pass http://myjira;
    }
}
```

## Безопасность

### TLS Configuration

```bash
# Генерация сертификатов
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout server.key -out server.crt

# Настройка Caddy для автоматического TLS
*.suite.example.com {
    tls {
        dns cloudflare {env.CF_API_TOKEN}
    }
}
```

### Firewall Rules

```bash
# Настройка UFW
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw deny all        # Block all other
```

## Мониторинг и алерты

### Prometheus алерты

```yaml
# alerting_rules.yml
groups:
  - name: my-suite-ha
    rules:
      - alert: ServiceDown
        expr: up{job="my-suite-ha"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Service {{ $labels.instance }} is down"

      - alert: HighResponseTime
        expr: http_request_duration_seconds{job="my-suite-ha"} > 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High response time on {{ $labels.instance }}"
```

### Telegram уведомления

```bash
# Настройка алертов
export TELEGRAM_BOT_TOKEN="your-token"
export TELEGRAM_CHAT_ID="your-chat-id"

# Запуск мониторинга
/home/akarakuts/telegram-alerts.sh
```

## Troubleshooting

### Проблема: Сервис не отвечает

```bash
# Проверить статус контейнера
docker compose ps

# Проверить логи
docker compose logs myjira

# Перезапустить сервис
docker compose restart myjira
```

### Проблема: Высокая нагрузка на CPU

```bash
# Проверить использование CPU
top -bn1 | head -20

# Найти тяжелые процессы
ps aux --sort=-%cpu | head -10

# Масштабировать сервис
docker compose up -d --scale myjira=3
```

### Проблема: Нехватка памяти

```bash
# Проверить использование памяти
free -h

# Найти тяжелые процессы
ps aux --sort=-%mem | head -10

# Освободить память
sync && echo 3 | sudo tee /proc/sys/vm/drop_caches
```

## Ссылки

- [Disaster Recovery Plan](disaster-recovery-plan.md)
- [Backup Strategy](backup-strategy.md)
- [Incident Response](incident-response.md)
- [Deployment Guide](../deployment-guide.md)
