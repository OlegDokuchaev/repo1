#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <substrate.h>

/// robloxN:// → roblox://  (оставляем path, query, fragment нетронутыми)
static NSURL *RBXFixScheme(NSURL *url) {
    if (!url) return url;
    static NSRegularExpression *re;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        re = [NSRegularExpression regularExpressionWithPattern:@"^roblox\\d+$"
                                                       options:0 error:nil];
    });
    NSString *scheme = url.scheme.lowercaseString;
    if ([re firstMatchInString:scheme options:0 range:NSMakeRange(0, scheme.length)]) {
        NSURLComponents *c = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        c.scheme = @"roblox";
        return c.URL ?: url;
    }
    return url;
}

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
        if (![patched isEqual:ctx.URL]) {
            /* URL — readonly; меняем его через KVC.  
               Если Apple сменит имя ивара, try/catch не даст аварийно упасть. */
            @try  { [ctx setValue:patched forKey:@"URL"];  }
            @catch(NSException *) { [ctx setValue:patched forKey:@"_url"]; }
        }
    }
    %orig(contexts);
}
%end

/* 3. Исходящие вызовы внутри Roblox (не обязательно, но полезно) */
%hook UIApplication
- (void)openURL:(NSURL *)url
        options:(NSDictionary<NSString *, id> *)o
completionHandler:(void (^)(BOOL))h
{
    %orig(RBXFixScheme(url), o, h);
}
%end