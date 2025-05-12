#!/bin/bash

is_roblox_running_sql() {
  local BUNDLE="$1"
  local STATE=$(sqlite3 /var/mobile/Library/FrontBoard/applicationState.db \
                "SELECT process_state FROM application_state \
                 WHERE application_identifier='$BUNDLE';")
  echo "$STATE"

  [[ "$STATE" =~ ^(2|3|4)$ ]]
}

BUNDLE="$(uicache -l | grep -i roblox | cut -d ' ' -f1)"
PLACE=142823291
echo "$BUNDLE"

if ! is_roblox_running_sql "$BUNDLE"; then
    uiopen "roblox://placeId=${PLACE}"
fi