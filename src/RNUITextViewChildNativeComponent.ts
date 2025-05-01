import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent'
import type {ColorValue, ViewProps} from 'react-native'
import type {
  BubblingEventHandler,
  Float,
  Int32,
  WithDefault,
} from 'react-native/Libraries/Types/CodegenTypes'

interface TargetedEvent {
  target: Int32
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

interface NativeProps extends ViewProps {
  text: string
  color?: ColorValue
  fontSize?: Float
  fontStyle?: WithDefault<FontStyle, 'normal'>
  fontWeight?: WithDefault<NativeFontWeight, 'normal'>
  fontFamily?: string
  letterSpacing?: Float
  lineHeight?: Float
  textDecorationLine?: WithDefault<TextDecorationLine, 'none'>
  textDecorationStyle?: WithDefault<TextDecorationStyle, 'solid'>
  textDecorationColor?: ColorValue
  shadowRadius?: WithDefault<Float, 0>
  onPress?: BubblingEventHandler<TargetedEvent>
  onLongPress?: BubblingEventHandler<TargetedEvent>
}

export default codegenNativeComponent<NativeProps>('RNUITextViewChild', {
  excludedPlatforms: ['android'],
})
