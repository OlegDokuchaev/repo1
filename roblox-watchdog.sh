#!/bin/bash

# ---------- configurable ----------
BUNDLE="$(uicache -l | grep -i roblox | cut -d ' ' -f1)"
PLACE=142823291
INTERVAL=60
LOGTAG="roblox-watchdog"
PIDFILE="/var/mobile/Library/Logs/${LOGTAG}.pid"
# ----------------------------------

is_roblox_running() {
  local BID="$1"
  LABEL_PREFIX="UIKitApplication:$BID"

  read pid status <<< "$(launchctl list | awk -v lbl="$LABEL_PREFIX" '$3 ~ lbl {print $1,$2}')"

  if [[ "$pid" =~ ^[0-9]+$ ]] && [[ "$status" == 0 ]]; then
        return 0
  fi
  return 1
}

# ────────────────────────────────────────────────────────────────────────────────

echo $$ > "$PIDFILE"
trap 'rm -f "$PIDFILE"' EXIT INT TERM

while true; do
    if ! is_roblox_running "$BUNDLE"; then
        uiopen "roblox://placeId=${PLACE}"
    fi
    sleep "$INTERVAL"
done