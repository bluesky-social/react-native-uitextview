import React from 'react'
import {
  StyleSheet,
  type TextProps,
  type ViewStyle,
  Text as RNText,
  Platform
} from 'react-native'
import RNUITextViewChildNativeComponent from './RNUITextViewChildNativeComponent'
import RNUITextViewNativeComponent from './RNUITextViewNativeComponent'

const TextAncestorContext = React.createContext<[boolean, ViewStyle]>([
  false,
  StyleSheet.create({})
])

const textDefaults: TextProps = {
  allowFontScaling: true,
  selectable: true
}

const useTextAncestorContext = () => React.useContext(TextAncestorContext)

function UITextViewChild({
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
        <RNUITextViewNativeComponent
          {...textDefaults}
          {...rest}
          // ellipsizeMode={rest.ellipsizeMode ?? rest.lineBreakMode ?? 'tail'}
          style={[flattenedStyle]}
          // onPress={undefined} // We want these to go to the children only
          // onLongPress={undefined}
        >
          {React.Children.toArray(children).map((c, index) => {
            if (React.isValidElement(c)) {
              return c
            } else if (typeof c === 'string' || typeof c === 'number') {
              return (
                <RNUITextViewChildNativeComponent
                  key={index}
                  style={flattenedStyle}
                  text={c.toString()}
                  {...rest}
                />
              )
            }

            return null
          })}
        </RNUITextViewNativeComponent>
      </TextAncestorContext.Provider>
    )
  } else {
    return (
      <>
        {React.Children.toArray(children).map((c, index) => {
          if (React.isValidElement(c)) {
            return c
          } else if (typeof c === 'string' || typeof c === 'number') {
            return (
              <RNUITextViewChildNativeComponent
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

function UITextViewInner(
  props: TextProps & {
    uiTextView?: boolean
  }
) {
  const [isAncestor] = useTextAncestorContext()

  // Even if the uiTextView prop is set, we can still default to using
  // normal selection (i.e. base RN text) if the text doesn't need to be
  // selectable
  if ((!props.selectable || !props.uiTextView) && !isAncestor) {
    return <RNText {...props} />
  }
  return <UITextViewChild {...props} />
}

export function UITextView(props: TextProps & {uiTextView?: boolean}) {
  if (Platform.OS !== 'ios') {
    return <RNText {...props} />
  }
  return <UITextViewInner {...props} />
}
