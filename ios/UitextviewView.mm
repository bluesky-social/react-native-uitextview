#ifdef RCT_NEW_ARCH_ENABLED
#import "UitextviewView.h"

#import <react/renderer/components/RNUitextviewViewSpec/ComponentDescriptors.h>
#import <react/renderer/components/RNUitextviewViewSpec/EventEmitters.h>
#import <react/renderer/components/RNUitextviewViewSpec/Props.h>
#import <react/renderer/components/RNUitextviewViewSpec/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"
#import "Utils.h"

using namespace facebook::react;

@interface UitextviewView () <RCTUitextviewViewViewProtocol>

@end

@implementation UitextviewView {
    UIView * _view;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
    return concreteComponentDescriptorProvider<UitextviewViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const UitextviewViewProps>();
    _props = defaultProps;

    _view = [[UIView alloc] init];

    self.contentView = _view;
  }

  return self;
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
    const auto &oldViewProps = *std::static_pointer_cast<UitextviewViewProps const>(_props);
    const auto &newViewProps = *std::static_pointer_cast<UitextviewViewProps const>(props);

    if (oldViewProps.color != newViewProps.color) {
        NSString * colorToConvert = [[NSString alloc] initWithUTF8String: newViewProps.color.c_str()];
        [_view setBackgroundColor: [Utils hexStringToColor:colorToConvert]];
    }

    [super updateProps:props oldProps:oldProps];
}

Class<RCTComponentViewProtocol> UitextviewViewCls(void)
{
    return UitextviewView.class;
}

@end
#endif
