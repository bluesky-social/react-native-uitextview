import {Platform, Text as RNText} from 'react-native'
import {act, create, type ReactTestRenderer} from 'react-test-renderer'
import RNUITextViewChild from '../RNUITextViewChildNativeComponent'
import RNUITextView from '../RNUITextViewNativeComponent'
import {UITextView as Text} from '../Text'

jest.mock('../RNUITextViewChildNativeComponent', () => 'RNUITextViewChild')
jest.mock('../RNUITextViewNativeComponent', () => 'RNUITextView')

let renderer: ReactTestRenderer

afterEach(() => {
  if (renderer) {
    act(() => renderer.unmount())
  }
  jest.restoreAllMocks()
})

it('passes paragraph props to text fragments and inherits them through nested spans', () => {
  act(() => {
    renderer = create(
      <Text
        selectable
        uiTextView
        paragraphMarkerEnd={32}
        paragraphHangingIndent={44}>
        {'\t•\tAn item with '}
        <Text style={{fontWeight: 'bold'}}>{'bold text\n'}</Text>
        <Text paragraphMarkerEnd={60} paragraphHangingIndent={72}>
          {'\t12.\tA nested item\n'}
        </Text>
        <Text paragraphHangingIndent={0}>{'Unindented text'}</Text>
      </Text>,
    )
  })

  const fragments = renderer.root.findAllByType(RNUITextViewChild)
  expect(
    fragments.map(({props}) => [
      props.text,
      props.paragraphMarkerEnd,
      props.paragraphHangingIndent,
    ]),
  ).toEqual([
    ['\t•\tAn item with ', 32, 44],
    ['bold text\n', 32, 44],
    ['\t12.\tA nested item\n', 60, 72],
    ['Unindented text', 32, 0],
  ])
  expect(renderer.root.findByType(RNUITextView).props).not.toHaveProperty(
    'paragraphMarkerEnd',
  )
  expect(renderer.root.findByType(RNUITextView).props).not.toHaveProperty(
    'paragraphHangingIndent',
  )
})

it('removes inherited paragraph props when they are unset on an update', () => {
  const answer = (enabled: boolean) => (
    <Text
      selectable
      uiTextView
      paragraphMarkerEnd={enabled ? 32 : undefined}
      paragraphHangingIndent={enabled ? 44 : undefined}>
      <Text>{'\t•\tAn item'}</Text>
    </Text>
  )
  act(() => {
    renderer = create(answer(true))
  })
  expect(
    renderer.root.findByType(RNUITextViewChild).props.paragraphHangingIndent,
  ).toBe(44)

  act(() => renderer.update(answer(false)))
  const {props} = renderer.root.findByType(RNUITextViewChild)
  expect(props.paragraphMarkerEnd).toBeUndefined()
  expect(props.paragraphHangingIndent).toBeUndefined()
})

it.each([
  ['ios', false, true],
  ['ios', true, false],
  ['android', true, true],
] as const)(
  'ignores paragraph props for base Text on %s (selectable=%s, uiTextView=%s)',
  (platform, selectable, uiTextView) => {
    jest.replaceProperty(Platform, 'OS', platform)
    act(() => {
      renderer = create(
        <Text
          selectable={selectable}
          uiTextView={uiTextView}
          paragraphMarkerEnd={32}
          paragraphHangingIndent={44}>
          Hello
        </Text>,
      )
    })

    const {props} = renderer.root.findByType(RNText)
    expect(props.children).toBe('Hello')
    expect(props).not.toHaveProperty('paragraphMarkerEnd')
    expect(props).not.toHaveProperty('paragraphHangingIndent')
    expect(renderer.root.findAllByType(RNUITextViewChild)).toHaveLength(0)
  },
)
