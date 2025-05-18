// Tweak.xm — iOS 15.8.3 (arm64e / arm64)

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <ctype.h>

#pragma mark – helpers -------------------------------------------------------

static inline bool strIsClone(const char *s)
{
    if (strncmp(s, "roblox", 6) != 0) return false;
    const char *p = s + 6;
    if (!*p) return false;                     // минимум одна цифра
    for (; *p; ++p)
        if (!isdigit((unsigned char)*p))
            return false;
    return true;
}

static bool cfIsClone(CFStringRef str)
{
    if (!str) return false;
    // 256 байт — достаточно для URL-схем + safety-margin
    char buf[256];
    const char *c = CFStringGetCStringPtr(str, kCFStringEncodingUTF8);
    if (!c) {
        if (!CFStringGetCString(str, buf, sizeof(buf), kCFStringEncodingUTF8))
            return false;
        c = buf;
    }
    return strIsClone(c);
}

static CFStringRef kRoblox = CFSTR("roblox");          // immortal

#pragma mark – 1. CFURLCopyScheme -------------------------------------------

%hookf(CFStringRef, CFURLCopyScheme, CFURLRef url)
{
    CFStringRef s = %orig(url);                         // +1 retain (rule *Copy*)
    if (cfIsClone(s)) {
        CFRelease(s);                                   // балансируем %orig
        return CFRetain(kRoblox);                       // +1 для вызывающего
    }
    return s;                                           // как есть
}

#pragma mark – 2. RBLinkingHelper -------------------------------------------

%hook RBLinkingHelper
+ (void)postDeepLinkNotificationWithURLString:(NSString *)urlStr
{
    if (urlStr.length > 7 && [urlStr hasPrefix:@"roblox"]) {
        NSUInteger colon = [urlStr rangeOfString:@":"].location;
        if (colon != NSNotFound) {
            NSString *scheme = [urlStr substringToIndex:colon];
            if (strIsClone(scheme.UTF8String)) {
                urlStr = [@"roblox" stringByAppendingString:
                          [urlStr substringFromIndex:scheme.length]];
            }
        }
    }
    %orig(urlStr);
}
%end

#pragma mark – ctor ---------------------------------------------------------

%ctor
{
    // Logos сам подставит trampoline и сформирует %orig,
    // поэтому дополнительных dlsym-манипуляций не нужно.
    %init;
}