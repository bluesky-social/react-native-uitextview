#import <React/RCTViewManager.h>
#import <React/RCTUIManager.h>
#import "RCTBridge.h"

@interface UitextviewViewManager : RCTViewManager
@end

@implementation UitextviewViewManager

RCT_EXPORT_MODULE(UitextviewView)

- (UIView *)view
{
  return [[UIView alloc] init];
}

RCT_EXPORT_VIEW_PROPERTY(color, NSString)

@end
