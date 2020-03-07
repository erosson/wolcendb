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
const buildRevisions = require('../public/buildRevisions.json')
const langs = require('../datamine/lang.json')

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
    const baseFlags = {buildRevisions, langs, datamine, searchIndex, changelog}
    return Promise.all([
      // fetch a list of pages from SSRPagesCLI
      new Promise((resolve, reject) => {
        const flags = baseFlags
        const pagesApp = Elm.SSRPagesCLI.init({flags})
        pagesApp.ports.ssrCliPages.subscribe(resolve)
      }),
      // initialize a SSRRenderCLI renderer. We initialize this once and reuse it for every render.
      // Rerunning the elm program for every render was simpler, but way too slow!
      // This avoids rebuilding datamine indexes, etc.
      fs.readFile('./datamine.tmp/SSRRenderCLI.elm.js')
      .then(elm => elm.toString())
      .then(elm => {
        const flags = {...baseFlags, url: ''}
        const renderDom = new jsdom.JSDOM(template, {runScripts: 'outside-only'})
        renderDom.window.eval(`${elm}\n\nwindow.app = Elm.SSRRenderCLI.init({node: document.getElementById('root'), flags: ${JSON.stringify(flags)}})`)
        return renderDom
      })
    ])
  })
  .then(([ssrCliPages, renderDom]) => {
    const pages = [
      '', '/changelog', '/privacy', '/affix', '/ailment', '/passive', '/skill', '/city/building_seekers_garrison', '/city/building_trade_assembly', '/gem', '/reagent', '/loot', '/loot/unique',
    // ]
    // startup time is too slow to run the generated pages!
    ].concat(ssrCliPages)
    console.log('page count: ', pages.length)
    // return Promise.all(pages.map(path => run(renderDom, path)))
    //
    // NOPE, too many pages for that. Run in batches instead.
    // https://stackoverflow.com/questions/53964228/how-do-i-perform-a-large-batch-of-promises
    // https://blog.neverendingqs.com/2017/12/02/promises-batches-reduce.html
    const batchSize = 1
    const startTime = Date.now()
    return _.flow(
      _.chunk(batchSize),
      // .convert({cap:false}) passes the map index. https://github.com/lodash/lodash/issues/2387
      _.reduce.convert({cap: false})((chain, batch, i) =>
        chain.then(() => {
          if (i % 50 == 0) console.log('batch', i, 'done: ', i * batchSize, '/', pages.length, ", ", (Date.now() - startTime) / 1000, 'sec')
          return Promise.all(batch.map(path => run(renderDom, path)))
        }),
        Promise.resolve(),
      ),
    )(pages)
  })
  .catch(err => {
    console.error(err && err.slice ? err.slice(-10000) : err)
    process.exit(1)
  })
}
function run(renderDom, path_) {
  const url = "https://wolcendb.erosson.org"+path_
  const dest = SSR_BUILD_DIR + path_ + '/index.html'
  // console.log('dest', dest)
  return staticElm({renderDom, url, dest, path_})
  // return staticElm({renderDom, url, path_}).then(html => console.log(html))
  // return staticElm({renderDom, url, path_}).then(html => console.log(html.length))
}
function staticElm({renderDom, dest, url, path_}) {
  return Promise.resolve().then(() => {
    // send port message to change url; wait for port message saying view is rendered
    const oldHtml = renderDom.window.document.documentElement.outerHTML
    renderDom.window.eval(`app.ports.ssrCliRender.send("${url}")`)
    // renderDom.window.app.ports.ssrCliRender.send(url)
    return new Promise(resolve => {
      // renderDom.window.app.ports.urlChange.subscribe(resolve)
      // NOPE that didn't work. Instead, poll for html changes
      let i = 0
      function pollUntilChanged() {
        if (oldHtml == renderDom.window.document.documentElement.outerHTML) {
          i += 1
          if (i % 100 == 0) console.log('polling...', url, i, oldHtml)
          setTimeout(pollUntilChanged, 1)
        }
        else {
          // console.log('resolved', url, i)
          resolve()
        }
      }
      pollUntilChanged()
    })
  })
  .then(() => {
    // ssr'ed content is non-interactive, since Elm can't access it. Disable interactive elements.
    renderDom.window.eval(`Array.from(document.getElementsByTagName('a')).map(el => {el.setAttribute('href', '#'); el.removeAttribute('target'); el.removeAttribute('onClick');})`)
    renderDom.window.eval(`Array.from(document.getElementsByTagName('input')).map(el => el.setAttribute('readonly', 'readonly'))`)
    renderDom.window.eval(`Array.from(document.getElementsByTagName('textarea')).map(el => el.setAttribute('readonly', 'readonly'))`)
    // return Promise.resolve(renderDom.window.document.getElementById('root').innerHTML)
    return '<!DOCTYPE html>\n' + renderDom.window.document.documentElement.outerHTML
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
