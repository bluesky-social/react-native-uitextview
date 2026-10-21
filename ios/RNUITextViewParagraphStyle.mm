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

    NSMutableArray<NSTextTab *> *tabs = [NSMutableArray new];
    const bool hasMarkerEnd = std::isfinite(style.markerEnd) && style.markerEnd >= 0;
    const bool hasHangingIndent = std::isfinite(style.hangingIndent) && style.hangingIndent >= 0;
    if (hasMarkerEnd) {
      [tabs addObject:[[NSTextTab alloc] initWithTextAlignment:NSTextAlignmentRight
                                                    location:style.markerEnd
                                                     options:@{}]];
    }
    if (hasHangingIndent) {
      [tabs addObject:[[NSTextTab alloc] initWithTextAlignment:NSTextAlignmentLeft
                                                    location:style.hangingIndent
                                                     options:@{}]];
    }
    [tabs sortUsingComparator:^NSComparisonResult(NSTextTab *left, NSTextTab *right) {
      if (left.location < right.location) return NSOrderedAscending;
      if (left.location > right.location) return NSOrderedDescending;
      return NSOrderedSame;
    }];

    // Expand to whole paragraphs so nested spans and inline attachments share
    // the indent. A terminating newline belongs to the preceding paragraph.
    const auto paragraphRange = [nativeString.string paragraphRangeForRange:range];
    [nativeString enumerateAttribute:NSParagraphStyleAttributeName
                             inRange:paragraphRange
                             options:0
                          usingBlock:^(NSParagraphStyle *existingStyle, NSRange runRange, BOOL *stop) {
      NSMutableParagraphStyle *paragraphStyle =
          existingStyle ? [existingStyle mutableCopy] : [NSMutableParagraphStyle new];
      paragraphStyle.tabStops = tabs;
      if (hasHangingIndent) {
        paragraphStyle.headIndent = style.hangingIndent;
      }
      // Preserve React Native's alignment, line height and writing direction.
      [nativeString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:runRange];
    }];
  }

  return RCTAttributedStringBoxFromNSAttributedString(nativeString);
}

} // namespace facebook::react
