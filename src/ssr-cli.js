 // https://korban.net/posts/elm/2019-04-23-how-i-generate-static-html-from-elm-elmstatic/
const fs = require('fs').promises
const jsdom = require('jsdom')
const datamine = require('../public/datamine.json')
const searchIndex = require('../public/searchIndex.json')
const mkdirp = require('mkdirp')
const path = require('path')
const ncp = require('ncp')
const {promisify} = require('util')
const {Elm} = require('../datamine.tmp/SSRPagesCLI.elm.js')
const _ = require('lodash/fp')

const SSR_BUILD_DIR = './build-ssr'

main()

function main() {
  promisify(ncp.ncp)('./build', SSR_BUILD_DIR)
  .then(() => mkdirp(SSR_BUILD_DIR+'/no-ssr'))
  .then(() => fs.copyFile(SSR_BUILD_DIR+'/index.html', SSR_BUILD_DIR+'/no-ssr/index.html'))
  .then(() => Promise.all([
    fs.readFile(SSR_BUILD_DIR+'/index.html').then(f => f.toString()),
    fs.readFile('./CHANGELOG.md').then(f => f.toString()),
  ]))
  .then(([template, changelog]) => {
    const flags = {datamine, searchIndex, changelog}
    const pagesApp = Elm.SSRPagesCLI.init({flags})
    return new Promise((resolve, reject) => {
      pagesApp.ports.ssrCliPages.subscribe(pages => resolve([template, changelog, pages]))
    })
  })
  .then(async ([template, changelog, ssrCliPages]) => {
    const run = run_(template, changelog)
    const pages = [
      '', '/changelog', '/privacy', '/affix', '/ailment', '/passive', '/skill', '/city/building_seekers_garrison', '/city/building_trade_assembly', '/gem', '/reagent',
    ]
    // startup time is too slow to run the generated pages!
    // ].concat(ssrCliPages)
    console.log('page count: ', pages.length)
    // return Promise.all(pages.map(path => run(path)))
    //
    // NOPE, too many pages for that. Run in batches instead.
    // https://stackoverflow.com/questions/53964228/how-do-i-perform-a-large-batch-of-promises
    // https://blog.neverendingqs.com/2017/12/02/promises-batches-reduce.html
    const batchSize = 10
    const startTime = Date.now()
    return _.flow(
      _.chunk(batchSize),
      // .convert({cap:false}) passes the map index. https://github.com/lodash/lodash/issues/2387
      _.reduce.convert({cap: false})((chain, batch, i) =>
        chain.then(() => {
          console.log('batch', i, 'done: ', i * batchSize, '/', pages.length, ", ", (Date.now() - startTime) / 1000, 'sec')
          return Promise.all(batch.map(path => run(path)))
        }),
        Promise.resolve(),
      ),
    )(pages)
  })
  .catch(err => {
    console.error(err)
    process.exit(1)
  })
}
function run_(template, changelog) {
  return path_ => {
    const flags = {datamine, searchIndex, changelog, url: "https://wolcendb.erosson.org"+path_}
    const dest = SSR_BUILD_DIR + path_ + '/index.html'
    // console.log('dest', dest)
    return staticElm({path_, flags, template, dest})
    // staticElm({path_, flags, template}).then(console.log)
  }
}
function staticElm({template, flags, dest, path_}) {
  const dom = new jsdom.JSDOM(template, {runScripts: 'outside-only'})
  return fs.readFile('./datamine.tmp/SSRRenderCLI.elm.js')
  .then(elm => elm.toString())
  .then(elm => {
    try {
      dom.window.eval(`${elm}\n\nlet app = Elm.SSRRenderCLI.init({node: document.getElementById('root'), flags: ${JSON.stringify(flags || {})}})`)
      // ssr'ed content is non-interactive, since Elm can't access it. Disable interactive elements.
      dom.window.eval(`Array.from(document.getElementsByTagName('a')).map(el => {el.setAttribute('href', '#'); el.removeAttribute('target'); el.removeAttribute('onClick');})`)
      dom.window.eval(`Array.from(document.getElementsByTagName('input')).map(el => el.setAttribute('readonly', 'readonly'))`)
      dom.window.eval(`Array.from(document.getElementsByTagName('textarea')).map(el => el.setAttribute('readonly', 'readonly'))`)
      // return Promise.resolve(dom.window.document.getElementById('root').innerHTML)
      return Promise.resolve('<!DOCTYPE html>\n' + dom.window.document.documentElement.outerHTML)
    }
    catch (e) {
      console.error('ssrrender error', {path_, dest})
      throw e
    }
  })
  .then(html => {
    if (dest) {
      return mkdirp(path.dirname(dest))
      .then(() => fs.writeFile(dest, html))
    }
    else {
      return Promise.resolve(html)
    }
  })
}
