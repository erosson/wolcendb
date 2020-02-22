import datamine from '../datamine/imports.mjs'
import Elm from '../datamine.tmp/BuildSearchIndexCLI.elm.js'
import fs from 'fs'
import {promisify} from 'util'
// https://stackoverflow.com/questions/46745014/alternative-for-dirname-in-node-when-using-the-experimental-modules-flag
import {dirname} from 'path'
import {fileURLToPath} from 'url'
const __dirname = dirname(fileURLToPath(import.meta.url))

const app = Elm.Elm.BuildSearchIndexCLI.init({flags: {datamine}})
app.ports.stderr.subscribe(err => {
    // console.error(err)
  console.error(err.slice(-10000))
  process.exit(1)
})
app.ports.stdout.subscribe(out => {
  promisify(fs.writeFile)(__dirname + '/../datamine/searchIndex.json', JSON.stringify(out))
  .then(() => process.exit(0))
  .catch(err => {
    // console.error(err)
    console.error(err.slice(-10000))
    process.exit(2)
  })
})
