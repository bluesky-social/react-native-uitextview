#import <XCTest/XCTest.h>
#import <CoreText/CoreText.h>
#import <UIKit/UIKit.h>

#import "../../../ios/RNUITextViewParagraphStyle.h"
#import <react/renderer/textlayoutmanager/RCTAttributedTextUtils.h>
#import <react/renderer/textlayoutmanager/TextLayoutManager.h>

using namespace facebook::react;

namespace {

TextAttributes textAttributes() {
  auto attributes = TextAttributes::defaultTextAttributes();
  attributes.fontSize = 18;
  attributes.lineHeight = 26;
  attributes.allowFontScaling = false;
  attributes.alignment = TextAlignment::Left;
  attributes.baseWritingDirection = WritingDirection::LeftToRight;
  return attributes;
}

void appendText(AttributedString &string, NSString *text,
                TextAttributes attributes = textAttributes()) {
  auto fragment = AttributedString::Fragment{};
  fragment.string = text.UTF8String;
  fragment.textAttributes = attributes;
  string.appendFragment(std::move(fragment));
}

NSAttributedString *convert(const AttributedString &string,
                            const std::vector<RNUITextViewParagraphStyle> &styles) {
  return RCTNSAttributedStringFromAttributedStringBox(
      RNUITextViewAttributedStringBox(string, styles));
}

NSParagraphStyle *paragraphStyle(NSAttributedString *string, NSUInteger index) {
  return [string attribute:NSParagraphStyleAttributeName atIndex:index effectiveRange:nullptr];
}

UITextView *textView(NSAttributedString *string, CGFloat width) {
  UITextView *view;
  if (@available(iOS 16.0, *)) {
    view = [UITextView textViewUsingTextLayoutManager:NO];
  } else {
    view = [UITextView new];
  }
  view.frame = CGRectMake(0, 0, width, 4096);
  view.scrollEnabled = NO;
  view.editable = NO;
  view.selectable = YES;
  view.textContainerInset = UIEdgeInsetsZero;
  view.textContainer.lineFragmentPadding = 0;
  view.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
  view.layoutManager.usesFontLeading = NO;
  view.attributedText = string;
  [view.layoutManager ensureLayoutForTextContainer:view.textContainer];
  return view;
}

CGFloat glyphX(NSLayoutManager *layout, NSUInteger glyph) {
  return [layout lineFragmentRectForGlyphAtIndex:glyph effectiveRange:nullptr].origin.x +
      [layout locationForGlyphAtIndex:glyph].x;
}

// Use the last marker glyph's advance, not its ink bounds (which have side bearings).
CGFloat markerEndX(UITextView *view, NSRange marker) {
  const auto character = NSMaxRange(marker) - 1;
  const auto glyphIndex = [view.layoutManager glyphIndexForCharacterAtIndex:character];
  CGGlyph glyph = [view.layoutManager glyphAtIndex:glyphIndex];
  UIFont *font = [view.attributedText attribute:NSFontAttributeName
                                       atIndex:character effectiveRange:nullptr];
  CTFontRef ctFont = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, nullptr);
  CGSize advance;
  CTFontGetAdvancesForGlyphs(ctFont, kCTFontOrientationHorizontal, &glyph, &advance, 1);
  CFRelease(ctFont);
  return glyphX(view.layoutManager, glyphIndex) + advance.width;
}

} // namespace

@interface ParagraphStyleTests : XCTestCase
@end

@implementation ParagraphStyleTests

- (void)testMarkerAdvancesBodyAndWrappedLinesAtTwoWidths {
  auto string = AttributedString{};
  NSMutableArray<NSValue *> *markers = [NSMutableArray new];
  NSUInteger offset = 0;
  for (NSString *marker in @[@"1.", @"12.", @"•"]) {
    [markers addObject:[NSValue valueWithRange:NSMakeRange(offset + 1, marker.length)]];
    NSString *item = [NSString stringWithFormat:
        @"\t%@\tAn item with enough words to wrap onto several continuation lines at both test widths.\n", marker];
    appendText(string, item);
    offset += item.length;
  }
  auto native = convert(string, {{0, 32, 44}, {1, 32, 44}, {2, 32, 44}});
  const auto tolerance = 1.0 / UIScreen.mainScreen.scale;
  for (NSNumber *width in @[@180, @260]) {
    auto view = textView(native, width.doubleValue);
    for (NSValue *value in markers) {
      const auto marker = value.rangeValue;
      XCTAssertEqualWithAccuracy(markerEndX(view, marker), 32, tolerance);
      const auto bodyGlyph = [view.layoutManager glyphIndexForCharacterAtIndex:NSMaxRange(marker) + 1];
      XCTAssertEqualWithAccuracy(glyphX(view.layoutManager, bodyGlyph), 44, tolerance);
    }
    __block NSUInteger continuations = 0;
    [view.layoutManager enumerateLineFragmentsForGlyphRange:
        [view.layoutManager glyphRangeForTextContainer:view.textContainer]
        usingBlock:^(CGRect rect, CGRect usedRect, NSTextContainer *container,
                     NSRange glyphRange, BOOL *stop) {
      const auto character = [view.layoutManager characterIndexForGlyphAtIndex:glyphRange.location];
      if ([native.string characterAtIndex:character] != '\t') {
        continuations++;
        XCTAssertEqualWithAccuracy(glyphX(view.layoutManager, glyphRange.location), 44, tolerance);
      }
    }];
    XCTAssertGreaterThanOrEqual(continuations, 3u);
  }
}

