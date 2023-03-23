#!/usr/bin/env node
const util = require('../util')
const path = require('path')
const mkdirp = require('mkdirp')
const fs = require('fs').promises
const {promisify} = require('util')
const rimraf = promisify(require('rimraf'))
const glob = promisify(require('glob'))
const lang = require('./lang.exec.js')
const _ = require('lodash/fp')
const xml2js = require('xml2js')
const xml2json = promisify((new xml2js.Parser()).parseString)

const dest = path.join(util.PATH.DATAMINE_BUILD, 'datamine.json')

async function main() {
  const json = await buildJson()
  await mkdirp(path.dirname(dest))
  return fs.writeFile(dest, JSON.stringify(json))
}
async function buildJson() {
  const revisionF = await fs.readFile(path.join(util.PATH.DATAMINE_BUILD, 'revision.json'))
  const revision = JSON.parse(await revisionF.toString())

  const localizationXmls = await glob(path.join('localization', '**', '*.xml'), {cwd: util.PATH.DATAMINE})
  const localizationJsons = await Promise.all(localizationXmls.map(async src => {
    const [_, json] = await lang.runXml(path.join(util.PATH.DATAMINE, src))
    return [src.replace(/\.xml$/, '.json'), json]
  }))

  const gameXmls = await glob(path.join('Game', '**', '*.xml'), {cwd: util.PATH.DATAMINE})
  const gameJsons = await Promise.all(gameXmls.map(async src => {
    try {
      const f = await fs.readFile(path.join(util.PATH.DATAMINE, src))
      const xml = await f.toString()
      const json = await xml2json(xml)
      return [src.replace(/\.xml$/, '.json'), json]
    }
    catch (cause) {
      throw new Error(`error converting '${src}' to json`, {cause})
    }
  }))

  return {
    'revision.json': revision,
    ..._.fromPairs(localizationJsons),
    ..._.fromPairs(gameJsons),
  }
}
if (require.main == module) {
  main().catch(err => {
    console.error(err)
    process.exit(1)
  })
}
