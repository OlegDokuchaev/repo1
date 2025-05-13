###############################################################################
# paths & filenames
###############################################################################
JBREV       ?= /var/jb
BINDIR       = $(JBREV)/usr/local/bin
LOGDIR       = /var/mobile/Library/Logs

SCRIPT       = roblox-watchdog.sh
PIDFILE      = $(LOGDIR)/roblox-watchdog.pid

###############################################################################
# tools
###############################################################################
INSTALL      = $(JBREV)/usr/bin/install
NOHUP        = $(JBREV)/usr/bin/nohup   # present in Dopamine
PGREP        = $(JBREV)/usr/bin/pgrep
TAIL         = $(JBREV)/usr/bin/tail

###############################################################################
# targets
###############################################################################
.PHONY: all start stop status log reinstall

all: start                 ## default action

start: $(BINDIR)/$(SCRIPT)
	@echo "▶ starting watchdog …"
	$(NOHUP) $< >/dev/null 2>&1 &
	@echo $$! > $(PIDFILE)

stop:
	@if [ -f $(PIDFILE) ]; then \
	    kill "$$(cat $(PIDFILE))" 2>/dev/null || true; \
	    rm -f $(PIDFILE); \
	    echo "■ watchdog stopped"; \
	else \
	    echo "■ no PID-file → nothing to stop"; \
	fi

status:
	@if [ -f $(PIDFILE) ] && kill -0 "$$(cat $(PIDFILE))" 2>/dev/null; then \
	    echo "✓ watchdog running (PID $$(cat $(PIDFILE))) [pidfile]"; \
	elif $(PGREP) -f $(SCRIPT) >/dev/null; then \
	    echo "✓ watchdog running (found via pgrep)"; \
	else \
	    echo "✗ watchdog NOT running"; \
	fi

log:
	@echo "— live log —"
	log stream --predicate 'eventMessage CONTAINS "roblox-watchdog"' --style syslog

# (re)install the script into $BINDIR
$(BINDIR)/$(SCRIPT): $(SCRIPT)
	$(INSTALL) -d -m755 $(BINDIR)
	$(INSTALL) -m755 $< $@

reinstall: stop $(BINDIR)/$(SCRIPT) start
