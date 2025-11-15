import React, {useCallback} from 'react'
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

function UITextViewChild({
  style,
  children,
  onSelectionChange,
  ...rest
}: TextProps & {
  uiTextView?: boolean
  onSelectionChange?: (event: {
    nativeEvent: {target: number; start: number; end: number}
  }) => void
}) {
  const [isAncestor, rootStyle] = useTextAncestorContext()

  // Flatten the styles, and apply the root styles when needed
  const flattenedStyle = React.useMemo(
    () => flattenStyles(rootStyle, style),
    [rootStyle, style],
  )

  // Wrap onSelectionChange in useCallback to prevent unnecessary re-renders
  const handleSelectionChange = useCallback(
    (event: {
      nativeEvent: {target: number; start: number; end: number}
    }) => {
      onSelectionChange?.(event)
    },
    [onSelectionChange],
  )

  if (!isAncestor) {
    return (
      <TextAncestorContext.Provider value={[true, flattenedStyle]}>
        <RNUITextViewNativeComponent
          {...textDefaults}
          {...rest}
          // ellipsizeMode={rest.ellipsizeMode ?? rest.lineBreakMode ?? 'tail'}
          style={[flattenedStyle]}
          onSelectionChange={handleSelectionChange}
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

function UITextViewInner(
  props: TextProps & {
    uiTextView?: boolean
    onSelectionChange?: (event: {
      nativeEvent: {target: number; start: number; end: number}
    }) => void
  },
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

export function UITextView(
  props: TextProps & {
    uiTextView?: boolean
    /**
     * Callback fired when text selection changes.
     * Only available on iOS when using uiTextView={true}.
     * 
     * @example
     * ```tsx
     * <UITextView
     *   uiTextView={true}
     *   onSelectionChange={(event) => {
     *     const {start, end} = event.nativeEvent;
     *     console.log(`Selected range: ${start}-${end}`);
     *   }}
     * >
     *   Selectable text
     * </UITextView>
     * ```
     */
    onSelectionChange?: (event: {
      nativeEvent: {target: number; start: number; end: number}
    }) => void
  },
) {
  if (Platform.OS !== 'ios') {
    return <RNText {...props} />
  }
  return <UITextViewInner {...props} />
}
