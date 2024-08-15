#ifdef RCT_NEW_ARCH_ENABLED
#import "RNUITextView.h"
#import "RNUITextViewChild.h"
#import "RNUITextViewComponentDescriptor.h"

#import <react/renderer/components/RNUITextViewSpec/EventEmitters.h>
#import <react/renderer/components/RNUITextViewSpec/Props.h>
#import <react/renderer/components/RNUITextViewSpec/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"
#import "Utils.h"

using namespace facebook::react;

@interface RNUITextView () <RCTRNUITextViewViewProtocol>

@end

@implementation RNUITextView {
    UIView * _view;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
    return concreteComponentDescriptorProvider<RNUITextViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const RNUITextViewProps>();
    _props = defaultProps;

    _view = [[UIView alloc] init];

    self.contentView = _view;
  }

  return self;
}

- (void)didAddSubview:(UIView *)subview
{
  // See if its a child and if it is, get the text from that object

  // Store class in var

  if ([subview isKindOfClass:[RNUITextViewChild class]]) {
    RNUITextViewChild *child = (RNUITextViewChild *)subview;
  }
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
  const auto &oldViewProps = *std::static_pointer_cast<RNUITextViewProps const>(_props);
  const auto &newViewProps = *std::static_pointer_cast<RNUITextViewProps const>(props);

//    if (oldViewProps.color != newViewProps.color) {
//        NSString * colorToConvert = [[NSString alloc] initWithUTF8String: newViewProps.color.c_str()];
//        [_view setBackgroundColor: [Utils hexStringToColor:colorToConvert]];
//    }

  [super updateProps:props oldProps:oldProps];
}

- (void)setAttributedString
{
  printf("updating attr string\n");
}

Class<RCTComponentViewProtocol> RNUITextViewCls(void)
{
    return RNUITextView.class;
}

@end
#endif
