import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent'
import type {ViewProps} from 'react-native'
import type {
  BubblingEventHandler,
  Int32,
  WithDefault,
} from 'react-native/Libraries/Types/CodegenTypes'

interface TargetedEvent {
  target: Int32
}

interface TextLayoutEvent extends TargetedEvent {
  lines: string[]
}

type EllipsizeMode = 'head' | 'middle' | 'tail' | 'clip'

interface NativeProps extends ViewProps {
  numberOfLines?: Int32
  allowFontScaling?: WithDefault<boolean, true>
  ellipsizeMode?: WithDefault<EllipsizeMode, 'tail'>
  selectable?: boolean
  onTextLayout?: BubblingEventHandler<TextLayoutEvent>
}

export default codegenNativeComponent<NativeProps>('RNUITextView', {
  excludedPlatforms: ['android'],
})
