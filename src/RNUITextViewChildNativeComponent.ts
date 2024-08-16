import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent'
import type {ColorValue, ViewProps} from 'react-native'
import type {
  Float,
  WithDefault
} from 'react-native/Libraries/Types/CodegenTypes'

type TextDecorationLine = 'none' | 'underline' | 'line-through'

type TextDecorationStyle = 'solid' | 'double' | 'dotted' | 'dashed'

interface NativeProps extends ViewProps {
  text: string
  color?: ColorValue
  fontSize?: Float
  fontStyle?: string
  fontWeight?: string
  fontFamily?: string
  letterSpacing?: Float
  lineHeight?: Float
  textDecorationLine?: WithDefault<TextDecorationLine, 'none'>
  textDecorationStyle?: WithDefault<TextDecorationStyle, 'solid'>
  textDecorationColor?: ColorValue
}

export default codegenNativeComponent<NativeProps>('RNUITextViewChild')
