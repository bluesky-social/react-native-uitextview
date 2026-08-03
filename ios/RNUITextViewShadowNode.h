#pragma once

#include <react/renderer/components/RNUITextViewSpec/EventEmitters.h>
#include <react/renderer/components/RNUITextViewSpec/Props.h>
#include <react/renderer/components/view/ConcreteViewShadowNode.h>
#include <react/renderer/textlayoutmanager/TextLayoutManager.h>
#include <react/renderer/core/LayoutContext.h>
#include <react/renderer/core/ShadowNode.h>

#include <string>
#include <vector>

namespace facebook::react {

extern const char RNUITextViewComponentName[];

struct RNUITextViewHighlightMetadata {
  Tag tag;
  std::string group;
  bool suppressHighlighting;
  Float pressRetentionOffsetTop;
  Float pressRetentionOffsetRight;
  Float pressRetentionOffsetBottom;
  Float pressRetentionOffsetLeft;
};

struct RNUITextViewAttachment {
  const ShadowNode *shadowNode;
  size_t fragmentIndex;
};

struct RNUITextViewContent {
  AttributedString attributedString;
  std::vector<RNUITextViewAttachment> attachments;
};

class RNUITextViewStateReal final {
 public:
  AttributedString attributedString;
  std::vector<RNUITextViewHighlightMetadata> highlightMetadata;
};

class RNUITextViewShadowNode final : public ConcreteViewShadowNode<
RNUITextViewComponentName,
RNUITextViewProps,
RNUITextViewEventEmitter,
RNUITextViewStateReal> {
public:
  using ConcreteViewShadowNode::ConcreteViewShadowNode;

  RNUITextViewShadowNode(
   const ShadowNode& sourceShadowNode,
   const ShadowNodeFragment& fragment
  );

  static ShadowNodeTraits BaseTraits() {
    auto traits = ConcreteViewShadowNode::BaseTraits();
    traits.set(ShadowNodeTraits::Trait::LeafYogaNode);
    traits.set(ShadowNodeTraits::Trait::MeasurableYogaNode);
    return traits;
  }

  void layout(LayoutContext layoutContext) override;

  Size measureContent(
      const LayoutContext& layoutContext,
      const LayoutConstraints& layoutConstraints) const override;

private:
  RNUITextViewContent getContentWithMeasuredAttachments(
      const LayoutContext& layoutContext,
      const LayoutConstraints& layoutConstraints,
      std::vector<RNUITextViewHighlightMetadata> *highlightMetadata = nullptr) const;

  AttributedString getAttributedString(
      const LayoutContext& layoutContext,
      std::vector<RNUITextViewHighlightMetadata> *highlightMetadata = nullptr,
      std::vector<RNUITextViewAttachment> *attachments = nullptr) const;
};
} // namespace facebook::React