- (void)testUTF16NestedSpansAttachmentAndParagraphBoundaries {
  auto string = AttributedString{};
  appendText(string, @"😀 introduction\n");
  appendText(string, @"\t•\tEmoji 😀 and ");
  auto bold = textAttributes();
  bold.fontWeight = FontWeight::Bold;
  appendText(string, @"bold", bold);
  auto attachment = AttributedString::Fragment{};
  attachment.string = AttributedString::Fragment::AttachmentCharacter();
  attachment.parentShadowView.layoutMetrics.frame.size = {12, 12};
  string.appendFragment(std::move(attachment));
  appendText(string, @" after attachment\n");
  appendText(string, @"\t12.\tNested item\n");
  appendText(string, @"Plain ending");
  auto baseline = RCTNSAttributedStringFromAttributedString(string);
  auto native = convert(string, {{1, 32, 44}, {2, 32, 44}, {4, 32, 44}, {5, 60, 72}});
  XCTAssertEqualObjects(native.string, baseline.string);
  XCTAssertEqualWithAccuracy(paragraphStyle(native, 0).headIndent, 0, 0.001);
  const auto item = [native.string rangeOfString:@"\t•"].location;
  const auto nested = [native.string rangeOfString:@"\t12."].location;
  for (NSUInteger i = item; i < nested; i++) {
    XCTAssertEqualWithAccuracy(paragraphStyle(native, i).headIndent, 44, 0.001);
  }
  XCTAssertEqualWithAccuracy(paragraphStyle(native, nested).headIndent, 72, 0.001);
  XCTAssertEqualWithAccuracy(paragraphStyle(native, native.length - 1).headIndent, 0, 0.001);
  const auto attachmentIndex = [native.string rangeOfString:@"\uFFFC"].location;
  XCTAssertNotNil([native attribute:NSAttachmentAttributeName atIndex:attachmentIndex effectiveRange:nullptr]);
  const auto boldIndex = [native.string rangeOfString:@"bold"].location;
  XCTAssertEqualObjects([native attribute:NSFontAttributeName atIndex:boldIndex effectiveRange:nullptr],
                        [baseline attribute:NSFontAttributeName atIndex:boldIndex effectiveRange:nullptr]);
  XCTAssertEqual(paragraphStyle(native, item).alignment, NSTextAlignmentLeft);
  XCTAssertEqual(paragraphStyle(native, item).baseWritingDirection, NSWritingDirectionLeftToRight);
  XCTAssertEqualWithAccuracy(paragraphStyle(native, item).minimumLineHeight, 26, 0.001);
}

- (void)testLeadingNewlineOverridesPreviousParagraphAndPreservesOmittedIndent {
  auto string = AttributedString{};
  appendText(string, @"first");
  appendText(string, @"\nsecond\n");
  appendText(string, @"third");
  auto native = convert(string, {{0, 32, 44}, {1, 60, -1}, {2, -1, 0}});
  for (NSUInteger i = 0; i < 6; i++) {
    auto style = paragraphStyle(native, i);
    XCTAssertEqualWithAccuracy(style.headIndent, 44, 0.001);
    XCTAssertEqual(style.tabStops.count, 1u);
    XCTAssertEqualWithAccuracy(style.tabStops.firstObject.location, 60, 0.001);
    XCTAssertEqual(style.tabStops.firstObject.alignment, NSTextAlignmentRight);
  }
  XCTAssertEqualWithAccuracy(paragraphStyle(native, 6).headIndent, 0, 0.001);
  XCTAssertEqualWithAccuracy(paragraphStyle(native, 6).tabStops.firstObject.location, 60, 0.001);
  XCTAssertEqualWithAccuracy(paragraphStyle(native, 13).headIndent, 0, 0.001);
  XCTAssertEqual(paragraphStyle(native, 13).tabStops.firstObject.alignment, NSTextAlignmentLeft);
}

- (void)testParagraphTerminatorsAndSplitCRLF {
  for (NSString *separator in @[@"\n", @"\r", @"\r\n", @"\u2029"]) {
    auto string = AttributedString{};
    appendText(string, [@"first" stringByAppendingString:separator]);
    appendText(string, @"second");
    auto native = convert(string, {{0, 32, 44}, {1, 60, 72}});
    XCTAssertEqualWithAccuracy(paragraphStyle(native, 4).headIndent, 44, 0.001);
    XCTAssertEqualWithAccuracy(paragraphStyle(native, 5).headIndent, 44, 0.001);
    XCTAssertEqualWithAccuracy(paragraphStyle(native, native.length - 1).headIndent, 72, 0.001);
  }
  auto string = AttributedString{};
  appendText(string, @"first\r");
  appendText(string, @"\nsecond");
  auto native = convert(string, {{0, 32, 44}, {1, 60, 72}});
  XCTAssertEqualWithAccuracy(paragraphStyle(native, 0).headIndent, 72, 0.001);
  XCTAssertEqualWithAccuracy(paragraphStyle(native, native.length - 1).headIndent, 72, 0.001);
}

