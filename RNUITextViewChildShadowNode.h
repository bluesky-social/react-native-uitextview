#pragma once

#include <react/renderer/components/RNUITextViewSpec/EventEmitters.h>
#include <react/renderer/components/RNUITextViewSpec/Props.h>
#include <react/renderer/components/RNUITextViewSpec/States.h>
#include <react/renderer/components/view/ConcreteViewShadowNode.h>
#include <jsi/jsi.h>

namespace facebook::react {

JSI_EXPORT extern const char RNUITextViewChildComponentName[];

using RNUITextViewChildShadowNode = ConcreteViewShadowNode<
    RNUITextViewChildComponentName,
    RNUITextViewProps,
    RNUITextViewEventEmitter,
    RNUITextViewState>;

} // namespace facebook::React
