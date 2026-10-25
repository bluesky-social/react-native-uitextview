import type {TextStyle} from 'react-native'
import {flattenStyles} from '../util'

const nativeFontWeight = (fontWeight: TextStyle['fontWeight']) =>
  flattenStyles({}, {fontWeight}).fontWeight

it.each<[TextStyle['fontWeight'], string]>([
  [100, 'ultraLight'],
  ['ultralight', 'ultraLight'],
  [200, 'ultraLight'],
  ['thin', 'ultraLight'],
  [300, 'light'],
  [400, 'normal'],
  ['normal', 'normal'],
  [500, 'medium'],
  [600, 'semibold'],
  [700, 'bold'],
  ['700', 'bold'],
  ['bold', 'bold'],
  [800, 'heavy'],
  ['800', 'heavy'],
  [900, 'heavy'],
  ['heavy', 'heavy'],
  ['black', 'heavy'],
])('maps fontWeight %p to %p', (fontWeight, expected) => {
  expect(nativeFontWeight(fontWeight)).toBe(expected)
})

it('keeps 700 and bold at the same weight', () => {
  expect(nativeFontWeight(700)).toBe(nativeFontWeight('bold'))
})
