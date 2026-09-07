#!/bin/bash
# my* Suite — Health Check Automation
# Проверка здоровья всех сервисов с автоматическим восстановлением
# Запуск: ./health-check.sh

set -e

LOG_FILE="/var/log/my-suite/health-check.log"
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

# Сервисы и порты
declare -A SERVICES=(
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

log "=== HEALTH CHECK ==="

TOTAL=0
HEALTHY=0
UNHEALTHY=()
RESTARTED=()

for SERVICE in "${!SERVICES[@]}"; do
    PORT=${SERVICES[$SERVICE]}
    TOTAL=$((TOTAL + 1))
    
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://localhost:${PORT}/healthz" 2>/dev/null)
    
    if [ "$STATUS" = "200" ]; then
        HEALTHY=$((HEALTHY + 1))
        log "✅ $SERVICE ($port): OK"
    else
        UNHEALTHY+=("$SERVICE")
        log "❌ $SERVICE ($port): HTTP $STATUS"
        
        # Автоматическое восстановление
        log "Попытка восстановления $SERVICE..."
        cd /opt/myatlassian/mycrowd/deploy/suite
        docker compose restart "$SERVICE" > /dev/null 2>&1
        
        sleep 10
        
        STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://localhost:${PORT}/healthz" 2>/dev/null)
        if [ "$STATUS" = "200" ]; then
            RESTARTED+=("$SERVICE")
            log "✅ $SERVICE восстановлен автоматически"
        else
            log "❌ $SERVICE не восстановлен"
        fi
    fi
done

# Отчет
log ""
log "=== ИТОГО ==="
log "Всего сервисов: $TOTAL"
log "Здоровых: $HEALTHY"
log "Нездоровых: ${#UNHEALTHY[@]}"
log "Восстановлено: ${#RESTARTED[@]}"

# Отправка алерта если есть проблемы
if [ ${#UNHEALTHY[@]} -gt 0 ]; then
    MESSAGE="⚠️ <b>HEALTH CHECK ALERT</b>

Время: $(date '+%Y-%m-%d %H:%M:%S')
Всего: $TOTAL сервисов
Здоровых: $HEALTHY
Нездоровых: ${#UNHEALTHY[@]}

Нездоровые сервисы:"
    
    for SERVICE in "${UNHEALTHY[@]}"; do
        MESSAGE="$MESSAGE
- $SERVICE"
    done
    
    if [ ${#RESTARTED[@]} -gt 0 ]; then
        MESSAGE="$MESSAGE

Восстановлено автоматически:"
        for SERVICE in "${RESTARTED[@]}"; do
            MESSAGE="$MESSAGE
- $SERVICE"
        done
    fi
    
    send_alert "$MESSAGE"
fi

log "=== HEALTH CHECK COMPLETE ==="
