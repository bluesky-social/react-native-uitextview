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

#include <cmath>

using namespace facebook::react;

// Matches Pressability's DEFAULT_MIN_PRESS_DURATION. Without this, a quick tap
// can add and remove the highlight layer before Core Animation presents it.
static const CFTimeInterval RNUITextViewMinimumPressHighlightDuration = 0.13;
static const CFTimeInterval RNUITextViewLongPressDelay = 0.5;
static const CGFloat RNUITextViewPressMovementThreshold = 10;

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

@interface RNUITextViewPressGestureRecognizer : UIGestureRecognizer

@property (nonatomic, assign) BOOL hasLongPressHandler;
@property (nonatomic, assign) BOOL exceededLongPressMovement;

@end


@implementation RNUITextViewPressGestureRecognizer {
  CGPoint _initialLocation;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
  if (self.state != UIGestureRecognizerStatePossible || touches.count != 1) {
    self.state = UIGestureRecognizerStateCancelled;
    return;
  }

  _initialLocation = [touches.anyObject locationInView:self.view];
  self.exceededLongPressMovement = NO;
  // Unlike UILongPressGestureRecognizer, transition synchronously from the raw
  // touch instead of waiting for a timer-backed recognition pass.
  self.state = UIGestureRecognizerStateBegan;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
  const auto location = [touches.anyObject locationInView:self.view];
  if (std::hypot(location.x - _initialLocation.x, location.y - _initialLocation.y) >
      RNUITextViewPressMovementThreshold) {
    // Pressability cancels long-press recognition after 10 points of travel,
    // but keeps the ordinary press alive while it remains inside the expanded
    // press-retention rectangle.
    self.exceededLongPressMovement = YES;
  }
  self.state = UIGestureRecognizerStateChanged;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
  self.state = UIGestureRecognizerStateEnded;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
  self.state = UIGestureRecognizerStateCancelled;
}

- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)preventedGestureRecognizer
{
  // When this recognizer is active, the touch began on pressable text. In that
  // case link interaction wins over UITextView's selection recognizers, while
  // ancestor gestures such as a parent scroll view remain simultaneous.
  const auto belongsToTextView =
      preventedGestureRecognizer.view != nil &&
      [preventedGestureRecognizer.view isDescendantOfView:self.view];
  return self.hasLongPressHandler && belongsToTextView;
}

- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer
{
  const auto belongsToTextView =
      preventingGestureRecognizer.view != nil &&
      [preventingGestureRecognizer.view isDescendantOfView:self.view];
  if (belongsToTextView) {
    return !self.hasLongPressHandler;
  }
  return YES;
}

@end

@interface RNUITextView () <RCTRNUITextViewViewProtocol, UIGestureRecognizerDelegate, UITextViewDelegate>

@end

