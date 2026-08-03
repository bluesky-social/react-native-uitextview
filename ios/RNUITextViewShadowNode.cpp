#include "RNUITextViewShadowNode.h"
#include "RNUITextViewChildShadowNode.h"
#include <react/debug/react_native_assert.h>
#include <react/renderer/components/view/ViewShadowNode.h>
#include <react/renderer/graphics/rounding.h>
#include <react/renderer/mounting/ShadowView.h>

#include <cmath>

namespace facebook::react {

static ShadowView shadowViewFromShadowNode(const ShadowNode& shadowNode) {
  auto shadowView = ShadowView{shadowNode};
  // The attributed string only needs the component identity and event emitter.
  // Dropping props and state avoids retaining the shadow tree through state.
  shadowView.props = nullptr;
  shadowView.state = nullptr;
  return shadowView;
}

static ParagraphAttributes paragraphAttributesFromProps(
    const RNUITextViewProps& props) {
  auto paragraphAttributes = ParagraphAttributes{};
  paragraphAttributes.maximumNumberOfLines = props.numberOfLines;
  if (props.ellipsizeMode == RNUITextViewEllipsizeMode::Head) {
    paragraphAttributes.ellipsizeMode = EllipsizeMode::Head;
  } else if (props.ellipsizeMode == RNUITextViewEllipsizeMode::Middle) {
    paragraphAttributes.ellipsizeMode = EllipsizeMode::Middle;
  } else if (props.ellipsizeMode == RNUITextViewEllipsizeMode::Tail) {
    paragraphAttributes.ellipsizeMode = EllipsizeMode::Tail;
  } else if (props.ellipsizeMode == RNUITextViewEllipsizeMode::Clip) {
    paragraphAttributes.ellipsizeMode = EllipsizeMode::Clip;
  }
  return paragraphAttributes;
}

RNUITextViewShadowNode::RNUITextViewShadowNode(
   const ShadowNode& sourceShadowNode,
   const ShadowNodeFragment& fragment
) : ConcreteViewShadowNode(sourceShadowNode, fragment) {
};

Size RNUITextViewShadowNode::measureContent(
  const LayoutContext& layoutContext,
  const LayoutConstraints& layoutConstraints) const {
    const auto &baseProps = getConcreteProps();
    const auto paragraphAttributes = paragraphAttributesFromProps(baseProps);
    const auto content =
        getContentWithMeasuredAttachments(layoutContext, layoutConstraints);

    TextLayoutContext textLayoutContext{
      .pointScaleFactor = layoutContext.pointScaleFactor,
      .surfaceId = getSurfaceId(),
    };
    const auto textLayoutManager = std::make_shared<const TextLayoutManager>(getContextContainer());

    return textLayoutManager->measure(
      AttributedStringBox{content.attributedString},
      paragraphAttributes,
      textLayoutContext,
      layoutConstraints
    ).size;
}

RNUITextViewContent RNUITextViewShadowNode::getContentWithMeasuredAttachments(
    const LayoutContext& layoutContext,
    const LayoutConstraints& layoutConstraints,
    std::vector<RNUITextViewHighlightMetadata> *highlightMetadata) const {
  auto attachments = std::vector<RNUITextViewAttachment>{};
  auto attributedString =
      getAttributedString(layoutContext, highlightMetadata, &attachments);

  if (attachments.empty()) {
    return RNUITextViewContent{
      std::move(attributedString),
      std::move(attachments),
    };
  }

  auto localLayoutConstraints = layoutConstraints;
  localLayoutConstraints.minimumSize = Size{0, 0};
  auto &fragments = attributedString.getFragments();

  for (const auto &attachment : attachments) {
    const auto layoutableShadowNode =
        dynamic_cast<const LayoutableShadowNode *>(attachment.shadowNode);
    if (layoutableShadowNode == nullptr) {
      continue;
    }

    auto size =
        layoutableShadowNode->measure(layoutContext, localLayoutConstraints);
    size.width += 0.01f;
    size.height += 0.01f;
    size = roundToPixel<&ceil>(size, layoutContext.pointScaleFactor);

    auto fragmentLayoutMetrics = LayoutMetrics{};
    fragmentLayoutMetrics.pointScaleFactor = layoutContext.pointScaleFactor;
    fragmentLayoutMetrics.frame.size = size;
    fragments[attachment.fragmentIndex].parentShadowView.layoutMetrics =
        fragmentLayoutMetrics;
  }

  return RNUITextViewContent{
    std::move(attributedString),
    std::move(attachments),
  };
}

AttributedString RNUITextViewShadowNode::getAttributedString(
  const LayoutContext& layoutContext,
  std::vector<RNUITextViewHighlightMetadata> *highlightMetadata,
  std::vector<RNUITextViewAttachment> *attachments) const {
    const auto &baseProps = getConcreteProps();
    auto baseTextAttributes = TextAttributes::defaultTextAttributes();
    baseTextAttributes.backgroundColor = baseProps.backgroundColor;
    baseTextAttributes.allowFontScaling = baseProps.allowFontScaling;
    // Match RN Text measurement/rendering by carrying the multiplier through
    // TextAttributes instead of pre-scaling fontSize/lineHeight ourselves.
    baseTextAttributes.fontSizeMultiplier = layoutContext.fontSizeMultiplier;

    auto baseAttributedString = AttributedString{};
    baseAttributedString.setBaseTextAttributes(baseTextAttributes);
    const auto &children = getChildren();
    for (size_t i = 0; i < children.size(); i++) {
      const auto child = children[i].get();
      if (auto textViewChild = dynamic_cast<const RNUITextViewChildShadowNode *>(child)) {
        auto &props = textViewChild->getConcreteProps();
        auto fragment = AttributedString::Fragment{};
        auto textAttributes = baseTextAttributes;
        textAttributes.backgroundColor = props.backgroundColor;
        textAttributes.fontSize = props.fontSize;
        textAttributes.lineHeight = props.lineHeight;
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
        } else if (props.textDecorationStyle == RNUITextViewChildTextDecorationStyle::Double) {
          textAttributes.textDecorationStyle = TextDecorationStyle::Double;
        }
        
        if (props.textAlign == RNUITextViewChildTextAlign::Left) {
          textAttributes.alignment = TextAlignment::Left;
        } else if (props.textAlign == RNUITextViewChildTextAlign::Right) {
          textAttributes.alignment = TextAlignment::Right;
        } else if (props.textAlign == RNUITextViewChildTextAlign::Center) {
          textAttributes.alignment = TextAlignment::Center;
        } else if (props.textAlign == RNUITextViewChildTextAlign::Justify) {
          textAttributes.alignment = TextAlignment::Justified;
        } else if (props.textAlign == RNUITextViewChildTextAlign::Auto) {
          textAttributes.alignment = TextAlignment::Natural;
        }
        
        textAttributes.backgroundColor = props.backgroundColor;

        fragment.string = props.text;
        fragment.textAttributes = textAttributes;
        fragment.parentShadowView = shadowViewFromShadowNode(*textViewChild);

        if (highlightMetadata != nullptr && !props.highlightGroup.empty()) {
          highlightMetadata->push_back(RNUITextViewHighlightMetadata{
            fragment.parentShadowView.tag,
            props.highlightGroup,
            props.suppressHighlighting,
            props.pressRetentionOffsetTop,
            props.pressRetentionOffsetRight,
            props.pressRetentionOffsetBottom,
            props.pressRetentionOffsetLeft,
          });
        }

        baseAttributedString.appendFragment(std::move(fragment));
      } else if (attachments != nullptr) {
        auto fragment = AttributedString::Fragment{};
        fragment.string = AttributedString::Fragment::AttachmentCharacter();
        fragment.textAttributes = baseTextAttributes;
        fragment.parentShadowView = shadowViewFromShadowNode(*child);
        baseAttributedString.appendFragment(std::move(fragment));
        attachments->push_back(RNUITextViewAttachment{
          child,
          baseAttributedString.getFragments().size() - 1,
        });
      }
    }
    
