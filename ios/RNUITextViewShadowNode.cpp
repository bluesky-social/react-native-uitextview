#include "RNUITextViewShadowNode.h"
#include "RNUITextViewChildShadowNode.h"
#include <react/renderer/components/view/ViewShadowNode.h>

#include <cmath>

namespace facebook::react {

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
    if (baseProps.ellipsizeMode == RNUITextViewEllipsizeMode::Head) {
      paragraphAttributes.ellipsizeMode = EllipsizeMode::Head;
    } else if (baseProps.ellipsizeMode == RNUITextViewEllipsizeMode::Middle) {
      paragraphAttributes.ellipsizeMode = EllipsizeMode::Middle;
    } else if (baseProps.ellipsizeMode == RNUITextViewEllipsizeMode::Tail) {
      paragraphAttributes.ellipsizeMode = EllipsizeMode::Tail;
    } else if (baseProps.ellipsizeMode == RNUITextViewEllipsizeMode::Clip) {
      paragraphAttributes.ellipsizeMode = EllipsizeMode::Clip;
    }

    auto baseTextAttributes = TextAttributes::defaultTextAttributes();
    baseTextAttributes.backgroundColor = baseProps.backgroundColor;
    baseTextAttributes.allowFontScaling = baseProps.allowFontScaling;
    
    Float fontSizeMultiplier = 1.0;
    if (baseTextAttributes.allowFontScaling) {
      fontSizeMultiplier = layoutContext.fontSizeMultiplier;
    }
    
    auto baseAttributedString = AttributedString{};
    const auto &children = getChildren();
    for (size_t i = 0; i < children.size(); i++) {
      const auto child = children[i].get();
      if (auto textViewChild = dynamic_cast<const RNUITextViewChildShadowNode *>(child)) {
        auto &props = textViewChild->getConcreteProps();
        auto fragment = AttributedString::Fragment{};
        auto textAttributes = TextAttributes::defaultTextAttributes();

        textAttributes.allowFontScaling = baseProps.allowFontScaling;
        textAttributes.backgroundColor = props.backgroundColor;
        textAttributes.fontSize = props.fontSize * fontSizeMultiplier;
        textAttributes.lineHeight = props.lineHeight * fontSizeMultiplier;
        textAttributes.foregroundColor = props.color;
        textAttributes.textShadowColor = props.shadowColor;
        textAttributes.textShadowOffset = props.shadowOffset;
        textAttributes.textShadowRadius = props.shadowRadius;
        textAttributes.letterSpacing = props.letterSpacing;
        textAttributes.textDecorationColor = props.textDecorationColor;
        textAttributes.fontFamily = props.fontFamily;
        
        if (props.fontStyle == RNUITextViewChildFontStyle::Italic) {
          textAttributes.fontStyle = FontStyle::Italic;
        } else {
          textAttributes.fontStyle = FontStyle::Normal;
        }
        
        if (props.fontWeight == RNUITextViewChildFontWeight::Bold) {
          textAttributes.fontWeight = FontWeight::Bold;
        } else if (props.fontWeight == RNUITextViewChildFontWeight::UltraLight) {
          textAttributes.fontWeight = FontWeight::UltraLight;
        } else if (props.fontWeight == RNUITextViewChildFontWeight::Light) {
          textAttributes.fontWeight = FontWeight::Light;
        } else if (props.fontWeight == RNUITextViewChildFontWeight::Medium) {
          textAttributes.fontWeight = FontWeight::Medium;
        } else if (props.fontWeight == RNUITextViewChildFontWeight::Semibold) {
          textAttributes.fontWeight = FontWeight::Semibold;
        } else if (props.fontWeight == RNUITextViewChildFontWeight::Heavy) {
          textAttributes.fontWeight = FontWeight::Heavy;
        } else {
          textAttributes.fontWeight = FontWeight::Regular;
        }
                
        if (props.textDecorationLine == RNUITextViewChildTextDecorationLine::LineThrough) {
          textAttributes.textDecorationLineType = TextDecorationLineType::Strikethrough;
        } else if (props.textDecorationLine == RNUITextViewChildTextDecorationLine::Underline) {
          textAttributes.textDecorationLineType = TextDecorationLineType::Underline;
        } else {
          textAttributes.textDecorationLineType = TextDecorationLineType::None;
        }
        
        if (props.textDecorationStyle == RNUITextViewChildTextDecorationStyle::Solid) {
          textAttributes.textDecorationStyle = TextDecorationStyle::Solid;
        } else if (props.textDecorationStyle == RNUITextViewChildTextDecorationStyle::Dotted) {
          textAttributes.textDecorationStyle = TextDecorationStyle::Dotted;
        } else if (props.textDecorationStyle == RNUITextViewChildTextDecorationStyle::Dashed) {
          textAttributes.textDecorationStyle = TextDecorationStyle::Dashed;
        } else if (props.textDecorationStyle == RNUITextViewChildTextDecorationStyle::Dotted) {
          textAttributes.textDecorationStyle = TextDecorationStyle::Double;
        }
        
        textAttributes.backgroundColor = props.backgroundColor;

        fragment.string = props.text;
        fragment.textAttributes = textAttributes;

        baseAttributedString.appendFragment(std::move(fragment));
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
