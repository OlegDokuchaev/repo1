PREFIX      ?= /usr/local
LAUNCHDIR   = /Library/LaunchDaemons

SCRIPT      = autorestart.sh
PLIST       = com.example.roblox.autorestart.plist

SCRIPT_DEST = $(PREFIX)/bin/$(SCRIPT)
PLIST_DEST  = $(LAUNCHDIR)/$(PLIST)

.PHONY: all install uninstall logtail

all:
	@echo "Nothing to build – use 'make install'"

install: $(SCRIPT) $(PLIST)
	install -m 755   $(SCRIPT) $(SCRIPT_DEST)
	install -m 644   $(PLIST) $(PLIST_DEST)
	launchctl load   $(PLIST_DEST)
	@echo "✅  Autorestart installed and loaded."

uninstall: $(SCRIPT_DEST) $(PLIST_DEST)
	- launchctl unload $(PLIST_DEST)
	- rm -f $(PLIST_DEST) $(SCRIPT_DEST)
	@echo "🗑️  Autorestart removed."

logtail:
	tail -f /var/log/roblox-autorestart.out
