import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent'
import type {ColorValue, ViewProps} from 'react-native'
import type {Float} from 'react-native/Libraries/Types/CodegenTypes'

interface NativeProps extends ViewProps {
  text: string
  color: ColorValue
  fontSize: Float
  fontStyle: string
  fontWeight: string
  fontFamily: string
  letterSpacing: Float
  lineHeight: Float
  textDecorationLine: string
  textDecorationStyle: string
  textDecorationColor: ColorValue
}

export default codegenNativeComponent<NativeProps>('RNUITextViewChild')
