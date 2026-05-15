import React from 'react'
import {
  Platform,
  StyleSheet,
  Text as RNText,
  type TextProps,
  type ViewStyle,
} from 'react-native'
import RNUITextViewChildNativeComponent from './RNUITextViewChildNativeComponent'
import RNUITextViewNativeComponent from './RNUITextViewNativeComponent'
import {flattenStyles} from './util'

const TextAncestorContext = React.createContext<[boolean, ViewStyle]>([
  false,
  StyleSheet.create({}),
])

const textDefaults: TextProps = {
  allowFontScaling: true,
  selectable: true,
}

const useTextAncestorContext = () => React.useContext(TextAncestorContext)

/**
 * Event fired by `onSelectionChange`. `start`/`end` are 0-based UTF-16 indices
 * into the rendered string. `start === end` means the selection was cleared.
 */
export type SelectionChangeEvent = {
  nativeEvent: {target: number; start: number; end: number}
}

type UITextViewProps = TextProps & {
  uiTextView?: boolean
  /**
   * Fired when the native text selection changes. Only fires on iOS when
   * `uiTextView` is true. Note: fires on every selection-edge adjustment
   * (e.g. dragging a selection handle), so consumers driving expensive work
   * off this event should debounce.
   */
  onSelectionChange?: (event: SelectionChangeEvent) => void
}

function UITextViewChild({style, children, ...rest}: UITextViewProps) {
  const [isAncestor, rootStyle] = useTextAncestorContext()

  // Flatten the styles, and apply the root styles when needed
  const flattenedStyle = React.useMemo(
    () => flattenStyles(rootStyle, style),
    [rootStyle, style],
  )

  if (!isAncestor) {
    return (
      <TextAncestorContext.Provider value={[true, flattenedStyle]}>
        <RNUITextViewNativeComponent
          {...textDefaults}
          {...rest}
          // ellipsizeMode={rest.ellipsizeMode ?? rest.lineBreakMode ?? 'tail'}
          style={[flattenedStyle]}
          // @ts-expect-error Weirdness
          onPress={undefined}
          onLongPress={undefined}>
          {React.Children.toArray(children).map((c, index) => {
            if (React.isValidElement(c)) {
              return c
            } else if (typeof c === 'string' || typeof c === 'number') {
              return (
                // @ts-expect-error @TODO fix this type
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
              // @ts-expect-error @TODO fix this type
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

function UITextViewInner(props: UITextViewProps) {
  const [isAncestor] = useTextAncestorContext()

  // Even if the uiTextView prop is set, we can still default to using
  // normal selection (i.e. base RN text) if the text doesn't need to be
  // selectable
  if ((!props.selectable || !props.uiTextView) && !isAncestor) {
    return <RNText {...props} />
  }
  return <UITextViewChild {...props} />
}

export function UITextView(props: UITextViewProps) {
  if (Platform.OS !== 'ios') {
    return <RNText {...props} />
  }
  return <UITextViewInner {...props} />
}
