import * as React from 'react'

import {
  Alert,
  FlatList,
  Text as RNText,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  View,
} from 'react-native'
import {UITextView as Text} from '@bsky.app/react-native-uitextview'

// Recycling fixture for PR #46 test plan item 6. 100 selectable UITextViews in
// a fixed-height FlatList — scroll to force cell recycling, then select text
// in any visible row and tap outside to confirm the window-level recognizer
// still wires up correctly after RNUITextView's prepareForRecycle.
const RECYCLE_ITEMS = Array.from({length: 100}, (_, i) => ({
  id: String(i),
  text: `Row ${i}: selectable UITextView — long-press to select, then tap outside.`,
}))

// Regression fixture for #42 / PR #45. Poppins-Regular has typoLineGap=100
// (per OS/2 table), so without the fix UITextView renders each line ~10% taller
// than RCTTextLayoutManager measured. With clipsToBounds=true on the wrapper,
// the cumulative drift clips lines off the bottom. Red border = View bounds.
const CUSTOM_FONT_PARAGRAPH =
  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod ' +
  'tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, ' +
  'quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo ' +
  'consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse ' +
  'cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat ' +
  'non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. ' +
  'Curabitur pretium tincidunt lacus. Nulla gravida orci a odio. Nullam varius, ' +
  'turpis et commodo pharetra, est eros bibendum elit, nec luctus magna felis ' +
  'sollicitudin mauris. Integer in mauris eu nibh euismod gravida. ' +
  'Phasellus a est. Phasellus magna. In hac habitasse platea dictumst. ' +
  'Curabitur at lacus ac velit ornare lobortis. Curabitur a felis in nunc ' +
  'fringilla tristique. Morbi mattis ullamcorper velit. ' +
  'Last line goes here with descenders: gypsy jumping pyramid pygmy.'

// Regression fixture for allowFontScaling={false}. Raise iOS Dynamic Type
// (Settings > Accessibility > Display & Text Size > Larger Text). The `false`
// rows should stay fixed while the `true` rows grow. Base RN Text and
// RN-UITextView should match each other.
const FONT_SCALING_PARAGRAPH =
  'Dynamic Type check with a nested bold span. This paragraph should wrap ' +
  'onto multiple lines so scaling differences are easy to spot.'

function SelectionChangeDemo() {
  const [range, setRange] = React.useState<{start: number; end: number} | null>(
    null,
  )
  const body = '😀😀 Hello 你好 مرحبا 🎉'
  const selected = range ? body.substring(range.start, range.end) : null
  return (
    <View>
      <RNText style={styles.selectionRangeLabel}>
        {range
          ? `start=${range.start} end=${range.end}`
          : '(no selection events yet)'}
      </RNText>
      <RNText style={styles.selectionRangeLabel}>
        substring: {selected != null ? `"${selected}"` : '(none)'}
      </RNText>
      <Text
        selectable
        uiTextView
        style={styles.selectionBody}
        onSelectionChange={e =>
          setRange({start: e.nativeEvent.start, end: e.nativeEvent.end})
        }>
        {body}
      </Text>
    </View>
  )
}

