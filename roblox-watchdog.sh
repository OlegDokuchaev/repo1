#!/bin/bash
set -euo pipefail

### Settings
PLACE=142823291     # your placeId
INTERVAL=60         # check interval in seconds
RESTART_INTERVAL=10 # restart interval in seconds

### Function: checks if a launchctl agent for the given bundle-id is alive
is_roblox_running() {
  local BID="$1" \
        LABEL="UIKitApplication:$BID"

  # look for a matching service in launchctl list
  read pid status <<< "$(
    launchctl list \
      | awk -v lbl="$LABEL" '$3 ~ lbl { print $1, $2 }'
  )"

  # consider running if PID is numeric and exit status is 0
  [[ "$pid" =~ ^[0-9]+$ ]] && [[ "$status" == 0 ]]
}

### Gather all Roblox bundle-IDs
mapfile -t BUNDLES < <(
  uicache -l \
    | awk '{print $1}' \
    | grep -E '^com\.roblox\.robloxmobile[0-9]+$'
)

if (( ${#BUNDLES[@]} == 0 )); then
  echo "❌ No Roblox copies found in uicache" >&2
  exit 1
fi

echo "🔍 Monitoring Roblox instances:"
for b in "${BUNDLES[@]}"; do
  echo "  • $b"
done
echo

### Main loop
while true; do
  for BID in "${BUNDLES[@]}"; do
    # extract numeric suffix (empty ⇒ first copy)
    suffix="${BID#com.roblox.robloxmobile}"
    scheme="roblox${suffix}"
    inst="$suffix"

    printf '[%s] Checking instance %s (bundle=%s)… ' \
      "$(date +'%H:%M:%S')" "$inst" "$BID"

    if is_roblox_running "$BID"; then
      echo "OK"
    else
      echo "not running – restarting via ${scheme}://"
      uiopen "${scheme}://placeId=${PLACE}"
      sleep "$RESTART_INTERVAL"
    fi
  done

  echo "— Sleeping for $INTERVAL seconds before next check —"
  sleep "$INTERVAL"
done