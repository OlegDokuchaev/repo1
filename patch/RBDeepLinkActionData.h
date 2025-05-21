#import "RBModel.h"

@class NSString;

@interface RBDeepLinkActionData : RBModel
{
    int _handlerType;
    NSString *_url;
}

@property(nonatomic) int handlerType; // @synthesize handlerType=_handlerType;
@property(retain, nonatomic) NSString *url; // @synthesize url=_url;
- (id)initWithDictionary:(id)arg1;

@end