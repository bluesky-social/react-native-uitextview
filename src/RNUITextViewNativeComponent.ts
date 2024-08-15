import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent'
import type {ViewProps} from 'react-native'
import type {Int32} from 'react-native/Libraries/Types/CodegenTypes'

interface NativeProps extends ViewProps {
  numberOfLines?: Int32
  allowsFontScaling?: boolean
  ellipsizeMode?: string
  selectable?: boolean
}

export default codegenNativeComponent<NativeProps>('RNUITextView', {
  excludedPlatforms: ['android']
})
