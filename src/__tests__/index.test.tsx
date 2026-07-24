import {Text as RNText} from 'react-native'
import {UITextView} from '../Text.web'

it('uses React Native Text on web without forwarding native-only props', () => {
  const element = UITextView({
    children: 'Hello',
    uiTextView: true,
    onSelectionChange: jest.fn(),
    testID: 'text',
  })

  expect(element.type).toBe(RNText)
  expect(element.props).toEqual({children: 'Hello', testID: 'text'})
})
