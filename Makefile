##############################################################################
# пути и имена
##############################################################################
JBREV      ?= /var/jb
BINDIR      = $(JBREV)/usr/local/bin
LOGDIR      = /var/mobile/Library/Logs
SCRIPT      = roblox-watchdog.sh
PIDFILE     = $(LOGDIR)/roblox-watchdog.pid
LOGFILE     = $(LOGDIR)/roblox-watchdog.log

SCRIPT_DST  = $(BINDIR)/$(SCRIPT)

SHELL       = $(JBREV)/bin/sh
INSTALL     = $(JBREV)/usr/bin/install
MKDIR       = /bin/mkdir -p
NOHUP       = /var/jb/usr/bin/nohup
KILL        = /bin/kill
TAIL        = /usr/bin/tail

.PHONY: all install start stop restart status uninstall log

all:
	@echo "Run 'make install' or 'make start'"

##############################################################################
# установка/обновление скрипта
##############################################################################
install: $(SCRIPT)
	@$(MKDIR) $(BINDIR) $(LOGDIR)
	$(INSTALL) -m755 $(SCRIPT) $(SCRIPT_DST)
	@echo "✓ script installed to $(SCRIPT_DST)"

##############################################################################
# запуск / остановка
##############################################################################
start: install
	@if [ -f $(PIDFILE) ] && kill -0 "$$(cat $(PIDFILE))" 2>/dev/null; then \
		echo "Watchdog уже запущен (pid $$(cat $(PIDFILE)))"; \
	else \
		$(NOHUP) $(SCRIPT_DST) >>$(LOGFILE) 2>&1 & \
		echo $$! > $(PIDFILE); \
		echo "✓ watchdog started (pid $$!)"; \
	fi

stop:
	@if [ -f $(PIDFILE) ] && kill -0 "$$(cat $(PIDFILE))" 2>/dev/null; then \
		$(KILL) "$$(cat $(PIDFILE))"; \
		rm -f $(PIDFILE); \
		echo "✓ watchdog stopped"; \
	else \
		echo "Watchdog не запущен"; \
	fi

restart: stop start
status:
	@if [ -f $(PIDFILE) ] && kill -0 "$$(cat $(PIDFILE))" 2>/dev/null; then \
		echo "Watchdog работает (pid $$(cat $(PIDFILE)))"; \
	else \
		echo "Watchdog не запущен"; \
	fi

##############################################################################
# удаление
##############################################################################
uninstall: stop
	@rm -f $(SCRIPT_DST) $(LOGFILE)
	@echo "✓ watchdog removed"

##############################################################################
# просмотр лога вживую
##############################################################################
log:
	@$(TAIL) -f $(LOGFILE)