    return baseAttributedString;
}

void RNUITextViewShadowNode::layout(LayoutContext layoutContext) {
  ensureUnsealed();
  const auto layoutMetrics = getLayoutMetrics();
  const auto size = layoutMetrics.getContentFrame().size;
  const auto layoutConstraints = LayoutConstraints{
    size,
    size,
    layoutMetrics.layoutDirection,
  };
  auto highlightMetadata = std::vector<RNUITextViewHighlightMetadata>{};
  auto content = getContentWithMeasuredAttachments(
      layoutContext, layoutConstraints, &highlightMetadata);

  setStateData(RNUITextViewStateReal{
    content.attributedString,
    std::move(highlightMetadata),
  });

  if (content.attachments.empty()) {
    return;
  }

  const auto paragraphAttributes =
      paragraphAttributesFromProps(getConcreteProps());
  const auto textLayoutContext = TextLayoutContext{
    .pointScaleFactor = layoutContext.pointScaleFactor,
    .surfaceId = getSurfaceId(),
  };
  const auto textLayoutManager =
      std::make_shared<const TextLayoutManager>(getContextContainer());
  const auto measurement = textLayoutManager->measure(
      AttributedStringBox{content.attributedString},
      paragraphAttributes,
      textLayoutContext,
      layoutConstraints);

  react_native_assert(
      content.attachments.size() == measurement.attachments.size());

  auto textViewShadowNode = this;
  auto textViewOwningShadowNode = std::shared_ptr<ShadowNode>{};

  for (size_t i = 0; i < content.attachments.size(); i++) {
    const auto &attachment = content.attachments[i];
    if (dynamic_cast<const LayoutableShadowNode *>(attachment.shadowNode) ==
        nullptr) {
      continue;
    }

    auto clonedShadowNode = std::shared_ptr<ShadowNode>{};
    textViewOwningShadowNode = textViewShadowNode->cloneTree(
        attachment.shadowNode->getFamily(),
        [&](const ShadowNode& oldShadowNode) {
          clonedShadowNode = oldShadowNode.clone({});
          return clonedShadowNode;
        });
    textViewShadowNode =
        static_cast<RNUITextViewShadowNode *>(textViewOwningShadowNode.get());

    auto &layoutableShadowNode =
        dynamic_cast<LayoutableShadowNode &>(*clonedShadowNode);
    const auto &attachmentMeasurement = measurement.attachments[i];
    if (attachmentMeasurement.isClipped) {
      layoutableShadowNode.setLayoutMetrics(
          LayoutMetrics{.frame = {}, .displayType = DisplayType::None});
      continue;
    }

    auto attachmentFrame = attachmentMeasurement.frame;
    attachmentFrame.origin.x += layoutMetrics.contentInsets.left;
    attachmentFrame.origin.y += layoutMetrics.contentInsets.top;
    const auto attachmentSize = roundToPixel<&ceil>(
        attachmentFrame.size, layoutMetrics.pointScaleFactor);
    const auto attachmentOrigin = roundToPixel<&round>(
        attachmentFrame.origin, layoutMetrics.pointScaleFactor);
    const auto attachmentLayoutConstraints = LayoutConstraints{
      attachmentSize,
      attachmentSize,
      layoutConstraints.layoutDirection,
    };

    layoutableShadowNode.layoutTree(
        layoutContext, attachmentLayoutConstraints);
    auto attachmentLayoutMetrics = layoutableShadowNode.getLayoutMetrics();
    attachmentLayoutMetrics.frame.origin = attachmentOrigin;
    layoutableShadowNode.setLayoutMetrics(attachmentLayoutMetrics);
  }

  if (textViewShadowNode != this) {
    children_ = textViewShadowNode->children_;
  }
}
}
