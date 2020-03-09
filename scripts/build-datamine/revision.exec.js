#!/usr/bin/env node
const util = require('../util')
const path = require('path')
const fs = require('fs').promises
const _ = require('lodash/fp')
const mkdirp = require('mkdirp')

const dest = path.join(util.PATH.DATAMINE_BUILD, 'revision.json')
const src = path.join(util.PATH.DATAMINE, 'revision.txt')

async function main() {
  const f = await fs.readFile(src)
  const str = await f.toString()
  const json = _.flow(
    _.split('\n'),
    _.filter(line => line.trim() !== ''),
    _.map(line => line.split(':').map(s => s.trim())),
    _.fromPairs,
  )(str)
  await mkdirp(path.dirname(dest))
  return fs.writeFile(dest, JSON.stringify(json))
}
if (require.main == module) {
  main().catch(err => {
    console.error(err)
    process.exit(1)
  })
}
