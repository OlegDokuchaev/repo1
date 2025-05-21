THEOS_PACKAGE_SCHEME = rootless
ARCHS   = arm64 arm64e
PACKAGE_VERSION = 1.0-32
include /var/theos/makefiles/common.mk

TWEAK_NAME = rbxurlpatch
rbxurlpatch_FILES = Tweak.xm
rbxurlpatch_FRAMEWORKS = UIKit
rbxurlpatch_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"

include $(THEOS_MAKE_PATH)/aggregate.mk