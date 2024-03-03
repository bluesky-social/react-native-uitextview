import React from 'react'
import {
  Platform,
  requireNativeComponent,
  StyleSheet,
  UIManager,
  ViewStyle,
  TextProps,
  Text as RNText
} from 'react-native'

const LINKING_ERROR =
  `The package 'react-native-uitextview' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ios: "- You have run 'pod install'\n", default: ''}) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n'

// These props are for the main native wrapper component
export interface RNUITextViewProps extends TextProps {
  children: React.ReactNode
  style: ViewStyle[]
}

// These props are for each of the children native components
type RNUITextViewChildProps = TextProps & {
  text: string
  onTextPress?: (...args: any[]) => void
  onTextLongPress?: (...args: any[]) => void
}

const RNUITextView =
  UIManager.getViewManagerConfig('RNUITextView') != null
    ? requireNativeComponent<RNUITextViewProps>('RNUITextView')
    : () => {
        throw new Error(LINKING_ERROR)
      }
export const RNUITextViewChild =
  UIManager.getViewManagerConfig &&
  UIManager.getViewManagerConfig('RNUITextViewChild') != null
    ? requireNativeComponent<RNUITextViewChildProps>('RNUITextViewChild')
    : () => {
        throw new Error(LINKING_ERROR)
      }

const TextAncestorContext = React.createContext<[boolean, ViewStyle]>([
  false,
  StyleSheet.create({})
])

const useTextAncestorContext = () => React.useContext(TextAncestorContext)

const textDefaults: TextProps = {
  allowFontScaling: true,
  selectable: true
}

function UITextViewInner({
  style,
  children,
  ...rest
}: TextProps & {
  uiTextView?: boolean
}) {
  const [isAncestor, rootStyle] = useTextAncestorContext()

  // Flatten the styles, and apply the root styles when needed
  const flattenedStyle = React.useMemo(
    () => StyleSheet.flatten([rootStyle, style]),
    [rootStyle, style]
  )

  if (!isAncestor) {
    return (
      <TextAncestorContext.Provider value={[true, flattenedStyle]}>
        <RNUITextView
          {...textDefaults}
          {...rest}
          ellipsizeMode={rest.ellipsizeMode ?? rest.lineBreakMode ?? 'tail'}
          style={[flattenedStyle]}
          onPress={undefined} // We want these to go to the children only
          onLongPress={undefined}>
          {React.Children.toArray(children).map((c, index) => {
            if (React.isValidElement(c)) {
              return c
            } else if (typeof c === 'string' || typeof c === 'number') {
              return (
                <RNUITextViewChild
                  key={index}
                  style={flattenedStyle}
                  text={c.toString()}
                  {...rest}
                />
              )
            }

            return null
          })}
        </RNUITextView>
      </TextAncestorContext.Provider>
    )
  } else {
    return (
      <>
        {React.Children.toArray(children).map((c, index) => {
          if (React.isValidElement(c)) {
            return c
          } else if (typeof c === 'string' || c === 'number') {
            return (
              <RNUITextViewChild
                key={index}
                style={flattenedStyle}
                text={c.toString()}
                {...rest}
              />
            )
          }

          return null
        })}
      </>
    )
  }
}

export function UITextView(
  props: TextProps & {
    uiTextView?: boolean
  }
) {
  if (Platform.OS !== 'ios') {
    return <RNText {...props} />
  }

  // This will never actually get called conditionally, so we don't need
  // to worry about the warning
  // eslint-disable-next-line react-hooks/rules-of-hooks
  const [isAncestor] = useTextAncestorContext()

  // Even if the uiTextView prop is set, we can still default to using
  // normal selection (i.e. base RN text) if the text doesn't need to be
  // selectable
  if (!props.selectable && !props.uiTextView && !isAncestor) {
    return <RNText {...props} />
  }
  return <UITextViewInner {...props} />
}
