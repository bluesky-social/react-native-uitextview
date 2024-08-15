import React from 'react'
import {StyleSheet, View} from 'react-native'
import {UITextView} from 'react-native-uitextview'

export default function App() {
  const [text] = React.useState('test')

  return (
    <View style={styles.container}>
      <UITextView style={styles.box} uiTextView={true} selectable={true}>
        {text}
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
    width: 80,
    height: 80,
    marginVertical: 20,
    backgroundColor: 'red'
  }
})
