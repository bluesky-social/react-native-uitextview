#pragma once

#include <react/renderer/components/RNUITextViewSpec/EventEmitters.h>
#include <react/renderer/components/RNUITextViewSpec/Props.h>
#include <react/renderer/components/RNUITextViewSpec/States.h>
#include <react/renderer/core/ConcreteShadowNode.h>

namespace facebook::react {
JSI_EXPORT extern const char RNUITextViewChildComponentName[];

class RNUITextViewChildShadowNode : public ConcreteShadowNode<
  RNUITextViewChildComponentName,
  ShadowNode,
  RNUITextViewChildProps> {
 public:
  using ConcreteShadowNode::ConcreteShadowNode;
};
}
