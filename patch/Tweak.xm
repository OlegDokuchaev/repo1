//
//  rbxurlpatch 1.0-5   (iOS 15 rootless)
//
//  Меняет robloxN:// → roblox:// и даёт расширенный лог
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <os/log.h>                // unified-log
#import <substrate.h>
#import <sys/stat.h>

#pragma mark –– лог-утилиты

static void RBXFileLog(NSString *line)
{
    static NSFileHandle *fh;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        mkdir("/var/mobile/Library/Logs", 0755);
        NSString *p=@"/var/mobile/Library/Logs/rbxurlpatch.log";
        [[NSFileManager defaultManager] createFileAtPath:p contents:nil attributes:nil];
        fh=[NSFileHandle fileHandleForWritingAtPath:p];
        [fh seekToEndOfFile];
    });
    [fh writeData:[[line stringByAppendingString:@"\n"]
                   dataUsingEncoding:NSUTF8StringEncoding]];
}
static inline void RBXLog(NSString *fmt, ...)
{
    va_list va; va_start(va,fmt);
    NSString *s=[[NSString alloc] initWithFormat:fmt arguments:va];
    va_end(va);
    os_log(OS_LOG_DEFAULT, "%{public}s", s.UTF8String);
    RBXFileLog(s);
}

#pragma mark –– замена схемы

static NSURL *RBXFix(NSURL *url)
{
    if(!url) return url;
    static NSRegularExpression *re;
    static dispatch_once_t once;
    dispatch_once(&once,^{
        re=[NSRegularExpression regularExpressionWithPattern:@"^roblox\\d+$"
                                                     options:0 error:nil];
    });
    NSString *sch=url.scheme.lowercaseString;
    if([re firstMatchInString:sch options:0 range:NSMakeRange(0,sch.length)]){
        NSURLComponents *c=[NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        c.scheme=@"roblox";
        NSURL *patched=c.URL?:url;
        RBXLog(@"patch %@  →  %@", url, patched);
        return patched;
    }
    return url;
}

__attribute__((constructor))
static void RBXInit()
{
    RBXLog(@"▶︎ rbxurlpatch.dylib injected ✔︎ (pid=%d)", getpid());
}

#pragma mark –– UIApplicationDelegate (cold + hot)

%hook NSObject
- (BOOL)application:(UIApplication *)app
didFinishLaunchingWithOptions:(NSDictionary *)opts
{
    RBXLog(@"[AppDelegate] didFinishLaunching, opts=%@", opts);
    NSMutableDictionary *m=[opts mutableCopy];
    NSURL *u=opts[UIApplicationLaunchOptionsURLKey];
    if(u) m[UIApplicationLaunchOptionsURLKey]=RBXFix(u);          // UIApplicationLaunchOptionsURLKey  [oai_citation:8‡Apple Developer](https://developer.apple.com/documentation/uikit/uiapplication/launchoptionskey/url?language=objc&utm_source=chatgpt.com)
    return %orig(app, m);
}
- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary *)opts
{
    RBXLog(@"[AppDelegate] openURL=%@", url);
    return %orig(app, RBXFix(url), opts);
}
%end

#pragma mark –– UISceneDelegate (iOS 13+)

%hook UIScene
- (void)openURLContexts:(NSSet<UIOpenURLContext *> *)ctxs
{
    RBXLog(@"[Scene] openURLContexts=%lu",(unsigned long)ctxs.count);
    for(UIOpenURLContext *ctx in ctxs){
        RBXLog(@"   ctx.URL=%@", ctx.URL);
        NSURL *p=RBXFix(ctx.URL);
        if(p!=ctx.URL) [ctx setValue:p forKey:@"URL"];        // обход readonly
    }
    %orig(ctxs);
}
%end

#pragma mark –– FrontBoard / LaunchServices (до запуска приложения)

%hook LSApplicationWorkspace
- (BOOL)openSensitiveURL:(NSURL *)url withOptions:(NSDictionary *)opt
{
    RBXLog(@"[LSAppWorkspace] openSensitiveURL=%@", url);
    return %orig(RBXFix(url), opt);
}
%end

#pragma mark –– исходящие вызовы из Roblox

%hook UIApplication
- (void)openURL:(NSURL *)url
        options:(NSDictionary *)o
completionHandler:(void(^)(BOOL))h
{
    RBXLog(@"[UIApplication] outgoing openURL=%@", url);
    %orig(RBXFix(url), o, h);
}
%end