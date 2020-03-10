#!/usr/bin/env node
const {Elm} = require('./SearchIndex.elm.js')
const util = require('../util')
const path = require('path')
const fs = require('fs').promises
const _ = require('lodash/fp')
const mkdirp = require('mkdirp')
const child_process = require('child_process')

const dest = path.join(util.PATH.DATAMINE_BUILD, 'searchIndex.json')

// TODO one search-index per language. Right now we can only search english!
async function main() {
  const f = await fs.readFile(path.join(util.PATH.DATAMINE_BUILD, 'datamine.json'))
  const datamine = JSON.parse(await f.toString())
  const app = Elm.SearchIndex.init({flags: {datamine}})
  app.ports.stderr.subscribe(err => {throw new Error(err && err.slice ? err.slice(-10000) : err)})
  app.ports.stdout.subscribe(async json => {
    await mkdirp(path.dirname(dest))
    await fs.writeFile(dest, JSON.stringify(json)),
    process.exit(0)
  })
}
if (require.main == module) {
  main().catch(err => {
    console.error(err)
    process.exit(1)
  })
}
