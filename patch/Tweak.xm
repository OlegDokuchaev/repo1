#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>

/// roblox1:// → roblox://   (оставляет параметры и путь нетронутыми)
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
        return c.URL ?: url;
    }
    return url;
}

/* 1. ВХОДЯЩИЕ deep-links (iOS 11+ classic AppDelegate) */
%hook NSObject   // будет перехвачено только у класса-делегата
- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)opts
{
    return %orig(app, RBXFixScheme(url), opts);
}
%end

/* 2. ВХОДЯЩИЕ deep-links (iOS 13+ c UIScene) */
%hook UIScene
- (void)openURLContexts:(NSSet<UIOpenURLContext *> *)contexts
{
    if (contexts.count == 0) return %orig(contexts);

    NSMutableSet *fixed = [NSMutableSet setWithCapacity:contexts.count];
    for (UIOpenURLContext *ctx in contexts) {
        NSURL *u = RBXFixScheme(ctx.URL);
        if (u == ctx.URL) {
            [fixed addObject:ctx];
        } else {
            // клонируем контекст с патченым URL
            UIOpenURLContext *clone =
                [[UIOpenURLContext alloc] initWithURL:u options:ctx.options];
            [fixed addObject:clone];
        }
    }
    %orig(fixed);
}
%end

/* 3. Исходящие вызовы из Roblox самого себя (не обязателен, но полезен) */
%hook UIApplication
- (void)openURL:(NSURL *)url
        options:(NSDictionary<NSString *, id> *)opts
completionHandler:(void (^)(BOOL))handler
{
    %orig(RBXFixScheme(url), opts, handler);
}
%end