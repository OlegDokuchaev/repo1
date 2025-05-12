# 1. Берём bundle-ID мода
BID=$(uicache -l | grep -i codex | cut -d' ' -f1)
echo "$BID"

# 2. UID mobile
UID=$(id -u mobile)
echo "$UID"

# 3. Печатаем агент
launchctl asuser "$UID" launchctl print "gui/$UID/$BID"
echo "EXIT=$?"
