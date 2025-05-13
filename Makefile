JBREV       ?= /var/jb
BINDIR      := $(JBREV)/usr/local/bin
LDIR        := $(JBREV)/Library/LaunchDaemons

SCRIPT      := roblox-watchdog.sh
PLIST       := com.roblox.watchdog.plist

SCRIPT_DEST := $(BINDIR)/$(SCRIPT)
PLIST_DEST  := $(LDIR)/$(PLIST)

.PHONY: all install uninstall reload logtail

all:
	echo "Nothing to build – use 'make install'"

install: $(SCRIPT) $(PLIST)
	install -m 755    $(SCRIPT) $(SCRIPT_DEST)
	install -m 644    $(PLIST) $(PLIST_DEST)
	launchctl load -w $(PLIST_DEST)
	echo "Roblox watchdog installed and loaded."

uninstall: $(SCRIPT_DEST) $(PLIST_DEST)
	launchctl unload -w $(PLIST_DEST)
	rm -f $(PLIST_DEST) $(SCRIPT_DEST)
	echo "Roblox watchdog removed."

reload: $(PLIST_DEST)
	launchctl unload -w $(PLIST_DEST);
	launchctl load   -w $(PLIST_DEST);
	echo "Roblox watchdog reloaded.";

logtail:
	tail -f /var/log/roblox-watchdog.out
