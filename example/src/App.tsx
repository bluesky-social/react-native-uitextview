import React from 'react'
import {StyleSheet, View} from 'react-native'
import {UITextView} from 'react-native-uitextview'

export default function App() {
  const [text] = React.useState('test')

  return (
    <View style={styles.container}>
      <UITextView style={styles.box} uiTextView={true} selectable={true}>
        <UITextView>Test text!</UITextView>
        <UITextView>More text!!</UITextView>
      </UITextView>
    </View>
  )
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center'
  },
  box: {
    width: 100,
    height: 80,
    marginVertical: 20,
    backgroundColor: 'red'
  }
})
