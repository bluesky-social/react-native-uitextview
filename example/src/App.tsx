import React from 'react'
import {StyleSheet, View} from 'react-native'
import {UITextView} from 'react-native-uitextview'

export default function App() {
  const [text] = React.useState('test')

  return (
    <View style={styles.container}>
      <UITextView uiTextView={true} style={{fontSize: 20}} selectable={true}>
        This is text. IT's selectable and highlightable 👀. It's also being
        rendered with Fabric.
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
    backgroundColor: 'red'
  }
})
