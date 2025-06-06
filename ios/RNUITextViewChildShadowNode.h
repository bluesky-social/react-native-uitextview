#pragma once

#include "generated/RNUITextViewSpec/EventEmitters.h"
#include "generated/RNUITextViewSpec/Props.h"
#include "generated/RNUITextViewSpec/States.h"
#include <react/renderer/components/view/ConcreteViewShadowNode.h>

namespace facebook::react {
extern const char RNUITextViewChildComponentName[];

using RNUITextViewChildShadowNode = ConcreteViewShadowNode<
    RNUITextViewChildComponentName,
    RNUITextViewChildProps,
    RNUITextViewChildEventEmitter,
    RNUITextViewChildState>;
}
