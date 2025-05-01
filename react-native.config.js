const project = (() => {
  const path = require('node:path')
  try {
    const {configureProjects} = require('react-native-test-app')

    return configureProjects({
      android: {},
      ios: {
        sourceDir: path.join('example', 'ios'),
      },
    })
  } catch (e) {
    return undefined
  }
})()

/**
 * @type {import('@react-native-community/cli-types').UserDependencyConfig}
 */
module.exports = {
  dependencies: {
    // Help rn-cli find and autolink this library
    'react-native-uitextview': {
      root: __dirname,
    },
  },
  ...(project ? {project} : undefined),
}
