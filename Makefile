###############################################################################
# paths
###############################################################################
JBREV      ?= /var/jb
BINDIR      = $(JBREV)/usr/local/bin
AGENTDIR    = /var/mobile/Library/LaunchAgents

SCRIPT      = roblox-watchdog.sh
PLIST       = com.roblox.watchdog.plist

SCRIPT_DST  = $(BINDIR)/$(SCRIPT)
PLIST_DST   = $(AGENTDIR)/$(PLIST)

###############################################################################
# tools
###############################################################################
INSTALL     = $(JBREV)/usr/bin/install
LAUNCHCTL   = /bin/launchctl          # system one works fine
UID         := $(shell id -u mobile)
DOMAIN      = gui/$(UID)

.PHONY: all install uninstall reload log dirs

all:
	@echo "Nothing to build – run 'make install'"

dirs:
	$(INSTALL) -d -m755 $(BINDIR) $(AGENTDIR) /var/mobile/Library/Logs

install: dirs $(SCRIPT) $(PLIST)
	$(INSTALL) -m755 $(SCRIPT) $(SCRIPT_DST)
	$(INSTALL) -m644 $(PLIST)  $(PLIST_DST)
	-$(LAUNCHCTL) bootout  $(DOMAIN) $(PLIST_DST) 2>/dev/null || true
	$(LAUNCHCTL) bootstrap $(DOMAIN) $(PLIST_DST)
	$(LAUNCHCTL) enable    $(DOMAIN)/com.roblox.watchdog
	@echo "✓ watchdog installed & running"

uninstall:
	-$(LAUNCHCTL) bootout $(DOMAIN) $(PLIST_DST) 2>/dev/null || true
	rm -f $(PLIST_DST) $(SCRIPT_DST)
	@echo "✓ watchdog removed"

reload:
	$(LAUNCHCTL) bootout   $(DOMAIN) $(PLIST_DST)
	$(LAUNCHCTL) bootstrap $(DOMAIN) $(PLIST_DST)
	@echo "✓ watchdog reloaded"

log:
	log stream --style syslog --predicate 'subsystem == "com.apple.system.logger" AND senderImagePath ENDSWITH "roblox-watchdog"'
