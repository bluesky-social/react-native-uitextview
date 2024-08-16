#pragma once

#include "RNUITextViewChildShadowNode.h"

#include <react/renderer/core/ConcreteComponentDescriptor.h>
#include <react/renderer/componentregistry/ComponentDescriptorProviderRegistry.h>

namespace facebook::react {
using RNUITextViewChildComponentDescriptor = ConcreteComponentDescriptor<RNUITextViewChildShadowNode>;

void RNUITextViewChildSpec_registerComponentDescriptorsFromCodegen(
  std::shared_ptr<const ComponentDescriptorProviderRegistry> registry);
}
