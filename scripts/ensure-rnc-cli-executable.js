const fs = require('node:fs')
const path = require('node:path')

if (process.platform !== 'win32') {
  const packagePath = require.resolve(
    '@react-native-community/cli/package.json',
  )
  const packageJson = JSON.parse(fs.readFileSync(packagePath, 'utf8'))
  const binPath = packageJson.bin?.['rnc-cli']

  if (typeof binPath !== 'string') {
    throw new Error('Could not resolve the rnc-cli executable')
  }

  const executablePath = path.resolve(path.dirname(packagePath), binPath)
  const mode = fs.statSync(executablePath).mode

  fs.chmodSync(executablePath, mode | 0o111)
}
