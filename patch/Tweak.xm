#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>
#import <os/log.h>
#import <sys/stat.h>

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

/* ————————————————————— helpers ————————————————————— */
static inline bool strIsBase(const char *s) {
    return strcmp(s, "roblox") == 0;
}
static inline bool strIsClone(const char *s) {
    size_t len = strlen(s);
    if (len <= 6 || strncmp(s, "roblox", 6)) return false;
    for (size_t i = 6; i < len; ++i)
        if (!isdigit((unsigned char)s[i])) return false;
    return true;
}
static bool cfIsBase(CFStringRef s);
static bool cfIsClone(CFStringRef s);

static bool cfStrTest(CFStringRef s, bool (*pred)(const char*)) {
    const char *c = CFStringGetCStringPtr(s, kCFStringEncodingUTF8);
    char buf[64];
    if (!c) {
        if (!CFStringGetCString(s, buf, sizeof(buf), kCFStringEncodingUTF8))
            return false;
        c = buf;
    }
    return pred(c);
}
static bool cfIsBase(CFStringRef s)  { return cfStrTest(s, strIsBase);  }
static bool cfIsClone(CFStringRef s) { return cfStrTest(s, strIsClone); }

static CFStringRef kBase = CFSTR("roblox");   // retain-free literal

/* ——————————————————— originals via dlsym ——————————————————— */
static CFComparisonResult (*orig_CFStringCompare)
        (CFStringRef, CFStringRef, CFStringCompareFlags) = NULL;
static CFComparisonResult (*orig_CFStringCompareWithOptions)
        (CFStringRef, CFStringRef, CFRange, CFComparisonResult,
         CFStringCompareFlags) = NULL;   // same ABI for *_Locale
static Boolean (*orig_CFEqual)(CFTypeRef, CFTypeRef) = NULL;
static CFStringRef (*orig_CFURLCopyScheme)(CFURLRef) = NULL;

/* ———————————————————— 1. scheme getter ———————————————————— */
%hookf(CFStringRef, CFURLCopyScheme, CFURLRef url)
{
    CFStringRef s = orig_CFURLCopyScheme(url);
    if (!s) return s;

    if (cfIsClone(s)) {
        CFRelease(s);
        return CFRetain(kBase);          // follow CF Create/Copy rule
    }
    return s;
}

/* ———————————————————— 2. string equality ———————————————————— */
%hookf(Boolean, CFEqual, CFTypeRef a, CFTypeRef b)
{
    if (CFGetTypeID(a)==CFStringGetTypeID() &&
        CFGetTypeID(b)==CFStringGetTypeID()) {
        if ((cfIsBase(a)&&cfIsClone(b)) || (cfIsClone(a)&&cfIsBase(b)))
            return true;
    }
    return orig_CFEqual(a, b);
}

/* ———————————————————— 3a. CFStringCompare ———————————————————— */
%hookf(CFComparisonResult, CFStringCompare,
       CFStringRef a, CFStringRef b, CFStringCompareFlags flags)
{
    if ((cfIsBase(a)&&cfIsClone(b)) || (cfIsClone(a)&&cfIsBase(b)))
        return kCFCompareEqualTo;
    return orig_CFStringCompare(a, b, flags);
}

/* ———————————————————— 3b. …WithOptions & …WithOptionsAndLocale ——— */
%hookf(CFComparisonResult, CFStringCompareWithOptions,
       CFStringRef a, CFStringRef b,
       CFRange rangeA, CFRange rangeB, CFStringCompareFlags flags)
{
    // упрощённо: если сравниваются «полные» строки — применяем правила
    if (rangeA.location==0 && rangeB.location==0 &&
        rangeA.length==CFStringGetLength(a) &&
        rangeB.length==CFStringGetLength(b)) {
        if ((cfIsBase(a)&&cfIsClone(b)) || (cfIsClone(a)&&cfIsBase(b)))
            return kCFCompareEqualTo;
    }
    return orig_CFStringCompareWithOptions(a, b, rangeA, rangeB, flags);
}

/* alias: CFStringCompareWithOptionsAndLocale имеет ту же сигнатуру,
   поэтому Logos автоматически применит тот же hook               */

/* ———————————————————— 3c. Obj-C layer (safety net) ——————————— */
%hook NSURL
- (NSString *)scheme
{
    NSString *orig = %orig;
    if (orig && cfIsClone((__bridge CFStringRef)orig))
        return @"roblox";
    return orig;
}
%end

/* ———————————————————— ctor ———————————————————— */
%ctor {
    orig_CFStringCompare = dlsym(RTLD_NEXT, "CFStringCompare");
    orig_CFStringCompareWithOptions =
        dlsym(RTLD_NEXT, "CFStringCompareWithOptions");
    orig_CFEqual = dlsym(RTLD_NEXT, "CFEqual");
    orig_CFURLCopyScheme = dlsym(RTLD_NEXT, "CFURLCopyScheme");
    %init;
}