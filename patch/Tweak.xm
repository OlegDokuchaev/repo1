#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <CoreFoundation/CoreFoundation.h>
#import <substrate.h>
#import <os/log.h>
#import <sys/stat.h>
#include <dlfcn.h>
#include <ctype.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import "RBDeepLinkActionData.h"   // сгенерированный заголовок
#include <substrate.h>

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

static void ShowAlert(NSString *message, NSString *title) {
    // Создаём контроллер с параметрами
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:title
                         message:message
                  preferredStyle:UIAlertControllerStyleAlert];

    // Добавляем кнопку OK
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:nil];
    [alert addAction:okAction];

    // Находим топ-most UIViewController
    UIViewController *rootVC = [UIApplication sharedApplication].delegate.window.rootViewController;
    UIViewController *presentingVC = rootVC;
    while (presentingVC.presentedViewController) {
        presentingVC = presentingVC.presentedViewController;
    }

    // Показываем алерт
    [presentingVC presentViewController:alert animated:YES completion:nil];
}

static NSURL *AFix(NSURL *u) {
    RBXLog(@"AFix");

    if ([[u scheme] isEqualToString:@"roblox1"]) {
        /* «отрезаем» символ ‘1’ и создаём новый объект */
        NSString *fixed = [@"roblox://" stringByAppendingString:
                           [[u absoluteString] substringFromIndex:10]];
        return [NSURL URLWithString:fixed];
    }
    return u;
}

%hook RBAppsFlyerTracker

// –[RBAppsFlyerTracker didResolveDeepLink:]  ⇢ 1 аргумент
- (void)didResolveDeepLink:(id)result {
    ShowAlert(@"didResolveDeepLink", @"didResolveDeepLink");
    RBXLog(@"didResolveDeepLink");

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

// Подсмотренная в рантайме сигнатура: –(void)openLink:(id)link;
%hook RBLinkingProtocol
- (void)openLink:(id)link {
    ShowAlert(@"openLink", @"openLink");
    RBXLog(@"openLink");

    // Универсально работаем и со строками, и с NSURL
    NSString *urlString = nil;

    if ([link isKindOfClass:[NSString class]]) {
        urlString = (NSString *)link;
    } else if ([link isKindOfClass:[NSURL class]]) {
        urlString = [(NSURL *)link absoluteString];
    }

    if ([urlString hasPrefix:@"roblox1://"]) {

        NSString *patched = [urlString stringByReplacingOccurrencesOfString:@"roblox1://"
                                                                 withString:@"roblox://"];

        if ([link isKindOfClass:[NSString class]]) {
            link = patched;
        } else if ([link isKindOfClass:[NSURL class]]) {
            link = [NSURL URLWithString:patched];
        }
    }
    %orig(link);   // передаём исправленную ссылку оригиналу
}
%end

%group RBUIApplicationHooks          // ℹ️ активируем вручную
%hook UIApplication

- (BOOL)openURL:(NSURL *)url {
    ShowAlert(@"openURL", @"openURL");
    RBXLog(@"openURL");

    NSURL *patched = url;
    if ([[url absoluteString] hasPrefix:@"roblox1://"]) {
        NSString *fixed = [[url absoluteString]
                           stringByReplacingOccurrencesOfString:@"roblox1://"
                                                         withString:@"roblox://"];
        patched = [NSURL URLWithString:fixed];
    }
    return %orig(patched);
}

- (void)openURL:(NSURL *)url
        options:(NSDictionary *)options
completionHandler:(id)completion {
    ShowAlert(@"openURL2", @"openURL2");
    RBXLog(@"openURL2");

    NSURL *patched = url;
    if ([[url absoluteString] hasPrefix:@"roblox1://"]) {
        NSString *fixed = [[url absoluteString]
                           stringByReplacingOccurrencesOfString:@"roblox1://"
                                                         withString:@"roblox://"];
        patched = [NSURL URLWithString:fixed];
    }
    %orig(patched, options, completion);
}
%end
%end

%group RBLateHooks   // <- объявляем группу, которую активируем вручную
%hook RBLinkingHelper
- (void)postDeepLinkNotificationWithURLString:(NSString *)urlStr {
    ShowAlert(@"postDeepLinkNotificationWithURLString", @"postDeepLinkNotificationWithURLString");
    RBXLog(@"postDeepLinkNotificationWithURLString");

    // заменяем только неправильный префикс
    if ([urlStr hasPrefix:@"roblox1://"]) {
        RBXLog(@"[Fix] patching scheme → %@", urlStr);
        urlStr = [urlStr stringByReplacingOccurrencesOfString:@"roblox1://"
                                                   withString:@"roblox://"];
    }
    %orig(urlStr);          // уведомляем систему уже «правильной» строкой
}
%end
%end

static void InitLateHooksIfNeeded(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        %init(RBUIApplicationHooks);
        RBXLog(@"UIApplication хуки активированы");
    });
}

%hook RBDeepLinkActionData
- (void)setUrl:(NSString *)url { %orig([AFix([NSURL URLWithString:url]) absoluteString]); }
- (id)initWithDictionary:(NSDictionary *)dict {
    id s = %orig;
    if (s) { [self setUrl:[AFix([NSURL URLWithString:[self url]]) absoluteString]]; }
    return s;
}
%end

%hookf(CFComparisonResult, CFStringCompare, CFStringRef str1, CFStringRef str2, CFOptionFlags opts) {
    RBXLog(@"[StringHook] CFStringCompare: '%@' vs '%@' (opts=0x%llx)'",
           (__bridge NSString *)str1,
           (__bridge NSString *)str2,
           (unsigned long long)opts);
    return %orig;
}

%ctor {
    %init;
    RBXLog(@"RobloxDLFix injected");

    dispatch_async(dispatch_get_main_queue(), ^{
        RBXLog(@"RobloxDLFix injected (pid %d)", getpid());

        // вызывайте ЭТОТ код уже внутри процесса Roblox, лучше в main-queue
        NSString *exe = [[NSBundle mainBundle] executablePath];
        unsigned int n = 0;
        const char **names = objc_copyClassNamesForImage(exe.UTF8String, &n);
        RBXLog(@"Roblox-классов в образе %s: %u", exe.UTF8String, n);
        for (unsigned int i = 0; i < n; i++)
            RBXLog(@"%s", names[i]);       // здесь будут RB-, RBL-, RBN-… классы
        free(names);

        %init(RBLateHooks);
        RBXLog(@"RBLateHooks хуки активированы");

        // 3. Ждём загрузки фреймворка
            [[NSNotificationCenter defaultCenter]
              addObserverForName:NSBundleDidLoadNotification
                          object:nil
                           queue:nil
                      usingBlock:^(__unused NSNotification *n) {
                if (NSClassFromString(@"UIApplication"))
                    InitLateHooksIfNeeded();        // ← второй вызов, но once-guard
            }];
    });
}
