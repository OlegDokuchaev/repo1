###############################################################################
#  paths – меняй спокойно, если нужно
###############################################################################
JBREV       ?= /var/jb
SHELL        = $(JBREV)/bin/sh
PREFIX      ?= /var/mobile/roblox-watchdog        # где хранить файлы
BINDIR       = $(PREFIX)
LOGFILE      = /var/mobile/Library/Logs/roblox-watchdog.log
SCRIPT       = roblox-watchdog.sh

###############################################################################
#  make targets
###############################################################################
.PHONY: start stop status restart

start: $(SCRIPT)
	@mkdir -p $(BINDIR)
	@cp -f $(SCRIPT) $(BINDIR)/
	@echo "➜  starting watchdog (log → $(LOGFILE))"
	@nohup $(BINDIR)/$(SCRIPT) >>$(LOGFILE) 2>&1 & 

stop:
	@pids=$$(ps -eo pid,args | grep '[r]oblox-watchdog.sh' | awk '{print $$1}'); \
	if [ -n "$$pids" ]; then \
	    echo "➜  killing $$pids";                   \
	    kill $$pids;                                \
	else                                            \
	    echo "➜  watchdog not running";             \
	fi

status:
	@pids=$$(ps -eo pid,args | grep '[r]oblox-watchdog.sh' | awk '{print $$1}'); \
	if [ -n "$$pids" ]; then \
	    echo "✓ running – pids: $$pids";           \
	else                                            \
	    echo "✗ not running";                      \
	fi

restart: stop start