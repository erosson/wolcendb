#!/usr/bin/env node
const util = require('../util')
const path = require('path')
const fs = require('fs').promises
const _ = require('lodash/fp')
const mkdirp = require('mkdirp')
const {promisify} = require('util')
const glob = promisify(require('glob'))
const xlsxLoader = require('@erosson/xlsx-loader').default

const rootSrc = path.join(util.PATH.DATAMINE, 'lang')
const rootDest = path.join(util.PATH.DATAMINE_BUILD, 'lang')
const jsonDest = path.join(util.PATH.DATAMINE_BUILD, 'lang.json')

async function main() {
  const srcs = await glob('*', {cwd: rootSrc})
  await mkdirp(rootDest)
  fs.writeFile(jsonDest, JSON.stringify(srcs.map(src => src.toLowerCase())))

  const pairs = srcs.map(s => [path.join(rootSrc, s), path.join(rootDest, s.replace(/\.pak$/, '.json')).toLowerCase()])
  await Promise.all(pairs.map(runPak))
  return pairs
}
async function runPak([srcDir, destJson]) {
  const srcs = await glob(path.join(srcDir, '*'))
  const jsons = await Promise.all(srcs.map(runXml))
  const json = _.fromPairs(jsons)
  await mkdirp(path.dirname(destJson))
  return fs.writeFile(destJson, JSON.stringify(json))
}
async function runXml(src) {
  const json = await xlsxLoader.apply({resourcePath: src})
  return [path.basename(src), JSON.parse(json)]
}
if (require.main == module) {
  main().catch(err => {
    console.error(err)
    process.exit(1)
  })
}
module.exports = {runXml}