export default function App() {
  const [baseNumLines, setBaseNumLines] = React.useState(1)
  const [baseLayoutNumLines, setBaseLayoutNumLines] = React.useState(0)

  const [uiNumLines, setUiNumLines] = React.useState(1)
  const [uiLayoutNumLines, setUiLayoutNumLines] = React.useState(0)

  const onPress = React.useCallback((part?: number) => {
    Alert.alert('Pressed', `You pressed the text! Part: ${part}`)
  }, [])

  const onLongPress = React.useCallback((part?: number) => {
    Alert.alert('Long Pressed', `You long pressed the text! Part: ${part}`)
  }, [])

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.scrollView}>
        <View style={styles.box}>
          <RNText style={styles.header}>React Native UITextView Example</RNText>

          <View>
            <RNText style={styles.subheader}>UITextView, inline view</RNText>
            <Text selectable uiTextView style={styles.text}>
              Selectable text with an inline attachment{' '}
              <View style={styles.inlineBadge}>
                <RNText style={styles.inlineBadgeText}>1/3</RNText>
              </View>{' '}
              that wraps with the surrounding text.
            </Text>
            <RNText style={styles.subheader}>
              Transformed inline view at end
            </RNText>
            <Text selectable uiTextView style={styles.text}>
              This fixture verifies that a transformed attachment can extend
              below the final line without being clipped{' '}
              <View style={[styles.inlineBadge, styles.inlineBadgeOffset]}>
                <RNText style={styles.inlineBadgeText}>3/3</RNText>
              </View>
            </Text>
          </View>

          <View>
            <RNText style={styles.subheader}>
              Base RN-Text, not selectable:{' '}
            </RNText>
            <Text style={styles.text}>Hello world!</Text>
          </View>

          <View>
            <RNText style={styles.subheader}>Base RN-Text, selectable:</RNText>
            <RNText selectable style={styles.text}>
              Hello world!
            </RNText>
          </View>

          <View>
            <RNText style={styles.subheader}>RN-UITextView, selectable:</RNText>
            <Text selectable uiTextView style={styles.text}>
              Hello world!
            </Text>
          </View>

          <View>
            <RNText style={styles.subheader}>
              RN-UITextView, highlightable
            </RNText>
            <Text selectable uiTextView style={styles.text}>
              Hello world!
            </Text>
          </View>

          <RNText style={styles.header}>Alignments</RNText>

          <View>
            <RNText style={styles.subheader}>
              RN-UITextView, selectable, highlightable, aligned to left:
            </RNText>
            <Text style={[styles.text, styles.alignLeft]} selectable uiTextView>
              Hello world!
            </Text>
          </View>

          <View>
            <RNText style={styles.subheader}>
              RN-UITextView, selectable, highlightable, aligned to right:
            </RNText>
            <Text
              style={[styles.text, styles.alignRight]}
              selectable
              uiTextView>
              Hello world!
            </Text>
          </View>

          <View>
            <RNText style={styles.subheader}>
              RN-UITextView, selectable, highlightable, aligned to center:
            </RNText>
            <Text
              style={[styles.text, styles.alignCenter]}
              selectable
              uiTextView>
              Hello world!
            </Text>
          </View>

          <View>
            <RNText style={styles.subheader}>
              RN-UITextView, selectable, highlightable, aligned to justify:
            </RNText>
            <Text
              style={[styles.text, styles.alignJustify]}
              selectable
              uiTextView>
              Hello world!
            </Text>
          </View>

          <View>
            <RNText style={styles.subheader}>
              RN-UITextView, selectable, highlightable, auto aligned:
            </RNText>
            <Text style={[styles.text, styles.alignAuto]} selectable uiTextView>
              Hello world!
            </Text>
          </View>

          <RNText style={styles.header}>Styles</RNText>

          <View>
            <RNText style={styles.subheader}>Base, colored</RNText>
            <RNText style={[styles.text, styles.coloredBlue]}>'blue'</RNText>
            <RNText style={[styles.text, styles.coloredHex]}>'#804102'</RNText>
            <RNText style={[styles.text, styles.coloredHexShort]}>
              '#804'
            </RNText>
            <RNText style={[styles.text, styles.coloredHsl]}>
              '#hsl(0, 100%, 50%)'
            </RNText>
          </View>

          <View>
            <RNText style={styles.subheader}>UITextView, colored</RNText>
            <Text
              selectable
              uiTextView
              style={[styles.text, styles.coloredBlue]}>
              'blue'
            </Text>

            <Text
              selectable
              uiTextView
              style={[styles.text, styles.coloredHex]}>
              '#804102'
            </Text>
            <Text
              selectable
              uiTextView
              style={[styles.text, styles.coloredHexShort]}>
              '#804'
            </Text>
            <Text
              selectable
              uiTextView
              style={[styles.text, styles.coloredHsl]}>
              'hsl(0, 100%, 50%)'
            </Text>
          </View>

          <View>
            <RNText style={styles.subheader}>Base, nested styles</RNText>
            <RNText style={styles.text}>
              Root <RNText style={styles.coloredHex}>Child </RNText>
              <RNText style={styles.coloredBlue}>
                Child <RNText style={styles.coloredHsl}>Subchild</RNText>
              </RNText>
            </RNText>
          </View>

          <View>
            <RNText style={styles.subheader}>UITextView, nested styles</RNText>
            <Text selectable uiTextView style={styles.text}>
              Root{' '}
              <Text selectable uiTextView style={styles.coloredHex}>
                Child{' '}
              </Text>
              <Text selectable uiTextView style={styles.coloredBlue}>
                Child{' '}
                <Text selectable uiTextView style={styles.coloredHsl}>
                  Subchild
                </Text>
              </Text>
            </Text>
          </View>

          <View>
            <RNText style={styles.subheader}>Base, backgroundColor</RNText>
            <RNText style={[styles.text, styles.backgroundColor]}>
              Hello world!
            </RNText>
            <RNText style={[styles.text]}>
              Hello world!{' '}
              <RNText style={[styles.text, styles.backgroundColor]}>
                And more!
              </RNText>
            </RNText>
          </View>
          <View>
            <Text style={styles.subheader}>UITextView, backgroundColor</Text>
            <Text
              selectable
              uiTextView
              style={[styles.text, styles.backgroundColor]}>
              Hello world!
            </Text>
            <Text selectable uiTextView style={[styles.text]}>
              Hello world!{' '}
              <Text
                selectable
                uiTextView
                style={[styles.text, styles.backgroundColor]}>
                And more!
              </Text>
            </Text>
          </View>

          <View>
            <RNText style={styles.subheader}>Base, textDecorationLine</RNText>
            <RNText style={[styles.text, styles.underlined]}>
              Hello world!
            </RNText>
            <RNText style={[styles.text, styles.strikethrough]}>
              Hello world!
            </RNText>
            <RNText style={[styles.text, styles.underlinedStrikethrough]}>
              Hello world!
            </RNText>
            <RNText
              style={[
                styles.text,
                styles.underlinedStrikethrough,
                styles.decorationDashed,
              ]}>
              Hello world!
            </RNText>
            <RNText
              style={[
                styles.text,
                styles.underlinedStrikethrough,
                styles.decorationDotted,
              ]}>
              Hello world!
            </RNText>
            <RNText
              style={[
                styles.text,
                styles.underlinedStrikethrough,
                styles.decorationDouble,
              ]}>
              Hello world!
            </RNText>
            <RNText
              style={[
                styles.text,
                styles.underlinedStrikethrough,
                styles.decorationColored,
              ]}>
              Hello world!
            </RNText>
          </View>

          <View>
            <RNText style={styles.subheader}>
              UITextView, textDecorationLine
            </RNText>
            <Text
              selectable
              uiTextView
              style={[styles.text, styles.underlined]}>
              Hello world!
            </Text>
            <Text
              selectable
              uiTextView
              style={[styles.text, styles.strikethrough]}>
              Hello world!
            </Text>
            <Text selectable uiTextView>
              <Text
                selectable
                uiTextView
                style={[styles.text, styles.underlinedStrikethrough]}>
                Hello world!
              </Text>
            </Text>
            <Text selectable uiTextView>
              <Text
                selectable
                uiTextView
                style={[
                  styles.text,
                  styles.underlinedStrikethrough,
                  styles.decorationDashed,
                ]}>
                Hello world!
              </Text>
            </Text>
            <Text selectable uiTextView>
              <Text
                selectable
                uiTextView
                style={[
                  styles.text,
                  styles.underlinedStrikethrough,
                  styles.decorationDotted,
                ]}>
                Hello world!
              </Text>
            </Text>
            <Text selectable uiTextView>
              <Text
                selectable
                uiTextView
                style={[
                  styles.text,
                  styles.underlinedStrikethrough,
                  styles.decorationDouble,
                ]}>
                Hello world!
              </Text>
            </Text>
            <Text selectable uiTextView>
              <Text
                selectable
                uiTextView
                style={[
                  styles.text,
                  styles.underlinedStrikethrough,
                  styles.decorationColored,
                ]}>
                Hello world!
              </Text>
            </Text>
          </View>

          <View>
            <RNText style={styles.subheader}>Base, fontSize</RNText>
            <RNText style={styles.fontSize20}>Twenty</RNText>
            <RNText style={styles.fontSize30}>Twenty</RNText>
          </View>

          <View>
            <Text style={styles.subheader}>UITextView, fontSize</Text>
            <Text selectable uiTextView style={styles.fontSize20}>
              Twenty
            </Text>
            <Text selectable uiTextView style={styles.fontSize30}>
              Twenty
            </Text>
          </View>

          <View>
            <RNText style={styles.subheader}>Base, bold</RNText>
            <RNText style={[styles.text, styles.fontBold]}>Bold</RNText>
          </View>

          <View>
            <Text style={styles.subheader}>UITextView, bold</Text>
            <Text selectable uiTextView style={[styles.text, styles.fontBold]}>
              Bold
            </Text>
          </View>

          <View>
            <RNText style={styles.subheader}>Base, italic</RNText>
            <RNText style={[styles.text, styles.fontItalic]}>Bold</RNText>
          </View>

          <View>
            <Text style={styles.subheader}>UITextView, italic</Text>
            <Text
              selectable
              uiTextView
              style={[styles.text, styles.fontItalic]}>
              Bold
            </Text>
          </View>

          <View>
            <RNText style={styles.subheader}>Base, lineHeight</RNText>
            <RNText style={[styles.text, styles.lineHeight10]}>
              A really long string so that it takes up the width of the screen
              for us to test with.
            </RNText>
            <RNText style={[styles.text, styles.lineHeight30]}>
              A really long string so that it takes up the width of the screen
              for us to test with.
            </RNText>
          </View>

          <View>
            <Text style={styles.subheader}>UITextView, lineHeight</Text>
            <Text
              selectable
              uiTextView
              style={[styles.text, styles.lineHeight10]}>
              A really long string so that it takes up the width of the screen
              for us to test with.
            </Text>
            <Text
              selectable
              uiTextView
              style={[styles.text, styles.lineHeight30]}>
              A really long string so that it takes up the width of the screen
              for us to test with.
            </Text>
          </View>

          <View>
            <RNText style={styles.subheader}>Base, inherits</RNText>
            <RNText style={[styles.text, styles.underlined]}>
              A really long string so that{' '}
              <RNText style={[styles.coloredHex, styles.fontSize30]}>
                it takes{' '}
                <RNText style={styles.coloredHsl}>
                  up the width of the screen
                </RNText>{' '}
              </RNText>
              for us to test with.
            </RNText>
          </View>

          <View>
            <Text style={styles.subheader}>UITextView, inherits</Text>
            <Text
              style={[styles.text, styles.underlined]}
              selectable
              uiTextView>
              A really long string so that{' '}
              <Text style={[styles.coloredHex, styles.fontSize30]}>
                it takes{' '}
                <Text style={styles.coloredHsl}>
                  up the width of the screen
                </Text>{' '}
              </Text>
              for us to test with.
            </Text>
          </View>

          <RNText style={styles.header}>numberOfLines, ellipsizeMode</RNText>

          <View>
            <RNText style={styles.subheader}>Base, numberOfLines</RNText>
            <RNText
              style={[styles.text]}
              ellipsizeMode="tail"
              numberOfLines={2}>
              Tail: A really long string so that it takes up the width of the
              screen for us to test with. This should eventually cut off
            </RNText>
            <View style={styles.spacer} />
            <RNText
              style={[styles.text]}
              numberOfLines={2}
              ellipsizeMode="head">
              Head: A really long string so that it takes up the width of the
              screen for us to test with. This should eventually cut off
            </RNText>
            <View style={styles.spacer} />
            <RNText
              style={[styles.text]}
              numberOfLines={2}
              ellipsizeMode="middle">
              Middle: A really long string so that it takes up the width of the
              screen for us to test with. This should eventually cut off
            </RNText>
            <View style={styles.spacer} />
            <RNText
              style={[styles.text]}
              numberOfLines={2}
              ellipsizeMode="clip">
              Clip: A really long string so that it takes up the width of the
              screen for us to test with. This should eventually cut off
            </RNText>
          </View>

          <View>
            <Text style={styles.subheader}>UITextView, numberOfLines</Text>
            <Text
              selectable
              uiTextView
              numberOfLines={2}
              ellipsizeMode="tail"
              style={[styles.text]}>
              Tail: A really long string so that it takes up the width of the
              screen for us to test with. This should eventually cut off
            </Text>
            <View style={styles.spacer} />
            <Text
              style={[styles.text]}
              numberOfLines={2}
              ellipsizeMode="head"
              selectable
              uiTextView>
              Head: A really long string so that it takes up the width of the
              screen for us to test with. This should eventually cut off
            </Text>
            <View style={styles.spacer} />
            <Text
              style={[styles.text]}
              numberOfLines={2}
              ellipsizeMode="middle"
              selectable
              uiTextView>
              Middle: A really long string so that it takes up the width of the
              screen for us to test with. This should eventually cut off
            </Text>
            <View style={styles.spacer} />
            <Text
              style={[styles.text]}
              numberOfLines={2}
              ellipsizeMode="clip"
              selectable
              uiTextView>
              Clip: A really long string so that it takes up the width of the
              screen for us to test with. This should eventually cut off
            </Text>
          </View>

          <RNText style={styles.header}>Pressable</RNText>

          <View>
            <RNText style={styles.subheader}>Base</RNText>
            <RNText onPress={() => onPress(1)} style={styles.text}>
              Press Me
            </RNText>
            <RNText style={styles.text}>
              Portions of base text:{' '}
              <RNText
                style={[styles.text, styles.coloredBlue, styles.underlined]}
                onPress={() => onPress(1)}
                onLongPress={() => onLongPress(1)}>
                Part One
              </RNText>{' '}
              <RNText
                style={[styles.text, styles.coloredHsl, styles.underlined]}
                onPress={() => onPress(2)}
                onLongPress={() => onLongPress(2)}>
                Part Two
              </RNText>{' '}
              <RNText style={[styles.text]}>Emoji 😅😅😅😅</RNText>P
              <RNText
                style={[styles.text, styles.coloredHex, styles.underlined]}
                onPress={() => onPress(3)}
                onLongPress={() => onLongPress(3)}>
                Part Three{' '}
              </RNText>
            </RNText>
          </View>
          <View>
            <RNText style={styles.subheader}>UITextView</RNText>
            <Text
              style={styles.text}
              selectable
              uiTextView
              onPress={() => onPress(1)}>
              Press Me
            </Text>
            <Text
              style={styles.text}
              selectable
              suppressHighlighting
              uiTextView
              onPress={() => onPress(1)}>
              Press Me without a highlight
            </Text>
            <Text style={styles.text} selectable uiTextView>
              Portions of UITextView text:{' '}
              <Text
                style={[styles.text, styles.coloredBlue, styles.underlined]}
                onPress={() => onPress(1)}
                onLongPress={() => onLongPress(1)}>
                Part One
              </Text>{' '}
              <Text
                style={[styles.text, styles.coloredHsl, styles.underlined]}
                onPress={() => onPress(2)}
                onLongPress={() => onLongPress(2)}>
                Part Two
              </Text>{' '}
              <Text style={[styles.text]}>Emoji 😅😅😅😅</Text>P
              <Text
                style={[styles.text, styles.coloredHex, styles.underlined]}
                onPress={() => onPress(3)}
                onLongPress={() => onLongPress(3)}>
                Part Three{' '}
              </Text>
            </Text>
          </View>

          <View>
            <RNText style={styles.subheader}>
              UITextView, Bluesky emoji child shape
            </RNText>
            <RNText style={styles.fixtureLabel}>
              Control (emoji remains in the string):
            </RNText>
            <Text style={[styles.text, styles.flexOne]} selectable uiTextView>
              {'✅ '}
              <Text
                style={[styles.text, styles.coloredBlue, styles.underlined]}
                onPress={() => onPress(4)}>
                @thebulletin.org
              </Text>
              {' has been verified by '}
              <Text
                style={[styles.text, styles.coloredBlue, styles.underlined]}
                onPress={() => onPress(5)}>
                @bsky.app
              </Text>
              {'.'}
            </Text>
            <RNText style={styles.fixtureLabel}>
              Bluesky shape (nested emoji and empty-string fragments):
            </RNText>
            <Text style={[styles.text, styles.flexOne]} selectable uiTextView>
              {[
                [
                  '',
                  <Text key="emoji" style={[styles.text, styles.systemFont]}>
                    ✅
                  </Text>,
                  ' ',
                ],
                <Text
                  key="first-mention"
                  style={[styles.text, styles.coloredBlue, styles.underlined]}
                  onPress={() => onPress(6)}>
                  @thebulletin.org
                </Text>,
                ' has been verified by ',
                <Text
                  key="second-mention"
                  style={[styles.text, styles.coloredBlue, styles.underlined]}
                  onPress={() => onPress(7)}>
                  @bsky.app
                </Text>,
                '.',
              ]}
            </Text>
          </View>

          <RNText style={styles.header}>onTextLayout</RNText>
          <View>
            <RNText style={styles.subheader}>Base. Press to change</RNText>
            <RNText
              style={styles.text}
              numberOfLines={baseNumLines}
              onTextLayout={e => {
                setBaseLayoutNumLines(e.nativeEvent.lines.length)
              }}
              onPress={() => {
                setBaseNumLines(p => {
                  if (p === 1) return 2
                  return 1
                })
              }}>
              onTextLayout lines.length: {baseLayoutNumLines} Press me Press me
              Press me Press me Press me Press me Press me Press me Press me
            </RNText>
          </View>
          <View>
            <RNText style={styles.subheader}>
              UITextView. Press to change
            </RNText>
            <Text
              style={styles.text}
              numberOfLines={uiNumLines}
              onTextLayout={e => {
                setUiLayoutNumLines(e.nativeEvent.lines.length)
              }}
              onPress={() => {
                setUiNumLines(p => {
                  if (p === 1) return 2
                  return 1
                })
              }}
              selectable
              uiTextView>
              onTextLayout lines.length: {uiLayoutNumLines} Press me Press me
              Press me Press me Press me Press me Press me Press me Press me
            </Text>
          </View>

          <RNText style={styles.header}>onSelectionChange</RNText>
          <View>
            <RNText style={styles.subheader}>
              UITextView. Select to see start/end.
            </RNText>
            <SelectionChangeDemo />
          </View>

          <RNText style={styles.header}>Empty String</RNText>

          <View>
            <RNText style={styles.subheader}>Base</RNText>
            {/* eslint-disable-next-line react/self-closing-comp */}
            <RNText style={styles.text}></RNText>
          </View>
          <View>
            <RNText style={styles.subheader}>UITextView</RNText>
            {/* eslint-disable-next-line react/self-closing-comp */}
            <Text style={styles.text} selectable uiTextView></Text>
          </View>

          <RNText style={styles.fixtureHeader}>allowFontScaling fixture</RNText>
          <RNText style={styles.fixtureLabel}>
            Increase iOS Larger Text. The `allowFontScaling=false` rows should
            stay fixed-size; the `true` rows should grow. Base RN-Text and
            UITextView should match.
          </RNText>
          <RNText style={styles.fixtureLabel}>
            Base RN-Text, allowFontScaling=false
          </RNText>
          <RNText
            allowFontScaling={false}
            style={[styles.fontScalingText, styles.fixtureBorder]}>
            {FONT_SCALING_PARAGRAPH}{' '}
            <RNText style={styles.fontBold}>Bold child.</RNText>
          </RNText>
          <RNText style={styles.fixtureLabel}>
            Base RN-Text, allowFontScaling=true
          </RNText>
          <RNText
            allowFontScaling
            style={[styles.fontScalingText, styles.fixtureBorder]}>
            {FONT_SCALING_PARAGRAPH}{' '}
            <RNText style={styles.fontBold}>Bold child.</RNText>
          </RNText>
          <RNText style={styles.fixtureLabel}>
            UITextView, allowFontScaling=false
          </RNText>
          <Text
            allowFontScaling={false}
            selectable
            uiTextView
            style={[styles.fontScalingText, styles.fixtureBorder]}>
            {FONT_SCALING_PARAGRAPH}{' '}
            <Text style={styles.fontBold}>Bold child.</Text>
          </Text>
          <RNText style={styles.fixtureLabel}>
            UITextView, allowFontScaling=true
          </RNText>
          <Text
            allowFontScaling
            selectable
            uiTextView
            style={[styles.fontScalingText, styles.fixtureBorder]}>
            {FONT_SCALING_PARAGRAPH}{' '}
            <Text style={styles.fontBold}>Bold child.</Text>
          </Text>

          <RNText style={styles.fixtureHeader}>
            #46 fixture — FlatList recycling
          </RNText>
          <RNText style={styles.fixtureLabel}>
            Scroll, select a row, scroll it offscreen and back, then tap
            outside. No crash, selection clears.
          </RNText>
          <View style={styles.recycleList}>
            <FlatList
              data={RECYCLE_ITEMS}
              keyExtractor={item => item.id}
              renderItem={({item}) => (
                <Text selectable uiTextView style={styles.recycleRow}>
                  {item.text}
                </Text>
              )}
            />
          </View>

          <RNText style={styles.fixtureHeader}>
            #42 fixture — Poppins, lineGap=100/1000
          </RNText>
          <RNText style={styles.fixtureLabel}>Base RN-Text:</RNText>
          <RNText style={[styles.customFontText, styles.fixtureBorder]}>
            {CUSTOM_FONT_PARAGRAPH}
          </RNText>
          <RNText style={styles.fixtureLabel}>UITextView:</RNText>
          <Text
            selectable
            uiTextView
            style={[styles.customFontText, styles.fixtureBorder]}>
            {CUSTOM_FONT_PARAGRAPH}
          </Text>
        </View>
      </ScrollView>
    </SafeAreaView>
  )
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'space-around',
  },
  scrollView: {
    flex: 1,
    paddingHorizontal: 10,
  },
  box: {
    gap: 20,
    paddingBottom: 200,
  },
  spacer: {
    height: 10,
  },
  header: {
    fontSize: 26,
    fontWeight: 'bold',
    textAlign: 'center',
  },
  subheader: {
    fontSize: 22,
    fontWeight: 'bold',
  },
  alignCenter: {
    textAlign: 'center',
  },
  alignRight: {
    textAlign: 'right',
  },
  alignLeft: {
    textAlign: 'left',
  },
  alignJustify: {
    textAlign: 'justify',
  },
  alignAuto: {
    textAlign: 'auto',
  },
  text: {
    fontSize: 18,
  },
  flexOne: {
    flex: 1,
  },
  systemFont: {
    fontFamily: 'System',
  },
  coloredBlue: {
    color: 'blue',
  },
  coloredHex: {
    color: '#804102',
  },
  coloredHexShort: {
    color: '#804',
  },
  coloredHsl: {
    color: 'hsl(0, 100%, 50%)',
  },
  underlined: {
    textDecorationLine: 'underline',
  },
  strikethrough: {
    textDecorationLine: 'line-through',
  },
  underlinedStrikethrough: {
    textDecorationLine: 'underline',
  },
  decorationSolid: {
    textDecorationStyle: 'solid',
  },
  decorationDashed: {
    textDecorationStyle: 'dashed',
  },
  decorationDotted: {
    textDecorationStyle: 'dotted',
  },
  decorationDouble: {
    textDecorationStyle: 'double',
  },
  decorationColored: {
    textDecorationColor: 'blue',
  },
  fontSize20: {
    fontSize: 20,
  },
  fontSize30: {
    fontSize: 30,
  },
  fontItalic: {
    fontStyle: 'italic',
  },
  fontBold: {
    fontWeight: 'bold',
  },
  lineHeight10: {
    lineHeight: 10,
  },
  lineHeight30: {
    lineHeight: 30,
  },
  backgroundColor: {
    backgroundColor: 'yellow',
  },
  inlineBadge: {
    paddingVertical: 2,
    paddingHorizontal: 5,
    borderRadius: 999,
    backgroundColor: '#e5e7eb',
  },
  inlineBadgeText: {
    color: '#334155',
    fontSize: 12,
    fontWeight: '500',
  },
  inlineBadgeOffset: {
    transform: [{translateY: 6}],
  },
  selectionRangeLabel: {
    fontSize: 13,
    color: '#444',
  },
  selectionBody: {
    fontSize: 16,
  },
  fontScalingText: {
    fontSize: 18,
    lineHeight: 26,
  },
  customFontText: {
    fontFamily: 'Poppins',
    fontSize: 11,
  },
  fixtureBorder: {
    borderWidth: 1,
    borderColor: 'red',
  },
  fixtureHeader: {
    fontSize: 16,
    fontWeight: 'bold',
  },
  fixtureLabel: {
    fontSize: 13,
    fontWeight: '600',
  },
  recycleList: {
    height: 400,
    borderWidth: 1,
    borderColor: 'red',
  },
  recycleRow: {
    paddingVertical: 12,
    paddingHorizontal: 8,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderColor: '#999',
    fontSize: 14,
  },
})
