# 0. нужен точный Bundle-ID клиента
BID=$(uicache -l | grep -i codex | cut -d' ' -f1)   # com.delta.roblox

LABEL_PREFIX="UIKitApplication:$BID"                                     # как он отображается в launchctl

# В launchd-таблице PID = "-" → приложение загружено, но не активно.
# Число → реально запущено (в Fore/Back-state нам сейчас не важно).
read pid status <<<"$(launchctl list gui/$(id -u mobile)/$BID | awk '/"PID"/{p=$3}/"Status"/{s=$3} END{print p,s}')"
echo "$pid"
echo "$status"

if [ -z "$pid" ] ; then
    echo "Roblox-мод НЕ ЗАГРУЖЁН"
    exit 1
elif [ "$pid" = "-" ] ; then
    echo "Roblox-мод загружен, но НЕ ЗАПУЩЕН (PID «-»)."
    exit 2
else
    echo "Roblox-мод запущен, PID=$pid"
    exit 0
fi