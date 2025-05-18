// RobloxSchemeFix.xm
#include <CoreFoundation/CoreFoundation.h>
#include <Foundation/Foundation.h>
#include <ctype.h>

#pragma mark - helpers
static inline bool strIsClone(const char *s) {
    if (strncmp(s, "roblox", 6) != 0) return false;
    for (const char *p = s + 6; *p; ++p)
        if (!isdigit((unsigned char)*p)) return false;
    return true;
}

static bool cfIsClone(CFStringRef str) {
    const char *c = CFStringGetCStringPtr(str, kCFStringEncodingUTF8);
    char buf[64];
    if (!c) {
        if (!CFStringGetCString(str, buf, sizeof(buf), kCFStringEncodingUTF8))
            return false;
        c = buf;
    }
    return strIsClone(c);
}

static CFStringRef kBase = CFSTR("roblox");        // immortal

#pragma mark - 1. CFURLCopyScheme

%hookf(CFStringRef, CFURLCopyScheme, CFURLRef url)
{
    CFStringRef s = %orig(url);                     // ← правильный оригинал
    if (s && cfIsClone(s)) {
        CFRetain(kBase);                            // +1 для вызывающего кода
        CFRelease(s);                               // балансируем Copy-правило
        return kBase;
    }
    return s;
}

#pragma mark - 2. RBLinkingHelper

%hook RBLinkingHelper
+ (void)postDeepLinkNotificationWithURLString:(NSString *)urlStr
{
    if (urlStr.length > 6 && [urlStr hasPrefix:@"roblox"]) {
        NSRange colon = [urlStr rangeOfString:@":"];
        if (colon.location != NSNotFound) {
            NSString *scheme = [urlStr substringToIndex:colon.location];
            if (strIsClone(scheme.UTF8String)) {
                urlStr = [@"roblox" stringByAppendingString:
                          [urlStr substringFromIndex:scheme.length]];
            }
        }
    }
    %orig(urlStr);
}
%end

#pragma mark - ctor

%ctor {
    %init;     // никаких dlsym / MSFindSymbol не требуется
}