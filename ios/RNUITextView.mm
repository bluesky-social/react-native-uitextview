#import "RNUITextView.h"
#import "RNUITextViewShadowNode.h"
#import "RNUITextViewComponentDescriptor.h"
#import "RNUITextViewChild.h"
#import <React/RCTConversions.h>

#import <react/renderer/textlayoutmanager/RCTAttributedTextUtils.h>
#import <react/renderer/components/RNUITextViewSpec/EventEmitters.h>
#import <react/renderer/components/RNUITextViewSpec/Props.h>
#import <react/renderer/components/RNUITextViewSpec/RCTComponentViewHelpers.h>
#import "RCTFabricComponentsPlugins.h"

using namespace facebook::react;

static NSLineBreakMode RCTNSLineBreakModeFromEllipsizeMode(RNUITextViewEllipsizeMode ellipsizeMode)
{
  switch (ellipsizeMode) {
    case RNUITextViewEllipsizeMode::Clip:
      return NSLineBreakByClipping;
    case RNUITextViewEllipsizeMode::Head:
      return NSLineBreakByTruncatingHead;
    case RNUITextViewEllipsizeMode::Tail:
      return NSLineBreakByTruncatingTail;
    case RNUITextViewEllipsizeMode::Middle:
      return NSLineBreakByTruncatingMiddle;
  }
}

@interface RNUITextView () <RCTRNUITextViewViewProtocol, UIGestureRecognizerDelegate, UITextViewDelegate>

@end

@implementation RNUITextView{
  UIView * _view;
  UITextView * _textView;
  RNUITextViewShadowNode::ConcreteState::Shared _state;
  UITapGestureRecognizer * _outsideTapRecognizer;
  BOOL _suppressSelectionChange;
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
    _textView.selectable = false;
    _textView.textContainerInset = UIEdgeInsetsZero;
    _textView.textContainer.lineFragmentPadding = 0;
    // Keep UIKit's initial state in sync with the Codegen prop default. Since
    // both oldProps and newProps default to `tail`, updateProps will not apply
    // this value on the first render.
    _textView.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
    _textView.delegate = self;
    // Must match RCTTextLayoutManager, which measures with usesFontLeading = NO.
    _textView.layoutManager.usesFontLeading = NO;
    [self addSubview:_textView];

    const auto longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                          action:@selector(handleLongPressIfNecessary:)];
    longPressGestureRecognizer.delegate = self;

    const auto pressGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                action:@selector(handlePressIfNecessary:)];
    pressGestureRecognizer.delegate = self;
    [pressGestureRecognizer requireGestureRecognizerToFail:longPressGestureRecognizer];

    [_textView addGestureRecognizer:pressGestureRecognizer];
    [_textView addGestureRecognizer:longPressGestureRecognizer];

    _outsideTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                    action:@selector(handleOutsideTap:)];
    _outsideTapRecognizer.cancelsTouchesInView = NO;
    _outsideTapRecognizer.delegate = self;
  }

  return self;
}

- (void)didMoveToWindow
{
  [super didMoveToWindow];
  if (self.window) {
    [self.window addGestureRecognizer:_outsideTapRecognizer];
  } else {
    [_outsideTapRecognizer.view removeGestureRecognizer:_outsideTapRecognizer];
  }
}

- (void)dealloc
{
  [_outsideTapRecognizer.view removeGestureRecognizer:_outsideTapRecognizer];
}

// See RCTParagraphComponentView
- (void)prepareForRecycle
{
  [super prepareForRecycle];
  _state.reset();

  // Reset the frame to zero so that when it properly lays out on the next use
  _textView.frame = CGRectZero;
  _textView.attributedText = nil;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  // _textView's frame is assigned inside drawRect, which only fires when
  // state changes. Trigger a redraw whenever the host frame moves out from
  // under it (rotation, parent relayout) so the text view resizes and
  // onTextLayout re-fires with the new line wrapping.
  if (!CGRectEqualToRect(_textView.frame, _view.frame)) {
    [self setNeedsDisplay];
  }
}

