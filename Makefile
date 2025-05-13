###############################################################################
#  paths – меняй спокойно, если нужно
###############################################################################
JBREV       ?= /var/jb
SHELL        = $(JBREV)/bin/sh
LOGFILE      = roblox-watchdog.log
SCRIPT       = roblox-watchdog.sh

###############################################################################
#  make targets
###############################################################################
.PHONY: start stop status restart

start: $(SCRIPT)
	@echo "➜  starting watchdog (log → $(LOGFILE))"
	@nohup $(SCRIPT) >>$(LOGFILE) 2>&1 & 

stop:
	@pids=$$(ps -eo pid,args | grep '[r]oblox-watchdog.sh' | awk '{print $$1}'); \
	if [ -n "$$pids" ]; then \
	    echo "➜  killing $$pids";                   \
	    kill -1 $$pids;                             \
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