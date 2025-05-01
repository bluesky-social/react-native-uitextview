#pragma once

#include <react/renderer/components/RNUITextViewSpec/EventEmitters.h>
#include <react/renderer/components/RNUITextViewSpec/Props.h>
#include <react/renderer/components/RNUITextViewSpec/States.h>
#include <react/renderer/components/view/ConcreteViewShadowNode.h>

namespace facebook::react {
extern const char RNUITextViewChildComponentName[];

using RNUITextViewChildShadowNode = ConcreteViewShadowNode<
    RNUITextViewChildComponentName,
    RNUITextViewChildProps,
    RNUITextViewChildEventEmitter,
    RNUITextViewChildState>;
}
