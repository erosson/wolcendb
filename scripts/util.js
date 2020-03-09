const path = require('path')
const fs = require('fs').promises
const mkdirp = require('mkdirp')
const {promisify} = require('util')
const glob = promisify(require('glob'))

const PATH = {}
PATH.ROOT = path.normalize(path.join(__dirname, ".."))
PATH.DATAMINE_TMP = path.join(PATH.ROOT, "datamine.tmp")
PATH.DATAMINE = path.join(PATH.ROOT, "datamine")
PATH.DATAMINE_BUILD = path.join(PATH.ROOT, "build-datamine")
PATH.BUILD_IMG = path.join(PATH.ROOT, "build-img")
PATH.BUILD_SSR = path.join(PATH.ROOT, "build-ssr2")
PATH.PUBLIC = path.join(PATH.ROOT, "public")

async function copyGlobs({src, dest, patterns}) {
  const groups = await Promise.all(patterns.map(pattern => glob(pattern, {cwd: src})))
  const paths = flatten(groups)
  const pairs = paths.map(p => [path.join(src, p), path.join(dest, p)])
  await Promise.all(pairs.map(async ([s,d]) => {
    await mkdirp(path.dirname(d))
    return fs.copyFile(s, d)
  }))
  return pairs
}
function flatten(groups) {
  return [].concat.apply([], groups)
}

module.exports = {PATH, flatten, copyGlobs}
