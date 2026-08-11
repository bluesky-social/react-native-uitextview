import {
  type CodegenTypes,
  type ColorValue,
  type ViewProps,
  codegenNativeComponent,
} from 'react-native'

interface TargetedEvent {
  target: CodegenTypes.Int32
}

interface TextLayoutEvent extends TargetedEvent {
  lines: string[]
}

/**
 * Event fired when text selection changes in the UITextView.
 * @property target - The view tag identifier
 * @property start - The start index of the selected range (0-based)
 * @property end - The end index of the selected range (0-based, exclusive)
 */
interface SelectionChangeEvent extends TargetedEvent {
  start: CodegenTypes.Int32
  end: CodegenTypes.Int32
}

type EllipsizeMode = 'head' | 'middle' | 'tail' | 'clip'

interface NativeProps extends ViewProps {
  numberOfLines?: CodegenTypes.Int32
  allowFontScaling?: CodegenTypes.WithDefault<boolean, true>
  ellipsizeMode?: CodegenTypes.WithDefault<EllipsizeMode, 'tail'>
  selectable?: boolean
  selectionColor?: ColorValue
  onTextLayout?: CodegenTypes.BubblingEventHandler<TextLayoutEvent>
  /**
   * Callback fired when the text selection changes.
   *
   * @example
   * ```tsx
   * <UITextView
   *   onSelectionChange={(event) => {
   *     console.log('Selection:', event.nativeEvent.start, event.nativeEvent.end);
   *   }}
   * >
   *   Selectable text
   * </UITextView>
   * ```
   */
  onSelectionChange?: CodegenTypes.BubblingEventHandler<SelectionChangeEvent>
}

export default codegenNativeComponent<NativeProps>('RNUITextView', {
  excludedPlatforms: ['android'],
})
