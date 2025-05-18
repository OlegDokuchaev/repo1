THEOS_PACKAGE_SCHEME = rootless
TARGET  = iphone:clang:latest:15.0
ARCHS   = arm64 arm64e

PACKAGE_VERSION = 1.0-14

TWEAK_NAME = rbxurlpatch
rbxurlpatch_FILES   = Tweak.xm
rbxurlpatch_CFLAGS  = -fobjc-arc
rbxurlpatch_LDFLAGS = -lobjc

# процессы, которые нужно killall после «make install»
INSTALL_TARGET_PROCESSES = com.roblox.robloxmobile1 com.roblox.robloxmobile2 SpringBoard

include /var/theos/makefiles/common.mk
include /var/theos/makefiles/tweak.mk