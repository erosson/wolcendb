#!/usr/bin/env node
const util = require('../util')
const path = require('path')
const fs = require('fs').promises
const mkdirp = require('mkdirp')
const {promisify} = require('util')
const rimraf = promisify(require('rimraf'))
const glob = promisify(require('glob'))
const imagemin = require('imagemin')
const imageminPngquant = require('imagemin-pngquant')

async function main() {
  await rimraf(util.PATH.BUILD_IMG)
  const srcs = util.flatten(await Promise.all([
    glob("Game/Libs/UI/u_resources/armors/**/*.png", {cwd: util.PATH.DATAMINE_TMP}),
    glob("Game/Libs/UI/u_resources/weapons/**/*.png", {cwd: util.PATH.DATAMINE_TMP}),
    glob("Game/Libs/UI/u_resources/spells/Active_Skills/**/*.png", {cwd: util.PATH.DATAMINE_TMP}),
    glob("Game/Libs/UI/u_resources/spells/variants/**/*.png", {cwd: util.PATH.DATAMINE_TMP}),
    glob("Game/Libs/UI/u_resources/gems/**/*.png", {cwd: util.PATH.DATAMINE_TMP}),
    glob("Game/Libs/UI/u_resources/reagents/**/*.png", {cwd: util.PATH.DATAMINE_TMP}),
  ]))
  const pairs = srcs.map(s => [path.join(util.PATH.DATAMINE_TMP, s), path.join(util.PATH.BUILD_IMG, s.toLowerCase())])
  await Promise.all(pairs.map(runPng))
  return pairs
}
async function runPng([src, dest]) {
  const destDir = path.dirname(dest)
  await mkdirp(destDir)
  // imagemin seems to only work with posix-style paths
  posixify = p => path.relative(util.PATH.ROOT, p).replace(/\\/g, '/')
  // console.log(posixify(src), posixify(destDir))
  // image compression. files extracted from wolcen are (understandably) not built for the web
  await imagemin([posixify(src)], {
    destination: posixify(destDir),
    plugins: [imageminPngquant({
      quality: [0.3, 0.7],
      strip: true,
    })],
  })
  const tmp = path.join(destDir, path.basename(src))
  // imagemin fails silently - for example, if the input file is missing.
  // I don't want silent failure here, so fs.access below will reject on failure.
  await fs.access(tmp)

  // imagemin destination must be a directory, sadly - it copies uppercased names.
  // lowercase it here.
  if (path.basename(src) !== path.basename(src).toLowerCase()) {
    await fs.rename(tmp, dest)
  }
  return Promise.resolve(dest)
}
if (require.main == module) {
  main().catch(err => {
    console.error(err)
    process.exit(1)
  })
}
