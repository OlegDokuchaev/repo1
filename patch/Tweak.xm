#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <CoreFoundation/CoreFoundation.h>
#import <substrate.h>
#import <os/log.h>
#import <sys/stat.h>
#include <dlfcn.h>
#include <ctype.h>

#define DLSYM_NAME(type, sym) ((type)(void *)dlsym(RTLD_DEFAULT, sym))

/* Helpers ---------------------------------------------------------------- */
static inline bool strIsClone(const char *s) {
    size_t len=strlen(s);
    if(len<=6||strncmp(s,"qwerty",6)) return false;
    for(size_t i=6;i<len;++i)
        if(!isdigit((unsigned char)s[i])) return false;
    return true;
}
static bool cfIsClone(CFStringRef s){
    const char *c=CFStringGetCStringPtr(s,kCFStringEncodingUTF8);
    char buf[64];
    if(!c){
        if(!CFStringGetCString(s,buf,sizeof(buf),kCFStringEncodingUTF8)) return false;
        c=buf;
    }
    return strIsClone(c);
}
static CFStringRef kBase = CFSTR("roblox");

/* 1. Единственный перехват ---------------------------------------------- */
static CFStringRef (*orig_CFURLCopyScheme)(CFURLRef url);

%hookf(CFStringRef, CFURLCopyScheme, CFURLRef url)
{
    CFStringRef s = orig_CFURLCopyScheme(url);   // kCFCopyRule
    if(s && cfIsClone(s)){
        CFRelease(s);
        return (CFStringRef)CFRetain(kBase);
    }
    return s;
}

/* 2. Obj-C safety-net (очень дёшево) ------------------------------------ */
%hook NSURL
- (NSString *)scheme {
    NSString *orig = %orig;
    if(orig && cfIsClone((__bridge CFStringRef)orig))
        return @"roblox";
    return orig;
}
%end

/* 3. ctor — берём оригинал ------------------------------------------------ */
%ctor {
    orig_CFURLCopyScheme =
        (CFStringRef(*)(CFURLRef))dlsym(RTLD_DEFAULT,"CFURLCopyScheme");
    %init;
}