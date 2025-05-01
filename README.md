![image](https://haileyok.com/content/images/size/w1920/2024/01/IMG_4730.jpeg)

### Note about support for this library
This library was made for the
[Bluesky Social App](https://github.com/bluesky-social/social-app). Support for this library
is very much dependent on two factors:

1. Do we have time to implement a feature or fix an issue?
2. How important is the feature to Bluesky or does it fix an issue present in Bluesky?

If there are features that you want to see in this library that don't already exist and
likely (or definitely) do not greatly improve the experience in Bluesky, please feel free
to submit a PR! Of course, you should also feel free to make feature suggestions or
bug reports as well, and whenever free time is available the might be worked on. Just know
it might take some time.

Thank you!

# React Native UITextView

The `Text` implementation in React Native much more closely resembles `UILabel` on iOS. Unfortunately, this prevents
the user from being able to highlight text for selection. The only copy behavior that is possible is to copy the
entire block of text.

`UITextView` however allows a user to highlight portions of the text block for copying,
translation, or other native capabilities.

React Native UITextView takes advantage of `UITextView` to allow for both types of copying
on iOS: highlight and copy or the current, `UILabel` behavior to just copy the entire
block of text.

## Installation

> [!WARNING]
> The final version of this package that supports the old React Native architecture is `1.4.0`. All versions `2.x` and
> higher support only the new architecture. Unfortunately I do not have time to maintain support for both architectures.
> Version `1.4.0` however is stable and - aside from the still missing features from the base `<Text>` component, should
> work the same as `2.x` and higher.

> [!NOTE]
> Version 2.0.0 of `react-native-uitextview` is tested against and used in production with React Nave 0.79. No other versions
> are officially supported. As there have been a number of changes to the text layout engine in the new architecture, things
> may be broken if you are not using this version of React Native with this package. Generally, these problems are inside of
> `RNUITextViewShadowNode.cpp`.

```sh
yarn add react-native-uitextview
cd ios
pod install
```

## Limitations

React Native UITextView can - for the most part - be used as a drop-in replacement
for existing blocks of `Text`. However, there are a few limitations:

- Children of `UITextView` may only be other UITextView children (base `Text` children
will be converted to `UITextView` children, so you only need to adjust the wrapper).
This means that things like in-line images are not supported as they are in the base
React Native `Text` component.
- A few styles have not yet been implemented, but all should be possible.

## Usage

Usage of this component is the same as the base React Native `Text` component. It
can be imported as `Text` from `react-native-uitextview`, so in most cases you only
need to replace your current `Text` import with this one.

Aside from the few limitations above, all of the existing styles and props that you
are using for `Text` should work. On non-iOS platforms, the base React Native `Text`
will always be used. On iOS, the base React Native `Text` component will be used
unless the `selectable` and the `uiTextView` props are both `true`.

```tsx
import { UITextView as Text } from "react-native-uitextview";

function SomeView() {
  return (
    <View style={{flex: 1}}>
      <Text
        style={{color: 'green', lineHeight: 20, fontSize: 14}}
        selectable
        uiTextView
      >
        This is some highlightable text! It uses UITextView
      </Text>
      <Text
        style={{color: 'blue', lineHeight: 20, fontSize: 14}}
        selectable // Note we do not add the uiTextView prop
      >
        This text still uses the base Text component. It can only be copied.
      </Text>
      <Text
        style={{color: 'red', lineHeight: 20, fontSize: 14}}
        uiTextView // Note we do not add the selectable prop
      >
        This text still uses the base Text component. It can't be highlighted
        or copied at all.
      </Text>
    </View>
  )
}
```

Nesting of `UITextView` components is supported. For example, if you have styles
that should be applied only to a portion of the text, or an `onPress` callback to
add to a link.

```tsx
<Text style={{fontSize: 14}} selectable uiTextView>
  This is some text that's highlightable with{' '}
  <Text
    style={{color: 'blue', textDecorationLine: 'underline'}}
    onPress={() => Linking.openURL('https://google.com')}
  >
    a link
  </Text>
  .
</Text>
```

## Contributing

Contributions are always welcome - and encouraged. Please note however that it might take
time for PRs to be reviewed and merged, and they might not be merged at all. This library
was created to support text selection in the
[Bluesky Social App](https://github.com/bluesky-social/social-app). Contributions that may
affect the proper functioning of the component in Bluesky will not be merged.

Some ideas for great contributions that we do not have time to properly implement:

- Full support for all RN styles
- Accessibility improvements

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
