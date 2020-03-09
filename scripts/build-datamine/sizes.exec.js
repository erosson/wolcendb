#!/usr/bin/env node
const util = require('../util')
const path = require('path')
const fs = require('fs').promises
const _ = require('lodash/fp')
const mkdirp = require('mkdirp')

const dest = path.join(util.PATH.DATAMINE_BUILD, 'sizes.json')

async function main() {
  const datamine = await (await fs.readFile(path.join(util.PATH.DATAMINE_BUILD, 'datamine.json'))).toString()
  const searchIndex = await (await fs.readFile(path.join(util.PATH.DATAMINE_BUILD, 'searchIndex.json'))).toString()
  const revision = JSON.parse(await (await fs.readFile(path.join(util.PATH.DATAMINE_BUILD, 'revision.json'))).toString())
  const json = {
    slug: Date.now(),
    buildRevision: revision['build-revision'],
    datamine: datamine.length,
    searchIndex: searchIndex.length,
  }

  await mkdirp(path.dirname(dest))
  await fs.writeFile(dest, JSON.stringify(json))
}
if (require.main == module) {
  main().catch(err => {
    console.error(err)
    process.exit(1)
  })
}
