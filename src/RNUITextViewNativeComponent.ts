import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent'
import type {ViewProps} from 'react-native'
import type {
  Int32,
  WithDefault
} from 'react-native/Libraries/Types/CodegenTypes'

type EllipsizeMode = 'head' | 'middle' | 'tail' | 'clip'

interface NativeProps extends ViewProps {
  numberOfLines?: Int32
  allowsFontScaling?: boolean
  ellipsizeMode?: WithDefault<EllipsizeMode, 'tail'>
  selectable?: boolean
}

export default codegenNativeComponent<NativeProps>('RNUITextView', {
  excludedPlatforms: ['android']
})
