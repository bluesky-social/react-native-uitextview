#pragma once

#include "RNUITextViewShadowNode.h"

#include <react/renderer/core/ConcreteComponentDescriptor.h>
#include <react/renderer/componentregistry/ComponentDescriptorProviderRegistry.h>

namespace facebook::react {
using RNUITextViewComponentDescriptor = ConcreteComponentDescriptor<RNUITextViewShadowNode>;

void RNUITextViewSpec_registerComponentDescriptorsFromCodegen(
  std::shared_ptr<const ComponentDescriptorProviderRegistry> registry);
}
