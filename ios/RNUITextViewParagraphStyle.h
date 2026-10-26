#pragma once

#include <react/renderer/attributedstring/AttributedStringBox.h>

#include <cstddef>
#include <vector>

namespace facebook::react {

struct RNUITextViewParagraphStyle {
  size_t fragmentIndex;
  Float markerEnd;
  Float hangingIndent;
};

// TextAttributes cannot carry tab stops or headIndent. Use an opaque native
// attributed string for styled paragraphs, shared by measurement and drawing.
AttributedStringBox RNUITextViewAttributedStringBox(
    const AttributedString &attributedString,
    const std::vector<RNUITextViewParagraphStyle> &paragraphStyles);

} // namespace facebook::react
