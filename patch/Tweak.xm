#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <os/log.h>          // unified-log
#import <substrate.h>

/// robloxN:// → roblox://  (оставляет путь, query, fragment нетронутыми)
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

        /*-- лог пишем в Unified Logging --*/
        os_log(OS_LOG_DEFAULT,
               "rbxurlpatch: %{public}@ → %{public}@",
               url.absoluteString, patched.absoluteString);   /* [oai_citation:0‡Apple Developer](https://developer.apple.com/documentation/os/generating-log-messages-from-your-code?utm_source=chatgpt.com)*/

        return patched;
    }
    return url;
}

/* 1. AppDelegate-маршрут (iOS 11 +) */
%hook NSObject
- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)opts
{
    return %orig(app, RBXFixScheme(url), opts);
}
%end

/* 2. SceneDelegate-маршрут (iOS 13 +) */
%hook UIScene
- (void)openURLContexts:(NSSet<UIOpenURLContext *> *)contexts
{
    for (UIOpenURLContext *ctx in contexts) {
        NSURL *patched = RBXFixScheme(ctx.URL);
        if (patched != ctx.URL) {
            /* KVC-обход readonly; Apple не запрещает, а init-конструктора нет  [oai_citation:1‡Apple Developer](https://developer.apple.com/documentation/uikit/uiopenurlcontext?utm_source=chatgpt.com) [oai_citation:2‡Apple Developer](https://developer.apple.com/documentation/uikit/uiscenedelegate/scene%28_%3Aopenurlcontexts%3A%29?utm_source=chatgpt.com) */
            [ctx setValue:patched forKey:@"URL"];
        }
    }
    %orig(contexts);
}
%end

/* 3. Исходящие вызовы внутри Roblox (не обязателен, но полезен) */
%hook UIApplication
- (void)openURL:(NSURL *)url
        options:(NSDictionary<NSString *, id> *)o
completionHandler:(void (^)(BOOL))h
{
    %orig(RBXFixScheme(url), o, h);
}
%end