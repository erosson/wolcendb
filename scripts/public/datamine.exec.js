#!/usr/bin/env node
const util = require('../util')
const path = require('path')
const fs = require('fs').promises
const mkdirp = require('mkdirp')
const {promisify} = require('util')
const rimraf = promisify(require('rimraf'))
const glob = promisify(require('glob'))

const srcDir = util.PATH.DATAMINE_BUILD
const destDir = util.PATH.PUBLIC_DATAMINE

async function main() {
  await fs.access(srcDir)
  const langs = await glob(path.join('lang', '*'), {cwd: srcDir})
  const pairs =
    ['datamine.json', 'searchIndex.json'].concat(langs)
    .map(src => [
      path.join(srcDir, src),
      path.join(destDir, (src === 'searchIndex.json' ? src : src.toLowerCase())),
    ])

  await rimraf(destDir)
  await Promise.all(pairs.map(async ([s, d]) => {
    await mkdirp(path.dirname(d))
    return fs.copyFile(s, d)
  }))
}
if (require.main == module) {
  main().catch(err => {
    console.error(err)
    process.exit(1)
  })
}
