# 0. нужен точный Bundle-ID клиента
BID=$(uicache -l | grep -i codex | cut -d' ' -f1)   # com.delta.roblox

LABEL_PREFIX="UIKitApplication:$BID"                                     # как он отображается в launchctl

launchctl list gui/$(id -u mobile)/$BID
echo $?

# В launchd-таблице PID = "-" → приложение загружено, но не активно.
# Число → реально запущено (в Fore/Back-state нам сейчас не важно).
pid=$(launchctl list | awk -v lbl="$LABEL_PREFIX" '$3 ~ lbl {print $1}')
echo "$pid"

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