- (void)drawRect:(CGRect)rect
{
  if (!_state) {
    return;
  }

  const auto &props = *std::static_pointer_cast<RNUITextViewProps const>(_props);

  const auto attrString = _state->getData().attributedString;
  const auto convertedAttrString = RCTNSAttributedStringFromAttributedString(attrString);

  // Setting attributedText clears any active text selection, and re-assigning
  // the frame triggers a layout flush that has the same effect. Bail out
  // entirely when nothing actually changed so a JS-side state update made in
  // response to onSelectionChange doesn't deselect what the user is selecting.
  const BOOL textChanged = ![_textView.attributedText isEqualToAttributedString:convertedAttrString];
  const BOOL frameChanged = !CGRectEqualToRect(_textView.frame, _view.frame);
  if (!textChanged && !frameChanged) {
    return;
  }
  if (textChanged) {
    // Reassigning attributedText clears any active selection. Save it and
    // restore after, while suppressing the synthetic textViewDidChangeSelection
    // events the clear-then-restore would otherwise produce — those would
    // round-trip to JS and re-trigger this same path, causing a loop.
    const NSRange savedRange = _textView.selectedRange;
    _suppressSelectionChange = YES;
    _textView.attributedText = convertedAttrString;
    if (savedRange.length > 0 && NSMaxRange(savedRange) <= _textView.attributedText.length) {
      _textView.selectedRange = savedRange;
    }
    _suppressSelectionChange = NO;
  }
  if (frameChanged) {
    _textView.frame = _view.frame;
  }

  __block std::vector<std::string> lines;
  const int maxLines = props.numberOfLines;
  [_textView.layoutManager enumerateLineFragmentsForGlyphRange:NSMakeRange(0, _textView.layoutManager.numberOfGlyphs) usingBlock:^(CGRect rect,
                                                                                              CGRect usedRect,
                                                                                              NSTextContainer * _Nonnull textContainer,
                                                                                              NSRange glyphRange,
                                                                                              BOOL * _Nonnull stop) {
    const auto charRange = [self->_textView.layoutManager characterRangeForGlyphRange:glyphRange actualGlyphRange:nil];
    const auto line = [self->_textView.text substringWithRange:charRange];
    lines.push_back(line.UTF8String);
    // enumerateLineFragments overshoots maximumNumberOfLines by one on iOS
    // 18, so cap explicitly.
    if (maxLines > 0 && lines.size() >= (size_t)maxLines) {
      *stop = YES;
    }
  }];

  if (_eventEmitter != nullptr) {
    std::dynamic_pointer_cast<const facebook::react::RNUITextViewEventEmitter>(_eventEmitter)
    ->onTextLayout(facebook::react::RNUITextViewEventEmitter::OnTextLayout{static_cast<int>(self.tag), lines});
  };
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

  if (oldViewProps.allowFontScaling != newViewProps.allowFontScaling) {
    if (@available(iOS 11.0, *)) {
      _textView.adjustsFontForContentSizeCategory = newViewProps.allowFontScaling;
    }
  }

  if (oldViewProps.ellipsizeMode != newViewProps.ellipsizeMode) {
    _textView.textContainer.lineBreakMode =
        RCTNSLineBreakModeFromEllipsizeMode(newViewProps.ellipsizeMode);
  }
  

  // I'm not sure if this is really the right way to handle this style. This means that the entire _view_ the text
  // is in will have this background color applied. To apply it just to a particular part of a string, you'd need
  // to do <Text><Text style={{backgroundColor: 'blue'}}>Hello</Text></Text>.
  // This is how the base <Text> component works though, so we'll go with it for now. Can change later if we want.
  if (oldViewProps.backgroundColor != newViewProps.backgroundColor) {
    _textView.backgroundColor = RCTUIColorFromSharedColor(newViewProps.backgroundColor);
  }

  [super updateProps:props oldProps:oldProps];
}

// See RCTParagraphComponentView
- (void)updateState:(const facebook::react::State::Shared &)state oldState:(const facebook::react::State::Shared &)oldState
{
  _state = std::static_pointer_cast<const RNUITextViewShadowNode::ConcreteState>(state);
  [self setNeedsDisplay];
}

// MARK: - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
  return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
  if (gestureRecognizer == _outsideTapRecognizer) {
    UIWindow *window = touch.window;
    if (!window) {
      return NO;
    }
    UIView *hitView = [window hitTest:[touch locationInView:nil] withEvent:nil];
    return ![hitView isDescendantOfView:self];
  }
  return YES;
}

