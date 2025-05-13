#!/bin/bash

is_roblox_running() {
  local BID="$1"
  LABEL_PREFIX="UIKitApplication:$BID"

  read pid status <<< "$(launchctl list | awk -v lbl="$LABEL_PREFIX" '$3 ~ lbl {print $1,$2}')"

  if [[ "$pid" =~ ^[0-9]+$ ]] && [[ "$status" == 0 ]]; then
        return 0
  fi
  return 1
}

BUNDLE="$(uicache -l | grep -i roblox | cut -d ' ' -f1)"
PLACE=142823291
INTERVAL=60

echo "Start with BUNDLE: $BUNDLE"

while true; do
    if ! is_roblox_running "$BUNDLE"; then
        uiopen "roblox://placeId=${PLACE}"
        echo "Start Roblox"
    else
        echo "Roblox is already running"
    fi

    sleep "$INTERVAL"
done