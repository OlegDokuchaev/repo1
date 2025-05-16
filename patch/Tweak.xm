#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>        // brought in by ElleKit at runtime

// Helper: convert “roblox1”→“roblox”, leave everything else unchanged
static NSURL *RBXSanitiseURL(NSURL *url)
{
    NSString *scheme = url.scheme.lowercaseString;
    NSRegularExpression *re =
        [NSRegularExpression regularExpressionWithPattern:@"^roblox\\d+$"
                                                  options:0 error:nil];

    if ([re firstMatchInString:scheme options:0
                         range:NSMakeRange(0, scheme.length)]) {

        // rebuild roblox://…  (resourceSpecifier preserves path + query)
        NSString *newStr =
            [NSString stringWithFormat:@"roblox://%@", url.resourceSpecifier ?: @""];
        return [NSURL URLWithString:newStr];
    }
    return url;  // untouched
}

/*  iOS 11+ uses application:openURL:options:
    Hook it in UIApplication so ALL URL-opens go through us, even if Roblox
    calls itself or another app redirects.                                         */
%hook UIApplication
- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    NSURL *patched = RBXSanitiseURL(url);
    return %orig(app, patched, options);
}
%end