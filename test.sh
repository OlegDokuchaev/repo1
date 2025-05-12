# 0. нужен точный Bundle-ID клиента
BID=$(uicache -l | grep -i codex | cut -d' ' -f1)   # com.delta.roblox

LABEL_PREFIX="UIKitApplication:$BID"                                     # как он отображается в launchctl

# В launchd-таблице PID = "-" → приложение загружено, но не активно.
# Число → реально запущено (в Fore/Back-state нам сейчас не важно).
echo "$(launchctl list | awk -v lbl="$LABEL_PREFIX" '$3 ~ lbl {print $1,$2}')"