#pragma once

#include <react-native-uitextview/EventEmitters.h>
#include <react-native-uitextview/Props.h>
#include <react-native-uitextview/States.h>
#include <react/renderer/components/view/ConcreteViewShadowNode.h>

namespace facebook::react {
extern const char RNUITextViewChildComponentName[];

using RNUITextViewChildShadowNode = ConcreteViewShadowNode<
    RNUITextViewChildComponentName,
    RNUITextViewChildProps,
    RNUITextViewChildEventEmitter,
    RNUITextViewChildState>;
}
