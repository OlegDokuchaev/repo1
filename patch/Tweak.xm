#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <CoreFoundation/CoreFoundation.h>
#import <substrate.h>
#import <os/log.h>
#import <sys/stat.h>
#include <dlfcn.h>
#include <ctype.h>

#define DLSYM_NAME(type, sym) ((type)(void *)dlsym(RTLD_DEFAULT, sym))

#pragma mark –– лог

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

#pragma mark –– замена схемы

%hook UIApplicationDelegate // Будет применяться ко всем классам, реализующим методы делегата

- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Проверяем, был ли запуск через URL-схему
    NSURL *url = launchOptions[UIApplicationLaunchOptionsURLKey];
    if (url) {
        NSString *scheme = url.scheme;
        RBXLog(@"[RobloxSchemeTweak] Launch URL: %@", url);
        if ([scheme hasPrefix:@"roblox"] && ![scheme isEqualToString:@"roblox"]) {
            // Если схема начинается с "roblox" (например, roblox3) но не ровно "roblox"
            NSString *originalURLStr = url.absoluteString;
            // Заменяем префикс схемы на "roblox"
            NSString *newURLStr = [originalURLStr stringByReplacingOccurrencesOfString:[scheme stringByAppendingString:@"://"]
                                                                           withString:@"roblox://"];
            NSURL *newURL = [NSURL URLWithString:newURLStr];
            RBXLog(@"[RobloxSchemeTweak] Replacing scheme %@ -> roblox, new URL = %@", scheme, newURL);
            // Формируем новый launchOptions с заменённой URL-схемой
            NSMutableDictionary *newOptions = launchOptions.mutableCopy;
            newOptions[UIApplicationLaunchOptionsURLKey] = newURL;
            // Вызываем оригинальный метод с модифицированным options
            BOOL result = %orig(app, newOptions);
            return result;
        }
    }
    // Если URL нет или схема не требует замены, вызываем оригинал
    return %orig;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary *)options {
    NSString *scheme = url.scheme;
    RBXLog(@"[RobloxSchemeTweak] openURL: %@", url);
    if ([scheme hasPrefix:@"roblox"] && ![scheme isEqualToString:@"roblox"]) {
        // Логика аналогична: меняем robloxN -> roblox
        NSString *originalURLStr = url.absoluteString;
        NSString *newURLStr = [originalURLStr stringByReplacingOccurrencesOfString:[scheme stringByAppendingString:@"://"]
                                                                       withString:@"roblox://"];
        NSURL *newURL = [NSURL URLWithString:newURLStr];
        RBXLog(@"[RobloxSchemeTweak] Replacing scheme %@ -> roblox, new URL = %@", scheme, newURL);
        return %orig(app, newURL, options);
    }
    return %orig;
}

// (Необязательно) Для старых iOS версий перехватываем устаревший метод, если Roblox его использует:
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url sourceApplication:(NSString *)src annotation:(id)annot {
    NSString *scheme = url.scheme;
    RBXLog(@"[RobloxSchemeTweak] openURL:sourceApplication: %@", url);
    if ([scheme hasPrefix:@"roblox"] && ![scheme isEqualToString:@"roblox"]) {
        NSString *origURLStr = url.absoluteString;
        NSString *newURLStr = [origURLStr stringByReplacingOccurrencesOfString:[scheme stringByAppendingString:@"://"]
                                                                    withString:@"roblox://"];
        NSURL *newURL = [NSURL URLWithString:newURLStr];
        RBXLog(@"[RobloxSchemeTweak] Replacing scheme %@ -> roblox, new URL = %@", scheme, newURL);
        return %orig(app, newURL, src, annot);
    }
    return %orig;
}

%end

/* Helpers ---------------------------------------------------------------- */
static inline bool strIsClone(const char *s) {
    size_t len=strlen(s);
    if(len<=6||strncmp(s,"roblox",6)) return false;
    for(size_t i=6;i<len;++i)
        if(!isdigit((unsigned char)s[i])) return false;
    return true;
}
static bool cfIsClone(CFStringRef s){
    const char *c=CFStringGetCStringPtr(s,kCFStringEncodingUTF8);
    char buf[64];
    if(!c){
        if(!CFStringGetCString(s,buf,sizeof(buf),kCFStringEncodingUTF8)) return false;
        c=buf;
    }
    return strIsClone(c);
}
static CFStringRef kBase = CFSTR("roblox");

/* 1. Единственный перехват ---------------------------------------------- */
static CFStringRef (*orig_CFURLCopyScheme)(CFURLRef url);

%hookf(CFStringRef, CFURLCopyScheme, CFURLRef url)
{
    RBXLog(@"CFStringRef");
    CFStringRef s = orig_CFURLCopyScheme(url);   // kCFCopyRule
    if(s && cfIsClone(s)){
        CFRelease(s);
        return (CFStringRef)CFRetain(kBase);
    }
    return s;
}

/* 2. Obj-C safety-net (очень дёшево) ------------------------------------ */
%hook NSURL
- (NSString *)scheme {
    NSString *orig = %orig;
    RBXLog(@"NSURL.scheme");
    if(orig && cfIsClone((__bridge CFStringRef)orig))
        return @"roblox";
    return orig;
}
%end

/* 3. ctor — берём оригинал ------------------------------------------------ */
%ctor {
    orig_CFURLCopyScheme =
        (CFStringRef(*)(CFURLRef))dlsym(RTLD_DEFAULT,"CFURLCopyScheme");
    %init;
}