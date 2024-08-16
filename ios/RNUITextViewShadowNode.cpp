#include "RNUITextViewShadowNode.h"
#include "RNUITextViewChildShadowNode.h"
#include <react/renderer/components/view/ViewShadowNode.h>

#include <cmath>

namespace facebook::react {

extern const char RNUITextViewComponentName[] = "RNUITextView";

RNUITextViewShadowNode::RNUITextViewShadowNode(
   const ShadowNode& sourceShadowNode,
   const ShadowNodeFragment& fragment
) : ConcreteViewShadowNode(sourceShadowNode, fragment) {
};

AttributedString _attributedString = AttributedString{};

Size RNUITextViewShadowNode::measureContent(
  const LayoutContext& layoutContext,
  const LayoutConstraints& layoutConstraints) const {
    const auto &baseProps = getConcreteProps();
    auto paragraphAttributes = ParagraphAttributes{};
    paragraphAttributes.maximumNumberOfLines = baseProps.numberOfLines;
    // @TODO
    // paragraphAttributes.textBreakStrategy = baseProps.ellipsizeMode;

    auto baseTextAttributes = TextAttributes::defaultTextAttributes();
    baseTextAttributes.backgroundColor = baseProps.backgroundColor;
    
    auto baseAttributedString = AttributedString{};
    const auto &children = getChildren();
    for (size_t i = 0; i < children.size(); i++) {
      const auto child = children[i].get();
      if (auto textViewChild = dynamic_cast<const RNUITextViewChildShadowNode *>(child)) {
        auto &props = textViewChild->getConcreteProps();
        auto fragment = AttributedString::Fragment{};
        auto textAttributes = TextAttributes::defaultTextAttributes();

        textAttributes.backgroundColor = props.backgroundColor;
        textAttributes.fontSize = props.fontSize;
        textAttributes.lineHeight = props.lineHeight;
        textAttributes.foregroundColor = props.color;
        textAttributes.textShadowColor = props.shadowColor;
        textAttributes.textShadowOffset = props.shadowOffset;
        textAttributes.textShadowRadius = props.shadowRadius;
        textAttributes.letterSpacing = props.letterSpacing;
        textAttributes.textDecorationColor = props.textDecorationColor;
        // @TODO add other line stuff here, needs enum

        fragment.string = props.text;
        fragment.textAttributes = textAttributes;

        baseAttributedString.appendFragment(fragment);
      }
    }
    
    _attributedString = baseAttributedString;
    
    TextLayoutContext textLayoutContext{};
    textLayoutContext.pointScaleFactor = layoutContext.pointScaleFactor;
    const auto textLayoutManager = std::make_shared<const TextLayoutManager>(getContextContainer());
        
    return textLayoutManager->measure(
     AttributedStringBox{baseAttributedString},
     paragraphAttributes,
     textLayoutContext,
     layoutConstraints
    ).size;
}

void RNUITextViewShadowNode::layout(LayoutContext layoutContext) {
  ensureUnsealed();
  setStateData(RNUITextViewStateReal{
    _attributedString
  });
}
}
