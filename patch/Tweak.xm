//
//  rbxurlpatch 1.0-4
//  (iOS 15 rootless / Dopamine)
//
//  Меняет robloxN:// на roblox:// и выводит расширенный лог.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <os/log.h>          // unified logging  [oai_citation:0‡Apple Developer](https://developer.apple.com/documentation/os/generating-log-messages-from-your-code?utm_source=chatgpt.com) [oai_citation:1‡Apple Developer](https://developer.apple.com/documentation/os/os_log?utm_source=chatgpt.com)
#import <substrate.h>       // ElleKit / MobileSubstrate runtime
#import <sys/stat.h>

#pragma mark – файл-лог --------------------------------------------------------

static void RBXFileLog(NSString *line)
{
    static NSFileHandle *fh;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSString *dir = @"/var/mobile/Library/Logs";
        NSString *path = [dir stringByAppendingPathComponent:@"rbxurlpatch.log"];

        /* создаём каталог, если его стёрли */
        mkdir(dir.UTF8String, 0755);

        [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
        fh = [NSFileHandle fileHandleForWritingAtPath:path];
        [fh seekToEndOfFile];
    });

    NSString *tsLine = [NSString stringWithFormat:@"%@\n", line];
    [fh writeData:[tsLine dataUsingEncoding:NSUTF8StringEncoding]];
}

static inline void RBXLogBoth(NSString *fmt, ...)
{
    va_list va;
    va_start(va, fmt);
    NSString *s = [[NSString alloc] initWithFormat:fmt arguments:va];
    va_end(va);

    os_log(OS_LOG_DEFAULT, "%{public}s", s.UTF8String);     // unified log  [oai_citation:2‡Medium](https://medium.com/%40vinodh_36508/logging-made-easy-exploring-apples-oslogs-6a9c6e239bf7?utm_source=chatgpt.com)
    RBXFileLog(s);                                          // резервный файл
}

#pragma mark – замена схемы ----------------------------------------------------

static NSURL *RBXFixScheme(NSURL *url)
{
    if (!url) return url;

    static NSRegularExpression *re;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        /* roblox1, roblox2, … */
        re = [NSRegularExpression regularExpressionWithPattern:@"^roblox\\d+$"
                                                       options:0 error:nil];
    });

    NSString *scheme = url.scheme.lowercaseString;
    if ([re firstMatchInString:scheme options:0
                         range:NSMakeRange(0, scheme.length)]) {

        NSURLComponents *c =
            [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        c.scheme = @"roblox";
        NSURL *patched = c.URL ?: url;

        RBXLogBoth(@"patched URL: %@ → %@", url.absoluteString, patched.absoluteString);
        return patched;
    }
    return url;
}

#pragma mark – инъекционный маркер ---------------------------------------------

__attribute__((constructor))
static void RBXLoaded(void)
{
    RBXLogBoth(@"▶︎ rbxurlpatch.dylib injected ✔︎");
}

#pragma mark – хуки ------------------------------------------------------------

/* 1. UIApplicationDelegate (iOS 11+) */
%hook NSObject
- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)opts
{
    RBXLogBoth(@"[AppDelegate] incoming URL = %@", url.absoluteString);
    return %orig(app, RBXFixScheme(url), opts);
}
%end

/* 2. UISceneDelegate (iOS 13+) */
%hook UIScene
- (void)openURLContexts:(NSSet<UIOpenURLContext *> *)contexts
{
    RBXLogBoth(@"[SceneDelegate] openURLContexts count = %lu",
               (unsigned long)contexts.count);          // API docs  [oai_citation:3‡Apple Developer](https://developer.apple.com/documentation/uikit/uiscenedelegate/scene%28_%3Aopenurlcontexts%3A%29?utm_source=chatgpt.com)

    for (UIOpenURLContext *ctx in contexts) {
        RBXLogBoth(@"    original → %@", ctx.URL.absoluteString);
        NSURL *patched = RBXFixScheme(ctx.URL);
        if (patched != ctx.URL) {
            /* URL — read-only; KVC-обход приемлем для твиков  [oai_citation:4‡Apple Developer](https://developer.apple.com/documentation/uikit/uiopenurlcontext/url?language=objc&utm_source=chatgpt.com) */
            [ctx setValue:patched forKey:@"URL"];
        }
    }
    %orig(contexts);
}
%end

/* 3. Вызовы openURL _изнутри_ Roblox */
%hook UIApplication
- (void)openURL:(NSURL *)url
        options:(NSDictionary<NSString*,id> *)o
completionHandler:(void (^)(BOOL))h
{
    RBXLogBoth(@"[UIApplication] will open %@", url.absoluteString);
    %orig(RBXFixScheme(url), o, h);
}
%end