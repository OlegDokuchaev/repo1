# 0. нужен точный Bundle-ID клиента
BID=$(uicache -l | grep -i codex | cut -d' ' -f1)   # com.delta.roblox

# 1. UID мобильного пользователя (на iOS это 501)
UID=$(id -u mobile)

# 2. Проверяем, жив ли агент
launchctl asuser "$UID" \
        launchctl print "user/$UID/$BID"
echo "EXIT=$?"
