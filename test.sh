sqlite3 /var/mobile/Library/FrontBoard/applicationState.db " \
SELECT hex(value) \
FROM   kvs \
JOIN   application_identifier_tab  ON kvs.application_identifier = application_identifier_tab.id \
JOIN   key_tab                     ON kvs.key = key_tab.id \
WHERE  key_tab.key = 'process-state';"
