BID="$(uicache -l | grep -i codex | cut -d ' ' -f1)"
launchctl print "gui/$(id -u mobile)/$BID"
echo $?
launchctl print "gui/$(id -u mobile)/$BID"
echo $?
BID="$(uicache -l | grep -i roblox | cut -d ' ' -f1)"
launchctl print "gui/$(id -u mobile)/$BID"
echo $?
launchctl print "gui/$(id -u mobile)/$BID"
echo $?
