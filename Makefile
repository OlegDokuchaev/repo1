###############################################################################
#  paths – меняй спокойно, если нужно
###############################################################################
LOGFILE      = roblox-watchdog.log
SCRIPT       = roblox-watchdog.sh
PID_FILE     = save_pid.txt

###############################################################################
#  make targets
###############################################################################
.PHONY: start stop status restart

start: $(SCRIPT)
	@echo "➜  starting watchdog"
	@nohup $(SCRIPT) > $(LOGFILE) >2&1 && @echo $! > $(PID_FILE) &

stop:
	@pids=$$(ps -eo pid,args | grep "$(cat $(PID_FILE))" | awk '{print $$1}'); \
	if [ -n "$$pids" ]; then \
	    echo "➜  killing $$pids";                   \
	    sudo kill $$pids;                             \
	else                                            \
	    echo "➜  watchdog not running";             \
	fi

status:
	@pids=$$(ps -eo pid,args | grep "$(cat $(PID_FILE))" | awk '{print $$1}'); \
	if [ -n "$$pids" ]; then \
	    echo "✓ running – pids: $$pids";           \
	else                                            \
	    echo "✗ not running";                      \
	fi

restart: stop start