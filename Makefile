### Installation paths ########################################################
JBREV        ?= /var/jb
BINDIR       =  $(JBREV)/usr/local/bin
LDIR         =  $(JBREV)/Library/LaunchDaemons

SCRIPT       =  roblox-watchdog.sh
PLIST        =  com.roblox.watchdog.plist

SCRIPT_DEST  =  $(BINDIR)/$(SCRIPT)
PLIST_DEST   =  $(LDIR)/$(PLIST)

### Tools #####################################################################
SHELL        =  $(JBREV)/bin/sh
INSTALL      =  $(JBREV)/usr/bin/install
LAUNCHCTL    =  $(JBREV)/usr/bin/launchctl
DOMAIN       =  system

.PHONY: all dirs install uninstall reload log

all:
	@echo "Nothing to build – run 'make install'"

dirs:
	$(INSTALL) -d -m 755 $(BINDIR) $(LDIR)

install: dirs $(SCRIPT) $(PLIST)
	$(INSTALL) -m 755 $(SCRIPT) $(SCRIPT_DEST)
	$(INSTALL) -m 644 $(PLIST)  $(PLIST_DEST)
	-$(LAUNCHCTL) enable    $(DOMAIN)/$(LABEL)           || true
	-$(LAUNCHCTL) bootout   $(DOMAIN)/$(PLIST_DEST)      2>/dev/null || true
	 $(LAUNCHCTL) bootstrap $(DOMAIN) $(PLIST_DEST)
	 $(LAUNCHCTL) kickstart -k $(DOMAIN)/$(LABEL)
	@echo "✓ watchdog installed & running"

uninstall:
	-$(LAUNCHCTL) bootout $(DOMAIN) $(PLIST_DEST) 2>/dev/null || true
	 rm -f $(PLIST_DEST) $(SCRIPT_DEST)
	@echo "✓ watchdog removed"

reload:
	$(LAUNCHCTL) kickstart -k $(DOMAIN)/$(LABEL)
	@echo "✓ watchdog reloaded"

log:
	log stream --style syslog --predicate 'process == "roblox-watchdog"' --info
