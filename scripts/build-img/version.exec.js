#!/usr/bin/env node
const util = require('../util')
const path = require('path')
const fs = require('fs').promises
const mkdirp = require('mkdirp')
const {promisify} = require('util')
const rimraf = promisify(require('rimraf'))
const glob = promisify(require('glob'))
const revision = require(path.join(util.PATH.DATAMINE_BUILD, 'revision.json'))

const dest = path.join(util.PATH.BUILD_IMG, 'datamine', revision['build-revision'])

async function main() {
  const langs = await glob(path.join('lang', '*'), {cwd: util.PATH.DATAMINE_BUILD})
  const pairs =
    ['datamine.json', 'searchIndex.json'].concat(langs)
    // The `+ '.js'` below is very important!
    // Cloudflare caches based on file extension. It doesn't cache `.json` and does cache `.js`, so we use the name `.json.js` to force caching.
    // https://support.cloudflare.com/hc/en-us/articles/200172516-Understanding-Cloudflare-s-CDN
    //
    // Using a fake file extension is recommended by some guy here:
    // https://community.cloudflare.com/t/which-file-extensions-does-cloudflare-cache-in-pro-paid-plan/40234/2
    // It's very silly-looking, but the alternative is using up Cloudflare page rules for custom caching. Page rules are expensive and scarce; let's not.
    //
    // Redbot is useful to (manually) test cacheability of our stuff. For example:
    // https://redbot.org/?uri=https%3A%2F%2Fimg-wolcendb.erosson.org%2Fdatamine%2F1.0.8.2_ER%2Fdatamine.json.js%3Ft%3D12345
    // https://redbot.org/?uri=https%3A%2F%2Fimg-wolcendb.erosson.org%2Fdatamine%2F1.0.8.2_ER%2Fdatamine.json%3Ft%3D12345
    // The `CF-Cache-Status` header is important. "Dynamic" is bad, that's completely uncached
    .map(src => [
      path.join(util.PATH.DATAMINE_BUILD, src),
      path.join(dest, (src === 'searchIndex.json' ? src : src.toLowerCase()) + '.js'),
    ])

  await rimraf(dest)
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
