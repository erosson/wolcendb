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
      promisify(fs.writeFile)(__dirname + '/../datamine/sizes.json', JSON.stringify(sizes)),

      // Cloudflare caches based on file extension. It doesn't cache `.json` and does cache `.js`.
      // https://support.cloudflare.com/hc/en-us/articles/200172516-Understanding-Cloudflare-s-CDN
      //
      // Using a fake file extension is recommended by some guy here:
      // https://community.cloudflare.com/t/which-file-extensions-does-cloudflare-cache-in-pro-paid-plan/40234/2
      // It's very silly-looking, but the alternative is using up Cloudflare page rules for custom caching. Page rules are expensive and scarce; let's not.
      //
      // Redbot tests cacheability of our stuff. For example:
      // https://redbot.org/?uri=https%3A%2F%2Fimg-wolcendb.erosson.org%2Fdatamine%2F1.0.8.2_ER%2Fdatamine.json.js%3Ft%3D12345
      // https://redbot.org/?uri=https%3A%2F%2Fimg-wolcendb.erosson.org%2Fdatamine%2F1.0.8.2_ER%2Fdatamine.json%3Ft%3D12345
      // The `CF-Cache-Status` header is important. "Dynamic" is bad, that's completely uncached
      promisify(fs.writeFile)(__dirname + '/../build-img/datamine/' + buildRevision + '/searchIndex.json.js', searchIndexStr),
      promisify(fs.writeFile)(__dirname + '/../build-img/datamine/' + buildRevision + '/datamine.json.js', datamineStr),
    ])
  )
  .then(() => process.exit(0))
  .catch(err => {
    // console.error(err)
    console.error(err && err.slice ? err.slice(-10000) : err)
    process.exit(2)
  })
})
