APP="$(uicache -l | grep -i roblox | cut -d ' ' -f1)"

sqlite3 /var/mobile/Library/FrontBoard/applicationState.db " \
SELECT key_tab.key, hex(value) \
FROM   kvs \
JOIN   application_identifier_tab ait ON kvs.application_identifier = ait.id \
JOIN   key_tab                         ON kvs.key = key_tab.id \
WHERE  ait.application_identifier = '$APP';"
