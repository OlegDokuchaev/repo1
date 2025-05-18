//  RobloxSchemeFix.xm
//  build:  make package install   (Theos)

/*----------------------------------------------------------------------*/
#include <CoreFoundation/CoreFoundation.h>
#include <Foundation/Foundation.h>
#include <dlfcn.h>
#include <ctype.h>

#ifndef RTLD_DEFAULT               // гарантировано в Darwin, но на случай exotic SDK
#define RTLD_DEFAULT ((void *)0)
#endif

#pragma mark - helpers

/* C-level test: “roblox” followed by ≥1 decimal digit */
static inline bool strIsClone(const char *s) {
    if (strncmp(s, "roblox", 6) != 0)      return false;
    size_t len = strlen(s);
    if (len <= 6)                          return false;
    for (size_t i = 6; i < len; ++i)
        if (!isdigit((unsigned char)s[i])) return false;   // cast → UB-free  [oai_citation:0‡GitHub](https://github.com/Ragekill3377/Titanox?utm_source=chatgpt.com)
    return true;
}

/* CFStringRef → bool, no recursion into CFStringCompare */
static bool cfIsClone(CFStringRef str) {
    const char *c = CFStringGetCStringPtr(str, kCFStringEncodingUTF8);
    char  buf[64];
    if (!c) {
        if (!CFStringGetCString(str, buf, sizeof(buf), kCFStringEncodingUTF8))
            return false;
        c = buf;
    }
    return strIsClone(c);
}

static CFStringRef kBase = CFSTR("roblox");    // immortal CFSTR (no release)

#pragma mark ----------------------------------------------------------------
#pragma mark 1.  Core Foundation entry-point  (CFURLCopyScheme)

static CFStringRef (*orig_CFURLCopyScheme)(CFURLRef url) = NULL;

%hookf(CFStringRef, CFURLCopyScheme, CFURLRef url)
{
    CFStringRef s = orig_CFURLCopyScheme(url);             // +1 retain by contract
    if (s && cfIsClone(s)) {
        CFRelease(s);                                      // balance retain
        return (CFStringRef)CFRetain(kBase);               // hand back +1
    }
    return s;                                              // unchanged
}

#pragma mark ----------------------------------------------------------------
#pragma mark 2.  Roblox router  (RBLinkingHelper)

%hook RBLinkingHelper
+ (void)postDeepLinkNotificationWithURLString:(NSString *)urlStr
{
    /* nil-check: оригинальная реализация логирует и выходит */
    if (urlStr && urlStr.length > 6 && [urlStr hasPrefix:@"roblox"]) {
        NSRange colon = [urlStr rangeOfString:@":"];        // separate scheme
        if (colon.location != NSNotFound) {
            NSString *scheme = [urlStr substringToIndex:colon.location];
            if (strIsClone(scheme.UTF8String)) {
                /* rebuild:  “roblox”  +  rest-of-URL */
                urlStr = [@"roblox" stringByAppendingString:
                          [urlStr substringFromIndex:scheme.length]];
            }
        }
    }
    %orig(urlStr);                                         // hidden self/_cmd forwarded
}
%end

#pragma mark ----------------------------------------------------------------
#pragma mark ctor

%ctor
{
    /* grab clean pointer before %init — prevents NULL / signature mismatch   *
     * self + _cmd are implicit; param-3 is NSString* (seen in your disasm)   */
    orig_CFURLCopyScheme =
        (CFStringRef(*)(CFURLRef))dlsym(RTLD_DEFAULT, "CFURLCopyScheme");
    %init;
}