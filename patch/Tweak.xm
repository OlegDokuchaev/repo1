//  Tweak.xm
//  rbxurlpatch 1.0-3  (iOS 15 rootless / Dopamine)
//
//  Цель: внутри процесса Roblox заменить схемы robloxN:// → roblox://,
//  чтобы deep-link-параметры placeId/launchData работали.

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <os/log.h>          // unified logging (iOS 10+)
#import <substrate.h>       // ElleKit/Substrate runtime

#pragma mark -- helpers -------------------------------------------------------

/// Запись в резервный текстовый лог (на случай, если unified-log недоступен)
static void RBXFileLog(NSString *line)
{
    static NSFileHandle *fh;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSString *path = @"/var/mobile/Library/Logs/rbxurlpatch.log";
        [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
        fh = [NSFileHandle fileHandleForWritingAtPath:path];
        [fh seekToEndOfFile];
    });
    [fh writeData:[[line stringByAppendingString:@"\n"]
                   dataUsingEncoding:NSUTF8StringEncoding]];
}

/// Если схема вида roblox1/roblox2 … — меняем на «roblox», сохраняя всё остальное.
static NSURL *RBXFixScheme(NSURL *url)
{
    if (!url) return url;

    static NSRegularExpression *re;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        re = [NSRegularExpression regularExpressionWithPattern:@"^roblox\\d+$"
                                                       options:0 error:nil];
    });

    NSString *scheme = url.scheme.lowercaseString;
    if ([re firstMatchInString:scheme options:0
                         range:NSMakeRange(0, scheme.length)]) {

        NSURLComponents *c = [NSURLComponents componentsWithURL:url
                                         resolvingAgainstBaseURL:NO];
        c.scheme = @"roblox";
        NSURL *patched = c.URL ?: url;

        /* ----- двойное логирование ----- */
        NSString *msg = [NSString stringWithFormat:@"roblox-scheme patched: %@ → %@",
                         url.absoluteString, patched.absoluteString];
        os_log(OS_LOG_DEFAULT, "%{public}s", msg.UTF8String);   // unified log
        RBXFileLog(msg);                                        // резервный файл

        return patched;
    }
    return url;
}

#pragma mark -- hooks ---------------------------------------------------------

/* 1. AppDelegate-маршрут (iOS 11+) */
%hook NSObject
- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)opts
{
    return %orig(app, RBXFixScheme(url), opts);
}
%end

/* 2. SceneDelegate-маршрут (iOS 13+) */
%hook UIScene
- (void)openURLContexts:(NSSet<UIOpenURLContext *> *)contexts
{
    for (UIOpenURLContext *ctx in contexts) {
        NSURL *patched = RBXFixScheme(ctx.URL);
        if (patched != ctx.URL) {
            /* KVC-обход readonly-свойства URL.
               initWithURL:options: у UIOpenURLContext отсутствует. */
            [ctx setValue:patched forKey:@"URL"];
        }
    }
    %orig(contexts);
}
%end

/* 3. Исходящие вызовы внутри Roblox (опционально, но полезно) */
%hook UIApplication
- (void)openURL:(NSURL *)url
        options:(NSDictionary<NSString *, id> *)o
completionHandler:(void (^)(BOOL))h
{
    %orig(RBXFixScheme(url), o, h);
}
%end