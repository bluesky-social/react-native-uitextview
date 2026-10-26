import {useState} from 'react'
import {Button, StyleSheet, Text as RNText, View} from 'react-native'
import {UITextView as Text} from '@bsky.app/react-native-uitextview'

export function HangingIndentExample() {
  const [narrow, setNarrow] = useState(false)
  const [enabled, setEnabled] = useState(true)
  const paragraphProps = {
    paragraphMarkerEnd: enabled ? 32 : undefined,
    paragraphHangingIndent: enabled ? 44 : undefined,
  }

  return (
    <View>
      <RNText style={styles.heading}>Selectable lists (LTR)</RNText>
      <RNText>
        Drag-select across the whole answer. Wrapped lines should align with the
        item text; the red border should contain every line. Change the width or
        remove the indents to check that layout updates.
      </RNText>
      <Button
        title={narrow ? 'Use full width' : 'Use narrow width'}
        onPress={() => setNarrow(value => !value)}
      />
      <Button
        title={enabled ? 'Remove indents' : 'Restore indents'}
        onPress={() => setEnabled(value => !value)}
      />
      <Text
        selectable
        uiTextView
        style={[styles.answer, narrow && styles.narrow]}>
        {'😀 你好 — one selectable answer, including all the lists.\n'}
        <Text {...paragraphProps}>
          {'\t•\tA bullet with enough text to wrap onto several lines. '}
          <Text style={styles.bold}>
            This nested bold span inherits the indent.
          </Text>
          {' The following text stays in the same paragraph.\n'}
        </Text>
        <Text {...paragraphProps}>
          {'\t•\tA second bullet. Both paragraphs in this child share the same tab stops and wrapped-line indent.\n' +
            '\t•\tAnother paragraph in the same child, with enough text to wrap and check its alignment.\n'}
        </Text>
        <Text {...paragraphProps}>
          {
            '\t9.\tA numbered item whose marker ends in the same column as the wider numbers below.\n'
          }
        </Text>
        <Text {...paragraphProps}>
          {
            '\t12.\tA multi-digit marker with wrapped text aligned underneath the start of the item text.\n'
          }
          <Text
            paragraphMarkerEnd={enabled ? 60 : undefined}
            paragraphHangingIndent={enabled ? 72 : undefined}>
            {
              '\t123.\tA nested item with a wider marker and a deeper hanging indent. This also wraps onto multiple lines.\n'
            }
          </Text>
        </Text>
        {
          'This final paragraph has no indent. Its wrapped lines should return to the left edge of the text view.'
        }
      </Text>
    </View>
  )
}

const styles = StyleSheet.create({
  heading: {
    fontSize: 22,
    fontWeight: 'bold',
  },
  answer: {
    fontSize: 18,
    lineHeight: 26,
    textAlign: 'left',
    writingDirection: 'ltr',
    borderWidth: 1,
    borderColor: 'red',
  },
  narrow: {
    width: 240,
  },
  bold: {
    fontWeight: 'bold',
  },
})
