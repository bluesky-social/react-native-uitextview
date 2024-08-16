#import <React/RCTViewManager.h>
#import <React/RCTUIManager.h>
#import "RCTBridge.h"
#import "Utils.h"

@interface RNUITextViewManager : RCTViewManager
@end

@implementation RNUITextViewManager

RCT_EXPORT_MODULE(RNUITextView)

- (UIView *)view
{
  return [[UIView alloc] init];
}

RCT_CUSTOM_VIEW_PROPERTY(color, NSString, UIView)
{
}

@end

@interface RNUITextViewChildManager : RCTViewManager
@end

@implementation RNUITextViewChildManager

RCT_EXPORT_MODULE(RNUITextViewChild)

- (UIView *)view
{
  return nil;
}

@end
