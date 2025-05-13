#!/var/jb/usr/bin/env bash
# Roblox watchdog — перезапускает игру, если она не активна.
set -euo pipefail

### Константы ###############################################################
INTERVAL=60                              # секунды между проверками
PLACE_ID=142823291                       # какой place запускать
PATH=/var/jb/usr/bin:/usr/bin:/bin       # гарантируем доступ к util'ам
LOG_TAG="roblox-watchdog"

# Полные пути, чтобы не зависеть от $PATH cron/nohup
UICACHE=/var/jb/usr/bin/uicache
LAUNCHCTL=/var/jb/usr/bin/launchctl
UIOPEN=/var/jb/usr/bin/uiopen
LOGGER=/var/jb/usr/bin/logger

### Функции #################################################################
log() { "$LOGGER" -t "$LOG_TAG" "$*"; }

is_roblox_running() {
    local bid="$1"
    # launchctl list выводит PID и статус. Нужна строка с нашим Bundle-ID
    local pid status
    read -r pid status \
        <<< "$("$LAUNCHCTL" list | awk -v lbl="UIKitApplication:$bid" '$3~lbl{print $1,$2}')"
    [[ "$pid" =~ ^[0-9]+$ && "$status" == 0 ]]
}

### Главный цикл ############################################################
while true; do
    bundle="$($UICACHE -l | awk '$0 ~ /roblox/i {print $1; exit}')"
    if [[ -z "$bundle" ]]; then
        log "Bundle ID Roblox не найден uicache-ем"
    elif is_roblox_running "$bundle"; then
        # Roblox уже работает
        :
    else
        log "Roblox не запущен, пытаюсь открыть place $PLACE_ID"
        "$UIOPEN" "roblox://placeId=$PLACE_ID" || log "uiopen вернул ошибку!"
    fi
    sleep "$INTERVAL"
done
