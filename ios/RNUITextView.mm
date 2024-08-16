#ifdef RCT_NEW_ARCH_ENABLED
#import "RNUITextView.h"
#import "RNUITextViewChild.h"
#import "RNUITextViewComponentDescriptor.h"

#import <react/renderer/components/RNUITextViewSpec/EventEmitters.h>
#import <react/renderer/components/RNUITextViewSpec/Props.h>
#import <react/renderer/components/RNUITextViewSpec/RCTComponentViewHelpers.h>
#import <react/renderer/textlayoutmanager/RCTAttributedTextUtils.h>

#import "RCTFabricComponentsPlugins.h"
#import "Utils.h"

using namespace facebook::react;

@interface RNUITextView () <RCTRNUITextViewViewProtocol>

@end

@implementation RNUITextView {
  UIView * _view;
  UITextView * _textView;
  RNUITextViewShadowNode::ConcreteState::Shared _state;
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
    self.clipsToBounds = true;
    
    _textView = [[UITextView alloc] init];
    _textView.scrollEnabled = false;
    _textView.editable = false;
    _textView.textContainerInset = UIEdgeInsetsZero;
    _textView.textContainer.lineFragmentPadding = 0;
    // fill the parent view
    _textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_textView];
  }
  
  return self;
}

// See RCTParagraphComponentView
- (void)updateState:(const facebook::react::State::Shared &)state oldState:(const facebook::react::State::Shared &)oldState
{
  _state = std::static_pointer_cast<const RNUITextViewShadowNode::ConcreteState>(state);
  
  // Redraw the rect for new text size
  [self setNeedsDisplay];
}

// See RCTParagraphComponentView
- (void)prepareForRecycle
{
  [super prepareForRecycle];
  _state.reset();
}

- (void)drawRect:(CGRect)rect
{
  if (!_state) {
    return;
  }
  
  auto attributedString = _state->getData().attributedString;
  _textView.attributedText = RCTNSAttributedStringFromAttributedString(attributedString);
  
  printf("Ready to draw: %s \n", _textView.attributedText.string.UTF8String);
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
  const auto &oldViewProps = *std::static_pointer_cast<RNUITextViewProps const>(_props);
  const auto &newViewProps = *std::static_pointer_cast<RNUITextViewProps const>(props);
  
  if (oldViewProps.numberOfLines != newViewProps.numberOfLines) {
    _textView.textContainer.maximumNumberOfLines = newViewProps.numberOfLines;
  }
  
  if (oldViewProps.selectable != newViewProps.selectable) {
    _textView.selectable = newViewProps.selectable;
  }
  
  if (oldViewProps.ellipsizeMode != newViewProps.ellipsizeMode) {
    // @TODO enum this
    // _textView.textContainer.lineBreakMode = newViewProps.ellipsizeMode;
  }

  [super updateProps:props oldProps:oldProps];
}

Class<RCTComponentViewProtocol> RNUITextViewCls(void)
{
  return RNUITextView.class;
}

@end
#endif