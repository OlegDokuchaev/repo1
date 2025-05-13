JBREV       ?= /var/jb
BINDIR      := $(JBREV)/usr/local/bin
LDIR        := $(JBREV)/Library/LaunchDaemons

SCRIPT      := roblox-watchdog.sh
PLIST       := com.roblox.watchdog.plist

SCRIPT_DEST := $(BINDIR)/$(SCRIPT)
PLIST_DEST  := $(LDIR)/$(PLIST)

SHELL       := $(JBREV)/bin/sh
INSTALL     := $(JBREV)/usr/bin/install
LAUNCHCTL   := /bin/launchctl

.PHONY: all dirs install uninstall reload logtail

all:
	@echo "Nothing to build – use 'make install'"

dirs:
	$(INSTALL) -d -m755 $(BINDIR) $(LDIR)

install: dirs $(SCRIPT) $(PLIST)
	$(INSTALL) -m755 $(SCRIPT) $(SCRIPT_DEST)
	$(INSTALL) -m644 $(PLIST)  $(PLIST_DEST)
	$(LAUNCHCTL) load -w $(PLIST_DEST)
	@echo "Roblox watchdog installed and loaded."

uninstall:
	-$(LAUNCHCTL) unload -w $(PLIST_DEST)
	-rm -f $(PLIST_DEST) $(SCRIPT_DEST)
	@echo "Roblox watchdog removed."

reload:
	$(LAUNCHCTL) unload -w $(PLIST_DEST)
	$(LAUNCHCTL)  load -w $(PLIST_DEST)
	@echo "Roblox watchdog reloaded."

logtail:
	tail -f /var/log/roblox-watchdog.out
