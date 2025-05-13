#!/var/jb/usr/bin/bash
set -euo pipefail

is_roblox_running() {
  local BID="$1"
  LABEL_PREFIX="UIKitApplication:$BID"

  read pid status <<< "$(/var/jb/usr/bin/launchctl list | /var/jb/usr/bin/awk -v lbl="$LABEL_PREFIX" '$3 ~ lbl {print $1,$2}')"

  if [[ "$pid" =~ ^[0-9]+$ ]] && [[ "$status" == 0 ]]; then
        return 0
  fi
  return 1
}

BUNDLE="$(/var/jb/usr/bin/uicache -l | /var/jb/usr/bin/grep -i roblox | /var/jb/usr/bin/cut -d ' ' -f1)"
PLACE=142823291

if ! is_roblox_running "$BUNDLE"; then
    /var/jb/usr/bin/uiopen "roblox://placeId=${PLACE}"
    logger -t roblox-watchdog "Roblox (re)launched"
else
    logger -t roblox-watchdog "Roblox already running"
fi

exit 0