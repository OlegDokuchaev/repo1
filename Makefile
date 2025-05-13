###############################################################################
#  paths – меняй спокойно, если нужно
###############################################################################
JBREV        ?= /var/jb
SHELL        = $(JBREV)/bin/sh
LOGFILE      = roblox-watchdog.log
SCRIPT       = roblox-watchdog.sh
PID_FILE     = save_pid.txt

###############################################################################
#  make targets
###############################################################################
.PHONY: start stop status restart

start: $(SCRIPT)
	@echo "➜  starting watchdog"
	@nohup $(SCRIPT) >$(LOGFILE) 2>&1 & \
	pid=$$!; \
	echo $$pid >$(PID_FILE)

stop:
	@if [ -f $(PID_FILE) ]; then \
		pid=$$(cat $(PID_FILE)); \
		if ps -p $$pid > /dev/null 2>&1; then \
			echo "➜  killing $$pid"; \
			sudo kill -15 $$pid; \
		else \
			echo "➜  no running process with PID $$pid"; \
		fi \
	else \
		echo "➜  no PID file, nothing to stop"; \
	fi

status:
	@if [ -f $(PID_FILE) ]; then \
		pid=$$(cat $(PID_FILE)); \
		if ps -p $$pid > /dev/null 2>&1; then \
			echo "✓ running – pid: $$pid"; \
		else \
			echo "✗ not running (pid $$pid not found)"; \
		fi \
	else \
		echo "✗ no PID file, process not started"; \
	fi

restart: stop start