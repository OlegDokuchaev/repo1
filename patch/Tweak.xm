#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <CoreFoundation/CoreFoundation.h>
#import <substrate.h>
#import <os/log.h>
#import <sys/stat.h>
#include <dlfcn.h>
#include <ctype.h>
#import <objc/message.h>   // objc_msgSend pointer cast

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

%hook RBAppsFlyerTracker

// –[RBAppsFlyerTracker didResolveDeepLink:]  ⇢ 1 аргумент
- (void)didResolveDeepLink:(id)result {

    // 1. Получаем deepLink динамически (AppsFlyerDeepLink*)
    id deepLink = [result performSelector:@selector(deepLink)];
    if (!deepLink) {         // safety-net против nil
        %orig(result);
        return;
    }

    // 2. Пытаемся вытащить navigationLink
    SEL navSel = NSSelectorFromString(@"navigationLink");
    if (![deepLink respondsToSelector:navSel]) {
        %orig(result);       // поле отсутствует — уходим
        return;
    }

    // 3. Читаем значение через objc_msgSend (ARC-safe cast)
    NSString *(*getter)(id, SEL) =
        (NSString *(*)(id, SEL))objc_msgSend;
    __unsafe_unretained NSString *nav =
        getter(deepLink, navSel);

    // 4. Если begin-схема «roblox1://» — патчим
    if ([nav hasPrefix:@"roblox1://"]) {

        NSString *patched = [nav stringByReplacingOccurrencesOfString:@"roblox1://"
                                                           withString:@"roblox://"];

        // KVC-сеттер остаётся самым простым
        @try {
            [deepLink setValue:patched forKey:@"navigationLink"];
        } @catch (NSException *e) {
            // Если property read-only — тихо игнорируем
        }
    }

    // 5. Продолжаем штатное выполнение оригинального метода
    %orig(result);
}
%end

%ctor {
    RBXLog(@"[RobloxDLFix] loaded with ElleKit ✅");
}
