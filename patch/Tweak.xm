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

%hookf(CFComparisonResult, CFStringCompare, CFStringRef a, CFStringRef b, CFStringCompareFlags flags)
{
    // helper: true, если строка == "roblox"
    auto IsBase  = ^BOOL(CFStringRef s) {
        return CFStringCompare(s, CFSTR("roblox"), 0) == kCFCompareEqualTo;
    };

    // helper: true, если строка начинается с "roblox" и после идут цифры
    auto IsClone = ^BOOL(CFStringRef s) {
        // быстро отсекаем prefix
        if (!CFStringHasPrefix(s, CFSTR("roblox"))) return NO;

        CFIndex len = CFStringGetLength(s);
        if (len <= 6) return NO;                 // "roblox" без цифр

        UniChar digits[len - 6];
        CFStringGetCharacters(s, CFRangeMake(6, len - 6), digits);

        for (CFIndex i = 0; i < len - 6; i++)
            if (!isdigit(digits[i])) return NO;  // встретили не-цифру

        return YES;                              // «roblox» + ≥1 цифра
    };

    BOOL aBase   = IsBase(a),   bBase   = IsBase(b);
    BOOL aClone  = IsClone(a),  bClone  = IsClone(b);

    if ( (aBase && bClone) || (aClone && bBase) )
        return kCFCompareEqualTo;                // считаем строки равными

    return %orig(a, b, flags);                   // во всех остальных случаях – обычное сравнение
}
%end
