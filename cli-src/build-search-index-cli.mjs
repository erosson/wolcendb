import datamine from '../datamine/imports.mjs'
import Elm from '../datamine.tmp/BuildSearchIndexCLI.elm.js'
import fs from 'fs'
import mkdirp from 'mkdirp'
import {promisify} from 'util'
// https://stackoverflow.com/questions/46745014/alternative-for-dirname-in-node-when-using-the-experimental-modules-flag
import {dirname} from 'path'
import {fileURLToPath} from 'url'
import revision from '../datamine/revision.json'
const __dirname = dirname(fileURLToPath(import.meta.url))
const slug = Date.now()
const buildRevision = revision['build-revision']

const app = Elm.Elm.BuildSearchIndexCLI.init({flags: {datamine}})
app.ports.stderr.subscribe(err => {
  // console.error(err)
  console.error(err && err.slice ? err.slice(-10000) : err)
  process.exit(1)
})
app.ports.stdout.subscribe(searchIndex => {
  const searchIndexStr = JSON.stringify(searchIndex)
  const datamineStr = JSON.stringify(datamine)
  const sizes = {
    slug,
    buildRevision,
    searchIndex: searchIndexStr.length,
    datamine: datamineStr.length,
  }
  mkdirp(__dirname + '/../build-img/datamine/' + buildRevision)
  .then(() =>
    Promise.all([
      promisify(fs.writeFile)(__dirname + '/../public/searchIndex.json', searchIndexStr),
      promisify(fs.writeFile)(__dirname + '/../public/datamine.json', datamineStr),
      promisify(fs.writeFile)(__dirname + '/../build-img/datamine/' + buildRevision + '/searchIndex.json', searchIndexStr),
      promisify(fs.writeFile)(__dirname + '/../build-img/datamine/' + buildRevision + '/datamine.json', datamineStr),
      promisify(fs.writeFile)(__dirname + '/../datamine/sizes.json', JSON.stringify(sizes)),
    ])
  )
  .then(() => process.exit(0))
  .catch(err => {
    // console.error(err)
    console.error(err && err.slice ? err.slice(-10000) : err)
    process.exit(2)
  })
})
