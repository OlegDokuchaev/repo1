#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <CoreFoundation/CoreFoundation.h>
#import <substrate.h>
#import <os/log.h>
#import <sys/stat.h>
#include <dlfcn.h>
#include <ctype.h>

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

- (void)didResolveDeepLink:(id)deepLinkResult {

    id deepLink   = [deepLinkResult deepLink];
    NSString *nav = [deepLink navigationLink];

    if ([nav hasPrefix:@"roblox1://"]) {
        NSString *patched =
            [nav stringByReplacingOccurrencesOfString:@"roblox1://"
                                           withString:@"roblox://"];

        [deepLink setValue:patched forKey:@"navigationLink"];
    }

    %orig(deepLinkResult);   // Continue normal flow
}
%end

%ctor {
    RBXLog(@"[RobloxDLFix] loaded with ElleKit ✅");
}
