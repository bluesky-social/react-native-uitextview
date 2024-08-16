#include "RNUITextViewShadowNode.h"
#include "RNUITextViewChildShadowNode.h"
#include <react/renderer/components/view/ViewShadowNode.h>

#include <cmath>

namespace facebook::react {

extern const char RNUITextViewComponentName[] = "RNUITextView";

using Content = RNUITextViewShadowNode::Content;

AttributedString _attributedString = AttributedString{};
ParagraphAttributes _paragraphAttributes = ParagraphAttributes{};

RNUITextViewShadowNode::RNUITextViewShadowNode(
   const ShadowNode& sourceShadowNode,
   const ShadowNodeFragment& fragment
) : ConcreteViewShadowNode(sourceShadowNode, fragment) {
  auto& sourceViewShadowNode = static_cast<const RNUITextViewShadowNode&>(sourceShadowNode);
  if (!fragment.children && !fragment.props && sourceViewShadowNode.getIsLayoutClean()) {
    cleanLayout();
  }
};

Size RNUITextViewShadowNode::measureContent(
  const LayoutContext& layoutContext,
  const LayoutConstraints& layoutConstraints) const {
    auto attributedString = _attributedString;
    
    TextLayoutContext textLayoutContext{};
    textLayoutContext.pointScaleFactor = layoutContext.pointScaleFactor;
    
    const auto contextContainer = getContextContainer();
    const auto textLayoutManager = std::make_shared<TextLayoutManager>(contextContainer);
    
    auto size = textLayoutManager->measure(
     AttributedStringBox{attributedString},
     _paragraphAttributes,
     textLayoutContext,
     layoutConstraints
    ).size;
    return size;
}

void RNUITextViewShadowNode::layout(LayoutContext layoutContext) {
  ensureUnsealed();
  
  auto &baseProps = getConcreteProps();
  auto paragraphAttributes = ParagraphAttributes{};
  paragraphAttributes.maximumNumberOfLines = baseProps.numberOfLines;
  // @TODO
  // paragraphAttributes.textBreakStrategy = baseProps.ellipsizeMode;
  
  auto baseTextAttributes = TextAttributes::defaultTextAttributes();
  
  auto baseAttributedString = AttributedString{};
  baseTextAttributes.fontSizeMultiplier = layoutContext.fontSizeMultiplier;
  baseTextAttributes.backgroundColor = baseProps.backgroundColor;
  
  auto &children = getChildren();
  for (size_t i = 0; i < children.size(); i++) {
    auto child = children[i].get();
    if (auto textViewChild = dynamic_cast<const RNUITextViewChildShadowNode *>(child)) {
      auto &props = textViewChild->getConcreteProps();
      auto fragment = AttributedString::Fragment{};
      auto textAttributes = TextAttributes::defaultTextAttributes();
      
      textAttributes.fontSizeMultiplier = layoutContext.fontSizeMultiplier;
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
  
  auto &state = getStateData();
  if (state.attributedString == baseAttributedString) {
    return;
  }

  _attributedString = baseAttributedString;
  setStateData(RNUITextViewStateReal{
    baseAttributedString
  });
}
}