@implementation RNUITextView{
  UIView * _view;
  UITextView * _textView;
  RNUITextViewShadowNode::ConcreteState::Shared _state;
  UITapGestureRecognizer * _outsideTapRecognizer;
  RNUITextViewPressGestureRecognizer * _pressGestureRecognizer;
  CAShapeLayer * _highlightLayer;
  NSString * _activeHighlightGroup;
  NSString * _activePressGroup;
  std::shared_ptr<const RNUITextViewChildEventEmitter> _activePressEventEmitter;
  BOOL _pressIsActive;
  BOOL _pressIsWithinRetention;
  BOOL _longPressIsEligible;
  BOOL _activePressSuppressesHighlighting;
  BOOL _longPressDispatched;
  BOOL _activePressHasPressHandler;
  BOOL _activePressHasLongPressHandler;
  NSUInteger _pressGeneration;
  CFTimeInterval _pressActivationTime;
  CGRect _activePressRect;
  UIEdgeInsets _activePressRetentionOffset;
  CFTimeInterval _highlightActivationTime;
  NSUInteger _highlightGeneration;
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
    // Match React Native's Paragraph component and allow transformed inline
    // attachments to paint outside the measured text bounds. Explicit
    // `overflow: hidden` styles are still handled by RCTViewComponentView.

    if (@available(iOS 16.0, *)) {
      // This component relies on NSLayoutManager for measurement, hit-testing,
      // and press-highlight geometry. Opt into TextKit 1 up front instead of
      // making UITextView create TextKit 2 and fall back on first access.
      _textView = [UITextView textViewUsingTextLayoutManager:NO];
    } else {
      _textView = [[UITextView alloc] init];
    }
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

    _pressGestureRecognizer = [[RNUITextViewPressGestureRecognizer alloc] initWithTarget:self
                                                                                  action:@selector(handlePressGesture:)];
    _pressGestureRecognizer.cancelsTouchesInView = NO;
    _pressGestureRecognizer.delegate = self;
    [_textView addGestureRecognizer:_pressGestureRecognizer];

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
    [self invalidateActivePress];
    [self clearPressHighlight];
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
  [self invalidateActivePress];
  [self clearPressHighlight];
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

  if (_activeHighlightGroup != nil) {
    [self updatePressHighlight];
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

  if (oldViewProps.selectionColor != newViewProps.selectionColor) {
    _textView.tintColor = RCTUIColorFromSharedColor(newViewProps.selectionColor);
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
  if (gestureRecognizer == _pressGestureRecognizer || otherGestureRecognizer == _pressGestureRecognizer) {
    const auto companion = gestureRecognizer == _pressGestureRecognizer
        ? otherGestureRecognizer
        : gestureRecognizer;
    const auto belongsToTextView =
        companion.view != nil && [companion.view isDescendantOfView:_textView];
    // Press-only spans coexist with UITextView's recognizers; an actual
    // selection invalidates the press in textViewDidChangeSelection:. Links
    // with onLongPress own the hold, while ancestor scrolling can cancel both.
    return belongsToTextView && !_pressGestureRecognizer.hasLongPressHandler;
  }
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
  if (gestureRecognizer == _pressGestureRecognizer) {
    const auto location = [touch locationInView:_textView];
    const auto eventEmitter = [self getTouchEventEmitter:location];
    BOOL hasLongPressHandler = NO;
    const auto group = [self highlightGroupForEventEmitter:eventEmitter
                                       suppressHighlighting:nullptr
                                            hasPressHandler:nullptr
                                        hasLongPressHandler:&hasLongPressHandler
                                       pressRetentionOffset:nullptr];
    _pressGestureRecognizer.hasLongPressHandler = hasLongPressHandler;
    // The recognizer enters `Began` synchronously. For a span that owns a
    // long press, cancel delivery of that same touch to UITextView so its
    // selection interaction cannot start in parallel. Keep this disabled for
    // press-only spans: a hold on those should still be available to native
    // text selection.
    _pressGestureRecognizer.cancelsTouchesInView = hasLongPressHandler;
    return group != nil;
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

- (NSString *)highlightGroupForEventEmitter:(std::shared_ptr<const RNUITextViewChildEventEmitter>)eventEmitter
                       suppressHighlighting:(BOOL *)suppressHighlighting
                            hasPressHandler:(BOOL *)hasPressHandler
                        hasLongPressHandler:(BOOL *)hasLongPressHandler
                       pressRetentionOffset:(UIEdgeInsets *)pressRetentionOffset
{
  if (!_state || !eventEmitter) {
    return nil;
  }

  const auto eventTarget = eventEmitter->getEventTarget();
  if (!eventTarget) {
    return nil;
  }

  const auto tag = eventTarget->getTag();
  for (const auto &metadata : _state->getData().highlightMetadata) {
    if (metadata.tag == tag) {
      const auto separator = metadata.group.rfind('|');
      const auto handlers = separator == std::string::npos
          ? std::string{}
          : metadata.group.substr(separator + 1);
      if (suppressHighlighting != nullptr) {
        *suppressHighlighting = metadata.suppressHighlighting;
      }
      if (hasPressHandler != nullptr) {
        *hasPressHandler = handlers.find('p') != std::string::npos;
      }
      if (hasLongPressHandler != nullptr) {
        *hasLongPressHandler = handlers.find('l') != std::string::npos;
      }
      if (pressRetentionOffset != nullptr) {
        *pressRetentionOffset = UIEdgeInsetsMake(
            metadata.pressRetentionOffsetTop,
            metadata.pressRetentionOffsetLeft,
            metadata.pressRetentionOffsetBottom,
            metadata.pressRetentionOffsetRight);
      }
      return [NSString stringWithUTF8String:metadata.group.c_str()];
    }
  }

  return nil;
}

- (CGRect)textRectForHighlightGroup:(NSString *)highlightGroup
{
  __block CGRect textRect = CGRectNull;
  const auto fullRange = NSMakeRange(0, _textView.attributedText.length);
  [_textView.attributedText enumerateAttribute:RCTAttributedStringEventEmitterKey
                                       inRange:fullRange
                                       options:0
                                    usingBlock:^(NSData *eventEmitterWrapper, NSRange characterRange, BOOL *stop) {
    if (eventEmitterWrapper == nil) {
      return;
    }

    const auto eventEmitter = std::dynamic_pointer_cast<const RNUITextViewChildEventEmitter>(
        RCTUnwrapEventEmitter(eventEmitterWrapper));
    const auto group = [self highlightGroupForEventEmitter:eventEmitter
                                      suppressHighlighting:nullptr
                                           hasPressHandler:nullptr
                                       hasLongPressHandler:nullptr
                                      pressRetentionOffset:nullptr];
    if (![group isEqualToString:highlightGroup]) {
      return;
    }

    const auto glyphRange = [self->_textView.layoutManager glyphRangeForCharacterRange:characterRange
                                                                  actualCharacterRange:nullptr];
    [self->_textView.layoutManager enumerateEnclosingRectsForGlyphRange:glyphRange
                                                withinSelectedGlyphRange:glyphRange
                                                         inTextContainer:self->_textView.textContainer
                                                              usingBlock:^(CGRect enclosingRect, BOOL *anotherStop) {
      const auto inset = self->_textView.textContainerInset;
      const auto rect = CGRectOffset(enclosingRect, inset.left, inset.top);
      textRect = CGRectIsNull(textRect) ? rect : CGRectUnion(textRect, rect);
    }];
  }];
  return textRect;
}

- (BOOL)isLocationWithinActivePressRect:(CGPoint)location
{
  if (CGRectIsNull(_activePressRect)) {
    return NO;
  }

  const auto offset = _activePressRetentionOffset;
  const auto retainedRect = CGRectMake(
      CGRectGetMinX(_activePressRect) - offset.left,
      CGRectGetMinY(_activePressRect) - offset.top,
      CGRectGetWidth(_activePressRect) + offset.left + offset.right,
      CGRectGetHeight(_activePressRect) + offset.top + offset.bottom);
  return CGRectContainsPoint(retainedRect, location);
}

- (void)clearPressHighlight
{
  _highlightGeneration++;
  _activeHighlightGroup = nil;
  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  [_highlightLayer removeFromSuperlayer];
  [CATransaction commit];
  _highlightLayer = nil;
}

- (void)activatePressHighlight
{
  _highlightGeneration++;
  _activeHighlightGroup = _activePressGroup;
  _highlightActivationTime = CACurrentMediaTime();
  [self updatePressHighlight];
}

- (void)invalidateActivePress
{
  _pressGeneration++;
  _pressIsActive = NO;
  _pressIsWithinRetention = NO;
  _longPressIsEligible = NO;
  _activePressSuppressesHighlighting = NO;
  _longPressDispatched = NO;
  _activePressHasPressHandler = NO;
  _activePressHasLongPressHandler = NO;
  _activePressRect = CGRectNull;
  _activePressGroup = nil;
  _activePressEventEmitter.reset();
}

- (void)emitPressEvent:(BOOL)isLongPress
           eventEmitter:(std::shared_ptr<const RNUITextViewChildEventEmitter>)eventEmitter
{
  if (!eventEmitter) {
    return;
  }

  const auto eventTarget = eventEmitter->getEventTarget();
  const auto target = eventTarget ? eventTarget->getTag() : 0;
  if (isLongPress) {
    eventEmitter->onLongPress(RNUITextViewChildEventEmitter::OnLongPress{target});
  } else {
    eventEmitter->onPress(RNUITextViewChildEventEmitter::OnPress{target});
  }
}

- (void)emitLongPressIfNecessary
{
  if (!_pressIsActive || !_pressIsWithinRetention || !_longPressIsEligible ||
      _longPressDispatched || !_activePressHasLongPressHandler) {
    return;
  }

  // Set this before emitting so a synchronous update cannot make release fall
  // through to onPress while the long-press event is being dispatched.
  _longPressDispatched = YES;
  [self emitPressEvent:YES eventEmitter:_activePressEventEmitter];
}

- (void)clearPressHighlightAfterMinimumDuration
{
  if (_activeHighlightGroup == nil) {
    return;
  }

  const auto elapsed = CACurrentMediaTime() - _highlightActivationTime;
  const auto remaining = RNUITextViewMinimumPressHighlightDuration - elapsed;
  if (remaining <= 0) {
    [self clearPressHighlight];
    return;
  }

  const auto generation = ++_highlightGeneration;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(remaining * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
    if (self->_highlightGeneration == generation) {
      [self clearPressHighlight];
    }
  });
}

- (void)updatePressHighlight
{
  if (_activeHighlightGroup == nil || _textView.attributedText.length == 0) {
    [self clearPressHighlight];
    return;
  }

  __block UIBezierPath *highlightPath = nil;
  const auto fullRange = NSMakeRange(0, _textView.attributedText.length);
  [_textView.attributedText enumerateAttribute:RCTAttributedStringEventEmitterKey
                                       inRange:fullRange
                                       options:0
                                    usingBlock:^(NSData *eventEmitterWrapper, NSRange characterRange, BOOL *stop) {
    if (eventEmitterWrapper == nil) {
      return;
    }

    const auto eventEmitter = std::dynamic_pointer_cast<const RNUITextViewChildEventEmitter>(
        RCTUnwrapEventEmitter(eventEmitterWrapper));
    const auto group = [self highlightGroupForEventEmitter:eventEmitter
                                      suppressHighlighting:nullptr
                                           hasPressHandler:nullptr
                                       hasLongPressHandler:nullptr
                                      pressRetentionOffset:nullptr];
    if (![group isEqualToString:self->_activeHighlightGroup]) {
      return;
    }

    const auto glyphRange = [self->_textView.layoutManager glyphRangeForCharacterRange:characterRange
                                                                  actualCharacterRange:nullptr];
    [self->_textView.layoutManager enumerateEnclosingRectsForGlyphRange:glyphRange
                                                withinSelectedGlyphRange:glyphRange
                                                         inTextContainer:self->_textView.textContainer
                                                              usingBlock:^(CGRect enclosingRect, BOOL *anotherStop) {
      const auto inset = self->_textView.textContainerInset;
      const auto textViewRect = CGRectOffset(enclosingRect, inset.left, inset.top);
      const auto path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(textViewRect, -2, -2)
                                                   cornerRadius:2];
      if (highlightPath != nil) {
        [highlightPath appendPath:path];
      } else {
        highlightPath = path;
      }
    }];
  }];

  if (highlightPath == nil) {
    [self clearPressHighlight];
    return;
  }

  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  if (_highlightLayer == nil) {
    _highlightLayer = [CAShapeLayer layer];
    _highlightLayer.fillColor = [UIColor colorWithWhite:0 alpha:0.25].CGColor;
    [_textView.layer addSublayer:_highlightLayer];
  }
  _highlightLayer.frame = _textView.bounds;
  _highlightLayer.path = highlightPath.CGPath;
  [CATransaction commit];
}

- (void)handlePressGesture:(RNUITextViewPressGestureRecognizer *)sender
{
  if (sender.state == UIGestureRecognizerStateBegan) {
    [self invalidateActivePress];
    [self clearPressHighlight];

    const auto location = [self getLocationOfPress:sender];
    const auto eventEmitter = [self getTouchEventEmitter:location];
    BOOL suppressHighlighting = NO;
    BOOL hasPressHandler = NO;
    UIEdgeInsets pressRetentionOffset = UIEdgeInsetsZero;
    const auto group = [self highlightGroupForEventEmitter:eventEmitter
                                      suppressHighlighting:&suppressHighlighting
                                           hasPressHandler:&hasPressHandler
                                       hasLongPressHandler:nullptr
                                      pressRetentionOffset:&pressRetentionOffset];
    if (group == nil) {
      return;
    }

    _pressIsActive = YES;
    _pressIsWithinRetention = YES;
    _activePressGroup = group;
    _activePressEventEmitter = eventEmitter;
    _activePressHasPressHandler = hasPressHandler;
    _activePressHasLongPressHandler = sender.hasLongPressHandler;
    _longPressIsEligible = _activePressHasLongPressHandler;
    _activePressSuppressesHighlighting = suppressHighlighting;
    _activePressRect = [self textRectForHighlightGroup:group];
    _activePressRetentionOffset = pressRetentionOffset;
    _pressActivationTime = CACurrentMediaTime();

    if (!_activePressSuppressesHighlighting) {
      [self activatePressHighlight];
    }

    if (_activePressHasLongPressHandler) {
      const auto generation = _pressGeneration;
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(RNUITextViewLongPressDelay * NSEC_PER_SEC)),
                     dispatch_get_main_queue(), ^{
        if (self->_pressGeneration == generation) {
          [self emitLongPressIfNecessary];
        }
      });
    }
    return;
  }

  if (sender.state == UIGestureRecognizerStateChanged && _pressIsActive) {
    const auto location = [self getLocationOfPress:sender];
    const auto isWithinRetention = [self isLocationWithinActivePressRect:location];
    if (sender.exceededLongPressMovement || !isWithinRetention) {
      _longPressIsEligible = NO;
    }
    if (_pressIsWithinRetention && !isWithinRetention) {
      _pressIsWithinRetention = NO;
      [self clearPressHighlightAfterMinimumDuration];
    } else if (!_pressIsWithinRetention && isWithinRetention) {
      _pressIsWithinRetention = YES;
      if (!_activePressSuppressesHighlighting) {
        [self activatePressHighlight];
      }
    }
    return;
  }

  if (sender.state == UIGestureRecognizerStateEnded) {
    _pressIsWithinRetention =
        _pressIsActive && [self isLocationWithinActivePressRect:[self getLocationOfPress:sender]];
    if (_pressIsActive && _pressIsWithinRetention && !_longPressDispatched &&
        _longPressIsEligible && _activePressHasLongPressHandler &&
        CACurrentMediaTime() - _pressActivationTime >= RNUITextViewLongPressDelay) {
      // The finger can lift after the threshold but before the main-queue timer
      // gets serviced. Treat elapsed time as authoritative in that race.
      [self emitLongPressIfNecessary];
    }
    if (_pressIsActive && _pressIsWithinRetention && !_longPressDispatched &&
        _activePressHasPressHandler) {
      [self emitPressEvent:NO eventEmitter:_activePressEventEmitter];
    }
    [self invalidateActivePress];
    [self clearPressHighlightAfterMinimumDuration];
    return;
  }

  if (sender.state == UIGestureRecognizerStateCancelled ||
      sender.state == UIGestureRecognizerStateFailed) {
    [self invalidateActivePress];
    [self clearPressHighlightAfterMinimumDuration];
  }
}

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

// MARK: - UITextViewDelegate

- (void)textViewDidChangeSelection:(UITextView *)textView
{
  if (_suppressSelectionChange) {
    return;
  }

  const NSRange selectedRange = textView.selectedRange;
  if (_pressIsActive && selectedRange.location != NSNotFound && selectedRange.length > 0) {
    if (_activePressHasLongPressHandler) {
      // A link with onLongPress owns the hold. Undo any selection started by
      // UITextView without cancelling the link's pending long-press timer.
      _suppressSelectionChange = YES;
      textView.selectedTextRange = nil;
      _suppressSelectionChange = NO;
      return;
    }

    // Without onLongPress, native selection owns the hold and the pending tap
    // must not fire when the finger eventually lifts.
    [self invalidateActivePress];
    [self clearPressHighlightAfterMinimumDuration];
  }
  if (_eventEmitter == nullptr) {
    return;
  }

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