- (void)handleOutsideTap:(UITapGestureRecognizer *)sender
{
  // Defer past the current event loop turn so any in-flight edit-menu action
  // (Copy / Define / Look Up / …) reads the live selection before we clear it.
  UITextView *textView = _textView;
  dispatch_async(dispatch_get_main_queue(), ^{
    UITextRange *range = textView.selectedTextRange;
    if (range != nil && !range.isEmpty) {
      textView.selectedTextRange = nil;
    }
  });
}

// MARK: - Touch handling

- (CGPoint)getLocationOfPress:(UIGestureRecognizer*)sender
{
  return [sender locationInView:_textView];
}

- (std::shared_ptr<const RNUITextViewChildEventEmitter>)getTouchEventEmitter:(CGPoint)location
{
  CGFloat fraction;
  const auto characterIndex = [_textView.layoutManager characterIndexForPoint:location
                                                               inTextContainer:_textView.textContainer
                                      fractionOfDistanceBetweenInsertionPoints:&fraction];

  const auto textLength = _textView.attributedText.length;
  if (textLength == 0 || characterIndex == NSNotFound || characterIndex >= textLength) {
    return nullptr;
  }

  const auto lastCharacterRange =
      [_textView.attributedText.string rangeOfComposedCharacterSequenceAtIndex:textLength - 1];
  if ((characterIndex == 0 && fraction <= 0) ||
      (characterIndex >= lastCharacterRange.location && fraction >= 1)) {
    return nullptr;
  }

  const auto glyphIndex = [_textView.layoutManager glyphIndexForCharacterAtIndex:characterIndex];
  const auto lineUsedRect = [_textView.layoutManager lineFragmentUsedRectForGlyphAtIndex:glyphIndex
                                                                           effectiveRange:nullptr];
  const auto textContainerLocation = CGPointMake(
      location.x - _textView.textContainerInset.left,
      location.y - _textView.textContainerInset.top);
  if (!CGRectContainsPoint(lineUsedRect, textContainerLocation)) {
    return nullptr;
  }

  NSData *eventEmitterWrapper =
      (NSData *)[_textView.attributedText attribute:RCTAttributedStringEventEmitterKey
                                           atIndex:characterIndex
                                    effectiveRange:nullptr];
  const auto eventEmitter = RCTUnwrapEventEmitter(eventEmitterWrapper);
  return std::dynamic_pointer_cast<const RNUITextViewChildEventEmitter>(eventEmitter);
}

- (void)handlePressIfNecessary:(UITapGestureRecognizer*)sender
{
  const auto location = [self getLocationOfPress:sender];
  const auto eventEmitter = [self getTouchEventEmitter:location];

  if (eventEmitter) {
    const auto eventTarget = eventEmitter->getEventTarget();
    const auto target = eventTarget ? eventTarget->getTag() : 0;
    eventEmitter->onPress(RNUITextViewChildEventEmitter::OnPress{target});
  }
}

- (void)handleLongPressIfNecessary:(UILongPressGestureRecognizer*)sender
{
  if (sender.state != UIGestureRecognizerStateBegan) {
    return;
  }

  const auto location = [self getLocationOfPress:sender];
  const auto eventEmitter = [self getTouchEventEmitter:location];

  if (eventEmitter) {
    const auto eventTarget = eventEmitter->getEventTarget();
    const auto target = eventTarget ? eventTarget->getTag() : 0;
    eventEmitter->onLongPress(RNUITextViewChildEventEmitter::OnLongPress{target});
  }
}

// MARK: - UITextViewDelegate

- (void)textViewDidChangeSelection:(UITextView *)textView
{
  if (_suppressSelectionChange) {
    return;
  }
  if (_eventEmitter == nullptr) {
    return;
  }

  const NSRange selectedRange = textView.selectedRange;
  if (selectedRange.location == NSNotFound) {
    return;
  }

  // Fires on programmatic selection changes too (e.g. the outside-tap clear
  // in handleOutsideTap:), so JS will see a synthetic empty-range event then.
  std::dynamic_pointer_cast<const facebook::react::RNUITextViewEventEmitter>(_eventEmitter)
    ->onSelectionChange(facebook::react::RNUITextViewEventEmitter::OnSelectionChange{
      static_cast<int>(self.tag),
      static_cast<int>(selectedRange.location),
      static_cast<int>(selectedRange.location + selectedRange.length),
    });
}

Class<RCTComponentViewProtocol> RNUITextViewCls(void)
{
  return RNUITextView.class;
}

@end
