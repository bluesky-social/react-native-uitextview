import {Text as RNText, type TextProps} from 'react-native'

/**
 * Event fired by `onSelectionChange`. This event is only available when using
 * the native UITextView implementation on iOS.
 */
export type SelectionChangeEvent = {
  nativeEvent: {target: number; start: number; end: number}
}

type UITextViewProps = TextProps & {
  uiTextView?: boolean
  paragraphMarkerEnd?: number
  paragraphHangingIndent?: number
  onSelectionChange?: (event: SelectionChangeEvent) => void
}

export function UITextView({
  uiTextView: _uiTextView,
  paragraphMarkerEnd: _paragraphMarkerEnd,
  paragraphHangingIndent: _paragraphHangingIndent,
  onSelectionChange: _onSelectionChange,
  ...props
}: UITextViewProps) {
  return <RNText {...props} />
}
