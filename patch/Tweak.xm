//  rbxurlpatch 1.0-6  — универсальный deep-link патч

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>
#import <os/log.h>
#import <sys/stat.h>

#pragma mark –– лог

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

#pragma mark –– замена схемы

static NSURL *Patch(NSURL *u)
{
    if(!u) return u;
    static NSRegularExpression *re;
    static dispatch_once_t once;
    dispatch_once(&once,^{
        re=[NSRegularExpression regularExpressionWithPattern:@"^roblox\\d+$"
                                                     options:0 error:nil];
    });
    NSString *sch=u.scheme.lowercaseString;
    if([re firstMatchInString:sch options:0 range:NSMakeRange(0,sch.length)]){
        NSURLComponents *c=[NSURLComponents componentsWithURL:u resolvingAgainstBaseURL:NO];
        c.scheme=@"roblox";
        NSURL *pu=c.URL?:u;
        RBXLog(@"patch %@  →  %@",u,pu);
        return pu;
    }
    return u;
}

#pragma mark –– динамические хуки

static BOOL (*orig_launch)(id,SEL,UIApplication*,NSDictionary*);
static BOOL patched_launch(id self,SEL _cmd,UIApplication* app,NSDictionary* opts){
    RBXLog(@"[launch] opts=%@",opts);
    NSMutableDictionary *m=[opts mutableCopy];
    NSURL *url=m[UIApplicationLaunchOptionsURLKey];
    if(url) m[UIApplicationLaunchOptionsURLKey]=Patch(url);
    return orig_launch(self,_cmd,app,m);
}

static void (*orig_sceneWill)(id,SEL,UIScene*,UISceneSession*,UISceneConnectionOptions*);
static void patched_sceneWill(id self,SEL _cmd,UIScene* sc,UISceneSession* sess,UISceneConnectionOptions* co){
    if(co.URLContexts.count){
        UIOpenURLContext *ctx=co.URLContexts.allObjects.firstObject;
        RBXLog(@"[scene willConnect] %@",ctx.URL);
        NSURL *pu=Patch(ctx.URL);
        if(pu!=ctx.URL) [ctx setValue:pu forKey:@"URL"];
    }
    orig_sceneWill(self,_cmd,sc,sess,co);
}

static void HookDelegate(id del)
{
    if(!del) return;
    Class cls=[del class];
    static dispatch_once_t once;
    dispatch_once(&once,^{ RBXLog(@"[Hook] AppDelegate = %@",cls); });

    MSHookMessageEx(cls,
        @selector(application:didFinishLaunchingWithOptions:),
        (IMP)patched_launch,(IMP*)&orig_launch);
}

static void HookSceneDelegate(id del)
{
    if(!del) return;
    Class cls=[del class];
    static dispatch_once_t once;
    dispatch_once(&once,^{ RBXLog(@"[Hook] SceneDelegate = %@",cls); });

    MSHookMessageEx(cls,
        @selector(scene:willConnectToSession:options:),
        (IMP)patched_sceneWill,(IMP*)&orig_sceneWill);
}

__attribute__((constructor))
static void entry()
{
    RBXLog(@"▶︎ rbxurlpatch injected (pid=%d)",getpid());

    dispatch_async(dispatch_get_main_queue(), ^{
        HookDelegate(UIApplication.sharedApplication.delegate);

        // первая сцена появляется уже к этому моменту
        for(UIScene* sc in UIApplication.sharedApplication.connectedScenes){
            HookSceneDelegate(sc.delegate);
        }
    });
}