import {
  type CodegenTypes,
  type ColorValue,
  type ViewProps,
  codegenNativeComponent,
} from 'react-native'

interface TargetedEvent {
  target: CodegenTypes.Int32
}

type TextDecorationLine = 'none' | 'underline' | 'line-through'

type TextDecorationStyle = 'solid' | 'double' | 'dotted' | 'dashed'

export type NativeFontWeight =
  | 'normal'
  | 'bold'
  | 'ultraLight'
  | 'light'
  | 'medium'
  | 'semibold'
  | 'heavy'

type FontStyle = 'normal' | 'italic'

type TextAlign = 'auto' | 'left' | 'right' | 'center' | 'justify'

interface NativeProps extends ViewProps {
  text: string
  color?: ColorValue
  fontSize?: CodegenTypes.Float
  fontStyle?: CodegenTypes.WithDefault<FontStyle, 'normal'>
  fontWeight?: CodegenTypes.WithDefault<NativeFontWeight, 'normal'>
  fontFamily?: string
  letterSpacing?: CodegenTypes.Float
  lineHeight?: CodegenTypes.Float
  textDecorationLine?: CodegenTypes.WithDefault<TextDecorationLine, 'none'>
  textDecorationStyle?: CodegenTypes.WithDefault<TextDecorationStyle, 'solid'>
  textDecorationColor?: ColorValue
  textAlign?: CodegenTypes.WithDefault<TextAlign, 'auto'>
  shadowRadius?: CodegenTypes.WithDefault<CodegenTypes.Float, 0>
  /** Internal identifier used to highlight all fragments in a pressable Text. */
  highlightGroup?: string
  /** Internal copy of Text's suppressHighlighting prop. */
  suppressHighlighting?: boolean
  /** Internal expansion of the owning Text's press-retention rectangle. */
  pressRetentionOffsetTop?: CodegenTypes.WithDefault<CodegenTypes.Float, 20>
  pressRetentionOffsetRight?: CodegenTypes.WithDefault<CodegenTypes.Float, 20>
  pressRetentionOffsetBottom?: CodegenTypes.WithDefault<CodegenTypes.Float, 30>
  pressRetentionOffsetLeft?: CodegenTypes.WithDefault<CodegenTypes.Float, 20>
  onPress?: CodegenTypes.BubblingEventHandler<TargetedEvent>
  onLongPress?: CodegenTypes.BubblingEventHandler<TargetedEvent>
}

export default codegenNativeComponent<NativeProps>('RNUITextViewChild', {
  excludedPlatforms: ['android'],
})
