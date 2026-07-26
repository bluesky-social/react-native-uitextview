import {resolvePressContext} from '../press'

it('creates a new group for pressable text', () => {
  const onPress = jest.fn()
  const result = resolvePressContext(
    'child',
    {onPress, suppressHighlighting: true},
    {highlightGroup: 'parent', onLongPress: jest.fn()},
  )

  expect(result).toEqual({
    highlightGroup: 'child|p',
    suppressHighlighting: true,
    pressRetentionOffset: undefined,
    onPress,
    onLongPress: undefined,
  })
})

it('inherits the owner through non-pressable nested text', () => {
  const ancestor = {
    highlightGroup: 'parent',
    suppressHighlighting: false,
    pressRetentionOffset: {top: 1, right: 2, bottom: 3, left: 4},
    onPress: jest.fn(),
    onLongPress: jest.fn(),
  }

  expect(resolvePressContext('child', {}, ancestor)).toBe(ancestor)
})

it('treats a long-press-only child as its own pressable group', () => {
  const onLongPress = jest.fn()
  expect(
    resolvePressContext(
      'child',
      {onLongPress},
      {highlightGroup: 'parent', onPress: jest.fn()},
    ),
  ).toEqual({
    highlightGroup: 'child|l',
    suppressHighlighting: false,
    pressRetentionOffset: undefined,
    onPress: undefined,
    onLongPress,
  })
})

it('uses the pressable owner retention offset', () => {
  const pressRetentionOffset = {top: 10, right: 20, bottom: 30, left: 40}

  expect(
    resolvePressContext(
      'child',
      {onPress: jest.fn(), pressRetentionOffset},
      {
        highlightGroup: 'parent',
        pressRetentionOffset: {top: 1, right: 2, bottom: 3, left: 4},
      },
    ).pressRetentionOffset,
  ).toBe(pressRetentionOffset)
})
