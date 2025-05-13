#!/usr/bin/env bash

set -euo pipefail
PATH="/var/jb/usr/bin:/usr/bin:/bin"
export PATH

is_roblox_running() {
    local bid="$1" label="UIKitApplication:$bid"

    read -r pid status <<<"$(launchctl list | awk -v l="$label" '$3~l {print $1,$2}')"
    [[ "$pid" =~ ^[0-9]+$ && "$status" == 0 ]]
}

BID="$(uicache -l | grep -i roblox | head -1 | cut -d' ' -f1)"
PLACE_ID=142823291

if is_roblox_running "$BID"; then
    logger -t roblox-watchdog 'Roblox already running'
else
    uiopen "roblox://placeId=${PLACE_ID}"
    logger -t roblox-watchdog 'Roblox relaunched'
fi