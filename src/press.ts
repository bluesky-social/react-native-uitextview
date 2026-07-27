import type {TextProps} from 'react-native'

export type PressContext = {
  highlightGroup?: string
  suppressHighlighting?: boolean
  pressRetentionOffset?: TextProps['pressRetentionOffset']
  onPress?: TextProps['onPress']
  onLongPress?: TextProps['onLongPress']
}

export function resolvePressContext(
  ownHighlightGroup: string,
  props: Pick<
    TextProps,
    'onPress' | 'onLongPress' | 'pressRetentionOffset' | 'suppressHighlighting'
  >,
  ancestor: PressContext,
): PressContext {
  const isPressable = props.onPress != null || props.onLongPress != null
  if (!isPressable) {
    return ancestor
  }

  return {
    // Keep handler capabilities in the identifier that native already uses to
    // group highlighted fragments. This avoids a separate prop/state channel
    // getting out of sync with the group and its event emitter.
    highlightGroup: `${ownHighlightGroup}|${props.onPress ? 'p' : ''}${
      props.onLongPress ? 'l' : ''
    }`,
    suppressHighlighting: props.suppressHighlighting === true,
    pressRetentionOffset: props.pressRetentionOffset,
    onPress: props.onPress,
    onLongPress: props.onLongPress,
  }
}
