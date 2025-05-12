BID="$(uicache -l | grep -i codex | cut -d ' ' -f1)"
launchctl print "gui/$(id -u mobile)/$BID"
launchctl print "gui/$(id -u mobile)/$BID"
