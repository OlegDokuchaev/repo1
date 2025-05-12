check_app_state() {
  local BID="$1" db="/var/mobile/Library/FrontBoard/applicationState.db"
  local table col
  # список подходящих таблиц/колонок
  for combo in \
    "application_state application_identifier" \
    "application bundle_identifier" \
    "EBTApplicationStateTable bundleID" \
  ; do
     table=${combo% *}; col=${combo#* }
     state=$(sqlite3 "$db" "SELECT state FROM $table WHERE $col='$BID' LIMIT 1;" 2>/dev/null)
     echo "$table"
     echo $"state"
     [ -n "$state" ] && { echo "$state"; return; }
  done
  echo "unknown"   # таблица не найдена
}

BUNDLE="$(uicache -l | grep -i codex | cut -d ' ' -f1)"
case $(check_app_state "$BUNDLE") in
  0|unknown)   echo "Roblox закрыт";;
  2)           echo "Roblox в foreground";;
  3|4)         echo "Roblox в фоне/спит";;
esac
