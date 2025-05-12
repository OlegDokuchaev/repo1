#!/bin/bash

BID=$(uicache -l | grep -i codex | cut -d' ' -f1)   # com.delta.roblox
LABEL_PREFIX="UIKitApplication:$BID"

read pid status <<< "$(launchctl list | awk -v lbl="$LABEL_PREFIX" '$3 ~ lbl {print $1,$2}')"
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