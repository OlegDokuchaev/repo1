###############################################################################
# Paths
###############################################################################
JBREV        ?= /var/jb
BINDIR        = $(JBREV)/usr/local/bin
AGENTDIR      = /var/mobile/Library/LaunchAgents
LOGDIR        = /var/mobile/Library/Logs

SCRIPT        = roblox-watchdog.sh
PLIST         = com.roblox.watchdog.plist

SCRIPT_DST    = $(BINDIR)/$(SCRIPT)
PLIST_DST     = $(AGENTDIR)/$(PLIST)

###############################################################################
# Tools
###############################################################################
SHELL        =  $(JBREV)/bin/sh
INSTALL       = $(JBREV)/usr/bin/install
LAUNCHCTL     = $(JBREV)/usr/bin/launchctl
MOBILE_UID    := $(shell id -u mobile)
DOMAIN        = user/$(MOBILE_UID)

.PHONY: all dirs install uninstall reload log

all:
	@echo "Nothing to build – run 'make install'"

dirs:
	$(INSTALL) -d -m755 $(BINDIR) $(AGENTDIR) $(LOGDIR)

install: dirs $(SCRIPT) $(PLIST)
	$(INSTALL) -m755 $(SCRIPT) $(SCRIPT_DST)
	$(INSTALL) -m644 $(PLIST)  $(PLIST_DST)
	# reload cleanly
	-$(LAUNCHCTL) bootout  $(DOMAIN) $(PLIST_DST) 2>/dev/null || true
	$(LAUNCHCTL) bootstrap $(DOMAIN) $(PLIST_DST)
	@echo "✓ Roblox watchdog installed & running"

uninstall:
	-$(LAUNCHCTL) bootout $(DOMAIN) $(PLIST_DST) 2>/dev/null || true
	rm -f $(PLIST_DST) $(SCRIPT_DST)
	@echo "✓ Roblox watchdog removed"

reload:
	$(LAUNCHCTL) bootout   $(DOMAIN) $(PLIST_DST)
	$(LAUNCHCTL) bootstrap $(DOMAIN) $(PLIST_DST)
	@echo "✓ Roblox watchdog reloaded"

log:
	log stream --info --predicate 'senderImagePath ENDSWITH "roblox-watchdog.sh"' --style syslog
