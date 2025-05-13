#!/bin/bash
set -euo pipefail

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

if ! is_roblox_running "$BUNDLE"; then
    uiopen "roblox://placeId=${PLACE}"
    logger -t roblox-watchdog "Roblox relaunched"
else
    logger -t roblox-watchdog "Roblox is already launched"
fi

exit 0