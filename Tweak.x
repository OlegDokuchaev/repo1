#import <UIKit/UIKit.h>

%hook UIApplication

// iOS 10+ entry-point that Roblox actually implements
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary *)options
{
    // our clones use schemes like roblox1, roblox2, … roblox5
    NSString *s = url.scheme.lowercaseString;
    if ([s hasPrefix:@"roblox"] && ![s isEqualToString:@"roblox"]) {
        // rebuild the URL with the original scheme so Roblox accepts params
        NSURLComponents *c = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        c.scheme = @"roblox";
        url = c.URL;
    }
    // call the real handler
    return %orig(application, url, options);
}

%end