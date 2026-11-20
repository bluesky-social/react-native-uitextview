#import "RNUITextViewParagraphStyle.h"

#import <react/renderer/textlayoutmanager/RCTAttributedTextUtils.h>

#include <cmath>

namespace facebook::react {

AttributedStringBox RNUITextViewAttributedStringBox(
    const AttributedString &attributedString,
    const std::vector<RNUITextViewParagraphStyle> &paragraphStyles) {
  if (paragraphStyles.empty()) {
    return AttributedStringBox{attributedString};
  }

  NSMutableAttributedString *nativeString =
      [RCTNSAttributedStringFromAttributedString(attributedString) mutableCopy];
  const auto &fragments = attributedString.getFragments();
  struct StyledRange {
    NSRange range;
    const RNUITextViewParagraphStyle *style;
  };
  std::vector<StyledRange> styledRanges;
  styledRanges.reserve(paragraphStyles.size());
  NSUInteger offset = 0;
  size_t styleIndex = 0;

  for (size_t i = 0; i < fragments.size(); i++) {
    // NSRange uses UTF-16 offsets, while fragment.string contains UTF-8.
    const auto &fragment = fragments[i];
    NSString *text = [NSString stringWithUTF8String:fragment.string.c_str()];
    if (fragment.textAttributes.textTransform.has_value() && !fragment.isAttachment()) {
      text = RCTNSStringFromStringApplyingTextTransform(
          text, fragment.textAttributes.textTransform.value());
    }
    const auto range = NSMakeRange(offset, text.length);
    offset += text.length;

    if (styleIndex >= paragraphStyles.size() ||
        paragraphStyles[styleIndex].fragmentIndex != i) {
      continue;
    }
    const auto &style = paragraphStyles[styleIndex++];
    if (range.length == 0) {
      continue;
    }
    styledRanges.push_back({range, &style});
  }

  // If React Native changes its conversion, mapped UTF-16 ranges may drift.
  // Keep its unmodified attributed string rather than style incorrect ranges.
  if (offset != nativeString.length) {
    return RCTAttributedStringBoxFromNSAttributedString(nativeString);
  }

  // Fragment ranges are ordered and disjoint. Walk paragraph boundaries once,
  // then sweep their intersections with those ranges. This bounds the work by
  // the text, fragment and native style-run counts, even when many rich spans
  // inherit the same paragraph settings.
  NSString *text = nativeString.string;
  NSUInteger paragraphStart = 0;
  size_t firstStyle = 0;
  while (paragraphStart < text.length && firstStyle < styledRanges.size()) {
    NSUInteger paragraphEnd;
    [text getParagraphStart:nullptr end:&paragraphEnd contentsEnd:nullptr
                  forRange:NSMakeRange(paragraphStart, 0)];

    const RNUITextViewParagraphStyle *tabStyle = nullptr;
    Float headIndent = -1;
    for (size_t i = firstStyle;
         i < styledRanges.size() && styledRanges[i].range.location < paragraphEnd;
         i++) {
      const auto &style = *styledRanges[i].style;
      // Preserve fragment-order precedence: every style replaces the tabs,
      // but only an explicitly valid hanging indent replaces headIndent.
      // (markerEnd, hangingIndent) (32, 44) then (60, -1) leaves tab 60 and headIndent 44.
      tabStyle = &style;
      if (std::isfinite(style.hangingIndent) && style.hangingIndent >= 0) {
        headIndent = style.hangingIndent;
      }
    }
    while (firstStyle < styledRanges.size() &&
           NSMaxRange(styledRanges[firstStyle].range) <= paragraphEnd) {
      firstStyle++;
    }
    const auto paragraphRange = NSMakeRange(paragraphStart, paragraphEnd - paragraphStart);
    paragraphStart = paragraphEnd;
    if (tabStyle == nullptr) {
      continue;
    }

    NSMutableArray<NSTextTab *> *tabs = [NSMutableArray new];
    const bool hasMarkerEnd = std::isfinite(tabStyle->markerEnd) && tabStyle->markerEnd >= 0;
    const bool hasHangingIndent = std::isfinite(tabStyle->hangingIndent) && tabStyle->hangingIndent >= 0;
    if (hasMarkerEnd) {
      [tabs addObject:[[NSTextTab alloc] initWithTextAlignment:NSTextAlignmentRight
                                                    location:tabStyle->markerEnd
                                                     options:@{}]];
    }
    if (hasHangingIndent) {
      [tabs addObject:[[NSTextTab alloc] initWithTextAlignment:NSTextAlignmentLeft
                                                    location:tabStyle->hangingIndent
                                                     options:@{}]];
    }
    [tabs sortUsingComparator:^NSComparisonResult(NSTextTab *left, NSTextTab *right) {
      if (left.location < right.location) return NSOrderedAscending;
      if (left.location > right.location) return NSOrderedDescending;
      return NSOrderedSame;
    }];

    // Expand to whole paragraphs so nested spans and inline attachments share
    // the indent. A terminating newline belongs to the preceding paragraph.
    [nativeString enumerateAttribute:NSParagraphStyleAttributeName
                             inRange:paragraphRange
                             options:0
                          usingBlock:^(NSParagraphStyle *existingStyle, NSRange runRange, BOOL *stop) {
      NSMutableParagraphStyle *paragraphStyle =
          existingStyle ? [existingStyle mutableCopy] : [NSMutableParagraphStyle new];
      paragraphStyle.tabStops = tabs;
      if (headIndent >= 0) {
        paragraphStyle.headIndent = headIndent;
      }
      // Preserve React Native's alignment, line height and writing direction.
      [nativeString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:runRange];
    }];
  }

  return RCTAttributedStringBoxFromNSAttributedString(nativeString);
}

} // namespace facebook::react
