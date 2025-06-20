#pragma once

#include <react/renderer/components/RNUITextViewSpec/EventEmitters.h>
#include <react/renderer/components/RNUITextViewSpec/Props.h>
#include <react/renderer/components/view/ConcreteViewShadowNode.h>
#include <react/renderer/textlayoutmanager/TextLayoutManager.h>
#include <react/renderer/core/LayoutContext.h>
#include <react/renderer/core/ShadowNode.h>

namespace facebook::react {

extern const char RNUITextViewComponentName[];

class RNUITextViewStateReal final {
 public:
  AttributedString attributedString;
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
  mutable AttributedString _attributedString;
};
} // namespace facebook::React
