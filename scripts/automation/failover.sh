#!/bin/bash
# my* Suite — Automatic Failover Script
# Автоматическое переключение при сбое сервиса
# Запуск: ./failover.sh [service_name]

set -e

SERVICE=$1
LOG_FILE="/var/log/my-suite/failover.log"
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

send_alert() {
    local message="$1"
    if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            -d "chat_id=${TELEGRAM_CHAT_ID}" \
            -d "text=${message}" \
            -d "parse_mode=HTML" > /dev/null 2>&1
    fi
}

check_service() {
    local port=$1
    local status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://localhost:${port}/healthz" 2>/dev/null)
    echo "$status"
}

# Определение портов сервисов
declare -A SERVICE_PORTS=(
    ["myjira"]="3001"
    ["myconf"]="3100"
    ["mycrowd"]="8080"
    ["mystatuspage"]="8090"
    ["mybitbucket"]="3002"
    ["mybamboo"]="3003"
    ["myportal"]="3004"
    ["myopsgenie"]="3005"
    ["myservicedesk"]="3006"
    ["mycompass"]="3007"
    ["mycalendars"]="3008"
    ["myrovo"]="3010"
    ["myanalytics"]="3011"
    ["mymarketplace"]="3012"
    ["myalign"]="3013"
    ["mynotifications"]="3014"
    ["mychat"]="3015"
    ["mytrello"]="3016"
    ["mydiscovery"]="3017"
    ["myatlas"]="3018"
    ["myflow"]="3020"
    ["mysearch"]="3021"
    ["myjam"]="3022"
    ["myrunbook"]="3023"
    ["mytimesheets"]="3024"
    ["myforms"]="3025"
)

# Проверка аргументов
if [ -z "$SERVICE" ]; then
    echo "Использование: $0 <service_name>"
    echo "Доступные сервисы: ${!SERVICE_PORTS[@]}"
    exit 1
fi

if [ -z "${SERVICE_PORTS[$SERVICE]}" ]; then
    echo "Ошибка: Неизвестный сервис '$SERVICE'"
    exit 1
fi

PORT=${SERVICE_PORTS[$SERVICE]}

log "=== FAILOVER: $SERVICE (port $PORT) ==="

# Шаг 1: Проверить текущий статус
log "Шаг 1: Проверка статуса сервиса..."
STATUS=$(check_service "$PORT")
if [ "$STATUS" = "200" ]; then
    log "Сервис $SERVICE работает нормально (HTTP $STATUS)"
    exit 0
fi

log "Сервис $SERVICE не отвечает (HTTP $STATUS)"

# Шаг 2: Отправить алерт
send_alert "⚠️ <b>FAILOVER ALERT</b>

Сервис: $SERVICE
Порт: $PORT
Статус: HTTP $STATUS
Время: $(date '+%Y-%m-%d %H:%M:%S')

Начинается автоматическое восстановление..."

# Шаг 3: Перезапустить сервис
log "Шаг 3: Перезапуск сервиса..."
cd /opt/myatlassian/mycrowd/deploy/suite
docker compose restart "$SERVICE" 2>&1 | tee -a "$LOG_FILE"

# Шаг 4: Ожидание восстановления
log "Шаг 4: Ожидание восстановления (30 сек)..."
sleep 30

# Шаг 5: Проверка восстановления
log "Шаг 5: Проверка восстановления..."
STATUS=$(check_service "$PORT")
if [ "$STATUS" = "200" ]; then
    log "✅ Сервис $SERVICE восстановлен (HTTP $STATUS)"
    send_alert "✅ <b>FAILOVER SUCCESS</b>

Сервис: $SERVICE
Статус: HTTP $STATUS
Время: $(date '+%Y-%m-%d %H:%M:%S')

Сервис успешно восстановлен автоматически."
else
    log "❌ Сервис $SERVICE не восстановлен (HTTP $STATUS)"
    send_alert "❌ <b>FAILOVER FAILED</b>

Сервис: $SERVICE
Статус: HTTP $STATUS
Время: $(date '+%Y-%m-%d %H:%M:%S')

Автоматическое восстановление не удалось. Требуется ручное вмешательство."
    exit 1
fi

log "=== FAILOVER COMPLETE ==="
