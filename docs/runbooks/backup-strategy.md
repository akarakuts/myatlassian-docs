# my* Suite — Backup Strategy

## Обзор

Стратегия резервного копирования для всех 27 сервисов my* suite.

## Архитектура бэкапов

```
┌─────────────────────────────────────────────────────────────┐
│                    PRIMARY BACKUP                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │ myjira   │  │ myconf   │  │ mycrowd  │  │ myportal │  │
│  │ DB + files│  │ DB + files│  │ DB + files│  │ DB + files│  │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │
│                    │                                        │
│                    ▼                                        │
│            ┌──────────────┐                                │
│            │  pg_dump     │                                │
│            │  (custom)    │                                │
│            └──────────────┘                                │
│                    │                                        │
│                    ▼                                        │
│            ┌──────────────┐                                │
│            │  Local disk  │                                │
│            │  /backups/   │                                │
│            └──────────────┘                                │
└─────────────────────────────────────────────────────────────┘
                    │
                    ▼ (rsync/rclone)
┌─────────────────────────────────────────────────────────────┐
│                    OFFSITE BACKUP                           │
│            ┌──────────────┐                                │
│            │  S3/GCS/     │                                │
│            │  Azure Blob  │                                │
│            └──────────────┘                                │
└─────────────────────────────────────────────────────────────┘
```

## Типы бэкапов

### 1. Полный бэкап (Full)

**Частота:** Ежедневно в 2:00
**Хранение:** 30 дней
**Содержимое:**
- Все 27 баз данных PostgreSQL
- Файлы приложений (migrations, configs)
- Загруженные файлы (attachments)

```bash
# Запуск полного бэкапа
cd /opt/myatlassian/mytools/backup
./target/release/mybackup full
```

### 2. Инкрементальный бэкап (Incremental)

**Частота:** Каждые 6 часов
**Хранение:** 7 дней
**Содержимое:**
- Только изменения с последнего полного бэкапа
- WAL архивы PostgreSQL

```bash
# Запуск инкрементального бэкапа
./target/release/mybackup incremental
```

### 3. Логи транзакций (WAL)

**Частота:** Непрерывно
**Хранение:** 3 дня
**Содержимое:**
- Write-Ahead Log файлы PostgreSQL
- Позволяет восстановление до конкретного момента времени

## Процедура бэкапа

### Автоматический бэкап

```bash
# Настройка cron для автоматических бэкапов
crontab -e

# Добавить:
# Полный бэкап ежедневно в 2:00
0 2 * * * /opt/myatlassian/mytools/backup/target/release/mybackup full

# Инкрементальный бэкап каждые 6 часов
0 */6 * * * /opt/myatlassian/mytools/backup/target/release/mybackup incremental

# Проверка бэкапов ежедневно в 6:00
0 6 * * * /opt/myatlassian/mytools/backup/target/release/mybackup verify-and-notify
```

### Ручной бэкап

```bash
# Полный бэкап
cd /opt/myatlassian/mytools/backup
./target/release/mybackup full

# Проверка бэкапа
./target/release/mybackup verify

# Отправка уведомления
./target/release/mybackup verify-and-notify
```

## Восстановление

### Восстановление полного бэкапа

```bash
# Найти последний бэкап
./target/release/mybackup list

# Восстановить
./target/release/mybackup restore --manifest /path/to/manifest.json --yes

# Проверить восстановление
./target/release/mybackup verify
```

### Восстановление до конкретного момента времени

```bash
# Восстановить из полного бэкапа
./target/release/mybackup restore --manifest /path/to/full-manifest.json --yes

# Применить WAL логи до нужного момента
# (PostgreSQL автоматически применит WAL при восстановлении)
```

## Хранение бэкапов

### Локальное хранение

```bash
# Директория бэкапов
/opt/backups/my-suite/

# Структура
/opt/backups/my-suite/
├── 2026-09-07/
│   ├── full/
│   │   ├── myjira.dump
│   │   ├── myconf.dump
│   │   └── ...
│   └── incremental/
│       ├── myjira-wal/
│       └── ...
└── manifest.json
```

### Облачное хранение

```bash
# Настройка S3
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_REGION="us-east-1"
export BACKUP_BUCKET="my-suite-backups"

# Синхронизация с S3
aws s3 sync /opt/backups/my-suite/ s3://$BACKUP_BUCKET/
```

## Проверка бэкапов

### Автоматическая проверка

```bash
# Проверка целостности
./target/release/mybackup verify

# Проверка с уведомлением
./target/release/mybackup verify-and-notify
```

### Ручная проверка

```bash
# Проверка манифеста
cat /opt/backups/my-suite/manifest.json | jq .

# Проверка целостности файлов
sha256sum -c /opt/backups/my-suite/checksums.sha256
```

## Безопасность бэкапов

### Шифрование

```bash
# Шифрование бэкапа
gpg --encrypt --recipient your-key@example.com backup.tar.gz

# Дешифрование
gpg --decrypt backup.tar.gz.gpg > backup.tar.gz
```

### Доступ

- Бэкапы доступны только администраторам
- Ключи шифрования хранятся в безопасном хранилище
- Регулярная ротация ключей

## Мониторинг

### Telegram уведомления

```bash
# Настройка уведомлений
export TELEGRAM_BOT_TOKEN="your-token"
export TELEGRAM_CHAT_ID="your-chat-id"

# Проверка с уведомлением
./target/release/mybackup verify-and-notify
```

### Метрики

```bash
# Проверка размера бэкапов
du -sh /opt/backups/my-suite/*

# Проверка последнего бэкапа
ls -lt /opt/backups/my-suite/ | head -5
```

## Troubleshooting

### Проблема: Бэкап не создается

```bash
# Проверить место на диске
df -h

# Проверить права доступа
ls -la /opt/backups/

# Проверить логи
tail -100 /var/log/backup.log
```

### Проблема: Восстановление не работает

```bash
# Проверить целостность бэкапа
./target/release/mybackup verify

# Проверить доступность PostgreSQL
sudo -u postgres psql -c "SELECT 1;"

# Проверить место на диске
df -h
```

## Ссылки

- [Disaster Recovery Plan](disaster-recovery-plan.md)
- [High Availability](high-availability.md)
- [Incident Response](incident-response.md)
