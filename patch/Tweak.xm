#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <CoreFoundation/CoreFoundation.h>
#import <substrate.h>
#import <os/log.h>
#import <sys/stat.h>
#include <dlfcn.h>
#include <ctype.h>

#pragma mark - helpers ------------------------------------------------------

/* C-проверка: roblox + ≥1 цифра */
static inline bool strIsClone(const char *s)
{
    if (strncmp(s, "roblox", 6) != 0) return false;
    size_t len = strlen(s);
    if (len <= 6) return false;
    for (size_t i = 6; i < len; ++i)
        if (!isdigit((unsigned char)s[i]))
            return false;
    return true;
}

/* CFStringRef → bool (клон ли) */
static bool cfIsClone(CFStringRef str)
{
    const char *c = CFStringGetCStringPtr(str, kCFStringEncodingUTF8);
    char buf[64];
    if (!c) {
        if (!CFStringGetCString(str, buf, sizeof(buf), kCFStringEncodingUTF8))
            return false;
        c = buf;
    }
    return strIsClone(c);
}

static CFStringRef kBase = CFSTR("roblox");   // «бессмертная» строка

#pragma mark - 1. CFURLCopyScheme hook --------------------------------------

static CFStringRef (*orig_CFURLCopyScheme)(CFURLRef url) = NULL;

%hookf(CFStringRef, CFURLCopyScheme, CFURLRef url)
{
    CFStringRef s = orig_CFURLCopyScheme(url);           // по правилу *Copy*: +1 retain
    if (s && cfIsClone(s)) {                             // robloxN → roblox
        CFRelease(s);                                    // отдаём нашу строку с +1
        return (CFStringRef)CFRetain(kBase);
    }
    return s;                                            // вернуть как есть
}

#pragma mark - 2. RBLinkingHelper hook --------------------------------------

%hook RBLinkingHelper              // класс есть во всех сборках Roblox iOS
+ (void)postDeepLinkNotificationWithURLString:(NSString *)urlStr
{
    if (urlStr.length > 7 && [urlStr hasPrefix:@"roblox"]) {
        // отделяем схему
        NSRange colon = [urlStr rangeOfString:@":"];
        if (colon.location != NSNotFound) {
            NSString *scheme = [urlStr substringToIndex:colon.location];
            if (scheme.length > 6 &&
                strIsClone([scheme UTF8String]))          // robloxN?
            {
                urlStr = [@"roblox" stringByAppendingString:
                          [urlStr substringFromIndex:scheme.length]];
            }
        }
    }
    %orig(urlStr);                                        // вызываем оригинал
}
%end

#pragma mark - ctor ---------------------------------------------------------

%ctor
{
    // безопасно: RTLD_DEFAULT присутствует во всех Darwin-SDK
    orig_CFURLCopyScheme = (CFStringRef(*)(CFURLRef))
        dlsym(RTLD_DEFAULT, "CFURLCopyScheme");
    %init;   // активируем хуки
}