is_roblox_running() {                # $1 = Bundle ID
  echo "$(launchctl print "gui/$(id -u mobile)/$1")"
  launchctl print "gui/$(id -u mobile)/$1" 2>/dev/null |
    grep -q "state = running"
}

is_roblox_in_memory() {              # 0 = не в памяти
  echo "$(launchctl print "gui/$(id -u mobile)/$1")"
  launchctl print "gui/$(id -u mobile)/$1" 2>/dev/null > /dev/null
}

BID="$(uicache -l | grep -i codex | cut -d ' ' -f1)"

if is_roblox_running "$BID"; then
   echo "Roblox сейчас на экране (running)"
elif is_roblox_in_memory "$BID"; then
   echo "Roblox заморожен в памяти (suspended)"
else
   echo "Roblox полностью выгружен"
fi
