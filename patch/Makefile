THEOS_DEVICE_IP = localhost       # usbmuxd / iproxy etc. if needed
TARGET          = iphone:clang:latest:14.0
ARCHS           = arm64 arm64e
INSTALL_TARGET_PROCESSES = robloxmob*, SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = rbxurlpatch
rbxurlpatch_FILES = Tweak.xm
rbxurlpatch_CFLAGS = -fobjc-arc
rbxurlpatch_LDFLAGS += -lobjc

include $(THEOS_MAKE_PATH)/tweak.mk