#ifdef RCT_NEW_ARCH_ENABLED
#import "RNUITextView.h"
#import "RNUITextViewChild.h"
#import "RNUITextViewComponentDescriptor.h"

#import <react/renderer/components/RNUITextViewSpec/EventEmitters.h>
#import <react/renderer/components/RNUITextViewSpec/Props.h>
#import <react/renderer/components/RNUITextViewSpec/RCTComponentViewHelpers.h>
#import <react/renderer/textlayoutmanager/RCTAttributedTextUtils.h>

#import "RCTFabricComponentsPlugins.h"

using namespace facebook::react;

@interface RNUITextView () <RCTRNUITextViewViewProtocol, UIGestureRecognizerDelegate>

@end

@implementation RNUITextView{
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
    [self addSubview:_textView];
    
    const auto longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                          action:@selector(handleLongPressIfNecessary:)
    ];
    longPressGestureRecognizer.delegate = self;
    
    const auto pressGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                action:@selector(handlePressIfNecessary:)
    ];
    pressGestureRecognizer.delegate = self;
    [pressGestureRecognizer requireGestureRecognizerToFail:longPressGestureRecognizer];
    
    [_textView addGestureRecognizer:pressGestureRecognizer];
    [_textView addGestureRecognizer:longPressGestureRecognizer];
  }

  return self;
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
  
  const auto attributedString = _state->getData().attributedString;
  _textView.attributedText = RCTNSAttributedStringFromAttributedString(attributedString);
  
  _textView.frame = _view.frame;
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
    if (newViewProps.ellipsizeMode == RNUITextViewEllipsizeMode::Head) {
      _textView.textContainer.lineBreakMode = NSLineBreakMode::NSLineBreakByTruncatingHead;
    } else if (newViewProps.ellipsizeMode == RNUITextViewEllipsizeMode::Middle) {
      _textView.textContainer.lineBreakMode = NSLineBreakMode::NSLineBreakByTruncatingMiddle;
    } else if (newViewProps.ellipsizeMode == RNUITextViewEllipsizeMode::Tail) {
      _textView.textContainer.lineBreakMode = NSLineBreakMode::NSLineBreakByTruncatingTail;
    } else if (newViewProps.ellipsizeMode == RNUITextViewEllipsizeMode::Clip) {
      _textView.textContainer.lineBreakMode = NSLineBreakMode::NSLineBreakByClipping;
    }
  }

  [super updateProps:props oldProps:oldProps];
}

// See RCTParagraphComponentView
- (void)updateState:(const facebook::react::State::Shared &)state oldState:(const facebook::react::State::Shared &)oldState
{
  _state = std::static_pointer_cast<const RNUITextViewShadowNode::ConcreteState>(state);
  [self setNeedsDisplay];
}

// Gesture recognizer delegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
  return YES;
}

// Touch events
- (CGPoint)getLocationOfPress:(UIGestureRecognizer*)sender
{
  return [sender locationInView:_textView];
}

- (void)insertSubview:(UIView *)view atIndex:(NSInteger)index
{
  const auto className = NSStringFromClass([view class]);
  printf("inserting subview: %s", className.UTF8String);
}

- (RNUITextViewChild*)getTouchChild:(CGPoint)location
{
  const auto fullText = _textView.attributedText.string;
  const auto charIndex = [_textView.layoutManager characterIndexForPoint:location
                                                         inTextContainer:_textView.textContainer
                                fractionOfDistanceBetweenInsertionPoints:nil
  ];
  
  int currIndex = -1;
  printf("%d", self.subviews.count);
  for (UIView* child in self.subviews) {
    const auto className = NSStringFromClass([child class]);
    printf("%s", className.UTF8String);
    if (![child isKindOfClass:[RNUITextViewChild class]]) {
      printf("not a child");
      continue;
    }
    
    RNUITextViewChild* textChild = (RNUITextViewChild*)child;
    
    // This is UTF16 code units!!
    currIndex += textChild.text.length;
    
    if (charIndex <= currIndex) {
      return textChild;
    }
  }
  
  return nil;
}

- (void)handlePressIfNecessary:(UITapGestureRecognizer*)sender
{
  const auto location = [self getLocationOfPress:sender];
  const auto child = [self getTouchChild:location];
  
  if (child && child.onPress) {
    child.onPress({});
  }
}

- (void)handleLongPressIfNecessary:(UILongPressGestureRecognizer*)sender
{
  const auto location = [self getLocationOfPress:sender];
  const auto child = [self getTouchChild:location];
  
  if (child && child.onLongPress) {
    child.onLongPress({});
  }
}

Class<RCTComponentViewProtocol> RNUITextViewCls(void)
{
  return RNUITextView.class;
}

@end
#endif
