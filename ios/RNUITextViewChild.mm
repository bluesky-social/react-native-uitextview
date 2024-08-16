#ifdef RCT_NEW_ARCH_ENABLED
#import "RNUITextViewChild.h"
#import "RNUITextView.h"
#import "RNUITextViewChildComponentDescriptor.h"

#import <react/renderer/components/RNUITextViewSpec/EventEmitters.h>
#import <react/renderer/components/RNUITextViewSpec/Props.h>
#import <react/renderer/components/RNUITextViewSpec/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"
#import "Utils.h"

using namespace facebook::react;

@interface RNUITextViewChild () <RCTRNUITextViewChildViewProtocol>

@end

@implementation RNUITextViewChild {
  NSString *text;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
    return concreteComponentDescriptorProvider<RNUITextViewChildComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const RNUITextViewChildProps>();
    _props = defaultProps;
  }
  return self;
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
  [super updateProps:props oldProps:oldProps];
}

Class<RCTComponentViewProtocol> RNUITextViewChildCls(void)
{
    return RNUITextViewChild.class;
}

@end
#endif
