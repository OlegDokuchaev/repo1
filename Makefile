JBREV ?= /var/jb

BINDIR    := $(JBREV)/usr/local/bin
LDIR      := $(JBREV)/Library/LaunchDaemons
LOGDIR    := /var/mobile/Library/Logs/roblox-watchdog

SCRIPT    := roblox-watchdog.sh
PLIST     := com.roblox.watchdog.plist

SCRIPT_DST := $(BINDIR)/$(SCRIPT)
PLIST_DST  := $(LDIR)/$(PLIST)

INSTALL   := $(JBREV)/usr/bin/install
LAUNCHCTL := $(JBREV)/usr/bin/launchctl

.PHONY: all dirs install uninstall reload logtail

all:
	@echo "Nothing to build – use \033[1mmake install\033[0m"

dirs:
	$(INSTALL) -d -m755 $(BINDIR) $(LDIR) $(LOGDIR)

install: dirs $(SCRIPT) $(PLIST)
	$(INSTALL) -m755 $(SCRIPT) $(SCRIPT_DST)
	$(INSTALL) -m644 $(PLIST)  $(PLIST_DST)
	$(LAUNCHCTL) bootstrap gui/$(shell id -u mobile) $(PLIST_DST)
	@echo "Roblox watchdog installed and loaded."

uninstall:
	-$(LAUNCHCTL) bootout gui/$(shell id -u mobile) $(PLIST_DST)
	-rm -f $(PLIST_DST) $(SCRIPT_DST)
	@echo "Roblox watchdog removed."

reload:
	$(LAUNCHCTL) bootout  gui/$(shell id -u mobile) $(PLIST_DST)
	$(LAUNCHCTL) bootstrap gui/$(shell id -u mobile) $(PLIST_DST)
	@echo "Roblox watchdog reloaded."

logtail:
	tail -F $(LOGDIR)/*.log