- (void)testTextTransformOffsetsAndRemovingProps {
  auto string = AttributedString{};
  auto uppercase = textAttributes();
  uppercase.textTransform = TextTransform::Uppercase;
  appendText(string, @"straße 😀\n", uppercase);
  appendText(string, @"\t•\tAn item");
  auto native = convert(string, {{1, 32, 44}});
  const auto item = [native.string rangeOfString:@"\t•"].location;
  XCTAssertNotEqual(item, NSNotFound);
  XCTAssertEqualWithAccuracy(paragraphStyle(native, item - 1).headIndent, 0, 0.001);
  XCTAssertEqualWithAccuracy(paragraphStyle(native, item).headIndent, 44, 0.001);
  auto view = textView(native, 180);
  const auto unstyled = RNUITextViewAttributedStringBox(string, {});
  XCTAssertTrue(unstyled.getMode() == AttributedStringBox::Mode::Value);
  view.attributedText = RCTNSAttributedStringFromAttributedStringBox(unstyled);
  XCTAssertEqualObjects(view.attributedText, RCTNSAttributedStringFromAttributedString(string));
  XCTAssertEqualWithAccuracy(paragraphStyle(view.attributedText, item).headIndent, 0, 0.001);
}

- (void)testMeasurementMatchesTextKitHeightAndAttachmentAtTwoWidths {
  auto string = AttributedString{};
  appendText(string, @"\t12.\tA list item with enough words to wrap before an inline ");
  auto attachment = AttributedString::Fragment{};
  attachment.string = AttributedString::Fragment::AttachmentCharacter();
  attachment.parentShadowView.layoutMetrics.frame.size = {16, 12};
  string.appendFragment(std::move(attachment));
  appendText(string, @" attachment and more words on subsequent lines.\n");
  appendText(string, @"\t•\tA nested item with more wrapping words and no final newline.");
  const std::vector<RNUITextViewParagraphStyle> styles = {{0, 32, 44}, {2, 32, 44}, {3, 60, 72}};
  auto manager = TextLayoutManager(std::make_shared<const ContextContainer>());
  const auto scale = UIScreen.mainScreen.scale;
  CGFloat narrowHeight = 0;
  for (NSNumber *width in @[@180, @300]) {
    auto constraints = LayoutConstraints{};
    constraints.maximumSize = {static_cast<Float>(width.doubleValue), 4096};
    auto context = TextLayoutContext{};
    context.pointScaleFactor = scale;
    const auto measurement = manager.measure(
        RNUITextViewAttributedStringBox(string, styles), ParagraphAttributes{}, context, constraints);
    auto view = textView(convert(string, styles), width.doubleValue);
    const auto used = [view.layoutManager usedRectForTextContainer:view.textContainer];
    XCTAssertEqualWithAccuracy(measurement.size.height, used.size.height, 1.0 / scale);
    XCTAssertEqual(measurement.attachments.size(), 1u);
    if (measurement.attachments.size() != 1) {
      continue;
    }
    XCTAssertFalse(measurement.attachments[0].isClipped);
    const auto character = [view.attributedText.string rangeOfString:@"\uFFFC"].location;
    const auto glyph = [view.layoutManager glyphIndexForCharacterAtIndex:character];
    XCTAssertEqualWithAccuracy(measurement.attachments[0].frame.origin.x,
                               glyphX(view.layoutManager, glyph), 1.0 / scale);
    if (narrowHeight == 0) {
      narrowHeight = used.size.height;
    } else {
      XCTAssertGreaterThan(narrowHeight, used.size.height);
    }
  }
}

- (void)testManyInheritedSpansPreserveDistinctParagraphAttributes {
  auto string = AttributedString{};
  std::vector<RNUITextViewParagraphStyle> styles;
  const size_t count = 1024;
  for (size_t i = 0; i < count; i++) {
    auto attributes = textAttributes();
    attributes.lineHeight = i % 2 == 0 ? 24 : 30;
    appendText(string, @"word ", attributes);
    styles.push_back({i, 32, 44});
  }
  auto native = convert(string, styles);
  for (size_t i = 0; i < count; i++) {
    auto style = paragraphStyle(native, i * 5);
    XCTAssertEqualWithAccuracy(style.headIndent, 44, 0.001);
    XCTAssertEqualWithAccuracy(style.minimumLineHeight, i % 2 == 0 ? 24 : 30, 0.001);
    XCTAssertEqual(style.tabStops.count, 2u);
  }
  // Record native timings; a regression baseline can be configured in Xcode.
  [self measureBlock:^{
    @autoreleasepool {
      convert(string, styles);
    }
  }];
}

@end
