// RobloxSchemeFix.xm
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <CoreFoundation/CoreFoundation.h>
#import <substrate.h>
#import <os/log.h>
#import <sys/stat.h>
#include <dlfcn.h>
#include <ctype.h>

static void RBXLog(NSString *fmt, ...)
{
    static NSFileHandle *fh;
    static dispatch_once_t once;
    va_list va; va_start(va,fmt);
    NSString *s=[[NSString alloc] initWithFormat:fmt arguments:va];
    va_end(va);

    os_log(OS_LOG_DEFAULT, "%{public}s", s.UTF8String);

    dispatch_once(&once, ^{
        mkdir("/var/mobile/Library/Logs",0755);
        NSString *p=@"/var/mobile/Library/Logs/rbxurlpatch.log";
        [[NSFileManager defaultManager] createFileAtPath:p contents:nil attributes:nil];
        fh=[NSFileHandle fileHandleForWritingAtPath:p]; [fh seekToEndOfFile];
    });
    [fh writeData:[[s stringByAppendingString:@"\n"]
                   dataUsingEncoding:NSUTF8StringEncoding]];
}

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
    RBXLog(@"Lua deep-link payload = %{CFURLCopyScheme}@", url);
    CFStringRef s = %orig(url);                     // ← правильный оригинал
    if (s && cfIsClone(s)) {
        CFRetain(kBase);                            // +1 для вызывающего кода
        CFRelease(s);                               // балансируем Copy-правило
        return kBase;
    }
    return s;
}

#pragma mark - 2. RBLinkingHelper

%hook RBAppsFlyerTracker
- (void)didResolveDeepLink:(id)result {
    // Печать всего объекта result (может быть NSDictionary или кастомный класс)
    RBXLog(@"AppsFlyer didResolveDeepLink: %{public}@", result);
    %orig;
}
%end

%hook RBLinkingHelper
+ (void)postDeepLinkNotificationWithURLString:(NSString *)urlStr {
    RBXLog(@"RBLinkingHelper URL = %{public}s", urlStr.UTF8String);
    %orig(urlStr);
}
%end

%hook RBMobileLuaScreenController
- (void)onNavigateToDeepLink:(NSDictionary *)info {
    RBXLog(@"Lua deep-link payload = %{public}@", info);
    %orig(info);
}
%end

__attribute__((constructor))
static void entry()
{
    RBXLog(@"▶︎ rbxurlpatch injected (pid=%d)",getpid());
}

__attribute__((constructor))
static void RBXInit()
{
    RBXLog(@"▶︎ rbxurlpatch.dylib injected ✔︎ (pid=%d)", getpid());
}

__attribute__((constructor))
static void RBXLoaded(void)
{
    RBXLog(@"▶︎ rbxurlpatch.dylib injected ✔︎");
}

#pragma mark - ctor

%ctor {
    %init;     // никаких dlsym / MSFindSymbol не требуется
}