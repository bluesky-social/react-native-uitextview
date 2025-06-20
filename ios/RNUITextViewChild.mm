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
  NSString * _text;
  RCTBubblingEventBlock _onPress;
  RCTBubblingEventBlock _onLongPress;
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
  const auto &oldViewProps = *std::static_pointer_cast<RNUITextViewChildProps const>(_props);
  const auto &newViewProps = *std::static_pointer_cast<RNUITextViewChildProps const>(props);

  if (newViewProps.text != oldViewProps.text) {
    NSString *text = [NSString stringWithUTF8String:newViewProps.text.c_str()];
    _text = text;
  }

  [super updateProps:props oldProps:oldProps];
}

- (void)onPress {
  if (_eventEmitter != nullptr) {
    std::dynamic_pointer_cast<const facebook::react::RNUITextViewChildEventEmitter>(_eventEmitter)
    ->onPress(facebook::react::RNUITextViewChildEventEmitter::OnPress{});
  }
}

- (void)onLongPress {
  if (_eventEmitter != nullptr) {
    std::dynamic_pointer_cast<const facebook::react::RNUITextViewChildEventEmitter>(_eventEmitter)
    ->onLongPress(facebook::react::RNUITextViewChildEventEmitter::OnLongPress{});
  }
}

+ (BOOL)shouldBeRecycled {
  return NO;
}

Class<RCTComponentViewProtocol> RNUITextViewChildCls(void)
{
    return RNUITextViewChild.class;
}

@end
